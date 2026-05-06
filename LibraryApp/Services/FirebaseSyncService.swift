import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftData

final class FirebaseSyncService {
    static let shared = FirebaseSyncService()
    
    private let db = Firestore.firestore()
    private var isSyncing = false
    
    private init() {}
    
    func startSyncing(container: ModelContainer) {
        guard !isSyncing else { return }
        isSyncing = true
        
        // 1. Listen to Books Collection
        db.collection("books").addSnapshotListener { snapshot, error in
            // Move processing to a background thread to avoid blocking the UI (Watchdog prevention)
            Task.detached(priority: .background) {
                guard let documents = snapshot?.documents else { return }
                
                // Create a dedicated background context for this sync cycle
                let context = ModelContext(container)
                
                // Optimize: Fetch all existing book IDs once
                let existingDescriptor = FetchDescriptor<Book>()
                let existingBooks = (try? context.fetch(existingDescriptor)) ?? []
                let existingIds = Set(existingBooks.map { $0.id })
                
                var hasChanges = false
                
                for doc in documents {
                    let data = doc.data()
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString) else { continue }
                    
                    // Only insert if it doesn't exist locally
                    if !existingIds.contains(id) {
                        let rawStatus = data["status"] as? String ?? "Available"
                        let status = BookStatus(rawValue: rawStatus) ?? .available
                        
                        let newBook = Book(
                            id: id,
                            title: data["title"] as? String ?? "Unknown Title",
                            author: data["author"] as? String ?? "Unknown Author",
                            genre: data["genre"] as? String ?? "General",
                            status: status,
                            rating: data["rating"] as? Double ?? 0.0,
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .now
                        )
                        context.insert(newBook)
                        hasChanges = true
                    }
                }
                
                if hasChanges {
                    do {
                        try context.save()
                    } catch {
                        print("FirebaseSyncService Background Save Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // Abstract hook for pushing SwiftData mutations directly up into Cloud!
    func pushBookToCloud(_ book: Book) {
        let payload: [String: Any] = [
            "id": book.id.uuidString,
            "title": book.title,
            "author": book.author,
            "genre": book.genre,
            "status": book.status.rawValue,
            "rating": book.rating,
            "createdAt": Timestamp(date: book.createdAt)
        ]
        db.collection("books").document(book.id.uuidString).setData(payload)
    }
    
    // Abstract hook directly pushing User Registrations formally backwards securely!
    func updateUserInCloud(_ user: AppUser) {
        var payload: [String: Any] = [
            "name": user.name,
            "email": user.email,
            "updatedAt": Timestamp(date: .now)
        ]
        
        if let membershipId = user.membershipId { payload["membershipId"] = membershipId }
        if let phone = user.phoneNumber { payload["phoneNumber"] = phone }
        if let address = user.address { payload["address"] = address }
        
        // Include profile image as base64 for direct database sync (Watchdog safe if image is resized)
        if let imageData = user.profileImageData {
            payload["profileImageBase64"] = imageData.base64EncodedString()
        }
        
        // Use the actual Firebase UID if available to ensure document matching
        let documentId = Auth.auth().currentUser?.uid ?? user.id.uuidString
        
        db.collection("profile").document(documentId).setData(payload, merge: true) { error in
            if let error = error {
                print("❌ FirebaseSyncService Error: Failed to save to 'profile' collection. \(error.localizedDescription)")
            } else {
                print("✅ FirebaseSyncService Success: Profile saved to 'profile/\(documentId)'")
            }
        }
    }
}
