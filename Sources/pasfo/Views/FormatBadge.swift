import SwiftUI

struct FormatBadge: View {
    let format: DetectedFormat
    var sourceAppName: String? = nil
    var sourceAppBundleId: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            // 应用图标
            if let icon = appIcon(for: sourceAppBundleId) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 20, height: 20)
            }

            // 格式标签（含应用名）
            tagView(
                icon: format.iconName,
                text: sourceAppName.map { "\($0) · \(format.label)" } ?? format.label,
                color: .orange
            )

            Spacer()
        }
    }

    private func appIcon(for bundleId: String?) -> NSImage? {
        guard let bundleId,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }

    private func tagView(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .foregroundStyle(color)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
