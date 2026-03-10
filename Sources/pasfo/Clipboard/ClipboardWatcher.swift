import AppKit

/// 轻量级剪贴板监视器，通过 Timer 轮询 changeCount 来跟踪来源 app
class ClipboardWatcher {
    static let shared = ClipboardWatcher()

    private(set) var lastSourceAppName: String?
    private(set) var lastSourceBundleIdentifier: String?
    private var changeCount: Int
    private var timer: Timer?

    private init() {
        changeCount = NSPasteboard.general.changeCount
        let app = NSWorkspace.shared.frontmostApplication
        lastSourceAppName = app?.localizedName
        lastSourceBundleIdentifier = app?.bundleIdentifier
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != changeCount else { return }
        changeCount = pasteboard.changeCount
        // 剪贴板变化时，frontmostApplication 是复制操作的来源 app
        let app = NSWorkspace.shared.frontmostApplication
        lastSourceAppName = app?.localizedName
        lastSourceBundleIdentifier = app?.bundleIdentifier
    }
}
