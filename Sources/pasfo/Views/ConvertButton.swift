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
                    .font(.body)
                if !action.targetApps.isEmpty {
                    Text("  \(action.targetApps)")
                        .font(.caption)
                        .foregroundStyle(isHovered ? Color.white.opacity(0.7) : .secondary)
                }
                Spacer()
                Text(keyHint)
                    .font(.body)
                    .foregroundStyle(isHovered ? Color.white.opacity(0.7) : Color(nsColor: .tertiaryLabelColor))
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isHovered ? .white : .primary)
            .background(isHovered ? Color.accentColor.opacity(0.8) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
