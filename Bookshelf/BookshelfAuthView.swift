//
//  BookshelfAuthView.swift
//  Bookshelf
//
//  Created by Christian Anovert on 7/30/26.
//




import SwiftUI
import AuthenticationServices
 
 
 
private enum AuthShelf {
    static let espresso   = Color(red: 0.13, green: 0.08, blue: 0.05)   // deepest wood, top of gradient
    static let walnut      = Color(red: 0.27, green: 0.17, blue: 0.11)   // mid wood tone
    static let walnutLight  = Color(red: 0.35, green: 0.23, blue: 0.15)   // lighter plank highlight
    static let shelfLine    = Color(red: 0.09, green: 0.05, blue: 0.03)   // dark line between shelves
    static let brass         = Color(red: 0.79, green: 0.63, blue: 0.29)   // accent / buttons
    static let brassDim      = Color(red: 0.79, green: 0.63, blue: 0.29).opacity(0.55)
    static let parchment    = Color(red: 0.95, green: 0.90, blue: 0.78)   // primary text
    static let parchmentDim = Color(red: 0.95, green: 0.90, blue: 0.78).opacity(0.68)
    static let errorRed     = Color(red: 0.80, green: 0.36, blue: 0.34)
}
 
// MARK: - Quotes
 
private let readingQuotes: [(text: String, author: String)] = [
    ("A reader lives a thousand lives before he dies. The man who never reads lives only one.", "George R.R. Martin"),
    ("The more that you read, the more things you will know. The more that you learn, the more places you'll go.", "Dr. Seuss"),
    ("Books are a uniquely portable magic.", "Stephen King"),
    ("I have always imagined that Paradise will be a kind of library.", "Jorge Luis Borges"),
    ("Once you learn to read, you will be forever free.", "Frederick Douglass"),
    ("A book is a dream that you hold in your hand.", "Neil Gaiman"),
    ("There is no friend as loyal as a book.", "Ernest Hemingway"),
    ("Reading should not be presented to children as a chore, but as a gift.", "Kate DiCamillo")
]
 
// MARK: - Main View
 
struct BookshelfAuthView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var mode: AuthMode = .login
    @State private var loginIdentifier = ""   // email OR username, login only
    @State private var username = ""          // sign up only
    @State private var email = ""             // sign up only
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var currentQuote = readingQuotes.randomElement()!
 
    enum AuthMode: Equatable {
        case login, signUp
    }
 
    var body: some View {
        ZStack {
            WoodShelfBackground()
 
            VStack(spacing: 0) {
                Spacer(minLength: 48)
 
                header
 
                Spacer(minLength: 28)
 
                quoteBlock
                    .padding(.horizontal, 36)
 
                Spacer(minLength: 36)
 
                modeSwitcher
                    .padding(.horizontal, 32)
                    .padding(.bottom, 22)
 
                formCard
                    .padding(.horizontal, 28)
 
                Spacer(minLength: 20)
 
                bookRow
                    .padding(.bottom, 18)
            }
        }
        .onAppear(perform: shuffleQuote)
    }
 
    // Pick a new quote each time the screen appears, avoiding an
    // immediate repeat of the one currently showing.
    private func shuffleQuote() {
        var next = readingQuotes.randomElement()!
        while readingQuotes.count > 1 && next.text == currentQuote.text {
            next = readingQuotes.randomElement()!
        }
        currentQuote = next
    }
 
    // MARK: Header
 
    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.pages")
                .font(.system(size: 30, weight: .light))
                .foregroundColor(AuthShelf.brass)
 
            Text("Bookshelf")
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundColor(AuthShelf.parchment)
                .tracking(0.5)
        }
    }
 
    // MARK: Quote
 
    private var quoteBlock: some View {
        VStack(spacing: 8) {
            Text("\u{201C}\(currentQuote.text)\u{201D}")
                .font(.system(size: 15, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(AuthShelf.parchmentDim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .id(currentQuote.text)
                .transition(.opacity)
 
            Text("— \(currentQuote.author)")
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundColor(AuthShelf.brass)
        }
        .animation(.easeInOut(duration: 0.35), value: currentQuote.text)
    }
 
    // MARK: Login / Sign up switcher
 
    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            switcherButton(title: "Log in", target: .login)
            switcherButton(title: "Sign up", target: .signUp)
        }
        .padding(4)
        .background(AuthShelf.espresso.opacity(0.55))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AuthShelf.brassDim, lineWidth: 1)
        )
        .cornerRadius(10)
    }
 
    private func switcherButton(title: String, target: AuthMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = target
                authViewModel.errorMessage = nil
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(mode == target ? AuthShelf.brass : Color.clear)
                .foregroundColor(mode == target ? AuthShelf.espresso : AuthShelf.parchmentDim)
                .cornerRadius(7)
        }
        .buttonStyle(.plain)
    }
 
    // MARK: Form
 
    private var formCard: some View {
        VStack(spacing: 14) {
            if mode == .signUp {
                shelfField(placeholder: "Username", text: $username, isSecure: false)
                shelfField(placeholder: "Email", text: $email, isSecure: false, keyboardType: .emailAddress)
            } else {
                shelfField(placeholder: "Email or username", text: $loginIdentifier, isSecure: false, keyboardType: .emailAddress)
            }
 
            shelfField(placeholder: "Password", text: $password, isSecure: true)
 
            if mode == .signUp {
                shelfField(placeholder: "Confirm password", text: $confirmPassword, isSecure: true)
            }
 
            if mode == .login {
                HStack {
                    Spacer()
                    Button("Forgot password?") {}
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AuthShelf.brass)
                }
            }
 
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AuthShelf.errorRed)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
 
            Button
            {
                if mode == .login
                {
                    authViewModel.logIn(identifier: loginIdentifier, password: password)
                }
                else
                {
                    authViewModel.signUp(username: username, email: email, password: password, confirmPassword: confirmPassword)
                }
            }
            label: {
                Group {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(AuthShelf.espresso)
                    } else {
                        Text(mode == .login ? "Log in" : "Create account")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(AuthShelf.brass)
                .foregroundColor(AuthShelf.espresso)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(authViewModel.isLoading)
            .padding(.top, 4)
 
            HStack {
                Rectangle().fill(AuthShelf.brassDim).frame(height: 1)
                Text("or")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(AuthShelf.parchmentDim)
                Rectangle().fill(AuthShelf.brassDim).frame(height: 1)
            }
            .padding(.vertical, 2)
 
            SignInWithAppleButton(.continue) { request in
                authViewModel.prepareAppleRequest(request)
            } onCompletion: { result in
                authViewModel.handleAppleCompletion(result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .cornerRadius(10)
        }
        .padding(20)
        .background(AuthShelf.walnutLight.opacity(0.45))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AuthShelf.brassDim, lineWidth: 1)
        )
        .cornerRadius(16)
    }
 
    private func shelfField(placeholder: String, text: Binding<String>, isSecure: Bool, keyboardType: UIKeyboardType = .default) -> some View {
        Group {
            if isSecure {
                SecureField("", text: text, prompt: Text(placeholder).foregroundColor(AuthShelf.parchmentDim))
            } else {
                TextField("", text: text, prompt: Text(placeholder).foregroundColor(AuthShelf.parchmentDim))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .font(.system(size: 15, design: .rounded))
        .foregroundColor(AuthShelf.parchment)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AuthShelf.espresso.opacity(0.55))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(AuthShelf.brassDim, lineWidth: 1)
        )
        .cornerRadius(9)
    }
 
    // MARK: Decorative book row (signature element)
 
    private var bookRow: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(bookSpineColors.enumerated()), id: \.offset) { index, color in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: bookSpineWidths[index], height: bookSpineHeights[index])
            }
        }
    }
 
    private let bookSpineColors: [Color] = [
        Color(red: 0.55, green: 0.24, blue: 0.20),
        Color(red: 0.36, green: 0.42, blue: 0.30),
        Color(red: 0.79, green: 0.63, blue: 0.29),
        Color(red: 0.29, green: 0.30, blue: 0.44),
        Color(red: 0.62, green: 0.35, blue: 0.20),
        Color(red: 0.44, green: 0.20, blue: 0.22),
        Color(red: 0.30, green: 0.42, blue: 0.40),
        Color(red: 0.70, green: 0.53, blue: 0.24),
        Color(red: 0.34, green: 0.24, blue: 0.42),
        Color(red: 0.50, green: 0.28, blue: 0.18)
    ]
    private let bookSpineWidths: [CGFloat] = [14, 10, 16, 12, 9, 15, 11, 13, 10, 17]
    private let bookSpineHeights: [CGFloat] = [46, 58, 40, 52, 60, 44, 56, 48, 50, 42]
}
 
// MARK: - Wood shelf background
 
private struct WoodShelfBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [AuthShelf.walnut, AuthShelf.espresso],
                    startPoint: .top,
                    endPoint: .bottom
                )
 
                // Horizontal shelf boards
                let shelfCount = 7
                let shelfSpacing = geo.size.height / CGFloat(shelfCount)
                VStack(spacing: 0) {
                    ForEach(0..<shelfCount, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: shelfSpacing)
                            .overlay(
                                Rectangle()
                                    .fill(AuthShelf.shelfLine)
                                    .frame(height: 2),
                                alignment: .bottom
                            )
                    }
                }
 
                // Subtle vertical wood grain
                HStack(spacing: 0) {
                    ForEach(0..<10, id: \.self) { i in
                        Rectangle()
                            .fill(i % 2 == 0 ? Color.white.opacity(0.015) : Color.black.opacity(0.03))
                            .frame(width: geo.size.width / 10)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}
 
// MARK: - Preview
 
#Preview {
    BookshelfAuthView()
        .environmentObject(AuthViewModel())
}
