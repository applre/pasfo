import SwiftUI

struct ConvertButton: View {
    let action: ConvertAction
    let keyHint: String
    let onConvert: () -> Void

    var body: some View {
        Button(action: onConvert) {
            HStack(spacing: 6) {
                Text(action.label)
                    .font(.system(size: 13, weight: action.isRecommended ? .semibold : .regular))
                Spacer()
                Text(keyHint)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .separatorColor).opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(ConvertButtonStyle(isRecommended: action.isRecommended))
    }
}

struct ConvertButtonStyle: ButtonStyle {
    let isRecommended: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                isRecommended
                    ? AnyShapeStyle(Color.accentColor)
                    : AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
            )
            .foregroundColor(isRecommended ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
