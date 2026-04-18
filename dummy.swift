import SwiftUI
import AppKit

func registerFonts() {
    let fontNames = ["CascadiaCode-VariableFont_wght.ttf", "CascadiaCode-Italic-VariableFont_wght.ttf"]
    for fontName in fontNames {
        if let fontURL = Bundle.main.url(forResource: fontName, withExtension: nil) {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                print("Error registering font: \(error!.takeRetainedValue())")
            }
        }
    }
}

class TerminalManager: ObservableObject {
    @Published var output: String = ""
    @Published var isRunning: Bool = false
    
    var resourcePath: String {
        return Bundle.main.resourcePath ?? FileManager.default.currentDirectoryPath
    }
    
    func runScript() {
        guard !isRunning else { return }
        isRunning = true
        output = "[*] begin moonleaf transition!\n"
        
        let scriptName = "updater.sh"
        let bundlePath = Bundle.main.path(forResource: "updater", ofType: "sh")
        let path = bundlePath ?? FileManager.default.currentDirectoryPath + "/" + scriptName
        
        output += "[*] Executing: \(path)\n\n"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        let fileHandle = pipe.fileHandleForReading
        fileHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                DispatchQueue.main.async {
                    self.output += str
                }
            }
        }
        
        process.terminationHandler = { proc in
            DispatchQueue.main.async {
                if proc.terminationStatus == 0 {
                    self.output += "\n[V] moonleaf has been successfully installed!\n"
                    self.isRunning = false

                    let alert = NSAlert()
                    alert.messageText = "Install success"
                    alert.informativeText = "Delete installer and open moonleaf?"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "Yes")
                    alert.addButton(withTitle: "Later")
                    
                    if alert.runModal() == .alertFirstButtonReturn {
                        let cleanup = Process()
                        cleanup.executableURL = URL(fileURLWithPath: "/bin/bash")
                        cleanup.arguments = ["-c", "rm -rf /Applications/macpaper.app && open -a /Applications/moonleaf.app"]
                        try? cleanup.run()
                        NSApplication.shared.terminate(nil)
                    }
                } else {
                    self.output += "\n[✘] Transition failed (Exit Code: \(proc.terminationStatus)).\n"
                    self.isRunning = false
                }
            }
        }

        
        do {
            try process.run()
        } catch {
            DispatchQueue.main.async {
                self.output += "[!] Error: \(error.localizedDescription)\n"
                self.isRunning = false
            }
        }
    }
    
    func openResourcesFolder() {
        if let resourcePath = Bundle.main.resourcePath {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: resourcePath)
        }
    }
}

struct ContentView: View {
    @StateObject var terminal = TerminalManager()
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.09)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Image(nsImage: NSImage(named: "moonleaf") ?? NSImage())
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42, height: 42)
                    
                    Text("moonleaf")
                        .font(.custom("Cascadia Code", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Please read below!")
                        .font(.custom("Cascadia Code", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("'macpaper' has been updated to 'moonleaf'.\nDue to my stupidity, there is a hard-coded link in the previous Updater, making it uneffective for this change. This installer will download the latest version of moonleaf from https://github.com/naomisphere/moonleaf\n\nIf you wish to know more, check the README file ")
                                .font(.custom("Cascadia Code", size: 13))
                                .foregroundColor(.white.opacity(0.9))
                                +
                            Text("here")
                                .font(.custom("Cascadia Code", size: 13))
                                .foregroundColor(.blue.opacity(0.8))
                                .underline()
                                +
                            Text(".")
                                .font(.custom("Cascadia Code", size: 13))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .lineSpacing(4)
                        .onTapGesture {
                            terminal.openResourcesFolder()
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Your configuration and wallpapers will save, nothing will be lost.\nClick 'Continue' to execute the ")
                                .font(.custom("Cascadia Code", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                +
                            Text("installation script")
                                .font(.custom("Cascadia Code", size: 12))
                                .foregroundColor(.blue.opacity(0.8))
                                .underline()
                                +
                            Text(" located in the Resources folder.")
                                .font(.custom("Cascadia Code", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .onTapGesture {
                            terminal.openResourcesFolder()
                        }
                        
                        Link("View installer source on GitHub", destination: URL(string: "https://github.com/naomisphere/dummy-moonleaf-installer")!)
                            .font(.custom("Cascadia Code", size: 11))
                            .foregroundColor(.blue.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 8, height: 8)
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 8, height: 8)
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 8, height: 8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.04))
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(terminal.output)
                                .font(.custom("Cascadia Code", size: 11))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .id("bottom")
                        }
                        .frame(height: 140)
                        .background(Color.black.opacity(0.3))
                        .onChange(of: terminal.output) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .padding(24)

                Spacer(minLength: 24)

                Button(action: {
                    terminal.runScript()
                }) {
                    Text(terminal.isRunning ? "Installing..." : "Continue")
                        .font(.custom("Cascadia Code", size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 80)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(terminal.isRunning ? Color.white.opacity(0.03) : Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(terminal.isRunning)
                .padding(.bottom, 32)
            }
        }
        .frame(width: 600, height: 680)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerFonts()
        
        let contentView = ContentView()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.title = "moonleaf installer"
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()