import Testing
@testable import pasfo

@Suite("BoxDrawingConverter")
struct BoxDrawingConverterTests {

    let sampleTable = """
    ┌──────────┬──────────┬──────────┐
    │ Column 1 │ Column 2 │ Column 3 │
    ├──────────┼──────────┼──────────┤
    │ data 1   │ data 2   │ data 3   │
    │ data 4   │ data 5   │ data 6   │
    └──────────┴──────────┴──────────┘
    """

    @Test("解析 box-drawing 表格行数正确")
    func parseRowCount() {
        let rows = BoxDrawingConverter.parseBoxDrawingTable(sampleTable)
        #expect(rows.count == 3) // header + 2 data rows
    }

    @Test("解析 box-drawing 表格列数正确")
    func parseColumnCount() {
        let rows = BoxDrawingConverter.parseBoxDrawingTable(sampleTable)
        for row in rows {
            #expect(row.count == 3)
        }
    }

    @Test("解析 box-drawing 表格内容正确")
    func parseCellContent() {
        let rows = BoxDrawingConverter.parseBoxDrawingTable(sampleTable)
        #expect(rows[0][0] == "Column 1")
        #expect(rows[0][1] == "Column 2")
        #expect(rows[1][0] == "data 1")
        #expect(rows[2][2] == "data 6")
    }

    @Test("转换为 HTML 包含 table 标签")
    func toHTMLContainsTable() {
        let html = BoxDrawingConverter.toHTML(sampleTable)
        #expect(html.contains("<table"))
        #expect(html.contains("<th"))
        #expect(html.contains("<td"))
        #expect(html.contains("Column 1"))
        #expect(html.contains("data 3"))
    }

    @Test("转换为 Markdown 表格格式正确")
    func toMarkdownFormat() {
        let markdown = BoxDrawingConverter.toMarkdown(sampleTable)
        #expect(markdown.contains("| Column 1"))
        #expect(markdown.contains("| ---"))
        #expect(markdown.contains("| data 1"))
        // Should have header + separator + 2 data rows = 4 lines
        let lines = markdown.components(separatedBy: .newlines)
        #expect(lines.count == 4)
    }

    @Test("处理双线 box-drawing 表格")
    func doubleLineTable() {
        let input = """
        ╔══════════╦══════════╗
        ║ Header 1 ║ Header 2 ║
        ╠══════════╬══════════╣
        ║ Cell 1   ║ Cell 2   ║
        ╚══════════╩══════════╝
        """
        let rows = BoxDrawingConverter.parseBoxDrawingTable(input)
        #expect(rows.count == 2)
        #expect(rows[0][0] == "Header 1")
        #expect(rows[1][1] == "Cell 2")
    }

    @Test("多物理行合并为一个逻辑行（终端 wrap）")
    func multiPhysicalLinesMerge() {
        let input = """
        ┌──────────────┬──────────────────────────┬──────────────────────────┐
        │ 模块         │ 文件                     │ 功能                     │
        ├──────────────┼──────────────────────────┼──────────────────────────┤
        │ Box-drawing  │ BoxDrawingConverter.swift │ Unicode 表格 → HTML      │
        │ 转换         │                          │ table                    │
        ├──────────────┼──────────────────────────┼──────────────────────────┤
        │ Markdown 转换│ MarkdownConverter.swift   │ Markdown → Apple Notes   │
        │              │                          │ HTML                     │
        └──────────────┴──────────────────────────┴──────────────────────────┘
        """
        let rows = BoxDrawingConverter.parseBoxDrawingTable(input)
        #expect(rows.count == 3) // header + 2 data rows
        #expect(rows[1][0] == "Box-drawing 转换")
        #expect(rows[1][2] == "Unicode 表格 → HTML table")
        #expect(rows[2][0] == "Markdown 转换")
        #expect(rows[2][2] == "Markdown → Apple Notes HTML")
    }

    @Test("toMarkdown 续行正确合并")
    func toMarkdownWithContinuation() {
        let input = """
        ┌──────────────┬───────────┐
        │ Box-drawing  │ 功能A     │
        │ 转换         │           │
        ├──────────────┼───────────┤
        │ 测试         │ 功能B     │
        └──────────────┴───────────┘
        """
        let md = BoxDrawingConverter.toMarkdown(input)
        #expect(md.contains("Box-drawing 转换"))
        // 只有 header + separator + 1 data row = 3 lines
        let lines = md.components(separatedBy: .newlines)
        #expect(lines.count == 3)
    }

    @Test("处理 ASCII art 表格 (+---+)")
    func asciiArtTable() {
        let input = """
        +----------+----------+
        | Name     | Value    |
        +----------+----------+
        | foo      | bar      |
        +----------+----------+
        """
        let rows = BoxDrawingConverter.parseBoxDrawingTable(input)
        #expect(rows.count == 2)
        #expect(rows[0][0] == "Name")
        #expect(rows[1][1] == "bar")
    }
}
