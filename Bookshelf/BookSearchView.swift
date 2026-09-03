//
//  BookSearchView.swift
//  Bookshelf
//
//  Created by Christian Anovert on 9/3/26.
//

import SwiftUI

struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [GoogleBookItem] = []
    @State private var isSearching = false

    /// Called when the user picks a status for a search result.
    var onAdd: (LibraryBook) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(results, id: \.id) { item in
                    resultRow(item)
                }
            }
            .listStyle(.plain)
            .overlay {
                if isSearching
                {
                    ProgressView()
                }
                else if let errorMessage
                {
                    Text(errorMessage).foregroundColor(.red).padding()
                }
                else if results.isEmpty && !query.isEmpty
                {
                    ContentUnavailableView("No results", systemImage: "book.closed")
                }
            }
            .searchable(text: $query, prompt: "Title, author, or ISBN")
            .onSubmit(of: .search) { runSearch() }
            .navigationTitle("Add a Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func resultRow(_ item: GoogleBookItem) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.volumeInfo.secureThumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2))
            }
            .frame(width: 40, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.volumeInfo.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                Text(item.volumeInfo.authors?.joined(separator: ", ") ?? "Unknown author")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Menu {
                Button("Want to Read") { add(item, status: .wantToRead) }
                Button("Currently Reading") { add(item, status: .reading) }
                Button("Read") { add(item, status: .read) }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
            }
        }
        .padding(.vertical, 4)
    }

    private func add(_ item: GoogleBookItem, status: ReadingStatus) {
        let book = LibraryBook(
            title: item.volumeInfo.title,
            author: item.volumeInfo.authors?.first ?? "Unknown",
            status: status,
            spineColor: item.volumeInfo.title.spineColor,
            progress: status == .read ? 1.0 : 0.0,
            coverURL: item.volumeInfo.secureThumbnailURL   // NEW
        )
        onAdd(book)
        dismiss()
    }

    @State private var errorMessage: String?

    private func runSearch() {
        guard !query.isEmpty else { return }
        isSearching = true
        errorMessage = nil
        Task {
            do {
                let raw = try await searchBooks(query: query)
                results = raw.filter { !$0.looksLikeBundle }
            } catch {
                results = []
                errorMessage = error.localizedDescription
            }
            isSearching = false
        }
    }
}

// MARK: - Google Books networking

struct GoogleBooksResponse: Decodable {
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Decodable, Identifiable {
    var id: String { volumeInfo.title + (volumeInfo.authors?.first ?? "") }
    let volumeInfo: VolumeInfo
}

extension GoogleBookItem {
    var looksLikeBundle: Bool {
        let bundleKeywords = [
            "box set", "boxed set", "boxset",
            "collection", "complete series", "complete collection",
            "omnibus", "bundle", "trilogy bundle",
            "books 1-", "books 1–", "vol. 1-", "volumes 1-", "deluxe"
        ]
        let haystack = volumeInfo.title.lowercased()
        return bundleKeywords.contains { haystack.contains($0) }
    }
}

struct VolumeInfo: Decodable {
    let title: String
    let authors: [String]?
    let imageLinks: ImageLinks?

    var secureThumbnailURL: URL? {
        guard let raw = imageLinks?.thumbnail else { return nil }
        return URL(string: raw.replacingOccurrences(of: "http://", with: "https://"))
    }
}

struct ImageLinks: Decodable {
    let thumbnail: String?
}

func searchBooks(query: String) async throws -> [GoogleBookItem] {
    let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(encoded)&maxResults=20&printType=books&key=\(Secrets.googleBooksAPIKey)")!
    let (data, _) = try await URLSession.shared.data(from: url)
    let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
    return result.items ?? []
}

// Simple deterministic spine color so imported books still fit your shelf aesthetic.
private extension String {
    var spineColor: Color {
        let palette: [Color] = [
            Color(red: 0.29, green: 0.30, blue: 0.44),
            Color(red: 0.62, green: 0.35, blue: 0.20),
            Color(red: 0.55, green: 0.24, blue: 0.20),
            Color(red: 0.30, green: 0.42, blue: 0.40),
            Color(red: 0.34, green: 0.24, blue: 0.42),
            Color(red: 0.20, green: 0.45, blue: 0.48)
        ]
        let index = abs(self.hashValue) % palette.count
        return palette[index]
    }
}
