//
//  Secrets.swift
//  Bookshelf
//
//  Created by Christian Anovert on 9/3/26.
//
import Foundation

enum Secrets {
    static var googleBooksAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GoogleBooksAPIKey") as? String,
              !key.isEmpty else {
            fatalError("Missing GoogleBooksAPIKey — check Secrets.xcconfig is set up correctly.")
        }
        return key
    }
}

