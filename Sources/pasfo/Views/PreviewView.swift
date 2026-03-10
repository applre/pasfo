import SwiftUI

struct PreviewView: View {
    let text: String
    let maxLines: Int = 5

    var body: some View {
        Text(previewText)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(maxLines)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var previewText: String {
        ClipboardReader.preview(text, maxLines: maxLines)
    }
}
