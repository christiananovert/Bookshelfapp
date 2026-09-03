//
//  LibraryView.swift
//  Bookshelf
//
//  Created by Christian Anovert on 8/31/26.
//




import SwiftUI
 
// MARK: - Model
 
/// A single book entry in the user's library.
struct LibraryBook: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let status: ReadingStatus
    let spineColor: Color
    /// 0.0–1.0 for "Reading" books; ignored otherwise.
    let progress: Double
}
 
enum ReadingStatus: String, CaseIterable {
    case read = "Read"
    case reading = "Reading"
    case wantToRead = "Want to Read"
 
    var tintColor: Color {
        switch self {
        case .read:        return Color(red: 0.36, green: 0.42, blue: 0.30)   // moss
        case .reading:     return Shelf.coverGold
        case .wantToRead:  return Color(red: 0.34, green: 0.24, blue: 0.42)   // plum
        }
    }
}
 
// MARK: - Sample data
 
private let sampleBooks: [LibraryBook] = [
    LibraryBook(title: "The Midnight Library", author: "Matt Haig", status: .read,
                spineColor: Color(red: 0.29, green: 0.30, blue: 0.44), progress: 1.0),
    LibraryBook(title: "Project Hail Mary", author: "Andy Weir", status: .reading,
                spineColor: Color(red: 0.62, green: 0.35, blue: 0.20), progress: 0.64),
    LibraryBook(title: "Circe", author: "Madeline Miller", status: .read,
                spineColor: Color(red: 0.55, green: 0.24, blue: 0.20), progress: 1.0),
    LibraryBook(title: "Klara and the Sun", author: "Kazuo Ishiguro", status: .wantToRead,
                spineColor: Color(red: 0.70, green: 0.53, blue: 0.24), progress: 0.0),
    LibraryBook(title: "Tomorrow, and Tomorrow, and Tomorrow", author: "Gabrielle Zevin", status: .reading,
                spineColor: Color(red: 0.30, green: 0.42, blue: 0.40), progress: 0.31),
    LibraryBook(title: "The Song of Achilles", author: "Madeline Miller", status: .read,
                spineColor: Color(red: 0.44, green: 0.20, blue: 0.22), progress: 1.0),
    LibraryBook(title: "A Court of Thorns and Roses", author: "Sarah J. Maas", status: .wantToRead,
                spineColor: Color(red: 0.50, green: 0.28, blue: 0.18), progress: 0.0),
    LibraryBook(title: "Educated", author: "Tara Westover", status: .read,
                spineColor: Color(red: 0.36, green: 0.42, blue: 0.30), progress: 1.0),
]
 
/// Books the app is suggesting based on the user's taste — not yet on their shelf.
private let recommendedBooks: [LibraryBook] = [
    LibraryBook(title: "Piranesi", author: "Susanna Clarke", status: .wantToRead,
                spineColor: Color(red: 0.26, green: 0.34, blue: 0.38), progress: 0.0),
    LibraryBook(title: "The Invisible Life of Addie LaRue", author: "V.E. Schwab", status: .wantToRead,
                spineColor: Color(red: 0.24, green: 0.28, blue: 0.46), progress: 0.0),
    LibraryBook(title: "The House in the Cerulean Sea", author: "TJ Klune", status: .wantToRead,
                spineColor: Color(red: 0.20, green: 0.45, blue: 0.48), progress: 0.0),
    LibraryBook(title: "Mexican Gothic", author: "Silvia Moreno-Garcia", status: .wantToRead,
                spineColor: Color(red: 0.42, green: 0.20, blue: 0.24), progress: 0.0),
    LibraryBook(title: "The Night Circus", author: "Erin Morgenstern", status: .wantToRead,
                spineColor: Color(red: 0.16, green: 0.16, blue: 0.18), progress: 0.0),
]
 
/// A rotating "something different" shelf — genres or styles outside the user's usual picks.
private let discoverBooks: [LibraryBook] = [
    LibraryBook(title: "Braiding Sweetgrass", author: "Robin Wall Kimmerer", status: .wantToRead,
                spineColor: Color(red: 0.32, green: 0.40, blue: 0.24), progress: 0.0),
    LibraryBook(title: "The Three-Body Problem", author: "Liu Cixin", status: .wantToRead,
                spineColor: Color(red: 0.18, green: 0.22, blue: 0.32), progress: 0.0),
    LibraryBook(title: "Pachinko", author: "Min Jin Lee", status: .wantToRead,
                spineColor: Color(red: 0.52, green: 0.44, blue: 0.20), progress: 0.0),
    LibraryBook(title: "Gödel, Escher, Bach", author: "Douglas Hofstadter", status: .wantToRead,
                spineColor: Color(red: 0.46, green: 0.30, blue: 0.14), progress: 0.0),
    LibraryBook(title: "The Left Hand of Darkness", author: "Ursula K. Le Guin", status: .wantToRead,
                spineColor: Color(red: 0.30, green: 0.30, blue: 0.50), progress: 0.0),
]
 
// MARK: - Library View
 
struct LibraryView: View {
    @State private var books: [LibraryBook] = sampleBooks
    @State private var showingSearch = false

    private var currentlyReadingBooks: [LibraryBook] {
        books.filter { $0.status == .reading }
    }

    private var toBeReadBooks: [LibraryBook] {
        books.filter { $0.status == .wantToRead }
    }

    private var readBooks: [LibraryBook] {
        books.filter { $0.status == .read }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Shelf.wallTop, Shelf.wallBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                searchBarHeader
                    .padding(.top, 10)
                    .padding(.horizontal, 18)

                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        if !currentlyReadingBooks.isEmpty {
                            bookRow(title: "With a Bookmark ", books: currentlyReadingBooks, showBadge: false)
                        }
                        if !toBeReadBooks.isEmpty {
                            bookRow(title: "To Be Read", books: toBeReadBooks, showBadge: false)
                        }
                        if !readBooks.isEmpty {
                            bookRow(title: "Have Completed", books: readBooks, showBadge: false)
                        }
                        bookRow(title: "Your Recommendations", books: recommendedBooks, showBadge: false)
                        bookRow(title: "For Something New", books: discoverBooks, showBadge: false)
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Your Library")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSearch) {
            BookSearchView { newBook in
                books.append(newBook)
            }
        }
    }

    // MARK: Search bar (replaces old "X books on your shelf" header)

    private var searchBarHeader: some View {
        Button {
            showingSearch = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Shelf.ink.opacity(0.5))
                Text("Search for a book…")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Shelf.ink.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Shelf.ink.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Sections (unchanged)

    private func bookRow(title: String, books: [LibraryBook], showBadge: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(title)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(books) { book in
                        BookCard(book: book, showBadge: showBadge, showProgress: book.status == .reading)
                            .frame(width: 112)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 4)
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(Shelf.ink.opacity(0.8))
            .padding(.horizontal, 18)
    }
}
 
// MARK: - Book card
 
/// A small leather-bound "cover" card for one book, echoing the
/// BookFrameCard styling used on HomeView.
private struct BookCard: View {
    let book: LibraryBook
    /// Whether to show the small status pill (Read / Reading / Want) in the corner.
    /// Turned off for rows like Recommendations where the status isn't meaningful yet.
    var showBadge: Bool = true
    /// Whether to show the progress bar beneath the cover.
    var showProgress: Bool = false
 
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover face
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [book.spineColor.opacity(0.95), book.spineColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .aspectRatio(3.0/4.2, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Shelf.coverGold.opacity(0.55), lineWidth: 1.2)
                            .padding(4)
                    )
                    .overlay(
                        VStack(spacing: 6) {
                            Spacer()
                            Text(book.title)
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                            Text(book.author)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.75))
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
 
                if showBadge {
                    StatusBadge(status: book.status)
                        .padding(6)
                }
            }
 
            if showProgress {
                ProgressBar(value: book.progress, tint: book.status.tintColor)
                    .padding(.top, 8)
            }
        }
    }
}
 
private struct StatusBadge: View {
    let status: ReadingStatus
 
    var body: some View {
        Text(status == .reading ? "Reading" : (status == .read ? "Read" : "Want"))
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Capsule().fill(status.tintColor))
            .foregroundColor(.white)
    }
}
 
private struct ProgressBar: View {
    let value: Double
    let tint: Color
 
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.08))
                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * value)
            }
        }
        .frame(height: 5)
    }
}
 
// MARK: - Preview
 
#Preview {
    NavigationStack {
        LibraryView()
    }
}
 
