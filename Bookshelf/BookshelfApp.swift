//
//  BookshelfApp.swift
//  Bookshelf
//
//  Created by Christian Anovert on 7/30/26.
//

import SwiftUI
import FirebaseCore

@main
struct BookshelfApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
