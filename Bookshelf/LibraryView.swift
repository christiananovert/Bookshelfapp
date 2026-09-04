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
    /// Real cover art URL from search results. nil for the app-curated shelves,
    /// which fall back to the colored spine design.
    var coverURL: URL? = nil
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
 
// MARK: - Library View
 
struct LibraryView: View {
    /// The user's actual shelf. Starts empty — no sample data.
    @State private var books: [LibraryBook] = []
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
                    VStack(alignment: .leading, spacing: 30) {
                        // All five sections always render now, each with its own shelf.
                        bookRow(title: "With a Bookmark", books: currentlyReadingBooks, showBadge: false)
                        bookRow(title: "To Be Read", books: toBeReadBooks, showBadge: false)
                        bookRow(title: "Have Completed", books: readBooks, showBadge: false, enableReview: true)
                        bookRow(title: "Your Recommendations", books: [], showBadge: false)
                        bookRow(title: "For Something New", books: [], showBadge: false)
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
 
    // MARK: Sections
 
    /// A fixed height for the content area of every row (books + labels),
    /// so every shelf plank lines up at the same visual "depth" regardless
    /// of whether that row is empty or has a progress bar.
    private let rowContentHeight: CGFloat = 215
 
    /// A single horizontal shelf of books, physically resting on a wooden plank.
    /// When `enableReview` is true, tapping a book navigates to a page where
    /// the user can write their own review of that book.
    private func bookRow(title: String, books: [LibraryBook], showBadge: Bool, enableReview: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(title)
 
            Group {
                if books.isEmpty {
                    Text("This shelf is currently empty")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Shelf.ink.opacity(0.45))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 14) {
                            ForEach(books) { book in
                                if enableReview {
                                    NavigationLink {
                                        BookReviewView(book: book)
                                    } label: {
                                        BookCard(book: book, showBadge: showBadge, showProgress: book.status == .reading)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 112)
                                } else {
                                    BookCard(book: book, showBadge: showBadge, showProgress: book.status == .reading)
                                        .frame(width: 112)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                }
            }
            .frame(height: rowContentHeight, alignment: .bottom)
            .padding(.bottom, 14) // breathing room above the plank
            .background(alignment: .bottom) {
                shelfPlank
            }
        }
    }
 
    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(Shelf.ink.opacity(0.8))
            .padding(.horizontal, 18)
    }
 
    /// The wooden shelf ledge that book covers appear to sit on.
    private var shelfPlank: some View {
        VStack(spacing: 0) {
            // Thin highlight along the front lip of the shelf.
            Rectangle()
                .fill(Shelf.coverGold.opacity(0.55))
                .frame(height: 2)
 
            // Wood body of the plank.
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.44, green: 0.29, blue: 0.17),
                            Color(red: 0.30, green: 0.19, blue: 0.11)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 12)
        }
        .padding(.horizontal, 10)
        .shadow(color: .black.opacity(0.35), radius: 5, x: 0, y: 4)
    }
}
 
// MARK: - Book card
 
/// A small "cover" card for one book. Title and author render beneath
/// the cover art rather than overlaid on top of it, so real cover images
/// (which may have light backgrounds) stay legible.
private struct BookCard: View {
    let book: LibraryBook
    /// Whether to show the small status pill (Read / Reading / Want) in the corner.
    /// Turned off for rows like Recommendations where the status isn't meaningful yet.
    var showBadge: Bool = true
    /// Whether to show the progress bar beneath the cover.
    var showProgress: Bool = false
 
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Cover face
            ZStack(alignment: .topTrailing) {
                Group {
                    if let coverURL = book.coverURL {
                        AsyncImage(url: coverURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                spineFill // shown while loading or if the load fails
                            }
                        }
                    } else {
                        spineFill
                    }
                }
                .aspectRatio(3.0/4.2, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Shelf.coverGold.opacity(0.55), lineWidth: 1.2)
                        .padding(4)
                )
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
 
                if showBadge {
                    StatusBadge(status: book.status)
                        .padding(6)
                }
            }
 
            // Title & author beneath the cover
            VStack(alignment: .leading, spacing: 1) {
                Text(book.title)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundColor(Shelf.ink)
                    .lineLimit(2)
                Text(book.author)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Shelf.ink.opacity(0.6))
                    .lineLimit(1)
            }
 
            if showProgress {
                ProgressBar(value: book.progress, tint: book.status.tintColor)
                    .padding(.top, 2)
            }
        }
    }
 
    /// Plain colored gradient, used as the fallback when there's no
    /// cover art (curated shelves) or while a real cover is loading.
    private var spineFill: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [book.spineColor.opacity(0.95), book.spineColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
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
 
// MARK: - Book Review
 
/// A dedicated page for writing your own thoughts on a completed book.
/// Reached by tapping a book on the "Have Completed" shelf.
struct BookReviewView: View {
    let book: LibraryBook
 
    /// The user's review text. Empty for now — nothing pre-filled.
    @State private var reviewText: String = ""
 
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Shelf.wallTop, Shelf.wallBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
 
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
 
                    Text("Your Review")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Shelf.ink.opacity(0.8))
 
                    TextEditor(text: $reviewText)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Shelf.ink)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 260)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Shelf.ink.opacity(0.1), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }
 
    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Group {
                if let coverURL = book.coverURL {
                    AsyncImage(url: coverURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            spineFill
                        }
                    }
                } else {
                    spineFill
                }
            }
            .aspectRatio(3.0/4.2, contentMode: .fit)
            .frame(width: 84)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Shelf.coverGold.opacity(0.55), lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
 
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(Shelf.ink)
                Text(book.author)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Shelf.ink.opacity(0.6))
            }
            .padding(.top, 4)
 
            Spacer()
        }
    }
 
    private var spineFill: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(
                LinearGradient(
                    colors: [book.spineColor.opacity(0.95), book.spineColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}
 
// MARK: - Preview
 
#Preview {
    NavigationStack {
        LibraryView()
    }
}
 
