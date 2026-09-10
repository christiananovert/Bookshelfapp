//
//  LibraryView.swift
//  Bookshelf
//
//  Created by Christian Anovert on 8/31/26.
//
 
 
 
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
 
// MARK: - Model
 
/// A single book entry in the user's library.
struct LibraryBook: Identifiable {
    /// Matches the Firestore document ID once persisted, so add/update/delete
    /// all address the same doc. Generated locally when a book is first created.
    var id: String = UUID().uuidString
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
 
// MARK: - Firestore mapping
 
extension LibraryBook {
    /// Rebuilds a book from a Firestore document's ID + field dictionary.
    /// Returns nil if required fields are missing/malformed, so a single
    /// corrupt doc can't crash the whole shelf load — it's just skipped.
    init?(id: String, data: [String: Any]) {
        guard
            let title = data["title"] as? String,
            let author = data["author"] as? String,
            let statusRaw = data["status"] as? String,
            let status = ReadingStatus(rawValue: statusRaw)
        else { return nil }
 
        self.id = id
        self.title = title
        self.author = author
        self.status = status
        self.spineColor = Color(hex: data["spineColorHex"] as? String ?? "#CCA84D")
        self.progress = data["progress"] as? Double ?? 0.0
        if let coverURLString = data["coverURL"] as? String {
            self.coverURL = URL(string: coverURLString)
        } else {
            self.coverURL = nil
        }
    }
 
    /// The Firestore-writable representation of this book.
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "title": title,
            "author": author,
            "status": status.rawValue,
            "spineColorHex": spineColor.hexString,
            "progress": progress,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let coverURL {
            data["coverURL"] = coverURL.absoluteString
        }
        return data
    }
}
 
// MARK: - Color <-> hex
 
private extension Color {
    /// Builds a Color from a "#RRGGBB" string. Falls back to a neutral gold
    /// if the string is malformed, so a bad stored value never crashes the app.
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
 
        var value: UInt64 = 0
        guard cleaned.count == 6, Scanner(string: cleaned).scanHexInt64(&value) else {
            self = Color(red: 0.80, green: 0.66, blue: 0.30)
            return
        }
 
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
 
    /// Renders this Color as "#RRGGBB" for storage.
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
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
    /// The user's actual shelf, loaded from Firestore on appear.
    @State private var books: [LibraryBook] = []
    @State private var showingSearch = false
    /// The book currently awaiting the "are you sure?" confirmation.
    /// Non-nil drives the confirmationDialog below.
    @State private var bookPendingDeletion: LibraryBook?
    /// True until the initial Firestore fetch completes, so we don't flash
    /// "This shelf is currently empty" before the real data has loaded.
    @State private var isLoadingBooks = true
 
    private let db = Firestore.firestore()
 
    /// The signed-in user's books live at users/{uid}/books/{bookId}.
    /// nil if, for whatever reason, nobody's signed in when this loads.
    private var booksCollection: CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid).collection("books")
    }
 
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
                        if isLoadingBooks {
                            ProgressView()
                                .tint(Shelf.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                        } else {
                            // All five sections always render now, each with its own shelf.
                            bookRow(title: "With a Bookmark", books: currentlyReadingBooks, showBadge: false)
                            bookRow(title: "To Be Read", books: toBeReadBooks, showBadge: false)
                            bookRow(title: "Have Completed", books: readBooks, showBadge: false, enableReview: true)
                            bookRow(title: "Your Recommendations", books: [], showBadge: false)
                            bookRow(title: "For Something New", books: [], showBadge: false)
                        }
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Your Library")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadBooks()
        }
        .sheet(isPresented: $showingSearch) {
            BookSearchView { newBook in
                addBook(newBook)
            }
        }
        .alert(
            "Are you sure you want to take this book off the shelf?",
            isPresented: Binding(
                get: { bookPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented { bookPendingDeletion = nil }
                }
            )
        ) {
            Button("Remove Book", role: .destructive) {
                if let book = bookPendingDeletion {
                    deleteBook(book)
                }
                bookPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                bookPendingDeletion = nil
            }
        }
    }
 
    // MARK: Firestore sync
 
    /// Fetches the signed-in user's shelf once, on first appear. Ordered by
    /// when each book was added, so the shelf order stays stable across sessions.
    private func loadBooks() async {
        guard let booksCollection else {
            isLoadingBooks = false
            return
        }
        do {
            let snapshot = try await booksCollection.order(by: "updatedAt").getDocuments()
            books = snapshot.documents.compactMap { LibraryBook(id: $0.documentID, data: $0.data()) }
        } catch {
            // A failed load just leaves the shelf empty for this session rather
            // than crashing — the user can pull to refresh once that's added.
            print("Failed to load library: \(error)")
        }
        isLoadingBooks = false
    }
 
    /// Adds a book locally (instant UI feedback) and writes it to Firestore
    /// in the background so it's still there next time the app launches.
    private func addBook(_ book: LibraryBook) {
        books.append(book)
        guard let booksCollection else { return }
        Task {
            do {
                try await booksCollection.document(book.id).setData(book.firestoreData)
            } catch {
                print("Failed to save book: \(error)")
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
 
    // MARK: Deleting
 
    /// Removes a book from the shelf with a small fade/slide-out animation,
    /// and deletes the matching Firestore doc in the background.
    private func deleteBook(_ book: LibraryBook) {
        withAnimation(.easeOut(duration: 0.2)) {
            books.removeAll { $0.id == book.id }
        }
        guard let booksCollection else { return }
        Task {
            do {
                try await booksCollection.document(book.id).delete()
            } catch {
                print("Failed to delete book: \(error)")
            }
        }
    }
 
    /// Small dark trash-circle button overlaid on the top-left corner of a cover.
    /// Kept as a sibling overlay (not inside BookCard) so its tap target never
    /// competes with a wrapping NavigationLink's tap target. Tapping it doesn't
    /// delete directly — it just triggers the confirmation dialog above.
    private func deleteButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "trash.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(6)
                .background(Circle().fill(Color.black.opacity(0.55)))
        }
        .buttonStyle(.plain)
        .padding(4)
    }
 
    // MARK: Sections
 
    /// A fixed height for the content area of every row (books + labels),
    /// so every shelf plank lines up at the same visual "depth" regardless
    /// of whether that row is empty or has a progress bar.
    private let rowContentHeight: CGFloat = 215
 
    /// A single horizontal shelf of books, physically resting on a wooden plank.
    /// When `enableReview` is true, tapping a book navigates to a page where
    /// the user can write their own review of that book. Every book also gets
    /// a small trash button in its top-left corner to remove it from the shelf.
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
                                        ReviewsPage(book: book)
                                    } label: {
                                        BookCard(book: book, showBadge: showBadge, showProgress: book.status == .reading)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 112)
                                    .overlay(alignment: .topLeading) {
                                        deleteButton { bookPendingDeletion = book }
                                    }
                                } else {
                                    BookCard(book: book, showBadge: showBadge, showProgress: book.status == .reading)
                                        .frame(width: 112)
                                        .overlay(alignment: .topLeading) {
                                            deleteButton { bookPendingDeletion = book }
                                        }
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
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundColor(Shelf.ink)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(height: 42, alignment: .top) // fixed, so every card is the same height regardless of title length
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
 
// MARK: - Preview
 
#Preview {
    NavigationStack {
        LibraryView()
    }
}
