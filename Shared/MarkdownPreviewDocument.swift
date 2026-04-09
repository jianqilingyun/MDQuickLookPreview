import CoreGraphics
import Foundation
import UniformTypeIdentifiers

struct MarkdownPreviewDocument {
    let title: String
    let html: String
    let suggestedSize: CGSize

    static let supportedContentTypes: [UTType] = [
        UTType(filenameExtension: "md") ?? .plainText,
        UTType(filenameExtension: "markdown") ?? .plainText,
        UTType(importedAs: "net.daringfireball.markdown"),
        UTType(importedAs: "org.commonmark.markdown")
    ]

    static func load(from url: URL) throws -> MarkdownPreviewDocument {
        let settings = PreviewSettings.load()
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let markdown = try decodeString(from: data)
        let preparedMarkdown = truncateIfNeeded(markdown, language: settings.language)
        let title = resolvedTitle(from: preparedMarkdown, fallback: url.deletingPathExtension().lastPathComponent)
        let bodyHTML = MarkdownHTMLRenderer(settings: settings).render(preparedMarkdown)
        let pageHTML = HTMLDocumentBuilder.build(title: title, body: bodyHTML, settings: settings)

        return MarkdownPreviewDocument(
            title: title,
            html: pageHTML,
            suggestedSize: CGSize(width: 920, height: 1180)
        )
    }

    private static func decodeString(from data: Data) throws -> String {
        let encodings: [String.Encoding] = [
            .utf8,
            .unicode,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .windowsCP1252
        ]

        for encoding in encodings {
            if let string = String(data: data, encoding: encoding) {
                return string
            }
        }

        throw NSError(
            domain: "MDQuickLookPreview",
            code: 1001,
            userInfo: [NSLocalizedDescriptionKey: "Unable to decode Markdown file."]
        )
    }

    private static func truncateIfNeeded(_ markdown: String, language: PreviewSettings.AppLanguage) -> String {
        let maximumCharacters = 500_000
        guard markdown.count > maximumCharacters else {
            return markdown
        }

        let endIndex = markdown.index(markdown.startIndex, offsetBy: maximumCharacters)
        let message = AppStrings(language: language).truncatedPreviewMessage(characterCount: maximumCharacters)
        return """
        \(markdown[..<endIndex])

        ---
        > \(message)
        """
    }

    private static func resolvedTitle(from markdown: String, fallback: String) -> String {
        for line in markdown.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false) {
            let text = line.trimmingCharacters(in: .whitespaces)
            guard text.hasPrefix("#") else {
                continue
            }

            let candidate = text.drop(while: { $0 == "#" || $0 == " " })
            if !candidate.isEmpty {
                return String(candidate)
            }
        }

        return fallback
    }
}

private enum HTMLDocumentBuilder {
    static func build(title: String, body: String, settings: PreviewSettings) -> String {
        let themeVariables = settings.theme.cssVariables.map { key, value in
            "--\(key): \(value);"
        }.sorted().joined(separator: "\n              ")

        return """
        <!doctype html>
        <html lang="\(settings.language.htmlCode)">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(title.escapedHTML())</title>
          <style>
            :root {
              color-scheme: light;
              \(themeVariables)
              --font-size: \(settings.fontSize.points)px;
              --content-width: \(settings.contentWidth.cssWidth)px;
              --page-bg: var(--page-bg-light);
              --card-bg: var(--card-bg-light);
              --text: var(--text-light);
              --muted: var(--muted-light);
              --border: var(--border-light);
              --accent: var(--accent-light);
              --code-bg: var(--code-bg-light);
              --quote-bg: var(--quote-bg-light);
              --graph-node: var(--graph-node-light);
              --graph-edge: var(--graph-edge-light);
            }

            * { box-sizing: border-box; }
            html, body { margin: 0; padding: 0; }
            body {
              min-height: 100vh;
              padding: 22px 28px 40px;
              background: var(--page-bg);
              color: var(--text);
              font: var(--font-size)/1.68 -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            }
            article {
              width: min(100%, var(--content-width));
              margin: 0 auto;
              padding: 12px 8px 32px;
              overflow: hidden;
              isolation: isolate;
              -webkit-user-select: none;
              user-select: none;
            }
            article * {
              -webkit-user-select: text;
              user-select: text;
            }
            article ::selection {
              background: color-mix(in srgb, var(--accent) 22%, transparent);
              color: inherit;
            }
            h1, h2, h3, h4, h5, h6 {
              margin: 1.35em 0 0.5em;
              line-height: 1.2;
              letter-spacing: -0.03em;
            }
            h1 { margin-top: 0; font-size: 2.3rem; }
            h2 { font-size: 1.72rem; }
            h3 { font-size: 1.34rem; }
            p, ul, ol, blockquote, pre, table { margin: 0 0 1.1em; }
            ul, ol { padding-left: 1.5em; }
            li + li { margin-top: 0.35em; }
            a { color: var(--accent); text-decoration-thickness: 0.08em; }
            hr {
              border: 0;
              border-top: 1px solid var(--border);
              margin: 1.8em 0;
            }
            blockquote {
              padding: 0.85em 1em;
              border-left: 4px solid var(--accent);
              background: var(--quote-bg);
              border-radius: 12px;
              color: var(--muted);
            }
            code {
              padding: 0.12em 0.38em;
              border-radius: 8px;
              background: var(--code-bg);
              font: 0.92em/1.5 "SF Mono", SFMono-Regular, ui-monospace, Menlo, monospace;
            }
            pre {
              overflow-x: auto;
              padding: 1em 1.1em;
              border-radius: 16px;
              background: color-mix(in srgb, var(--code-bg) 88%, transparent);
              border: 1px solid var(--border);
            }
            pre code {
              padding: 0;
              background: transparent;
              border-radius: 0;
            }
            table {
              width: 100%;
              border-collapse: collapse;
              overflow: hidden;
              border: 1px solid var(--border);
              border-radius: 14px;
            }
            th, td {
              padding: 0.72em 0.8em;
              border-bottom: 1px solid var(--border);
              text-align: left;
              vertical-align: top;
            }
            th {
              font-weight: 600;
              background: color-mix(in srgb, var(--code-bg) 75%, transparent);
            }
            tr:last-child td { border-bottom: 0; }
            .md-image {
              display: inline-block;
              color: var(--muted);
              font-style: italic;
            }
            .md-fence-label {
              display: inline-block;
              margin-bottom: 0.65em;
              color: var(--muted);
              font-size: 0.78rem;
              letter-spacing: 0.08em;
              text-transform: uppercase;
            }
            .md-mermaid {
              margin: 0 0 1.2em;
              padding: 1em 1.1em;
              border-radius: 18px;
              border: 1px solid var(--border);
              background: color-mix(in srgb, var(--code-bg) 88%, transparent);
              overflow-x: auto;
            }
            .md-mermaid-svg {
              display: block;
              width: 100%;
              min-width: 320px;
              height: auto;
            }
            .md-mermaid-node rect,
            .md-mermaid-node polygon {
              fill: var(--graph-node);
              stroke: var(--graph-edge);
              stroke-width: 1.8;
            }
            .md-mermaid-node text,
            .md-mermaid-edge-label text {
              fill: var(--text);
              text-anchor: middle;
              font: 13px/1.2 -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            }
            .md-mermaid-edge {
              fill: none;
              stroke: var(--graph-edge);
              stroke-width: 1.8;
              marker-end: url(#md-arrowhead);
            }
            .md-mermaid-edge-label rect {
              fill: var(--card-bg);
              stroke: var(--border);
            }
          </style>
        </head>
        <body>
          <article>
            \(body)
          </article>
        </body>
        </html>
        """
    }
}

private struct MarkdownHTMLRenderer {
    let settings: PreviewSettings

    func render(_ markdown: String) -> String {
        let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        var blocks: [String] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                index += 1
                continue
            }

            if isHorizontalRule(trimmed) {
                blocks.append("<hr>")
                index += 1
                continue
            }

            if isFenceStart(trimmed) {
                let rendered = renderCodeBlock(lines: lines, start: index)
                blocks.append(rendered.html)
                index = rendered.nextIndex
                continue
            }

            if let heading = renderHeading(trimmed) {
                blocks.append(heading)
                index += 1
                continue
            }

            if let table = renderTable(lines: lines, start: index) {
                blocks.append(table.html)
                index = table.nextIndex
                continue
            }

            if let list = renderList(lines: lines, start: index) {
                blocks.append(list.html)
                index = list.nextIndex
                continue
            }

            if isBlockquote(line) {
                let quote = renderBlockquote(lines: lines, start: index)
                blocks.append(quote.html)
                index = quote.nextIndex
                continue
            }

            let paragraph = renderParagraph(lines: lines, start: index)
            blocks.append(paragraph.html)
            index = paragraph.nextIndex
        }

        return blocks.joined(separator: "\n")
    }

    private func renderHeading(_ line: String) -> String? {
        let level = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(level) else {
            return nil
        }

        let content = line.dropFirst(level).trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else {
            return nil
        }

        return "<h\(level)>\(renderInline(String(content)))</h\(level)>"
    }

    private func renderCodeBlock(lines: [String], start: Int) -> (html: String, nextIndex: Int) {
        let fenceLine = lines[start].trimmingCharacters(in: .whitespaces)
        let fenceMarker = fenceLine.hasPrefix("~~~") ? "~~~" : "```"
        let language = fenceLine.dropFirst(fenceMarker.count).trimmingCharacters(in: .whitespaces)

        var index = start + 1
        var content: [String] = []

        while index < lines.count {
            let candidate = lines[index].trimmingCharacters(in: .whitespaces)
            if candidate.hasPrefix(fenceMarker) {
                index += 1
                break
            }

            content.append(lines[index])
            index += 1
        }

        let blockSource = content.joined(separator: "\n")
        if language.caseInsensitiveCompare("mermaid") == .orderedSame,
           let diagram = MermaidFlowchartRenderer().render(blockSource) {
            return (diagram, index)
        }

        let label = language.isEmpty ? "" : "<div class=\"md-fence-label\">\(language.escapedHTML())</div>"
        let code = blockSource.escapedHTML()
        return ("<pre>\(label)<code>\(code)</code></pre>", index)
    }

    private func renderTable(lines: [String], start: Int) -> (html: String, nextIndex: Int)? {
        guard start + 1 < lines.count else {
            return nil
        }

        let headerLine = lines[start]
        let separatorLine = lines[start + 1]
        guard headerLine.contains("|"), isTableSeparator(separatorLine) else {
            return nil
        }

        let headers = splitTableRow(headerLine)
        let alignments = splitTableRow(separatorLine).map(alignment(for:))
        guard !headers.isEmpty, headers.count == alignments.count else {
            return nil
        }

        var bodyRows: [[String]] = []
        var index = start + 2

        while index < lines.count {
            let candidate = lines[index]
            let trimmed = candidate.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || !candidate.contains("|") {
                break
            }

            let row = splitTableRow(candidate)
            if row.count == headers.count {
                bodyRows.append(row)
                index += 1
                continue
            }

            break
        }

        let headerHTML = headers.enumerated().map { offset, value in
            "<th\(style(for: alignments[offset]))>\(renderInline(value))</th>"
        }.joined()

        let bodyHTML = bodyRows.map { row in
            let cells = row.enumerated().map { offset, value in
                "<td\(style(for: alignments[offset]))>\(renderInline(value))</td>"
            }.joined()
            return "<tr>\(cells)</tr>"
        }.joined()

        let html = """
        <table>
          <thead><tr>\(headerHTML)</tr></thead>
          <tbody>\(bodyHTML)</tbody>
        </table>
        """

        return (html, index)
    }

    private func renderList(lines: [String], start: Int) -> (html: String, nextIndex: Int)? {
        let firstLine = lines[start]
        let ordered = orderedListContent(from: firstLine) != nil
        guard ordered || unorderedListContent(from: firstLine) != nil else {
            return nil
        }

        var items: [String] = []
        var index = start

        while index < lines.count {
            let line = lines[index]
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                break
            }

            if ordered, let content = orderedListContent(from: line) {
                items.append("<li>\(renderInline(content))</li>")
                index += 1
                continue
            }

            if !ordered, let content = unorderedListContent(from: line) {
                items.append("<li>\(renderInline(content))</li>")
                index += 1
                continue
            }

            break
        }

        let tag = ordered ? "ol" : "ul"
        return ("<\(tag)>\n\(items.joined(separator: "\n"))\n</\(tag)>", index)
    }

    private func renderBlockquote(lines: [String], start: Int) -> (html: String, nextIndex: Int) {
        var index = start
        var quoteLines: [String] = []

        while index < lines.count {
            let line = lines[index]
            guard isBlockquote(line) else {
                break
            }

            let stripped = line.trimmingCharacters(in: .whitespaces)
                .dropFirst()
                .drop(while: { $0 == " " })
            quoteLines.append(String(stripped))
            index += 1
        }

        let nestedHTML = render(quoteLines.joined(separator: "\n"))
        return ("<blockquote>\(nestedHTML)</blockquote>", index)
    }

    private func renderParagraph(lines: [String], start: Int) -> (html: String, nextIndex: Int) {
        var index = start
        var collected: [String] = []

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || startsNewBlock(lines: lines, index: index) {
                break
            }

            collected.append(trimmed)
            index += 1
        }

        let text = collected.joined(separator: " ")
        return ("<p>\(renderInline(text))</p>", index)
    }

    private func renderInline(_ text: String) -> String {
        var placeholders: [String: String] = [:]
        var placeholderIndex = 0

        func store(_ html: String) -> String {
            let key = "@@MD\(placeholderIndex)@@"
            placeholderIndex += 1
            placeholders[key] = html
            return key
        }

        var transformed = text

        transformed = replacingMatches(
            in: transformed,
            pattern: "!\\[([^\\]]*)\\]\\(([^\\)\\s]+)(?:\\s+\"[^\"]*\")?\\)"
        ) { groups in
            let label = groups[1].isEmpty ? groups[2] : groups[1]
            return store("<span class=\"md-image\">[image: \(label.escapedHTML())]</span>")
        }

        transformed = replacingMatches(
            in: transformed,
            pattern: "\\[([^\\]]+)\\]\\(([^\\)\\s]+)(?:\\s+\"[^\"]*\")?\\)"
        ) { groups in
            let href = sanitizedHref(groups[2])
            return store("<a href=\"\(href.escapedHTMLAttribute())\">\(groups[1].escapedHTML())</a>")
        }

        transformed = replacingMatches(
            in: transformed,
            pattern: "`([^`]+)`"
        ) { groups in
            store("<code>\(groups[1].escapedHTML())</code>")
        }

        transformed = transformed.escapedHTML()
        transformed = replacingMatches(in: transformed, pattern: "\\*\\*(.+?)\\*\\*") { groups in
            "<strong>\(groups[1])</strong>"
        }
        transformed = replacingMatches(in: transformed, pattern: "__(.+?)__") { groups in
            "<strong>\(groups[1])</strong>"
        }
        transformed = replacingMatches(in: transformed, pattern: "~~(.+?)~~") { groups in
            "<del>\(groups[1])</del>"
        }
        transformed = replacingMatches(in: transformed, pattern: "(?<!\\*)\\*(?!\\s)(.+?)(?<!\\s)\\*(?!\\*)") { groups in
            "<em>\(groups[1])</em>"
        }
        transformed = replacingMatches(in: transformed, pattern: "(?<!_)_(?!\\s)(.+?)(?<!\\s)_(?!_)") { groups in
            "<em>\(groups[1])</em>"
        }

        for (key, value) in placeholders {
            transformed = transformed.replacingOccurrences(of: key, with: value)
        }

        return transformed
    }

    private func startsNewBlock(lines: [String], index: Int) -> Bool {
        let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
        if index == 0 {
            return false
        }

        return isHorizontalRule(trimmed)
            || isFenceStart(trimmed)
            || renderHeading(trimmed) != nil
            || isBlockquote(lines[index])
            || orderedListContent(from: lines[index]) != nil
            || unorderedListContent(from: lines[index]) != nil
            || renderTable(lines: lines, start: index) != nil
    }

    private func isFenceStart(_ line: String) -> Bool {
        line.hasPrefix("```") || line.hasPrefix("~~~")
    }

    private func isHorizontalRule(_ line: String) -> Bool {
        let compact = line.replacingOccurrences(of: " ", with: "")
        return compact == "---" || compact == "***" || compact == "___"
    }

    private func isBlockquote(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasPrefix(">")
    }

    private func orderedListContent(from line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let pattern = #"^\d+\.\s+(.+)$"#
        return firstCapture(in: trimmed, pattern: pattern)
    }

    private func unorderedListContent(from line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let pattern = #"^[-*+]\s+(.+)$"#
        return firstCapture(in: trimmed, pattern: pattern)
    }

    private func splitTableRow(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let normalized = trimmed
            .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        return normalized
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func isTableSeparator(_ line: String) -> Bool {
        let cells = splitTableRow(line)
        guard !cells.isEmpty else {
            return false
        }

        return cells.allSatisfy { cell in
            let compact = cell.replacingOccurrences(of: " ", with: "")
            guard compact.count >= 3 else { return false }
            let stripped = compact.replacingOccurrences(of: ":", with: "")
            return !stripped.isEmpty && stripped.allSatisfy { $0 == "-" }
        }
    }

    private func alignment(for cell: String) -> String {
        let compact = cell.replacingOccurrences(of: " ", with: "")
        let left = compact.hasPrefix(":")
        let right = compact.hasSuffix(":")

        switch (left, right) {
        case (true, true):
            return "center"
        case (false, true):
            return "right"
        default:
            return "left"
        }
    }

    private func style(for alignment: String) -> String {
        " style=\"text-align: \(alignment);\""
    }

    private func firstCapture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return String(text[captureRange])
    }

    private func replacingMatches(
        in text: String,
        pattern: String,
        options: NSRegularExpression.Options = [],
        transform: ([String]) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        guard !matches.isEmpty else {
            return text
        }

        var result = ""
        var cursor = text.startIndex

        for match in matches {
            guard let range = Range(match.range, in: text) else {
                continue
            }

            result += text[cursor..<range.lowerBound]

            let groups: [String] = (0..<match.numberOfRanges).map { index in
                guard let capture = Range(match.range(at: index), in: text) else {
                    return ""
                }
                return String(text[capture])
            }

            result += transform(groups)
            cursor = range.upperBound
        }

        result += text[cursor...]
        return result
    }

    private func sanitizedHref(_ href: String) -> String {
        let lowercased = href.lowercased()
        if lowercased.hasPrefix("http://")
            || lowercased.hasPrefix("https://")
            || lowercased.hasPrefix("mailto:")
            || lowercased.hasPrefix("file://")
            || !href.contains(":") {
            return href
        }

        return "#"
    }
}

extension String {
    func escapedHTML() -> String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    func escapedHTMLAttribute() -> String {
        escapedHTML()
    }
}
