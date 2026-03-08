import Foundation

/// 终端输出段落的格式
enum SegmentFormat: Hashable {
    case shellCommand
    case boxDrawingTable
    case diff
    case tree
    case columnTable
    case json
    case keyValue
    case code
    case text
}

/// 终端输出段落
struct Segment {
    let text: String
    let format: SegmentFormat
}

/// 分段检测器：将终端混合内容按空行分段，每段独立检测格式
struct SegmentDetector {

    /// 将文本分段并检测每段格式
    static func split(_ text: String) -> [Segment] {
        let cleaned = ANSICleaner.clean(text)
        let blocks = splitIntoBlocks(cleaned)
        return blocks.map { block in
            Segment(text: block, format: detectFormat(block))
        }
    }

    /// 按连续空行分割
    private static func splitIntoBlocks(_ text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var blocks: [String] = []
        var current: [String] = []

        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if !current.isEmpty {
                    blocks.append(current.joined(separator: "\n"))
                    current = []
                }
            } else {
                current.append(line)
            }
        }
        if !current.isEmpty {
            blocks.append(current.joined(separator: "\n"))
        }
        return blocks
    }

    /// 检测单段格式
    static func detectFormat(_ text: String) -> SegmentFormat {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard !lines.isEmpty else { return .text }

        // 1. Shell command: 单行以 $ 或 % 开头
        if lines.count == 1 {
            let t = lines[0].trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("$ ") || t.hasPrefix("% ") {
                return .shellCommand
            }
        }

        // 2. Box-drawing 表格
        if FormatDetector.containsBoxDrawing(trimmed) {
            return .boxDrawingTable
        }

        // 3. Diff
        if isDiff(lines) {
            return .diff
        }

        // 4. Tree
        if isTree(lines) {
            return .tree
        }

        // 5. JSON
        if isJSON(trimmed) {
            return .json
        }

        // 6. Column table (空格对齐, 2+ 列)
        if isColumnTable(lines) {
            return .columnTable
        }

        // 7. Key-Value
        if isKeyValue(lines) {
            return .keyValue
        }

        // 8. 代码
        if FormatDetector.isCodeSnippet(trimmed) {
            return .code
        }

        return .text
    }

    // MARK: - Format detection helpers

    private static func isDiff(_ lines: [String]) -> Bool {
        var addLines = 0
        var removeLines = 0
        var headerLines = 0
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("@@") || t.hasPrefix("diff ") {
                headerLines += 1
            } else if t.hasPrefix("--- ") || t.hasPrefix("+++ ") {
                headerLines += 1
            } else if t.hasPrefix("+") {
                addLines += 1
            } else if t.hasPrefix("-") {
                removeLines += 1
            }
        }
        let totalDiff = addLines + removeLines + headerLines
        // 必须有 diff 头部，或同时有 + 和 - 行，才算 diff
        let hasDiffMarkers = headerLines >= 1 || (addLines >= 1 && removeLines >= 1)
        return hasDiffMarkers && totalDiff >= 2 && Double(totalDiff) / Double(lines.count) > 0.4
    }

    private static func isTree(_ lines: [String]) -> Bool {
        var treeLines = 0
        for line in lines {
            if line.contains("\u{251C}") || line.contains("\u{2514}") ||
               line.contains("\u{2502}   ") || line.contains("\u{2502}\u{00A0}") {
                treeLines += 1
            }
        }
        return treeLines >= 2 && Double(treeLines) / Double(lines.count) > 0.3
    }

    private static func isJSON(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return (t.hasPrefix("{") && t.hasSuffix("}")) || (t.hasPrefix("[") && t.hasSuffix("]"))
    }

    private static func isColumnTable(_ lines: [String]) -> Bool {
        guard lines.count >= 2 else { return false }
        let cellCounts = lines.map { splitColumns($0).count }
        guard let first = cellCounts.first, first >= 2 else { return false }
        let consistent = cellCounts.filter { abs($0 - first) <= 1 }.count
        return Double(consistent) / Double(cellCounts.count) > 0.7
    }

    /// 按 2+ 个连续空格拆分列
    static func splitColumns(_ line: String) -> [String] {
        line.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\t", with: "  ")
            .replacingOccurrences(of: #"\s{2,}"#, with: "\t", options: .regularExpression)
            .components(separatedBy: "\t")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func isKeyValue(_ lines: [String]) -> Bool {
        guard lines.count >= 2 else { return false }
        var kvCount = 0
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.range(of: #"^[A-Za-z\u{4e00}-\u{9fff}][\w\s.\u{4e00}-\u{9fff}-]*[:=]\s+.+"#,
                       options: .regularExpression) != nil {
                kvCount += 1
            }
        }
        return kvCount >= 2 && Double(kvCount) / Double(lines.count) > 0.5
    }

    /// 检测是否为终端混合内容
    static func isTerminalMixed(_ text: String) -> Bool {
        let segments = split(text)
        guard segments.count >= 2 else { return false }
        let formats = Set(segments.map { $0.format })
        guard formats.count >= 2 else { return false }
        // 至少有一个终端特有格式
        let terminalFormats: Set<SegmentFormat> = [
            .boxDrawingTable, .diff, .tree, .shellCommand, .columnTable
        ]
        return !formats.isDisjoint(with: terminalFormats)
    }
}
