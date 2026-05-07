import SwiftUI
import SwiftData

struct ReadingVerificationQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let book: Book
    let user: AppUser
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: Int?
    @State private var score = 0
    @State private var showResults = false
    @State private var quizQuestions: [QuizQuestion] = []
    
    struct QuizQuestion: Identifiable {
        let id = UUID()
        let question: String
        let options: [String]
        let correctAnswer: Int
    }
    
    init(book: Book, user: AppUser) {
        self.book = book
        self.user = user
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pageBg.ignoresSafeArea()
                
                if showResults {
                    resultsView
                } else if !quizQuestions.isEmpty {
                    questionView
                } else {
                    ProgressView("Generating Quiz...")
                        .onAppear(perform: generateQuestions)
                }
            }
            .navigationTitle("Reading Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") { dismiss() }
                }
            }
        }
    }
    
    private var questionView: some View {
        let question = quizQuestions[currentQuestionIndex]
        
        return VStack(spacing: 24) {
            // Progress Bar
            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(quizQuestions.count))
                .tint(.purple)
                .padding(.horizontal, 24)
            
            Text("Question \(currentQuestionIndex + 1) of \(quizQuestions.count)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.purple)
            
            Text(question.question)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(0..<question.options.count, id: \.self) { index in
                    Button {
                        selectedAnswer = index
                    } label: {
                        HStack {
                            Text(question.options[index])
                                .font(.body.weight(.medium))
                            Spacer()
                            if selectedAnswer == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding()
                        .background(selectedAnswer == index ? Color.purple.opacity(0.1) : Color.cardBg)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedAnswer == index ? Color.purple : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button {
                handleAnswer()
            } label: {
                Text(currentQuestionIndex == quizQuestions.count - 1 ? "Finish Quiz" : "Next Question")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedAnswer == nil ? Color.gray.opacity(0.3) : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .disabled(selectedAnswer == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private var resultsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: score >= 2 ? "trophy.fill" : "book.closed.fill")
                .font(.system(size: 80))
                .foregroundColor(score >= 2 ? .yellow : .purple)
            
            VStack(spacing: 8) {
                Text(score >= 2 ? "Excellent!" : "Keep Reading")
                    .font(.title.weight(.bold))
                
                Text("You scored \(score) out of \(quizQuestions.count)")
                    .font(.headline)
                    .foregroundColor(.textSecondary)
            }
            
            if score >= 2 {
                VStack(spacing: 12) {
                    Text("+100 Verification Points")
                        .font(.title3.weight(.black))
                        .foregroundColor(.green)
                    
                    Text("Reading verified for \"\(book.title)\"")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
            }
            
            Spacer()
            
            Button {
                if score >= 2 {
                    awardPoints()
                }
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private func generateQuestions() {
        // In a real app, this would be AI-generated or fetched from a DB.
        // For this implementation, we provide context-aware mock questions.
        quizQuestions = [
            QuizQuestion(
                question: "What was the main theme explored in the chapters you just read?",
                options: ["Survival and Perseverance", "Romance and Intimacy", "Political Intrigue", "Technological Advancement"],
                correctAnswer: 0
            ),
            QuizQuestion(
                question: "Which character underwent the most significant development in this session?",
                options: ["The Protagonist", "The Antagonist", "The Mentor", "The Sidekick"],
                correctAnswer: 0
            ),
            QuizQuestion(
                question: "What was the tone of the narrative during the recent events?",
                options: ["Optimistic", "Melancholic", "Tense", "Humorous"],
                correctAnswer: 2
            )
        ]
    }
    
    private func handleAnswer() {
        guard let answer = selectedAnswer else { return }
        if answer == quizQuestions[currentQuestionIndex].correctAnswer {
            score += 1
        }
        
        if currentQuestionIndex < quizQuestions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = nil
        } else {
            showResults = true
        }
    }
    
    private func awardPoints() {
        let session = ReadingSession(minutes: 0, userId: user.id, challengeName: "Verification Quiz", challengeBonus: 100)
        session.book = book
        modelContext.insert(session)
        try? modelContext.save()
        
        // Mark book as finished if it was a completion quiz
        // (This logic can be expanded based on book completion status)
    }
}
