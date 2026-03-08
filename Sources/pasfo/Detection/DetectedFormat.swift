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
        case .boxDrawingTable: return "Box-drawing 表格"
        case .markdownTable: return "Markdown 表格"
        case .markdownMixed: return "Markdown 混合内容"
        case .html: return "HTML / Rich Text"
        case .terminalMixed: return "终端混合内容"
        case .codeSnippet: return "代码片段"
        case .plainText: return "纯文本"
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

    var badgeColor: String {
        switch self {
        case .boxDrawingTable: return "blue"
        case .markdownTable: return "blue"
        case .markdownMixed: return "purple"
        case .html: return "orange"
        case .terminalMixed: return "teal"
        case .codeSnippet: return "green"
        case .plainText: return "gray"
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
            return [.toAppleNotesHTML, .cleanANSI]
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
    case cleanANSI
    case toAppleNotesHighlighted

    var label: String {
        switch self {
        case .toAppleNotesHTML: return "→ Apple Notes"
        case .toMarkdownTable: return "→ Markdown 表格"
        case .toMarkdown: return "→ Markdown"
        case .toPlainText: return "→ 纯文本"
        case .cleanANSI: return "→ 清理 ANSI"
        case .toAppleNotesHighlighted: return "→ Apple Notes (高亮)"
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
