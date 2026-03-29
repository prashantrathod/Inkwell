import Cocoa
import WebKit

// ─── App Delegate ───────────────────────────────────────────────
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Window size
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

        // WebView configuration
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        // Allow file access
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")

        // Load the embedded HTML
        if let htmlPath = Bundle.main.path(forResource: "markdown-editor", ofType: "html") {
            let htmlURL = URL(fileURLWithPath: htmlPath)
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        }

        window.contentView?.addSubview(webView)
        window.makeKeyAndOrderFront(nil)

        // Build menus
        setupMenus()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

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
        fileMenu.addItem(withTitle: "Open...", action: #selector(triggerOpen), keyEquivalent: "o")
        fileMenu.addItem(withTitle: "Save", action: #selector(triggerSave), keyEquivalent: "s")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Export as HTML", action: #selector(triggerExport), keyEquivalent: "e")
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
        alert.informativeText = "A beautiful Markdown editor for macOS.\n\nVersion 1.0"
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc func triggerOpen() {
        webView.evaluateJavaScript("openFile()", completionHandler: nil)
    }

    @objc func triggerSave() {
        webView.evaluateJavaScript("saveFile()", completionHandler: nil)
    }

    @objc func triggerExport() {
        webView.evaluateJavaScript("exportHTML()", completionHandler: nil)
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
