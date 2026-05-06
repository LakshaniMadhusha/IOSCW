import SwiftUI

struct ReadingStatsCard: View {
    let streak: Int
    let points: Int
    let minutesToday: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reading Streak")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 4) {
                        Text("\(streak)")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.textPrimary)
                        
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Points")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 4) {
                        Text("\(points)")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.textPrimary)
                        
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Reading")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.textSecondary)
                    
                    Text("\(minutesToday) min")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.accent.opacity(0.3), .accent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}
