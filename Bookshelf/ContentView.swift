 //
//  ContentView.swift
//  Bookshelf
//
//  Created by Christian Anovert on 7/30/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        if authViewModel.isLoggedIn {
            HomeView()
                .environmentObject(authViewModel)
        } else{
            BookshelfAuthView()
                .environmentObject(authViewModel)
        }
    }
}

#Preview {
    ContentView()
}
