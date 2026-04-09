import Foundation

struct MermaidFlowchartRenderer {
    func render(_ source: String) -> String? {
        guard let graph = MermaidGraphParser().parse(source) else {
            return nil
        }

        let layout = MermaidGraphLayout(graph: graph)
        return MermaidSVGBuilder(graph: graph, layout: layout).build()
    }
}

private struct MermaidGraph {
    struct Node {
        enum Shape: Equatable {
            case rectangle
            case rounded
            case diamond
        }

        let id: String
        var label: String
        var shape: Shape
        let order: Int
    }

    struct Edge {
        let from: String
        let to: String
        let label: String?
    }

    var nodes: [String: Node]
    var edges: [Edge]
}

private struct MermaidGraphParser {
    func parse(_ source: String) -> MermaidGraph? {
        let rawLines = source.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        let lines = rawLines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("%%") }

        guard let header = lines.first else {
            return nil
        }

        let lowercasedHeader = header.lowercased()
        guard lowercasedHeader.hasPrefix("graph td")
            || lowercasedHeader.hasPrefix("flowchart td")
            || lowercasedHeader.hasPrefix("graph tb")
            || lowercasedHeader.hasPrefix("flowchart tb") else {
            return nil
        }

        var nodes: [String: MermaidGraph.Node] = [:]
        var edges: [MermaidGraph.Edge] = []
        var nextOrder = 0

        for line in lines.dropFirst() {
            if let labeledEdge = parseLabeledEdge(line) {
                let fromNode = parseNodeToken(labeledEdge.from, order: &nextOrder, nodes: &nodes)
                let toNode = parseNodeToken(labeledEdge.to, order: &nextOrder, nodes: &nodes)
                edges.append(.init(from: fromNode.id, to: toNode.id, label: labeledEdge.label))
                continue
            }

            let segments = line.components(separatedBy: "-->").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            guard segments.count >= 2 else {
                continue
            }

            var previous = parseNodeToken(segments[0], order: &nextOrder, nodes: &nodes)
            for segment in segments.dropFirst() {
                let nextNode = parseNodeToken(segment, order: &nextOrder, nodes: &nodes)
                edges.append(.init(from: previous.id, to: nextNode.id, label: nil))
                previous = nextNode
            }
        }

        guard !nodes.isEmpty else {
            return nil
        }

        return MermaidGraph(nodes: nodes, edges: edges)
    }

    private func parseLabeledEdge(_ line: String) -> (from: String, label: String, to: String)? {
        let pattern = #"^\s*(.+?)\s*-->\|([^|]+)\|\s*(.+?)\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              let fromRange = Range(match.range(at: 1), in: line),
              let labelRange = Range(match.range(at: 2), in: line),
              let toRange = Range(match.range(at: 3), in: line) else {
            return nil
        }

        return (
            from: String(line[fromRange]),
            label: String(line[labelRange]).trimmingCharacters(in: .whitespaces),
            to: String(line[toRange])
        )
    }

    private func parseNodeToken(
        _ token: String,
        order: inout Int,
        nodes: inout [String: MermaidGraph.Node]
    ) -> MermaidGraph.Node {
        let trimmed = token.trimmingCharacters(in: .whitespaces)
        let pattern = #"^([A-Za-z0-9_:\-]+)(?:\[(.*?)\]|\((.*?)\)|\{(.*?)\})?$"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let idRange = Range(match.range(at: 1), in: trimmed) else {
            return ensureNode(id: trimmed, label: trimmed, shape: .rectangle, order: &order, nodes: &nodes)
        }

        let id = String(trimmed[idRange])
        let squareLabel = capture(match, at: 2, in: trimmed)
        let roundedLabel = capture(match, at: 3, in: trimmed)
        let diamondLabel = capture(match, at: 4, in: trimmed)

        if let squareLabel {
            return ensureNode(id: id, label: squareLabel, shape: .rectangle, order: &order, nodes: &nodes)
        }

        if let roundedLabel {
            return ensureNode(id: id, label: roundedLabel, shape: .rounded, order: &order, nodes: &nodes)
        }

        if let diamondLabel {
            return ensureNode(id: id, label: diamondLabel, shape: .diamond, order: &order, nodes: &nodes)
        }

        return ensureNode(id: id, label: id, shape: .rectangle, order: &order, nodes: &nodes)
    }

    private func ensureNode(
        id: String,
        label: String,
        shape: MermaidGraph.Node.Shape,
        order: inout Int,
        nodes: inout [String: MermaidGraph.Node]
    ) -> MermaidGraph.Node {
        if var existing = nodes[id] {
            if existing.label == id && label != id {
                existing.label = label
            }
            if shape != .rectangle {
                existing.shape = shape
            }
            nodes[id] = existing
            return existing
        }

        let node = MermaidGraph.Node(id: id, label: label, shape: shape, order: order)
        order += 1
        nodes[id] = node
        return node
    }

    private func capture(_ match: NSTextCheckingResult, at index: Int, in text: String) -> String? {
        guard let range = Range(match.range(at: index), in: text) else {
            return nil
        }

        let value = String(text[range]).trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }
}

private struct MermaidGraphLayout {
    struct PositionedNode {
        let node: MermaidGraph.Node
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }

    let width: Double
    let height: Double
    let positionedNodes: [String: PositionedNode]

    init(graph: MermaidGraph) {
        let levelSpacing = 120.0
        let rowSpacing = 34.0
        let topPadding = 26.0
        let horizontalPadding = 28.0
        let verticalPadding = 28.0

        var levels = Dictionary(uniqueKeysWithValues: graph.nodes.keys.map { ($0, 0) })
        for _ in 0..<graph.nodes.count {
            for edge in graph.edges where edge.from != edge.to {
                let candidate = (levels[edge.from] ?? 0) + 1
                if candidate > (levels[edge.to] ?? 0) {
                    levels[edge.to] = candidate
                }
            }
        }

        let grouped = Dictionary(grouping: graph.nodes.values) { levels[$0.id] ?? 0 }
        let orderedLevels = grouped.keys.sorted()
        var rows: [[MermaidGraph.Node]] = orderedLevels.map { level in
            grouped[level, default: []].sorted { $0.order < $1.order }
        }

        if rows.isEmpty {
            rows = [graph.nodes.values.sorted { $0.order < $1.order }]
        }

        var rowWidths: [Double] = []
        var rowHeights: [Double] = []
        var nodeSizes: [String: (width: Double, height: Double)] = [:]

        for row in rows {
            let sizes = row.map { node -> (Double, Double) in
                let width = max(112.0, min(240.0, Double(node.label.count) * 8.0 + 34.0))
                let height = node.shape == .diamond ? 72.0 : 56.0
                nodeSizes[node.id] = (width, height)
                return (width, height)
            }

            let totalWidth = sizes.map(\.0).reduce(0, +) + Double(max(row.count - 1, 0)) * rowSpacing
            rowWidths.append(totalWidth)
            rowHeights.append(sizes.map(\.1).max() ?? 56.0)
        }

        let canvasWidth = max((rowWidths.max() ?? 220.0) + horizontalPadding * 2.0, 360.0)
        let canvasHeight = topPadding + rowHeights.enumerated().reduce(0.0) { partial, entry in
            partial + entry.element + (entry.offset == rowHeights.count - 1 ? 0 : levelSpacing)
        } + verticalPadding

        var positionedNodes: [String: PositionedNode] = [:]
        var currentY = topPadding

        for (rowIndex, row) in rows.enumerated() {
            let rowWidth = rowWidths[rowIndex]
            var currentX = (canvasWidth - rowWidth) / 2.0
            let rowHeight = rowHeights[rowIndex]

            for node in row {
                let size = nodeSizes[node.id] ?? (112.0, 56.0)
                let y = currentY + (rowHeight - size.height) / 2.0
                positionedNodes[node.id] = PositionedNode(
                    node: node,
                    x: currentX,
                    y: y,
                    width: size.width,
                    height: size.height
                )
                currentX += size.width + rowSpacing
            }

            currentY += rowHeight + levelSpacing
        }

        self.width = canvasWidth
        self.height = canvasHeight
        self.positionedNodes = positionedNodes
    }
}

private struct MermaidSVGBuilder {
    let graph: MermaidGraph
    let layout: MermaidGraphLayout

    func build() -> String {
        let edgesHTML = graph.edges.compactMap(renderEdge).joined(separator: "\n")
        let nodesHTML = graph.nodes.values
            .sorted { $0.order < $1.order }
            .compactMap { renderNode(layout.positionedNodes[$0.id]) }
            .joined(separator: "\n")

        return """
        <div class="md-mermaid">
          <div class="md-fence-label">mermaid / graph TD</div>
          <svg class="md-mermaid-svg" viewBox="0 0 \(Int(layout.width)) \(Int(layout.height))" role="img" aria-label="Mermaid flowchart">
            <defs>
              <marker id="md-arrowhead" markerWidth="10" markerHeight="8" refX="9" refY="4" orient="auto" markerUnits="strokeWidth">
                <path d="M 0 0 L 10 4 L 0 8 z" fill="var(--graph-edge)"></path>
              </marker>
            </defs>
            \(edgesHTML)
            \(nodesHTML)
          </svg>
        </div>
        """
    }

    private func renderEdge(_ edge: MermaidGraph.Edge) -> String? {
        guard let from = layout.positionedNodes[edge.from],
              let to = layout.positionedNodes[edge.to] else {
            return nil
        }

        let startX = from.x + from.width / 2.0
        let startY = from.y + from.height
        let endX = to.x + to.width / 2.0
        let endY = to.y
        let midY = (startY + endY) / 2.0
        let path = "M \(fmt(startX)) \(fmt(startY)) C \(fmt(startX)) \(fmt(midY)), \(fmt(endX)) \(fmt(midY)), \(fmt(endX)) \(fmt(endY))"

        var html = "<path class=\"md-mermaid-edge\" d=\"\(path)\" />"

        if let label = edge.label, !label.isEmpty {
            let labelX = (startX + endX) / 2.0
            let labelY = midY - 8.0
            html += """
            <g class="md-mermaid-edge-label">
              <rect x="\(fmt(labelX - Double(max(label.count, 4)) * 3.6 - 8.0))" y="\(fmt(labelY - 14.0))" width="\(fmt(Double(max(label.count, 4)) * 7.2 + 16.0))" height="22" rx="11" ry="11"></rect>
              <text x="\(fmt(labelX))" y="\(fmt(labelY))">\(label.escapedHTML())</text>
            </g>
            """
        }

        return html
    }

    private func renderNode(_ positionedNode: MermaidGraphLayout.PositionedNode?) -> String? {
        guard let positionedNode else {
            return nil
        }

        let node = positionedNode.node
        let centerX = positionedNode.x + positionedNode.width / 2.0
        let centerY = positionedNode.y + positionedNode.height / 2.0
        let shapeHTML: String

        switch node.shape {
        case .rectangle:
            shapeHTML = """
            <rect x="\(fmt(positionedNode.x))" y="\(fmt(positionedNode.y))" width="\(fmt(positionedNode.width))" height="\(fmt(positionedNode.height))" rx="14" ry="14"></rect>
            """
        case .rounded:
            shapeHTML = """
            <rect x="\(fmt(positionedNode.x))" y="\(fmt(positionedNode.y))" width="\(fmt(positionedNode.width))" height="\(fmt(positionedNode.height))" rx="28" ry="28"></rect>
            """
        case .diamond:
            let points = [
                "\(fmt(centerX)) \(fmt(positionedNode.y))",
                "\(fmt(positionedNode.x + positionedNode.width)) \(fmt(centerY))",
                "\(fmt(centerX)) \(fmt(positionedNode.y + positionedNode.height))",
                "\(fmt(positionedNode.x)) \(fmt(centerY))"
            ].joined(separator: " ")
            shapeHTML = "<polygon points=\"\(points)\"></polygon>"
        }

        return """
        <g class="md-mermaid-node">
          \(shapeHTML)
          <text x="\(fmt(centerX))" y="\(fmt(centerY + 5.0))">\(node.label.escapedHTML())</text>
        </g>
        """
    }

    private func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
