import Foundation

/// 剪贴板内容的检测格式
enum DetectedFormat: Equatable {
    case boxDrawingTable
    case markdownTable
    case markdownMixed
    case html
    case terminalMixed
    case codeSnippet
    case plainText

    var label: String {
        switch self {
        case .boxDrawingTable: return String(localized: "format.boxDrawingTable", bundle: .module)
        case .markdownTable: return String(localized: "format.markdownTable", bundle: .module)
        case .markdownMixed: return String(localized: "format.markdownMixed", bundle: .module)
        case .html: return String(localized: "format.html", bundle: .module)
        case .terminalMixed: return String(localized: "format.terminalMixed", bundle: .module)
        case .codeSnippet: return String(localized: "format.codeSnippet", bundle: .module)
        case .plainText: return String(localized: "format.plainText", bundle: .module)
        }
    }

    var iconName: String {
        switch self {
        case .boxDrawingTable: return "tablecells"
        case .markdownTable: return "tablecells"
        case .markdownMixed: return "doc.richtext"
        case .html: return "chevron.left.forwardslash.chevron.right"
        case .terminalMixed: return "terminal"
        case .codeSnippet: return "curlybraces"
        case .plainText: return "doc.text"
        }
    }

    /// 根据格式返回可用的转换操作
    var availableActions: [ConvertAction] {
        switch self {
        case .boxDrawingTable:
            return [.toAppleNotesHTML, .toMarkdownTable]
        case .markdownTable:
            return [.toAppleNotesHTML, .toPlainText]
        case .markdownMixed:
            return [.toAppleNotesHTML, .toPlainText]
        case .html:
            return [.toMarkdown, .toPlainText]
        case .terminalMixed:
            return [.toAppleNotesHTML, .toPlainText]
        case .codeSnippet:
            return [.toAppleNotesHighlighted, .toPlainText]
        case .plainText:
            return []
        }
    }
}

/// 转换操作
enum ConvertAction: Equatable {
    case toAppleNotesHTML
    case toMarkdownTable
    case toMarkdown
    case toPlainText
    case toAppleNotesHighlighted

    var label: String {
        switch self {
        case .toAppleNotesHTML: return String(localized: "action.toAppleNotesHTML", bundle: .module)
        case .toMarkdownTable: return String(localized: "action.toMarkdownTable", bundle: .module)
        case .toMarkdown: return String(localized: "action.toMarkdown", bundle: .module)
        case .toPlainText: return String(localized: "action.toPlainText", bundle: .module)
        case .toAppleNotesHighlighted: return String(localized: "action.toAppleNotesHighlighted", bundle: .module)
        }
    }

    var targetApps: String {
        switch self {
        case .toAppleNotesHTML: return "Apple Notes, Obsidian"
        case .toMarkdownTable: return "Obsidian, Notion"
        case .toMarkdown: return "Obsidian, Notion"
        case .toPlainText: return ""
        case .toAppleNotesHighlighted: return "Apple Notes, Obsidian"
        }
    }

    var isRecommended: Bool {
        switch self {
        case .toAppleNotesHTML, .toMarkdown, .toAppleNotesHighlighted:
            return true
        default:
            return false
        }
    }
}
