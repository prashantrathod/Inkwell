import Cocoa
import WebKit

// ─── App Delegate ───────────────────────────────────────────────
class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let width: CGFloat = min(1400, screenFrame.width * 0.85)
        let height: CGFloat = min(900, screenFrame.height * 0.85)
        let x = screenFrame.origin.x + (screenFrame.width - width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - height) / 2

        window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Inkwell"
        window.minSize = NSSize(width: 700, height: 500)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(red: 0.11, green: 0.098, blue: 0.09, alpha: 1.0)
        window.isReleasedWhenClosed = false

        // WebView configuration with message handlers for native file dialogs
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let contentController = config.userContentController
        contentController.add(self, name: "nativeOpen")
        contentController.add(self, name: "nativeSave")
        contentController.add(self, name: "nativeExport")

        webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")

        if let htmlPath = Bundle.main.path(forResource: "markdown-editor", ofType: "html") {
            let htmlURL = URL(fileURLWithPath: htmlPath)
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        }

        window.contentView?.addSubview(webView)
        window.makeKeyAndOrderFront(nil)
        setupMenus()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // ─── Native File Dialog Bridge ──────────────────────────────
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "nativeOpen":
            nativeOpenFile()
        case "nativeSave":
            if let body = message.body as? [String: String],
               let content = body["content"],
               let fileName = body["fileName"] {
                nativeSaveFile(content: content, fileName: fileName)
            }
        case "nativeExport":
            if let body = message.body as? [String: String],
               let content = body["content"],
               let fileName = body["fileName"] {
                nativeExportHTML(content: content, fileName: fileName)
            }
        default:
            break
        }
    }

    func nativeOpenFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .init(filenameExtension: "md")!,
            .init(filenameExtension: "markdown")!,
            .init(filenameExtension: "txt")!,
            .plainText
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a Markdown file to open"

        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let fileName = url.lastPathComponent
                let filePath = url.path
                let escapedContent = content
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "`", with: "\\`")
                    .replacingOccurrences(of: "$", with: "\\$")
                let js = "nativeDidOpenFile(`\(escapedContent)`, `\(fileName)`, `\(filePath)`);"
                self?.webView.evaluateJavaScript(js, completionHandler: nil)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Could not open file"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }

    func nativeSaveFile(content: String, fileName: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = fileName
        panel.allowedContentTypes = [
            .init(filenameExtension: "md")!,
            .plainText
        ]
        panel.message = "Choose where to save your Markdown file"

        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                let savedName = url.lastPathComponent
                let savedPath = url.path
                let js = "nativeDidSaveFile(`\(savedName)`, `\(savedPath)`);"
                self?.webView.evaluateJavaScript(js, completionHandler: nil)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Could not save file"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }

    func nativeExportHTML(content: String, fileName: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = fileName.replacingOccurrences(of: ".md", with: "") + ".html"
        panel.allowedContentTypes = [.html]
        panel.message = "Choose where to export the HTML file"

        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Could not export file"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }

    // ─── Menus ──────────────────────────────────────────────────
    func setupMenus() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Inkwell", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Inkwell", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "New Tab", action: #selector(triggerNewTab), keyEquivalent: "t")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Open...", action: #selector(triggerOpen), keyEquivalent: "o")
        fileMenu.addItem(withTitle: "Save...", action: #selector(triggerSave), keyEquivalent: "s")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Export as HTML...", action: #selector(triggerExport), keyEquivalent: "e")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Edit menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // View menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        let splitItem = viewMenu.addItem(withTitle: "Split View", action: #selector(viewSplit), keyEquivalent: "1")
        splitItem.keyEquivalentModifierMask = [.command]
        let editorItem = viewMenu.addItem(withTitle: "Editor Only", action: #selector(viewEditor), keyEquivalent: "2")
        editorItem.keyEquivalentModifierMask = [.command]
        let previewItem = viewMenu.addItem(withTitle: "Preview Only", action: #selector(viewPreview), keyEquivalent: "3")
        previewItem.keyEquivalentModifierMask = [.command]
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Toggle Dark Preview", action: #selector(triggerDarkMode), keyEquivalent: "d")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Inkwell"
        alert.informativeText = "A beautiful Markdown editor for macOS.\n\nVersion 1.1"
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc func triggerNewTab() {
        webView.evaluateJavaScript("addTab()", completionHandler: nil)
    }

    @objc func triggerOpen() {
        nativeOpenFile()
    }

    @objc func triggerSave() {
        webView.evaluateJavaScript("triggerNativeSave()", completionHandler: nil)
    }

    @objc func triggerExport() {
        webView.evaluateJavaScript("triggerNativeExport()", completionHandler: nil)
    }

    @objc func triggerDarkMode() {
        webView.evaluateJavaScript("togglePreviewDarkMode()", completionHandler: nil)
    }

    @objc func viewSplit() {
        webView.evaluateJavaScript("setView('split')", completionHandler: nil)
    }

    @objc func viewEditor() {
        webView.evaluateJavaScript("setView('editor-only')", completionHandler: nil)
    }

    @objc func viewPreview() {
        webView.evaluateJavaScript("setView('preview-only')", completionHandler: nil)
    }
}

// ─── Launch ─────────────────────────────────────────────────────
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
