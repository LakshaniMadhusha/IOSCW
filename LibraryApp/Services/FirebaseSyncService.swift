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
            Task.detached(priority: .background) {
                guard let documents = snapshot?.documents else { return }
                let context = ModelContext(container)
                
                let existingDescriptor = FetchDescriptor<Book>()
                let existingBooks = (try? context.fetch(existingDescriptor)) ?? []
                let existingIds = Set(existingBooks.map { $0.id })
                
                var hasChanges = false
                for doc in documents {
                    let data = doc.data()
                    guard let idString = data["id"] as? String, let id = UUID(uuidString: idString) else { continue }
                    
                    if !existingIds.contains(id) {
                        let newBook = Book(
                            id: id,
                            title: data["title"] as? String ?? "Unknown Title",
                            author: data["author"] as? String ?? "Unknown Author",
                            genre: data["genre"] as? String ?? "General",
                            status: BookStatus(rawValue: data["status"] as? String ?? "Available") ?? .available,
                            rating: data["rating"] as? Double ?? 0.0,
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .now
                        )
                        context.insert(newBook)
                        hasChanges = true
                    }
                }
                if hasChanges { try? context.save() }
            }
        }
        
        // 2. Listen to Hall Reservations
        db.collection("hall_reservations").addSnapshotListener { snapshot, error in
            Task.detached(priority: .background) {
                guard let documents = snapshot?.documents else { return }
                let context = ModelContext(container)
                
                let existingDescriptor = FetchDescriptor<HallReservation>()
                let existingReservations = (try? context.fetch(existingDescriptor)) ?? []
                let existingIds = Set(existingReservations.map { $0.id })
                
                var hasChanges = false
                for doc in documents {
                    let data = doc.data()
                    guard let idString = data["id"] as? String, let id = UUID(uuidString: idString) else { continue }
                    
                    if !existingIds.contains(id) {
                        let newRes = HallReservation(
                            id: id,
                            hallName: data["hallName"] as? String ?? "Library Hall",
                            hallAddress: data["hallAddress"] as? String ?? "",
                            reservationType: ReservationType(rawValue: data["reservationType"] as? String ?? "Seat") ?? .seat,
                            reservationDetails: data["details"] as? String ?? "",
                            bookingDate: (data["bookingDate"] as? Timestamp)?.dateValue() ?? .now,
                            bookingHours: data["bookingHours"] as? Int ?? 2,
                            attendeeCount: data["attendeeCount"] as? Int ?? 1,
                            status: HallReservationStatus(rawValue: data["status"] as? String ?? "Confirmed") ?? .confirmed,
                            userId: UUID(uuidString: data["userId"] as? String ?? "") ?? UUID()
                        )
                        context.insert(newRes)
                        hasChanges = true
                    }
                }
                if hasChanges { try? context.save() }
            }
        }
    }
    
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
    
    func updateUserInCloud(_ user: AppUser) {
        var payload: [String: Any] = [
            "name": user.name,
            "email": user.email,
            "occupation": user.occupation ?? "",
            "bio": user.bio ?? "",
            "favoriteGenre": user.favoriteGenre ?? "",
            "updatedAt": Timestamp(date: .now)
        ]
        
        if let membershipId = user.membershipId { payload["membershipId"] = membershipId }
        if let phone = user.phoneNumber { payload["phoneNumber"] = phone }
        if let address = user.address { payload["address"] = address }
        if let imageData = user.profileImageData {
            payload["profileImageBase64"] = imageData.base64EncodedString()
        }
        
        let documentId = Auth.auth().currentUser?.uid ?? user.id.uuidString
        db.collection("profile").document(documentId).setData(payload, merge: true)
    }

    func saveReservationToCloud(_ reservation: HallReservation) {
        let payload: [String: Any] = [
            "id": reservation.id.uuidString,
            "hallName": reservation.hallName,
            "hallAddress": reservation.hallAddress,
            "reservationType": reservation.reservationType.rawValue,
            "details": reservation.reservationDetails,
            "bookingDate": Timestamp(date: reservation.bookingDate),
            "bookingHours": reservation.bookingHours,
            "attendeeCount": reservation.attendeeCount,
            "status": reservation.status.rawValue,
            "userId": reservation.userId.uuidString,
            "createdAt": Timestamp(date: reservation.createdAt)
        ]
        db.collection("hall_reservations").document(reservation.id.uuidString).setData(payload, merge: true)
    }
}
