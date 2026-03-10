import SwiftUI

struct ConvertButton: View {
    let action: ConvertAction
    let keyHint: String
    let onConvert: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onConvert) {
            HStack(spacing: 0) {
                Text(action.label)
                    .font(action.isRecommended ? .body.weight(.semibold) : .body)
                if !action.targetApps.isEmpty {
                    Text("  \(action.targetApps)")
                        .font(.caption)
                        .foregroundStyle(isHovered ? .white.opacity(0.7) : .secondary)
                }
                Spacer()
                Text(keyHint)
                    .font(.caption)
                    .frame(minWidth: 10, alignment: .center)
                    .padding(3)
                    .background(
                        Color.secondary.opacity(isHovered ? 0.5 : 0.8),
                        in: Capsule()
                    )
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isHovered ? .white : .primary)
            .background(isHovered ? Color.accentColor.opacity(0.8) : .white.opacity(0.001))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
