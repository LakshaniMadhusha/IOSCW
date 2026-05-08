import XCTest
@testable import LibraryApp

final class ModelTests: XCTestCase {
    
    func testBookAvailableCopies() {
        let book = Book(title: "Test Book", author: "Author", genre: "Fiction", totalCopies: 3)
        
        XCTAssertEqual(book.availableCopies, 3)
        XCTAssertTrue(book.isAvailable)
        
        let loan1 = Loan(dueAt: .now.addingTimeInterval(3600))
        // In SwiftData, relationships might need a context to work fully,
        // but let's see if we can test the logic by setting the array directly if possible,
        // or by simulating the computed property dependencies.
        
        // Since loans is a var, we can try to set it or append to it.
        book.loans.append(loan1)
        
        XCTAssertEqual(book.availableCopies, 2)
        XCTAssertTrue(book.isAvailable)
        
        let loan2 = Loan(dueAt: .now.addingTimeInterval(3600))
        book.loans.append(loan2)
        
        let loan3 = Loan(dueAt: .now.addingTimeInterval(3600))
        book.loans.append(loan3)
        
        XCTAssertEqual(book.availableCopies, 0)
        XCTAssertFalse(book.isAvailable)
    }
    
    func testLoanIsActive() {
        let loan = Loan(dueAt: .now.addingTimeInterval(3600))
        XCTAssertTrue(loan.isActive)
        
        loan.returnedAt = .now
        XCTAssertFalse(loan.isActive)
    }
    
    func testLoanIsOverdue() {
        let loan = Loan(dueAt: .now.addingTimeInterval(-3600)) // Past due
        XCTAssertTrue(loan.isOverdue)
        
        loan.returnedAt = .now
        XCTAssertFalse(loan.isOverdue)
    }
}
