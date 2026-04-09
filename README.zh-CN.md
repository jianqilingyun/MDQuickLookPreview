# MD Quick Look

[English](./README.md) | [简体中文](./README.zh-CN.md)

一个轻量的 macOS Markdown 预览应用。

`MD Quick Look` 的目标很简单：快速查看排版后的 `.md` 文件，不用打开 VS Code 这类大型 IDE。

当前产品形态是独立预览器 App，不再依赖 Finder 的空格 Quick Look 接管。

## 功能

- 快速打开并预览 Markdown 文件
- 支持标题、列表、引用、代码块、表格
- 支持 Mermaid `graph TD` / `flowchart TD` 常用子集
- 文件保存后自动刷新
- 支持中英文界面切换
- 支持主题、字号、版心宽度设置

## 使用方式

- 双击 `.md` 文件后用 `MD Quick Look.app` 打开
- 在 Finder 中右键，选择“打开方式 > MD Quick Look”
- 把 `.md` 文件拖进应用窗口
- 在应用里用 `Open Markdown...` 打开文件

## 设为默认应用

如果你希望以后双击 `.md` 都默认用它打开：

1. 在 Finder 中选中任意一个 `.md` 文件
2. 按 `Command + I` 打开“显示简介”
3. 找到“打开方式”
4. 选择 `MD Quick Look`
5. 点击“全部更改...”
6. 确认

如果下拉列表里暂时没看到 `MD Quick Look`，先到 `Applications` 中右键打开一次 App，再回来设置。

## 安装

当前可直接使用的安装包位于：

```text
dist/MD-Quick-Look-1.0.dmg
```

安装步骤：

1. 打开 `.dmg`
2. 把 `MD Quick Look.app` 拖到 `Applications`
3. 第一次启动时，右键应用并选择“打开”

这是 ad-hoc 签名包，所以第一次仍然需要手动放行。

## 仓库与 Release

- GitHub 仓库保存源码、工程定义和打包脚本
- `.dmg` 安装包发布在 GitHub Releases，而不是直接提交到代码仓库

## 项目结构

- `App/`：主应用界面、窗口和文件打开逻辑
- `Shared/`：Markdown 渲染、Mermaid 渲染、设置模型、界面文案
- `scripts/`：打包脚本和图标生成脚本
- `project.yml`：XcodeGen 工程定义

## 构建

先生成工程：

```bash
xcodegen generate
```

再构建：

```bash
xcodebuild -project MDQuickLookPreview.xcodeproj -scheme MDQuickLookHost -configuration Debug -destination 'platform=macOS' build
```

## 打包

```bash
./scripts/package_dmg.sh
```

输出文件：

```text
dist/MD-Quick-Look-1.0.dmg
```

## 当前限制

- 图片目前只显示占位文本，不解析本地相对路径资源
- 列表只处理单层结构
- 复杂嵌套 Markdown 语法没有做完整兼容
- Mermaid 目前只覆盖常见流程图写法和基础节点形状
