//
//  Settingsview.swift
//  Bookshelf
//
//  Created by Christian Anovert on 9/4/26.
//

import SwiftUI
 
// MARK: - Settings
 
struct SettingsView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Shelf.wallTop, Shelf.wallBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
 
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Account")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Shelf.ink.opacity(0.55))
                        .textCase(.uppercase)
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
 
                    settingsCard {
                        NavigationLink {
                            ChangeUsernameView()
                        } label: {
                            SettingsRow(icon: "at", title: "Change Username")
                        }
                        .buttonStyle(.plain)
 
                        settingsDivider
 
                        NavigationLink {
                            ChangeNameView()
                        } label: {
                            SettingsRow(icon: "person.text.rectangle.fill", title: "Change Name")
                        }
                        .buttonStyle(.plain)
                    }
 
                    Text("Appearance")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Shelf.ink.opacity(0.55))
                        .textCase(.uppercase)
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
 
                    settingsCard {
                        NavigationLink {
                            ChangeLibraryLookView()
                        } label: {
                            SettingsRow(icon: "paintpalette.fill", title: "Change Library Look")
                        }
                        .buttonStyle(.plain)
                    }
 
                    // Add more sections/rows here as Settings grows.
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
 
    /// Wraps a group of settings rows in a rounded card, matching the app's shelf aesthetic.
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Shelf.ink.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }
 
    private var settingsDivider: some View {
        Divider()
            .padding(.leading, 52)
            .overlay(Shelf.ink.opacity(0.1))
    }
}
 
/// A single tappable row within a settings card.
private struct SettingsRow: View {
    let icon: String
    let title: String
 
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Shelf.coverGold))
 
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Shelf.ink)
 
            Spacer()
 
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Shelf.ink.opacity(0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
 
// MARK: - Settings destinations
 
/// Placeholder page for updating the user's @username. Empty for now.
struct ChangeUsernameView: View {
    var body: some View {
        PlaceholderPage(
            title: "Change Username",
            systemImage: "at",
            caption: "Pick a new username for your account."
        )
    }
}
 
/// Placeholder page for updating the user's display name. Empty for now.
struct ChangeNameView: View {
    var body: some View {
        PlaceholderPage(
            title: "Change Name",
            systemImage: "person.text.rectangle.fill",
            caption: "Update the name shown on your profile."
        )
    }
}
 
/// Placeholder page for customizing the look of the library shelves. Empty for now.
struct ChangeLibraryLookView: View {
    var body: some View {
        PlaceholderPage(
            title: "Change Library Look",
            systemImage: "paintpalette.fill",
            caption: "Choose a new theme, wallpaper, or shelf style for your library."
        )
    }
}
 
