import SwiftUI
import PlaygroundSupport

struct ReadingTrackerView: View {
    @State private var timeElapsed: TimeInterval = 0
    @State private var isRunning = false
    @State private var timer: Timer?

    var body: some View {
        VStack {
            Text("Time: \(timeElapsed)")
            if !isRunning {
                Button("Start") { startTimer() }
            } else {
                Button("Pause") { pauseTimer() }
            }
        }
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation(.linear(duration: 1.0)) {
                timeElapsed += 1
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
}
