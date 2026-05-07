import SwiftUI
import VisionKit
import SwiftData

struct BookScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allBooks: [Book]
    
    @State private var recognizedText = ""
    @State private var identifiedBook: Book?
    @State private var isNavigating = false
    @State private var showingNoMatchAlert = false
    
    let user: AppUser
    
    var body: some View {
        NavigationStack {
            ZStack {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerView(recognizedText: $recognizedText)
                        .ignoresSafeArea()
                        .onChange(of: recognizedText) { _, newValue in
                            if !newValue.isEmpty {
                                identifyBook(from: newValue)
                            }
                        }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Camera access is not available or VisionKit is not supported on this device.")
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Close") { dismiss() }
                            .buttonStyle(.borderedProminent)
                    }
                }
                
                // UI Overlays
                VStack {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        Spacer()
                        Text("Scan Book or Barcode")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                        Spacer()
                        Color.clear.frame(width: 30)
                    }
                    .padding()
                    .background(LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 150, weight: .ultraLight))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Point at a book cover, barcode, or ISBN")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationDestination(isPresented: $isNavigating) {
                if let book = identifiedBook {
                    BookDetailView(book: book, user: user)
                }
            }
            .alert("No Match Found", isPresented: $showingNoMatchAlert) {
                Button("Try Again") { recognizedText = "" }
            } message: {
                Text("We couldn't identify a book from '\(recognizedText)'. Please try scanning the barcode or the title again.")
            }
        }
    }
    
    private func identifyBook(from input: String) {
        let normalizedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 1. Try Barcode/ISBN match
        if let match = allBooks.first(where: { book in
            if let isbn = book.isbn?.lowercased() {
                return isbn == normalizedInput || normalizedInput.contains(isbn)
            }
            return false
        }) {
            identifiedBook = match
            isNavigating = true
            return
        }
        
        // 2. Try Title/Author text match (Fuzzy)
        if let match = allBooks.first(where: { book in
            let title = book.title.lowercased()
            let author = book.author.lowercased()
            return normalizedInput.contains(title) || title.contains(normalizedInput) || normalizedInput.contains(author)
        }) {
            identifiedBook = match
            isNavigating = true
            return
        }
        
        // 3. Optional: Only show alert if input looks like it could be a book (length > 3)
        if normalizedInput.count > 3 {
            showingNoMatchAlert = true
        }
    }
}
