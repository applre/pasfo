import AppKit

struct ClipboardContent {
    let text: String
    let hasHTML: Bool
    let htmlContent: String?
    let sourceAppName: String?
    let sourceAppBundleId: String?
}

struct ClipboardReader {
    /// 读取剪贴板内容并检测格式
    static func read() -> ClipboardContent? {
        let pasteboard = NSPasteboard.general

        let hasHTML = pasteboard.availableType(from: [.html]) != nil
        let htmlContent = pasteboard.string(forType: .html)
        let sourceAppName = ClipboardWatcher.shared.lastSourceAppName
        let sourceAppBundleId = ClipboardWatcher.shared.lastSourceBundleIdentifier

        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            // 如果没有纯文本但有 HTML
            if let html = htmlContent {
                return ClipboardContent(text: html, hasHTML: true, htmlContent: html, sourceAppName: sourceAppName, sourceAppBundleId: sourceAppBundleId)
            }
            return nil
        }

        return ClipboardContent(text: text, hasHTML: hasHTML, htmlContent: htmlContent, sourceAppName: sourceAppName, sourceAppBundleId: sourceAppBundleId)
    }

    /// 获取预览文本（最多 maxLines 行）
    static func preview(_ text: String, maxLines: Int = 5) -> String {
        let lines = text.components(separatedBy: .newlines)
        let previewLines = Array(lines.prefix(maxLines))
        let result = previewLines.joined(separator: "\n")
        if lines.count > maxLines {
            return result + "\n..."
        }
        return result
    }
}
