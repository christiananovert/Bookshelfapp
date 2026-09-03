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
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var errorMessage: String?
    @Published var isLoading = false

    // Holds the raw nonce between starting and completing an Apple sign-in.
    private var currentAppleNonce: String?

    init() {
        // Reflects the current Firebase session on launch.
        isLoggedIn = Auth.auth().currentUser != nil
    }

    // MARK: Email / password — not implemented yet

    func signUp(email: String, password: String, confirmPassword: String) {
        isLoggedIn = true
    }

    func logIn(email: String, password: String) {
        isLoggedIn = true
    }

    // MARK: Sign out

    func signOut() {
        try? Auth.auth().signOut()
        isLoggedIn = false
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
            Auth.auth().signIn(with: firebaseCredential) { [weak self] _, error in
                Task { @MainActor in
                    self?.isLoading = false
                    if let error {
                        self?.errorMessage = error.localizedDescription
                    } else {
                        self?.isLoggedIn = true
                    }
                }
            }
        }
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
