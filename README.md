# MD Quick Look

[English](./README.md) | [简体中文](./README.zh-CN.md)

A lightweight macOS Markdown viewer and editor.

`MD Quick Look` is a lightweight macOS app for previewing and lightly editing formatted Markdown files without opening a full IDE such as VS Code.

The current product form is a standalone viewer app. It does not rely on taking over Finder's spacebar Quick Look behavior.

## Features

- Open and preview Markdown files quickly
- Edit Markdown directly in the app
- Supports `Edit / Preview / Split` workspace modes
- Supports headings, lists, blockquotes, code blocks, and tables
- Supports a practical subset of Mermaid `graph TD` / `flowchart TD`
- Auto-refreshes when the file is saved
- Supports `Command + S` saving and unsaved-change prompts
- Supports both Chinese and English UI
- Includes theme, font size, content width, and default view settings

## How To Use

- Double-click a `.md` file and open it with `MD Quick Look.app`
- In Finder, right-click and choose `Open With > MD Quick Look`
- Drag a `.md` file into the app window
- Use `Open Markdown...` inside the app
- Switch between `Edit`, `Preview`, and `Split` in the toolbar or Settings
- Save changes with `Command + S`

## Default View

The app opens files in `Preview` mode by default.

You can change the default view inside `Settings > Default View`:

- `Preview`: open directly into formatted preview
- `Edit`: open directly into the Markdown editor
- `Split`: open with editor and preview side by side

## Set As Default App

To make `MD Quick Look` the default app for `.md` files:

1. Select any `.md` file in Finder
2. Press `Command + I` to open `Get Info`
3. Find the `Open with` section
4. Choose `MD Quick Look`
5. Click `Change All...`
6. Confirm

If `MD Quick Look` does not appear in the list yet, open the app once from `Applications` with right-click > `Open`, then return and set it again.

## Installation

The current installer package is:

```text
dist/MD-Quick-Look-1.0.dmg
```

Install steps:

1. Open the `.dmg`
2. Drag `MD Quick Look.app` into `Applications`
3. On first launch, right-click the app and choose `Open`

This package uses ad-hoc signing, so the first launch still requires manual approval.

## Repository And Releases

- The GitHub repository contains source code, project definition, and packaging scripts
- The `.dmg` installer is published in GitHub Releases instead of being committed into the code repository

## Project Structure

- `App/`: app UI, window handling, and file opening logic
- `Shared/`: Markdown rendering, Mermaid rendering, settings model, and localized UI strings
- `scripts/`: packaging and app icon scripts
- `project.yml`: XcodeGen project definition

## Build

Generate the Xcode project first:

```bash
xcodegen generate
```

Then build:

```bash
xcodebuild -project MDQuickLookPreview.xcodeproj -scheme MDQuickLookHost -configuration Debug -destination 'platform=macOS' build
```

## Package

```bash
./scripts/package_dmg.sh
```

Output:

```text
dist/MD-Quick-Look-1.0.dmg
```

## Current Limitations

- Images currently render as placeholders and do not resolve local relative assets
- Lists are currently handled as single-level structures
- Complex nested Markdown syntax is not fully supported
- Mermaid support is currently focused on common flowchart syntax and basic node shapes
- Editing is intentionally lightweight and does not include syntax highlighting or rich text tools
