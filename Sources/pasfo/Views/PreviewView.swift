import SwiftUI

struct PreviewView: View {
    let text: String
    let maxLines: Int = 5

    var body: some View {
        Text(previewText)
            .font(.body)
            .foregroundStyle(.primary.opacity(0.8))
            .lineSpacing(4)
            .lineLimit(maxLines)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(nsColor: .quaternarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var previewText: String {
        ClipboardReader.preview(text, maxLines: maxLines)
    }
}
