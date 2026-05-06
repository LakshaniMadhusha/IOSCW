import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            // Vibrant native background
            Color.accent.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // High-fidelity icon representation
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 72, weight: .medium))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 140, height: 140)
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)

                VStack(spacing: 8) {
                    Text("Library Companion")
                        .font(.title.weight(.heavy))
                        .foregroundColor(.white)
                        .scaleEffect(scale)
                    
                    Text("Member & Librarian Experience")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            // Classic iOS Spring parameters for snap scale
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0.5)) {
                scale = 1.0
            }
            // Ambient soft fade transition
            withAnimation(.easeIn(duration: 0.5).delay(0.2)) {
                opacity = 1.0
            }
        }
    }
}

