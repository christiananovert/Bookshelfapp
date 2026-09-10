//
//  ReviewsPage.swift
//  Bookshelf
//
 
import SwiftUI
 
// MARK: - Reviews Page
 
/// A dedicated page for writing your own thoughts on a completed book:
/// a star rating, a free-text review, a separate note on how the book made
/// you feel, and a recommendations section for similar reads.
/// Reached by tapping a book on the "Have Completed" shelf.
struct ReviewsPage: View {
    let book: LibraryBook
 
    @State private var rating: Int = 0
    @State private var reviewText: String = ""
    @State private var feelingText: String = ""
 
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Shelf.wallTop, Shelf.wallBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
 
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
 
                    ratingSection
                    reviewSection
                    feelingSection
 
                    similarBooksSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }
 
    // MARK: Header
 
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
 
    // MARK: Rating
 
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Rating")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Shelf.ink.opacity(0.8))
 
            // 1–5 tappable stars. Binds to `rating` (0 = unrated). Tapping the
            // currently-selected star clears it, so a mis-tap is easy to undo.
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: 26))
                        .foregroundColor(star <= rating ? Shelf.coverGold : Shelf.ink.opacity(0.25))
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.15)) {
                                rating = (rating == star) ? 0 : star
                            }
                        }
                }
            }
        }
    }
 
    // MARK: Review text
 
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Review")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Shelf.ink.opacity(0.8))
 
            reviewTextEditor(text: $reviewText, placeholder: "What did you think of it?")
        }
    }
 
    // MARK: Feelings text
 
    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How It Made You Feel")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Shelf.ink.opacity(0.8))
 
            reviewTextEditor(text: $feelingText, placeholder: "Nostalgic, hopeful, heartbroken…", minHeight: 120)
        }
    }
 
    /// A styled TextEditor matching the app's card look, with lightweight
    /// placeholder support since TextEditor has none built in. Shared by
    /// both the review and feelings boxes above.
    private func reviewTextEditor(text: Binding<String>, placeholder: String, minHeight: CGFloat = 200) -> some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Shelf.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
                .padding(10)
 
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(Shelf.ink.opacity(0.35))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 18)
                    .allowsHitTesting(false)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Shelf.ink.opacity(0.1), lineWidth: 1)
        )
    }
 
    // MARK: Similar books placeholder
 
    /// Placeholder for "books with similar vibes." Once a recommendation
    /// source (emotion-tag matching, genre, or an LLM call on the review/
    /// feeling text) is wired up, replace the dashed ghost cards below with
    /// real covers.
    private var similarBooksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("You Might Also Like")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Shelf.ink.opacity(0.8))
 
            Text("Recommendations based on this book and how it made you feel")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Shelf.ink.opacity(0.5))
 
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<4, id: \.self) { _ in
                        similarBookGhostCard
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
 
    private var similarBookGhostCard: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Shelf.ink.opacity(0.2), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                .aspectRatio(3.0/4.2, contentMode: .fit)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(Shelf.ink.opacity(0.3))
                )
 
            Text("Coming soon")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Shelf.ink.opacity(0.4))
        }
        .frame(width: 90)
    }
}
 
// MARK: - Preview
 
#Preview {
    NavigationStack {
        ReviewsPage(book: LibraryBook(
            title: "A Court of Thorns and Roses",
            author: "Sarah J. Maas",
            status: .read,
            spineColor: .red,
            progress: 1.0
        ))
    }
}

