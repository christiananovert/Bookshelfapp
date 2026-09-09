//
//  HomeView.swift
//  Bookshelf
//
//  Created by Christian Anovert on 7/30/26.
//
//

import SwiftUI
 
enum Shelf {
    static let wallTop    = Color(red: 0.93, green: 0.86, blue: 0.72)   // warm plaster
    static let wallBottom = Color(red: 0.86, green: 0.76, blue: 0.58)
    static let board      = Color(red: 0.52, green: 0.34, blue: 0.20)   // walnut
    static let boardLight = Color(red: 0.64, green: 0.44, blue: 0.27)
    static let boardEdge  = Color(red: 0.33, green: 0.20, blue: 0.11)
    static let ink        = Color(red: 0.24, green: 0.19, blue: 0.14)
 
    // Cover/book-frame palette (leather-bound look)
    static let coverRed      = Color(red: 0.45, green: 0.13, blue: 0.13)
    static let coverRedLight = Color(red: 0.58, green: 0.19, blue: 0.17)
    static let coverGold     = Color(red: 0.80, green: 0.66, blue: 0.30)
    static let page          = Color(red: 0.97, green: 0.94, blue: 0.86)
}
 
// MARK: - Navigation destinations
 
/// The five screens reachable from HomeView's buttons.
enum HomeDestination: Hashable {
    case settings
    case friends
    case library
    case forYou
    case clubs
}
 
struct HomeView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
 
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Shelf.wallTop, Shelf.wallBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
 
                VStack(spacing: 0) {
                    TopBar(signOutAction: { authViewModel.signOut() })
 
                    Spacer(minLength: 12)
 
                    BookFrameCard(username: authViewModel.username)
                        .padding(.horizontal, 20)
 
                    Spacer(minLength: 12)
 
                    BottomNavBar()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .settings:
                    SettingsView()
                case .friends:
                    FriendsView()
                case .library:
                    LibraryView()
                case .forYou:
                    ForYouView()
                case .clubs:
                    ClubsView()
                }
            }
        }
    }
}
 
// MARK: - Top bar
 
/// Sign out (trailing) and Settings (leading, placeholder) controls pinned to the top.
private struct TopBar: View {
    let signOutAction: () -> Void
 
    var body: some View {
        HStack {
            NavigationLink(value: HomeDestination.settings) {
                IconPillLabel(systemName: "gearshape.fill")
            }
            .buttonStyle(.plain)
 
            Spacer()
 
            Button(action: signOutAction) {
                Text("Sign out")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Color.black.opacity(0.22))
                    )
            }
        }
        .padding(.top, 14)
        .padding(.horizontal, 18)
    }
}
 
/// A round, glassy icon label used for the top bar's placeholder buttons.
private struct IconPillLabel: View {
    let systemName: String
 
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white.opacity(0.9))
            .frame(width: 34, height: 34)
            .background(
                Circle().fill(Color.black.opacity(0.22))
            )
    }
}
 
// MARK: - Middle: book-cover "frame" for the friends' review feed
 
/// Renders the main content area as the front cover of an open book —
/// a leather-look cover with a gold-rule border, framing an empty page
/// where the friends' reviews feed will eventually go. The header now
/// greets the signed-in user by their username instead of a static label.
private struct BookFrameCard: View {
    /// The signed-in user's username. Empty while it's still loading (e.g.
    /// right after launch, before Firestore responds), in which case a
    /// generic greeting is shown instead of leaving a blank gap.
    let username: String
 
    var body: some View {
        VStack(spacing: 0) {
            // Header stitched into the "cover"
            Text(username.isEmpty ? "Hello!" : "Hello, \(username)")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .padding(.top, 18)
                .padding(.bottom, 14)
 
            // Inner "page" — empty for now, ready to hold the feed later
            RoundedRectangle(cornerRadius: 10)
                .fill(Shelf.page)
                .padding(.horizontal, 14)
                .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Shelf.coverRedLight, Shelf.coverRed],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            // Gold rule just inside the cover edge, like foil-stamped trim
            RoundedRectangle(cornerRadius: 14)
                .stroke(Shelf.coverGold.opacity(0.7), lineWidth: 1.5)
                .padding(6)
        )
        .overlay(
            // Spine shadow down the left edge
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.35), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Spacer()
            }
        )
        .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 10)
        .frame(maxHeight: .infinity)
    }
}
 
// MARK: - Bottom navigation
 
/// Placeholder bottom bar: the user's own library, their friends, a
/// "for you" style book discovery feed, and their club chats/DMs.
private struct BottomNavBar: View {
    var body: some View {
        HStack {
            NavigationLink(value: HomeDestination.library) {
                NavIconLabel(systemName: "books.vertical.fill", label: "Library")
            }
            .buttonStyle(.plain)
 
            Spacer()
 
            NavigationLink(value: HomeDestination.friends) {
                NavIconLabel(systemName: "person.2.fill", label: "Friends")
            }
            .buttonStyle(.plain)
 
            Spacer()
 
            NavigationLink(value: HomeDestination.forYou) {
                NavIconLabel(systemName: "sparkles.rectangle.stack.fill", label: "For You")
            }
            .buttonStyle(.plain)
 
            Spacer()
 
            NavigationLink(value: HomeDestination.clubs) {
                NavIconLabel(systemName: "bubble.left.and.bubble.right.fill", label: "Clubs")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 22)
        .background(
            Shelf.boardEdge
                .opacity(0.92)
                .overlay(
                    Rectangle().fill(Shelf.boardLight).frame(height: 2),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
 
private struct NavIconLabel: View {
    let systemName: String
    let label: String
 
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: 20))
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .foregroundColor(.white.opacity(0.9))
    }
}
