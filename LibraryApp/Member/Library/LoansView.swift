import SwiftUI
import SwiftData

struct LoansView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var loans: [Loan]
    @State private var showingReturnConfirmation = false
    @State private var selectedLoan: Loan?
    @State private var showingRenewalConfirmation = false

    let userId: UUID

    init(userId: UUID) {
        self.userId = userId
        self._loans = Query(
            filter: #Predicate<Loan> { loan in
                loan.user?.id == userId && loan.returnedAt == nil
            },
            sort: [SortDescriptor(\.dueAt, order: .forward)]
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                if loans.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No Active Loans")
                            .font(.title3.weight(.bold))
                        Text("Borrow books from the library to start reading.")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 100)
                } else {
                        // Stats Header
                        VStack(spacing: 16) {
                            HStack(spacing: 20) {
                                StatCard(
                                    title: "Active Loans",
                                    value: "\(loans.count)",
                                    icon: "book.fill",
                                    color: .blue
                                )
                                StatCard(
                                    title: "Overdue",
                                    value: "\(loans.filter { $0.isOverdue }.count)",
                                    icon: "exclamationmark.triangle.fill",
                                    color: .red
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        // Loans List
                        VStack(spacing: 16) {
                            ForEach(loans) { loan in
                                LoanCardView(loan: loan) {
                                    selectedLoan = loan
                                    showingReturnConfirmation = true
                                } onRenew: {
                                    selectedLoan = loan
                                    showingRenewalConfirmation = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.pageBg.ignoresSafeArea())
            .navigationTitle("My Loans")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Return Book", isPresented: $showingReturnConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Return", role: .destructive) {
                    if let loan = selectedLoan {
                        returnBook(loan)
                    }
                }
            } message: {
                if let loan = selectedLoan, let book = loan.book {
                    Text("Return \"\(book.title)\"? This action cannot be undone.")
                }
            }
            .alert("Renew Loan", isPresented: $showingRenewalConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Renew for 14 days") {
                    if let loan = selectedLoan {
                        renewLoan(loan)
                    }
                }
            } message: {
                if let loan = selectedLoan, let book = loan.book {
                    Text("Extend loan for \"\(book.title)\" by 14 days?")
                }
            }
    }

    private func returnBook(_ loan: Loan) {
        loan.returnedAt = .now
        loan.book?.status = .available
        try? modelContext.save()
    }

    private func renewLoan(_ loan: Loan) {
        loan.dueAt = Calendar.current.date(byAdding: .day, value: 14, to: loan.dueAt) ?? loan.dueAt
        try? modelContext.save()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
            }
            Text(value)
                .font(.title2.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBg)
        .cornerRadius(16)
    }
}

struct LoanCardView: View {
    let loan: Loan
    let onReturn: () -> Void
    let onRenew: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Book Cover
                if let book = loan.book {
                    AsyncImage(url: URL(string: book.coverUrl ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 60, height: 80)
                                .overlay(
                                    Image(systemName: "book")
                                        .foregroundColor(.textSecondary)
                                )
                        }
                    }
                }

                // Book Details
                VStack(alignment: .leading, spacing: 4) {
                    if let book = loan.book {
                        Text(book.title)
                            .font(.headline)
                            .lineLimit(2)
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Text(book.genre)
                            .font(.caption)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }

            // Due Date & Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Due Date")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(loan.dueAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(loan.isOverdue ? .red : .primary)
                }

                Spacer()

                if loan.isOverdue {
                    Text("OVERDUE")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(Capsule())
                } else {
                    let daysLeft = Calendar.current.dateComponents([.day], from: .now, to: loan.dueAt).day ?? 0
                    Text("\(daysLeft) days left")
                        .font(.caption)
                        .foregroundColor(daysLeft <= 1 ? .orange : .green)
                }
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onRenew) {
                    Label("Renew", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }

                Button(action: onReturn) {
                    Label("Return", systemImage: "arrowshape.turn.up.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}