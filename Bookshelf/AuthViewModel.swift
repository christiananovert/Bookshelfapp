//
//  AuthViewModel.swift
//  Bookshelf
//
//  For now, only Sign in with Apple is wired up to Firebase.
//  Email/password methods are stubbed so the form's buttons compile
//  and won't crash if tapped — fill these in when you're ready.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
 
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    /// The signed-in user's username, for display (e.g. "Hello, Chris"). Empty
    /// when signed out or when it hasn't finished loading yet.
    @Published var username: String = ""
 
    private let db = Firestore.firestore()
 
    // Holds the raw nonce between starting and completing an Apple sign-in.
    private var currentAppleNonce: String?
 
    init() {
        // Reflects the current Firebase session on launch.
        if let currentUser = Auth.auth().currentUser {
            isLoggedIn = true
            Task { await loadUsername(uid: currentUser.uid) }
        }
    }
 
    /// Looks up `users/{uid}`'s username field and publishes it. Falls back to the
    /// Firebase Auth display name (set during email sign up, or by Apple) if the
    /// Firestore doc isn't there for some reason.
    private func loadUsername(uid: String) async {
        if let doc = try? await db.collection("users").document(uid).getDocument(),
           let fetchedUsername = doc.data()?["username"] as? String {
            username = fetchedUsername
        } else {
            username = Auth.auth().currentUser?.displayName ?? ""
        }
    }
 
    // MARK: Sign up (email + unique username + password)
 
    func signUp(username: String, email: String, password: String, confirmPassword: String) {
        errorMessage = nil
 
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
 
        guard !trimmedUsername.isEmpty, !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard Self.isValidUsername(trimmedUsername) else {
            errorMessage = "Usernames must be 3–20 characters: letters, numbers, and underscores only."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
 
        let usernameKey = trimmedUsername.lowercased()
        isLoading = true
 
        Task {
            do {
                let usernameRef = db.collection("usernames").document(usernameKey)
 
                // Fast-fail check before we even create the account.
                let existing = try await usernameRef.getDocument()
                if existing.exists {
                    isLoading = false
                    errorMessage = "That username is already taken."
                    return
                }
 
                // Create the actual Firebase Auth account.
                let authResult = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
                let uid = authResult.user.uid
 
                // Best-effort: attach the username as the account's display name.
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = trimmedUsername
                try? await changeRequest.commitChanges()
 
                // Claim the username + write the profile doc atomically. Wrapping this
                // in a transaction closes the race window from before: if two sign-ups
                // for the same username land at the same moment, Firestore serializes
                // them and only the first transaction to commit sees the username as
                // still available — the second re-reads, finds it taken, and aborts.
                do {
                    try await claimUsername(usernameKey: usernameKey, uid: uid, username: trimmedUsername, email: trimmedEmail)
                } catch {
                    // Roll back the orphaned auth account rather than leave a user
                    // with no profile/username record.
                    try? await authResult.user.delete()
                    throw error
                }
 
                self.username = trimmedUsername
                isLoading = false
                isLoggedIn = true
            } catch {
                isLoading = false
                errorMessage = (error as NSError).localizedDescription
            }
        }
    }
 
    // MARK: Log in (email OR username + password)
 
    func logIn(identifier: String, password: String) {
        errorMessage = nil
 
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
 
        isLoading = true
 
        Task {
            do {
                let email: String
                if trimmed.contains("@") {
                    // Looks like an email — use it directly.
                    email = trimmed
                } else {
                    // Treat it as a username and look up the email behind it.
                    let doc = try await db.collection("usernames").document(trimmed.lowercased()).getDocument()
                    guard let lookedUpEmail = doc.data()?["email"] as? String else {
                        isLoading = false
                        errorMessage = "No account found for that username."
                        return
                    }
                    email = lookedUpEmail
                }
 
                let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
                await loadUsername(uid: authResult.user.uid)
                isLoading = false
                isLoggedIn = true
            } catch {
                isLoading = false
                errorMessage = (error as NSError).localizedDescription
            }
        }
    }
 
    // MARK: Username claim (atomic)
 
    /// Atomically re-checks that `usernameKey` is still free and, if so, writes both
    /// the `usernames/{usernameKey}` and `users/{uid}` docs in one transaction. If the
    /// username was claimed by a concurrent sign-up in the meantime, this throws and
    /// nothing is written — the caller is expected to roll back the auth account it
    /// just created.
    ///
    /// Firestore's transaction API predates async/await, so this wraps the
    /// closure-based `runTransaction(_:completion:)` in a continuation.
    private func claimUsername(usernameKey: String, uid: String, username: String, email: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.runTransaction({ transaction, errorPointer -> Any? in
                let usernameRef = self.db.collection("usernames").document(usernameKey)
 
                let snapshot: DocumentSnapshot
                do {
                    snapshot = try transaction.getDocument(usernameRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
 
                if snapshot.exists {
                    errorPointer?.pointee = NSError(
                        domain: "AuthViewModel",
                        code: 409,
                        userInfo: [NSLocalizedDescriptionKey: "That username is already taken."]
                    )
                    return nil
                }
 
                transaction.setData(["uid": uid, "email": email], forDocument: usernameRef)
 
                let userRef = self.db.collection("users").document(uid)
                transaction.setData([
                    "username": username,
                    "email": email,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: userRef)
 
                return nil
            }) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
 
 
    func signOut() {
        try? Auth.auth().signOut()
        isLoggedIn = false
        username = ""
    }
 
    // MARK: Sign in with Apple
 
    // Call this to configure the ASAuthorizationAppleIDRequest before presenting it.
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }
 
    // Call this from the completion handler of the Apple sign-in button.
    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
 
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentAppleNonce,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Couldn't read Apple credentials."
                return
            }
 
            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: nonce,
                fullName: credential.fullName
            )
 
            isLoading = true
            Auth.auth().signIn(with: firebaseCredential) { [weak self] authResult, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        self.isLoading = false
                        self.errorMessage = error.localizedDescription
                    } else if let uid = authResult?.user.uid {
                        await self.loadUsername(uid: uid)
                        self.isLoading = false
                        self.isLoggedIn = true
                    }
                }
            }
        }
    }
 
    // MARK: Validation
 
    private static func isValidUsername(_ value: String) -> Bool {
        guard value.count >= 3, value.count <= 20 else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
        return value.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
 
    // MARK: Nonce helpers (required by Apple to prevent replay attacks)
 
    private static func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }
 
    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
