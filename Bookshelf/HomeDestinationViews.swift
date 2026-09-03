//
//  HomeDestinationViews.swift
//  Bookshelf
//
//  Created by Christian Anovert on 8/31/26.
//

import SwiftUI
 
// MARK: - Shared placeholder layout
 
/// A simple full-screen placeholder that matches the app's warm,
/// book-themed look. Swap the body out for real content later.
private struct PlaceholderPage: View {
    let title: String
    let systemImage: String
    let caption: String
 
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Shelf.wallTop, Shelf.wallBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
 
            VStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 84, height: 84)
                    .background(
                        Circle().fill(Shelf.coverRed)
                    )
                    .overlay(
                        Circle().stroke(Shelf.coverGold.opacity(0.7), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
 
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(Shelf.ink)
 
                Text(caption)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Shelf.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
 
// MARK: - Settings
 
struct SettingsView: View {
    var body: some View {
        PlaceholderPage(
            title: "Settings",
            systemImage: "gearshape.fill",
            caption: "Account, notifications, and app preferences will live here."
        )
    }
}
 
// MARK: - Friends
 
struct FriendsView: View {
    var body: some View {
        PlaceholderPage(
            title: "Friends",
            systemImage: "person.2.fill",
            caption: "See who's on Bookshelf, manage requests, and find new friends here."
        )
    }
}
 

 
// MARK: - For You
 
struct ForYouView: View {
    var body: some View {
        PlaceholderPage(
            title: "For You",
            systemImage: "sparkles.rectangle.stack.fill",
            caption: "A personalized feed of books to discover, tailored to your taste."
        )
    }
}
 
