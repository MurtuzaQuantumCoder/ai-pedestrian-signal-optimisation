import SwiftUI

struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        Text("\(Int((confidence * 100).rounded()))%")
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }

    private var color: Color {
        if confidence >= 0.75 { return .green }
        if confidence >= 0.5 { return .yellow }
        return .orange
    }
}
