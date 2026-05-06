import SwiftUI
import AppKit
import WebKit

@main
struct MDViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(filePath: appDelegate.filePath)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var filePath: String? = nil
    private var additionalWindows: [NSWindow] = []

    func application(_ application: NSApplication, open urls: [URL]) {
        for (index, url) in urls.enumerated() {
            let path = url.path
            if index == 0 {
                filePath = path
                NotificationCenter.default.post(name: .openFile, object: path)
            } else {
                openNewWindow(for: path)
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = Array(CommandLine.arguments.dropFirst())
        var isFirst = true

        for arg in args {
            if FileManager.default.fileExists(atPath: arg) {
                if isFirst {
                    filePath = arg
                    NotificationCenter.default.post(name: .openFile, object: arg)
                    isFirst = false
                } else {
                    openNewWindow(for: arg)
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func openNewWindow(for path: String) {
        let contentView = ContentView(filePath: path)
        let hostingView = NSHostingView(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.title = (path as NSString).lastPathComponent
        window.center()

        // Offset from last additional window so they don't stack exactly
        if let lastWindow = additionalWindows.last {
            var frame = window.frame
            frame.origin.x = lastWindow.frame.origin.x + 20
            frame.origin.y = lastWindow.frame.origin.y - 20
            window.setFrame(frame, display: false)
        }

        window.makeKeyAndOrderFront(nil)
        additionalWindows.append(window)
    }
}

extension Notification.Name {
    static let openFile = Notification.Name("openFile")
}

// WebView wrapper for rendering markdown
struct MarkdownWebView: NSViewRepresentable {
    let markdown: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let escapedMarkdown = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
            <style>
                :root {
                    color-scheme: light dark;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    padding: 20px;
                    max-width: 100%;
                    margin: 0;
                    background: transparent;
                }
                @media (prefers-color-scheme: dark) {
                    body { color: #c9d1d9; }
                    a { color: #58a6ff; }
                    code { background: #343942; }
                    pre { background: #282c34; }
                    blockquote { border-color: #3b434b; color: #8b949e; }
                    table th, table td { border-color: #30363d; }
                    hr { background: #30363d; }
                    h1, h2 { border-color: #21262d; }
                }
                @media (prefers-color-scheme: light) {
                    body { color: #24292f; }
                    a { color: #0969da; }
                    code { background: #f6f8fa; }
                    pre { background: #f6f8fa; }
                    blockquote { border-color: #d0d7de; color: #57606a; }
                    table th, table td { border-color: #d0d7de; }
                    hr { background: #d8dee4; }
                    h1, h2 { border-color: #d8dee4; }
                }
                h1, h2, h3, h4, h5, h6 {
                    font-weight: 600;
                    margin-top: 24px;
                    margin-bottom: 16px;
                }
                h1 { font-size: 2em; padding-bottom: 0.3em; border-bottom: 1px solid; }
                h2 { font-size: 1.5em; padding-bottom: 0.3em; border-bottom: 1px solid; }
                h3 { font-size: 1.25em; }
                h4 { font-size: 1em; }
                h5 { font-size: 0.875em; }
                h6 { font-size: 0.85em; }
                code {
                    font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace;
                    font-size: 85%;
                    padding: 0.2em 0.4em;
                    border-radius: 6px;
                }
                pre {
                    padding: 16px;
                    overflow: auto;
                    border-radius: 6px;
                    line-height: 1.45;
                }
                pre code {
                    padding: 0;
                    background: transparent;
                    font-size: 100%;
                }
                blockquote {
                    margin: 0;
                    padding: 0 1em;
                    border-left: 0.25em solid;
                }
                ul, ol {
                    padding-left: 2em;
                    margin-top: 0;
                    margin-bottom: 16px;
                }
                li + li {
                    margin-top: 0.25em;
                }
                table {
                    border-collapse: collapse;
                    width: 100%;
                    margin-bottom: 16px;
                }
                table th, table td {
                    padding: 6px 13px;
                    border: 1px solid;
                }
                table th {
                    font-weight: 600;
                }
                hr {
                    height: 0.25em;
                    padding: 0;
                    margin: 24px 0;
                    border: 0;
                }
                img {
                    max-width: 100%;
                    height: auto;
                }
                p {
                    margin-top: 0;
                    margin-bottom: 16px;
                }
            </style>
        </head>
        <body>
            <div id="content"></div>
            <script>
                document.getElementById('content').innerHTML = marked.parse(`\(escapedMarkdown)`);
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
    }
}

struct ContentView: View {
    @State private var rawContent: String = ""
    @State private var fileName: String = "MD Viewer"
    @State private var currentPath: String? = nil

    init(filePath: String?) {
        if let path = filePath {
            _currentPath = State(initialValue: path)
        }
    }

    var body: some View {
        Group {
            if currentPath != nil {
                HSplitView {
                    // Left pane: Raw markdown
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Source")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 10)
                        Divider()
                        ScrollView {
                            Text(rawContent)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(15)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(minWidth: 300)
                    .background(Color(nsColor: .textBackgroundColor))

                    // Right pane: Rendered markdown with WebView
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 10)
                        Divider()
                        MarkdownWebView(markdown: rawContent)
                    }
                    .frame(minWidth: 300)
                    .background(Color(nsColor: .textBackgroundColor))
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Drop a .md file here\nor right-click a file and\nchoose \"Open With\"")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .textBackgroundColor))
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    if let provider = providers.first {
                        _ = provider.loadObject(ofClass: URL.self) { url, _ in
                            if let url = url, url.pathExtension.lowercased() == "md" || url.pathExtension.lowercased() == "markdown" {
                                DispatchQueue.main.async {
                                    loadFile(path: url.path)
                                }
                            }
                        }
                    }
                    return true
                }
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .navigationTitle(fileName)
        .onAppear {
            if let path = currentPath {
                loadFile(path: path)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFile)) { notification in
            if let path = notification.object as? String {
                loadFile(path: path)
            }
        }
    }

    private func loadFile(path: String) {
        currentPath = path
        fileName = (path as NSString).lastPathComponent

        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            rawContent = content
        } catch {
            rawContent = "Error loading file: \(error.localizedDescription)"
        }
    }
}
