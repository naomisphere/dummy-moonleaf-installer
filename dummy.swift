import SwiftUI
import AppKit

func registerFonts() {
    let fontNames = ["Comfortaa-Regular.ttf", "Comfortaa-Bold.ttf", "Comfortaa-Light.ttf"]
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
}

struct ContentView: View {
    @StateObject var terminal = TerminalManager()
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.09)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 8, height: 8)
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 8, height: 8)
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 8, height: 8)
                        }
                        Spacer()
                        Text("")
                            .font(.custom("Comfortaa-Bold", size: 10))
                            .foregroundColor(.white.opacity(0.3))
                            .tracking(2)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.04))
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(terminal.output)
                                .font(.system(.footnote, design: .monospaced)) 
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .id("bottom")
                        }
                        .frame(height: 160)
                        .background(Color.black.opacity(0.3))
                        .onChange(of: terminal.output) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .padding(24)

                Spacer()
                
                VStack(spacing: 28) {
                    Image(nsImage: NSImage(named: "moonleaf") ?? NSImage())
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .shadow(color: .green.opacity(0.1), radius: 30, x: 0, y: 0)
                    
                    VStack(spacing: 12) {
                        Text("Please read below!")
                            .font(.custom("Comfortaa-Bold", size: 30))
                            .foregroundColor(.white)
                        
                        Rectangle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 40, height: 3)
                            .cornerRadius(1.5)
                    }
                    
                    VStack(spacing: 18) {
                        Text("macpaper has been revamped into 'moonleaf'.\n\nThe old updater had the 'macpaper' link hard-coded into it, making the previous updater ineffective.\nThis installer will download the new files. Apologies, this won't be an issue ever again.")
                            .font(.custom("Comfortaa-Regular", size: 16))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Clicking 'Continue' will execute the updater script located in:\n\(terminal.resourcePath)/updater.sh")
                            .font(.custom("Comfortaa-Light", size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 50)
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("installer progress is visible in the console above.\nThe source for this dummy installer is available on GitHub.\nhttps://github.com/naomisphere/dummy-moonleaf-installer")
                            .font(.custom("Comfortaa-Bold", size: 13))
                            .foregroundColor(.green.opacity(0.7))
                            .padding(.top, 4)
                    }
                }
                
                Spacer()

                Button(action: {
                    terminal.runScript()
                }) {
                    Text(terminal.isRunning ? "Installing..." : "Continue")
                        .font(.custom("Comfortaa-Bold", size: 15))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 80)
                        .background(
                            ZStack {
                                if terminal.isRunning {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.08))
                                } else {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
                                }
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            }
                        )
                        .shadow(color: Color.green.opacity(terminal.isRunning ? 0 : 0.15), radius: 20, x: 0, y: 8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(terminal.isRunning)
                .padding(.bottom, 60)
            }
        }
        .frame(width: 600, height: 820)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerFonts()
        
        let contentView = ContentView()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 820),
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

