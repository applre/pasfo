import SwiftUI

struct ConvertButton: View {
    let action: ConvertAction
    let keyHint: String
    var isHighlighted: Bool = false
    let onConvert: () -> Void
    var onHoverChanged: ((Bool) -> Void)? = nil

    @State private var isHovered = false

    private var active: Bool { isHovered || isHighlighted }

    var body: some View {
        Button(action: onConvert) {
            HStack(spacing: 0) {
                Text(action.label)
                    .font(.body)
                if !action.targetApps.isEmpty {
                    Text("  \(action.targetApps)")
                        .font(.caption)
                        .foregroundStyle(active ? Color.white.opacity(0.7) : .secondary)
                }
                Spacer()
                Text(keyHint)
                    .font(.body)
                    .foregroundStyle(active ? Color.white.opacity(0.7) : Color(nsColor: .tertiaryLabelColor))
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(active ? .white : .primary)
            .background(active ? Color.accentColor.opacity(0.8) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            onHoverChanged?(hovering)
        }
    }
}
