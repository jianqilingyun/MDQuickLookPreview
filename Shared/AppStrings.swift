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

    var workspaceModeLabel: String {
        switch language {
        case .simplifiedChinese: return "默认视图"
        case .english: return "Default View"
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

    var save: String {
        switch language {
        case .simplifiedChinese: return "保存"
        case .english: return "Save"
        }
    }

    var saveMarkdown: String {
        switch language {
        case .simplifiedChinese: return "保存 Markdown"
        case .english: return "Save Markdown"
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

    var editorTitle: String {
        switch language {
        case .simplifiedChinese: return "编辑"
        case .english: return "Editor"
        }
    }

    var previewTitle: String {
        switch language {
        case .simplifiedChinese: return "预览"
        case .english: return "Preview"
        }
    }

    var documentLabel: String {
        switch language {
        case .simplifiedChinese: return "当前文档"
        case .english: return "Current File"
        }
    }

    var unsavedChangesBadge: String {
        switch language {
        case .simplifiedChinese: return "未保存"
        case .english: return "Unsaved"
        }
    }

    var unsavedChangesTitle: String {
        switch language {
        case .simplifiedChinese: return "有未保存的修改"
        case .english: return "You Have Unsaved Changes"
        }
    }

    func unsavedChangesMessage(fileName: String) -> String {
        switch language {
        case .simplifiedChinese:
            return "“\(fileName)” 还有未保存的修改。继续之前要先保存吗？"
        case .english:
            return "“\(fileName)” has unsaved changes. Do you want to save before continuing?"
        }
    }

    var discardChanges: String {
        switch language {
        case .simplifiedChinese: return "不保存"
        case .english: return "Discard"
        }
    }

    var cancel: String {
        switch language {
        case .simplifiedChinese: return "取消"
        case .english: return "Cancel"
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
