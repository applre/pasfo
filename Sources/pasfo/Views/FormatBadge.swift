import SwiftUI

struct FormatBadge: View {
    let format: DetectedFormat
    var sourceAppName: String? = nil
    var sourceAppBundleId: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text(String(localized: "badge.detected", bundle: .module))
                .font(.caption)
                .foregroundStyle(.secondary)

            // 格式
            tagView(
                icon: format.iconName,
                text: format.label,
                color: .orange
            )

            // 应用来源
            if let app = sourceAppName {
                appTagView(
                    appName: app,
                    bundleId: sourceAppBundleId
                )
            }

            Spacer()
        }
    }

    private func appIcon(for bundleId: String?) -> NSImage? {
        print("[FormatBadge] bundleId=\(bundleId ?? "nil"), appName=\(sourceAppName ?? "nil")")
        guard let bundleId,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            print("[FormatBadge] urlForApplication returned nil")
            return nil
        }
        print("[FormatBadge] appURL=\(appURL)")
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }

    private func appTagView(appName: String, bundleId: String?) -> some View {
        HStack(spacing: 3) {
            if let icon = appIcon(for: bundleId) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 12, height: 12)
            } else {
                Image(systemName: "app.fill")
                    .font(.caption2)
            }
            Text(appName)
                .font(.caption)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .foregroundStyle(.blue)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func tagView(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
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
