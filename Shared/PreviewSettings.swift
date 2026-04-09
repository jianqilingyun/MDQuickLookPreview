import Foundation

struct PreviewSettings: Codable, Equatable {
    static let fallback = PreviewSettings(
        language: .simplifiedChinese,
        theme: .warm,
        fontSize: .medium,
        contentWidth: .comfortable
    )

    enum AppLanguage: String, CaseIterable, Codable, Identifiable {
        case simplifiedChinese
        case english

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .simplifiedChinese: return "中文"
            case .english: return "English"
            }
        }

        var htmlCode: String {
            switch self {
            case .simplifiedChinese: return "zh-CN"
            case .english: return "en"
            }
        }
    }

    enum ThemePreset: String, CaseIterable, Codable, Identifiable {
        case warm
        case paper
        case slate

        var id: String { rawValue }

        func displayName(in language: AppLanguage) -> String {
            switch (self, language) {
            case (.warm, .simplifiedChinese): return "暖色"
            case (.paper, .simplifiedChinese): return "纸白"
            case (.slate, .simplifiedChinese): return "石板"
            case (.warm, .english): return "Warm"
            case (.paper, .english): return "Paper"
            case (.slate, .english): return "Slate"
            }
        }

        var cssVariables: [String: String] {
            switch self {
            case .warm:
                return [
                    "page-bg-light": "#f5f1e8",
                    "card-bg-light": "rgba(255, 252, 246, 0.88)",
                    "text-light": "#211f1c",
                    "muted-light": "#6b645c",
                    "border-light": "rgba(60, 47, 35, 0.16)",
                    "accent-light": "#a14f2a",
                    "code-bg-light": "rgba(94, 66, 39, 0.08)",
                    "quote-bg-light": "rgba(161, 79, 42, 0.07)",
                    "graph-node-light": "#fff6e7",
                    "graph-edge-light": "#9e5937",
                    "page-bg-dark": "#121111",
                    "card-bg-dark": "rgba(26, 24, 23, 0.92)",
                    "text-dark": "#ede6dc",
                    "muted-dark": "#b1a99f",
                    "border-dark": "rgba(238, 227, 213, 0.12)",
                    "accent-dark": "#ff9f6e",
                    "code-bg-dark": "rgba(255, 255, 255, 0.08)",
                    "quote-bg-dark": "rgba(255, 159, 110, 0.12)",
                    "graph-node-dark": "#2f2621",
                    "graph-edge-dark": "#ff9f6e"
                ]
            case .paper:
                return [
                    "page-bg-light": "#f7f7f4",
                    "card-bg-light": "rgba(255, 255, 255, 0.94)",
                    "text-light": "#22262b",
                    "muted-light": "#66707d",
                    "border-light": "rgba(38, 44, 52, 0.12)",
                    "accent-light": "#1f6feb",
                    "code-bg-light": "rgba(31, 111, 235, 0.08)",
                    "quote-bg-light": "rgba(31, 111, 235, 0.07)",
                    "graph-node-light": "#f8fbff",
                    "graph-edge-light": "#1f6feb",
                    "page-bg-dark": "#0d1117",
                    "card-bg-dark": "rgba(22, 27, 34, 0.94)",
                    "text-dark": "#e6edf3",
                    "muted-dark": "#9da7b3",
                    "border-dark": "rgba(230, 237, 243, 0.12)",
                    "accent-dark": "#58a6ff",
                    "code-bg-dark": "rgba(88, 166, 255, 0.12)",
                    "quote-bg-dark": "rgba(88, 166, 255, 0.12)",
                    "graph-node-dark": "#132033",
                    "graph-edge-dark": "#58a6ff"
                ]
            case .slate:
                return [
                    "page-bg-light": "#edf1f3",
                    "card-bg-light": "rgba(255, 255, 255, 0.88)",
                    "text-light": "#16202a",
                    "muted-light": "#617180",
                    "border-light": "rgba(22, 32, 42, 0.14)",
                    "accent-light": "#0c7c78",
                    "code-bg-light": "rgba(12, 124, 120, 0.08)",
                    "quote-bg-light": "rgba(12, 124, 120, 0.08)",
                    "graph-node-light": "#eefaf8",
                    "graph-edge-light": "#0c7c78",
                    "page-bg-dark": "#0f171b",
                    "card-bg-dark": "rgba(17, 24, 29, 0.94)",
                    "text-dark": "#e5eff3",
                    "muted-dark": "#9ab0bb",
                    "border-dark": "rgba(229, 239, 243, 0.12)",
                    "accent-dark": "#49c5bf",
                    "code-bg-dark": "rgba(73, 197, 191, 0.12)",
                    "quote-bg-dark": "rgba(73, 197, 191, 0.12)",
                    "graph-node-dark": "#153035",
                    "graph-edge-dark": "#49c5bf"
                ]
            }
        }
    }

    enum FontSize: String, CaseIterable, Codable, Identifiable {
        case small
        case medium
        case large

        var id: String { rawValue }

        func displayName(in language: AppLanguage) -> String {
            switch (self, language) {
            case (.small, .simplifiedChinese): return "小"
            case (.medium, .simplifiedChinese): return "中"
            case (.large, .simplifiedChinese): return "大"
            case (.small, .english): return "Small"
            case (.medium, .english): return "Medium"
            case (.large, .english): return "Large"
            }
        }

        var points: Int {
            switch self {
            case .small: return 15
            case .medium: return 16
            case .large: return 18
            }
        }
    }

    enum ContentWidth: String, CaseIterable, Codable, Identifiable {
        case compact
        case comfortable
        case wide

        var id: String { rawValue }

        func displayName(in language: AppLanguage) -> String {
            switch (self, language) {
            case (.compact, .simplifiedChinese): return "紧凑"
            case (.comfortable, .simplifiedChinese): return "适中"
            case (.wide, .simplifiedChinese): return "宽"
            case (.compact, .english): return "Compact"
            case (.comfortable, .english): return "Comfortable"
            case (.wide, .english): return "Wide"
            }
        }

        var cssWidth: Int {
            switch self {
            case .compact: return 560
            case .comfortable: return 720
            case .wide: return 920
            }
        }
    }

    var language: AppLanguage
    var theme: ThemePreset
    var fontSize: FontSize
    var contentWidth: ContentWidth

    private enum CodingKeys: String, CodingKey {
        case language
        case theme
        case fontSize
        case contentWidth
    }

    init(language: AppLanguage, theme: ThemePreset, fontSize: FontSize, contentWidth: ContentWidth) {
        self.language = language
        self.theme = theme
        self.fontSize = fontSize
        self.contentWidth = contentWidth
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .simplifiedChinese
        theme = try container.decodeIfPresent(ThemePreset.self, forKey: .theme) ?? .warm
        fontSize = try container.decodeIfPresent(FontSize.self, forKey: .fontSize) ?? .medium
        contentWidth = try container.decodeIfPresent(ContentWidth.self, forKey: .contentWidth) ?? .comfortable
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(language, forKey: .language)
        try container.encode(theme, forKey: .theme)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(contentWidth, forKey: .contentWidth)
    }

    static func load() -> PreviewSettings {
        guard let data = try? Data(contentsOf: settingsURL()),
              let settings = try? JSONDecoder().decode(PreviewSettings.self, from: data) else {
            return fallback
        }

        return settings
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else {
            return
        }

        let url = Self.settingsURL()
        let directory = url.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch {
            return
        }
    }

    static func settingsURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/MDQuickLookPreview", isDirectory: true)
            .appendingPathComponent("preview-settings.json")
    }
}
