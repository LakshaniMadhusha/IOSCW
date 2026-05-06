import SwiftUI
import SwiftData
import PhotosUI

struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let bookToEdit: Book?
    
    init(bookToEdit: Book? = nil) {
        self.bookToEdit = bookToEdit
    }

    @State private var title = ""
    @State private var author = ""
    @State private var genre = ""
    @State private var coverUrl = ""
    @State private var pdfUrl = ""
    @State private var isbn = ""
    @State private var totalCopies = 1
    @State private var rating = 0.0
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    @State private var lookupMessage: String? = nil
    @State private var isLookingUp = false
    @State private var isSuccess = false
    
    @State private var isShowingScanner = false
    @State private var scannedText = ""
    @State private var scanningField: ScanField? = nil
    
    enum ScanField {
        case title
        case isbn
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pageBg.ignoresSafeArea()
                
                if isSuccess {
                    SuccessAnimationView(isEdit: bookToEdit != nil) {
                        dismiss()
                    }
                    .transition(.asymmetric(insertion: .scale, removal: .opacity))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            
                            // 1. Interactive Cover Header
                            BookCoverHeader(coverUrl: coverUrl, imageData: selectedImageData) {
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Label("Choose Photo", systemImage: "photo.badge.plus")
                                        .font(.caption.weight(.bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(10)
                                }
                            }
                            
                            VStack(spacing: 24) {
                                // 2. Metadata Section
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Book Information")
                                        .font(.headline)
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 1) {
                                        ModernInputField(title: "TITLE", text: $title, placeholder: "e.g. The Great Gatsby", icon: "book.closed")
                                        ModernInputField(title: "AUTHOR", text: $author, placeholder: "e.g. F. Scott Fitzgerald", icon: "person.text.rectangle")
                                        
                                        VStack(alignment: .leading, spacing: 12) {
                                            Label("GENRE", systemImage: "tag")
                                                .font(.system(size: 10, weight: .black))
                                                .foregroundColor(.textSecondary)
                                                .tracking(0.5)
                                            GenreCloud(selectedGenre: $genre)
                                        }
                                        .padding(16)
                                        .background(Color.cardBg)
                                    }
                                    .cornerRadius(24)
                                    .padding(.horizontal, 20)
                                }
                                
                                // 3. Library Logistics
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Library Logistics")
                                        .font(.headline)
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 16) {
                                        HStack {
                                            Label("Inventory", systemImage: "archivebox")
                                                .font(.subheadline.weight(.semibold))
                                            Spacer()
                                            Stepper("\(totalCopies) Copies", value: $totalCopies, in: 1...100)
                                                .font(.subheadline.weight(.bold))
                                        }
                                        .padding(16)
                                        .background(Color.cardBg)
                                        .cornerRadius(16)
                                        
                                        HStack {
                                            Label("Initial Rating", systemImage: "star.fill")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.amber)
                                            Spacer()
                                            RatingSlider(rating: $rating)
                                        }
                                        .padding(16)
                                        .background(Color.cardBg)
                                        .cornerRadius(16)
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                // 4. Digital Assets
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Digital Assets")
                                        .font(.headline)
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 1) {
                                        ModernInputField(title: "COVER IMAGE URL", text: $coverUrl, placeholder: "https://example.com/cover.jpg", icon: "photo")
                                        ModernInputField(title: "E-BOOK PDF URL", text: $pdfUrl, placeholder: "https://example.com/book.pdf", icon: "doc.text")
                                    }
                                    .cornerRadius(24)
                                    .padding(.horizontal, 20)
                                }
                                
                                // 5. Action Button
                                Button(action: handleSave) {
                                    HStack {
                                        Image(systemName: "tray.and.arrow.down.fill")
                                        Text(bookToEdit == nil ? "Publish to Library" : "Update Archive")
                                    }
                                    .font(.headline.weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(
                                        LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(24)
                                    .shadow(color: Color.purple.opacity(0.3), radius: 15, x: 0, y: 8)
                                }
                                .padding(.horizontal, 20)
                                .disabled(title.isEmpty || author.isEmpty)
                                .opacity(title.isEmpty || author.isEmpty ? 0.6 : 1.0)
                            }
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle(bookToEdit == nil ? "Catalog Book" : "Edit Metadata")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            scanningField = .isbn
                            isShowingScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                        }
                        
                        Button {
                            scanningField = .title
                            isShowingScanner = true
                        } label: {
                            Image(systemName: "text.viewfinder")
                        }
                    }
                    .foregroundColor(.purple)
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
            .onAppear {
                if let book = bookToEdit {
                    title = book.title
                    author = book.author
                    genre = book.genre
                    coverUrl = book.coverUrl ?? ""
                    pdfUrl = book.pdfUrl ?? ""
                    totalCopies = book.totalCopies
                    rating = book.rating
                }
            }
            .onChange(of: scannedText) { _, newValue in
                guard !newValue.isEmpty else { return }
                withAnimation {
                    if scanningField == .title { title = newValue }
                    else if scanningField == .isbn { 
                        isbn = newValue 
                        Task { await autoFillFromISBN() }
                    }
                }
                scannedText = ""
            }
            .sheet(isPresented: $isShowingScanner) {
                DataScannerView(recognizedText: $scannedText)
                    .ignoresSafeArea()
            }
        }
    }

    private func handleSave() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        if let book = bookToEdit {
            book.title = title
            book.author = author
            book.genre = genre
            book.coverUrl = coverUrl.isEmpty ? nil : coverUrl
            book.pdfUrl = pdfUrl.isEmpty ? nil : pdfUrl
            book.totalCopies = totalCopies
            book.rating = rating
            try? modelContext.save()
            FirebaseSyncService.shared.pushBookToCloud(book)
        } else {
            let book = Book(title: title, author: author, genre: genre, status: .available, rating: rating, coverUrl: coverUrl.isEmpty ? nil : coverUrl, pdfUrl: pdfUrl.isEmpty ? nil : pdfUrl, totalCopies: totalCopies)
            modelContext.insert(book)
            try? modelContext.save()
            FirebaseSyncService.shared.pushBookToCloud(book)
        }
        
        withAnimation(.spring()) {
            isSuccess = true
        }
    }

    @MainActor
    private func autoFillFromISBN() async {
        isLookingUp = true
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        do {
            let metadata = try await BookLookupService().lookupISBN(isbn)
            withAnimation {
                if !metadata.title.isEmpty { title = metadata.title }
                if !metadata.author.isEmpty { author = metadata.author }
                if !metadata.genre.isEmpty { genre = metadata.genre }
                if let cover = metadata.coverUrl { coverUrl = cover }
            }
            lookupMessage = "AI Match Found!"
        } catch {
            lookupMessage = "No manual match."
        }
        isLookingUp = false
    }
}

// MARK: - Premium UI Components

struct BookCoverHeader<Picker: View>: View {
    let coverUrl: String
    let imageData: Data?
    let picker: Picker
    
    init(coverUrl: String, imageData: Data?, @ViewBuilder picker: () -> Picker) {
        self.coverUrl = coverUrl
        self.imageData = imageData
        self.picker = picker()
    }
    
    var body: some View {
        ZStack {
            // Background Ambient Glow
            Circle()
                .fill(Color.purple.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
            
            VStack(spacing: 20) {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.cardBg)
                            .frame(width: 180, height: 270)
                            .shadow(color: Color.black.opacity(0.2), radius: 25, x: 0, y: 15)
                        
                        if let data = imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 180, height: 270)
                                .clipShape(RoundedRectangle(cornerRadius: 32))
                        } else if let url = URL(string: coverUrl), !coverUrl.isEmpty {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 180, height: 270)
                                        .clipShape(RoundedRectangle(cornerRadius: 32))
                                } else {
                                    Image(systemName: "book.pages.fill")
                                        .font(.system(size: 70))
                                        .foregroundColor(.purple.opacity(0.2))
                                }
                            }
                        } else {
                            Image(systemName: "plus.viewfinder")
                                .font(.system(size: 70))
                                .foregroundColor(.purple.opacity(0.2))
                        }
                    }
                    
                    picker
                        .offset(x: 10, y: 10)
                }
                
                Text("COVER MASTER PREVIEW")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.textSecondary)
                    .tracking(1.5)
            }
        }
        .padding(.top, 20)
    }
}

struct RatingSlider: View {
    @Binding var rating: Double
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: Double(index) <= rating ? "star.fill" : "star")
                    .foregroundColor(Double(index) <= rating ? .amber : .gray.opacity(0.3))
                    .onTapGesture {
                        withAnimation(.spring()) { rating = Double(index) }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
            }
        }
    }
}

struct ModernInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .font(.caption2)
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.textSecondary)
                    .tracking(1)
                Spacer()
                if !text.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption2)
                }
            }
            
            TextField(placeholder, text: $text)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.textPrimary)
        }
        .padding(18)
        .background(Color.cardBg)
    }
}

struct GenreCloud: View {
    @Binding var selectedGenre: String
    let genres = ["Fiction", "Non-Fiction", "Mystery", "Sci-Fi", "Comics", "Biography", "History", "Science"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(genres, id: \.self) { genre in
                    Button {
                        withAnimation(.spring()) { selectedGenre = genre }
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                    } label: {
                        Text(genre)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedGenre == genre ? Color.purple : Color.purple.opacity(0.08))
                            .foregroundColor(selectedGenre == genre ? .white : .purple)
                            .cornerRadius(14)
                    }
                }
            }
        }
    }
}

struct SuccessAnimationView: View {
    let isEdit: Bool
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle().fill(Color.green.opacity(0.12)).frame(width: 160, height: 160)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce, options: .repeat(2))
            }
            
            VStack(spacing: 12) {
                Text(isEdit ? "Archive Synchronized" : "Discovery Complete!")
                    .font(.title.weight(.black))
                Text(isEdit ? "The metadata update has been committed to the global directory." : "Your new title is now live for all members to discover and enjoy.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onComplete) {
                Text("Return to Hub")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 18)
                    .background(Color.green)
                    .cornerRadius(24)
                    .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
    }
}
