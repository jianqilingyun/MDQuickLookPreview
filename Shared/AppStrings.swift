import Foundation

struct AppStrings {
    let language: PreviewSettings.AppLanguage

    var settingsTitle: String {
        switch language {
        case .simplifiedChinese: return "设置"
        case .english: return "Settings"
        }
    }

    var languageLabel: String {
        switch language {
        case .simplifiedChinese: return "语言"
        case .english: return "Language"
        }
    }

    var themeLabel: String {
        switch language {
        case .simplifiedChinese: return "主题"
        case .english: return "Theme"
        }
    }

    var fontSizeLabel: String {
        switch language {
        case .simplifiedChinese: return "字号"
        case .english: return "Text Size"
        }
    }

    var contentWidthLabel: String {
        switch language {
        case .simplifiedChinese: return "版心宽度"
        case .english: return "Content Width"
        }
    }

    var openMarkdown: String {
        switch language {
        case .simplifiedChinese: return "打开 Markdown"
        case .english: return "Open Markdown"
        }
    }

    var openMarkdownEllipsis: String {
        switch language {
        case .simplifiedChinese: return "打开 Markdown..."
        case .english: return "Open Markdown..."
        }
    }

    var reload: String {
        switch language {
        case .simplifiedChinese: return "刷新"
        case .english: return "Reload"
        }
    }

    var reloadPreview: String {
        switch language {
        case .simplifiedChinese: return "刷新预览"
        case .english: return "Reload Preview"
        }
    }

    var previewMenu: String {
        switch language {
        case .simplifiedChinese: return "预览"
        case .english: return "Preview"
        }
    }

    var openTitle: String {
        switch language {
        case .simplifiedChinese: return "打开一个 Markdown 文件"
        case .english: return "Open a Markdown file"
        }
    }

    var emptyDescription: String {
        switch language {
        case .simplifiedChinese:
            return "把 `.md` 拖进来，或者点上面的“打开 Markdown”。如果你常用它，可以在 Finder 里把本 App 设为 Markdown 的默认打开方式。"
        case .english:
            return "Drop a `.md` file here or use “Open Markdown” above. If you use it often, set this app as the default Markdown viewer in Finder."
        }
    }

    var dropMarkdownHere: String {
        switch language {
        case .simplifiedChinese: return "拖放 Markdown 到这里"
        case .english: return "Drop Markdown Here"
        }
    }

    var localFilesOnlyError: String {
        switch language {
        case .simplifiedChinese: return "仅支持本地 Markdown 文件。"
        case .english: return "Only local Markdown files are supported."
        }
    }

    var openPanelTitle: String {
        switch language {
        case .simplifiedChinese: return "打开 Markdown 文件"
        case .english: return "Open Markdown File"
        }
    }

    func truncatedPreviewMessage(characterCount: Int) -> String {
        switch language {
        case .simplifiedChinese:
            return "为保证预览速度，已在 \(characterCount) 个字符后截断。"
        case .english:
            return "Preview truncated after \(characterCount) characters to keep rendering fast."
        }
    }
}
