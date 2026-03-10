import SwiftUI

struct FormatBadge: View {
    let format: DetectedFormat
    var sourceAppName: String? = nil
    var sourceAppBundleId: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            // 格式图标 + 格式名称
            tagView(
                icon: format.iconName,
                text: format.label,
                color: .orange
            )

            // 应用图标 + 应用名称
            if let bundleId = sourceAppBundleId, let icon = appIcon(for: bundleId) {
                HStack(spacing: 3) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 14, height: 14)
                    if let name = sourceAppName {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

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
