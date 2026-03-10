import SwiftUI

struct ContentView: View {
    @State private var clipboardContent: ClipboardContent?
    @State private var detectedFormat: DetectedFormat = .plainText
    @State private var feedbackMessage: String?
    @State private var showFeedback = false
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Header: format badge
            FormatBadge(format: detectedFormat, sourceAppName: clipboardContent?.sourceAppName, sourceAppBundleId: clipboardContent?.sourceAppBundleId)
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 6)

            Divider()
                .padding(.horizontal, 6)

            // Preview
            if let content = clipboardContent {
                PreviewView(text: content.text)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
            } else {
                Text("clipboard.empty", bundle: .module)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            // Action buttons
            if detectedFormat == .plainText {
                Text("clipboard.plainTextNoConvert", bundle: .module)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(detectedFormat.availableActions.enumerated()), id: \.offset) { index, action in
                        ConvertButton(
                            action: action,
                            keyHint: "\(index + 1)",
                            onConvert: { performConversion(action) }
                        )
                    }
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 5)
            }

            // Feedback
            if showFeedback, let message = feedbackMessage {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.callout)
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Divider()
                .padding(.horizontal, 6)

            // Footer: About & Quit
            VStack(spacing: 0) {
                footerButton(
                    title: String(localized: "footer.about", bundle: .module),
                    shortcutHint: nil
                ) {
                    NSApp.activate()
                    NSApp.orderFrontStandardAboutPanel()
                }

                footerButton(
                    title: String(localized: "footer.quit", bundle: .module),
                    shortcutHint: "⌘Q"
                ) {
                    NSApp.terminate(nil)
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
        }
        .frame(width: 300)
        .onAppear(perform: readClipboard)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            readClipboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            readClipboard()
        }
        .background(keyboardShortcuts)
    }

    // Keyboard shortcuts: 1, 2 keys for quick selection, ⌘Q for quit
    private var keyboardShortcuts: some View {
        Group {
            let actions = detectedFormat.availableActions
            if !actions.isEmpty {
                Button("") { performConversion(actions[0]) }
                    .keyboardShortcut("1", modifiers: [])
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .accessibilityHidden(true)
            }
            if actions.count > 1 {
                Button("") { performConversion(actions[1]) }
                    .keyboardShortcut("2", modifiers: [])
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .accessibilityHidden(true)
            }
            Button("") { NSApp.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func footerButton(title: String, shortcutHint: String?, action: @escaping () -> Void) -> some View {
        HoverButton(title: title, shortcutHint: shortcutHint, action: action)
    }

    private func readClipboard() {
        clipboardContent = ClipboardReader.read()
        if let content = clipboardContent {
            detectedFormat = FormatDetector.detect(content.text, hasHTMLPasteboard: content.hasHTML)
        } else {
            detectedFormat = .plainText
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            showFeedback = false
            feedbackMessage = nil
        }
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
            showSuccess(String(localized: "success.richText", bundle: .module))

        case .toMarkdownTable:
            let markdown = BoxDrawingConverter.toMarkdown(content.text)
            ClipboardWriter.writeText(markdown)
            showSuccess(String(localized: "success.markdownTable", bundle: .module))

        case .toMarkdown:
            let htmlSource = content.htmlContent ?? content.text
            let markdown = HTMLToMarkdownConverter.convert(htmlSource)
            ClipboardWriter.writeText(markdown)
            showSuccess(String(localized: "success.markdown", bundle: .module))

        case .toPlainText:
            let plain = ANSICleaner.clean(content.text)
            ClipboardWriter.writeText(plain)
            showSuccess(String(localized: "success.plainText", bundle: .module))

        case .toAppleNotesHighlighted:
            let html = CodeHighlighter.toHTML(content.text)
            ClipboardWriter.writeHTML(html, fallbackText: content.text)
            showSuccess(String(localized: "success.highlighted", bundle: .module))
        }
    }

    private struct HoverButton: View {
        let title: String
        let shortcutHint: String?
        let action: () -> Void
        @State private var isHovered = false

        var body: some View {
            Button(action: action) {
                HStack {
                    Text(title)
                        .font(.body)
                    Spacer()
                    if let hint = shortcutHint {
                        Text(hint)
                            .font(.caption)
                            .foregroundStyle(isHovered ? Color.white.opacity(0.7) : Color.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .frame(minHeight: 28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(isHovered ? .white : .primary)
                .background(isHovered ? Color.accentColor.opacity(0.8) : .white.opacity(0.001))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovered = hovering
            }
        }
    }

    private func showSuccess(_ message: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            feedbackMessage = message
            showFeedback = true
        }
        // 1.5 秒后自动关闭面板
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            NSApp.keyWindow?.close()
        }
    }
}
