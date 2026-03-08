import SwiftUI

struct FormatBadge: View {
    let format: DetectedFormat

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: format.iconName)
                .font(.system(size: 12))
            Text("检测到: \(format.label)")
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(badgeTextColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(badgeBackgroundColor)
        .clipShape(Capsule())
    }

    private var badgeTextColor: Color {
        switch format.badgeColor {
        case "blue": return Color(nsColor: .systemBlue)
        case "purple": return Color(nsColor: .systemPurple)
        case "orange": return Color(nsColor: .systemOrange)
        case "green": return Color(nsColor: .systemGreen)
        default: return .secondary
        }
    }

    private var badgeBackgroundColor: Color {
        badgeTextColor.opacity(0.12)
    }
}
