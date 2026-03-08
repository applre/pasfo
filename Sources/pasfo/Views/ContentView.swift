import SwiftUI

struct ContentView: View {
    @State private var clipboardContent: ClipboardContent?
    @State private var detectedFormat: DetectedFormat = .plainText
    @State private var feedbackMessage: String?
    @State private var showFeedback = false

    var body: some View {
        VStack(spacing: 0) {
            // Header: format badge
            HStack {
                FormatBadge(format: detectedFormat)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            // Preview
            if let content = clipboardContent {
                PreviewView(text: content.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            } else {
                Text("剪贴板为空")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }

            Divider()

            // Action buttons
            if detectedFormat == .plainText {
                Text("纯文本，无需转换")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(detectedFormat.availableActions.enumerated()), id: \.offset) { index, action in
                        ConvertButton(
                            action: action,
                            keyHint: "\(index + 1)",
                            onConvert: { performConversion(action) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            // Feedback
            if showFeedback, let message = feedbackMessage {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(width: 320)
        .onAppear(perform: readClipboard)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            readClipboard()
        }
        .background(keyboardShortcuts)
    }

    // Keyboard shortcuts: 1, 2 keys for quick selection
    private var keyboardShortcuts: some View {
        Group {
            let actions = detectedFormat.availableActions
            if actions.count > 0 {
                Button("") { performConversion(actions[0]) }
                    .keyboardShortcut("1", modifiers: [])
                    .frame(width: 0, height: 0)
                    .opacity(0)
            }
            if actions.count > 1 {
                Button("") { performConversion(actions[1]) }
                    .keyboardShortcut("2", modifiers: [])
                    .frame(width: 0, height: 0)
                    .opacity(0)
            }
        }
    }

    private func readClipboard() {
        clipboardContent = ClipboardReader.read()
        if let content = clipboardContent {
            detectedFormat = FormatDetector.detect(content.text, hasHTMLPasteboard: content.hasHTML)
        } else {
            detectedFormat = .plainText
        }
        showFeedback = false
        feedbackMessage = nil
    }

    private func performConversion(_ action: ConvertAction) {
        guard let content = clipboardContent else { return }

        switch action {
        case .toAppleNotesHTML:
            let html: String
            switch detectedFormat {
            case .boxDrawingTable:
                html = BoxDrawingConverter.toHTML(content.text)
            case .terminalMixed:
                html = TerminalMixedConverter.toHTML(content.text)
            case .markdownTable, .markdownMixed:
                html = MarkdownConverter.toHTML(content.text)
            default:
                html = MarkdownConverter.toHTML(content.text)
            }
            ClipboardWriter.writeHTML(html, fallbackText: content.text)
            showSuccess("已转换为 Rich Text，可直接粘贴")

        case .toMarkdownTable:
            let markdown = BoxDrawingConverter.toMarkdown(content.text)
            ClipboardWriter.writeText(markdown)
            showSuccess("已转换为 Markdown 表格")

        case .toMarkdown:
            let htmlSource = content.htmlContent ?? content.text
            let markdown = HTMLToMarkdownConverter.convert(htmlSource)
            ClipboardWriter.writeText(markdown)
            showSuccess("已转换为 Markdown")

        case .toPlainText:
            let plain = ANSICleaner.clean(content.text)
            ClipboardWriter.writeText(plain)
            showSuccess("已转换为纯文本")

        case .cleanANSI:
            let cleaned = ANSICleaner.clean(content.text)
            ClipboardWriter.writeText(cleaned)
            showSuccess("已清理 ANSI 转义符")

        case .toAppleNotesHighlighted:
            let html = CodeHighlighter.toHTML(content.text)
            ClipboardWriter.writeHTML(html, fallbackText: content.text)
            showSuccess("已转换为语法高亮 Rich Text")
        }
    }

    private func showSuccess(_ message: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            feedbackMessage = message
            showFeedback = true
        }
        // 1.5 秒后自动关闭面板
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            NSApp.keyWindow?.close()
        }
    }
}
