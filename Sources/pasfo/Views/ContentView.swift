import SwiftUI

struct ContentView: View {
    @State private var clipboardContent: ClipboardContent?
    @State private var detectedFormat: DetectedFormat = .plainText
    @State private var feedbackMessage: String?
    @State private var showFeedback = false
    @State private var dismissTask: Task<Void, Never>?
    @State private var focusedIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header: format badge
            FormatBadge(format: detectedFormat, sourceAppName: clipboardContent?.sourceAppName, sourceAppBundleId: clipboardContent?.sourceAppBundleId)
                .padding(.horizontal, 10)
                .padding(.top, 5)
                .padding(.bottom, 6)

            Divider()
                .padding(.horizontal, 6)

            // Preview
            if let content = clipboardContent {
                PreviewView(text: content.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            } else {
                Text("clipboard.empty", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            // Action buttons
            if detectedFormat == .plainText {
                Text("clipboard.plainTextNoConvert", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(detectedFormat.availableActions.enumerated()), id: \.offset) { index, action in
                        ConvertButton(
                            action: action,
                            keyHint: "\(index + 1)",
                            isHighlighted: focusedIndex == index,
                            onConvert: { performConversion(action) },
                            onHoverChanged: { hovering in
                                if hovering { focusedIndex = index }
                            }
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
                        .font(.caption)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Divider()
                .padding(.horizontal, 6)

            // Footer: About & Quit
            VStack(spacing: 0) {
                menuItem(
                    title: String(localized: "footer.about", bundle: .module),
                    shortcutHint: nil,
                    isHighlighted: focusedIndex == aboutIndex,
                    onHover: { hovering in if hovering { focusedIndex = aboutIndex } }
                ) {
                    NSApp.activate()
                    NSApp.orderFrontStandardAboutPanel()
                }

                menuItem(
                    title: String(localized: "footer.quit", bundle: .module),
                    shortcutHint: "⌘Q",
                    isHighlighted: focusedIndex == quitIndex,
                    onHover: { hovering in if hovering { focusedIndex = quitIndex } }
                ) {
                    NSApp.terminate(nil)
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
        }
        .frame(width: 300)
        .ignoresSafeArea()
        .onAppear(perform: readClipboard)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            readClipboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            readClipboard()
        }
        .background(keyboardShortcuts)
    }

    private var totalItemCount: Int {
        detectedFormat.availableActions.count + 2 // actions + About + Quit
    }

    private var aboutIndex: Int { detectedFormat.availableActions.count }
    private var quitIndex: Int { detectedFormat.availableActions.count + 1 }

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
            Button("") {
                focusedIndex = (focusedIndex - 1 + totalItemCount) % totalItemCount
            }
                .keyboardShortcut(.upArrow, modifiers: [])
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
            Button("") {
                focusedIndex = (focusedIndex + 1) % totalItemCount
            }
                .keyboardShortcut(.downArrow, modifiers: [])
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
            Button("") { executeFocusedItem() }
                .keyboardShortcut(.return, modifiers: [])
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
            Button("") { NSApp.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
        }
    }

    private func executeFocusedItem() {
        let actions = detectedFormat.availableActions
        if focusedIndex < actions.count {
            performConversion(actions[focusedIndex])
        } else if focusedIndex == aboutIndex {
            NSApp.activate()
            NSApp.orderFrontStandardAboutPanel()
        } else if focusedIndex == quitIndex {
            NSApp.terminate(nil)
        }
    }

    @ViewBuilder
    private func menuItem(title: String, shortcutHint: String?, isHighlighted: Bool, onHover: @escaping (Bool) -> Void, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                Spacer()
                if let hint = shortcutHint {
                    Text(hint)
                        .font(.body)
                        .foregroundStyle(isHighlighted ? Color.white.opacity(0.7) : Color(nsColor: .tertiaryLabelColor))
                }
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isHighlighted ? .white : .primary)
            .background(isHighlighted ? Color.accentColor.opacity(0.8) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover(perform: onHover)
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
