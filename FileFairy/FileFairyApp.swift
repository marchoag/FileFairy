//
//  FileFairyApp.swift
//  FileFairy
//
//  Created by Marc Hoag on 9/11/24.
//

import SwiftUI
import Foundation

@main
struct FileFairyApp: App {
    @State private var showSplash = true
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .frame(minWidth: 600, minHeight: 700)
                    .opacity(showSplash ? 0 : 1)
                
                if showSplash {
                    SplashScreenView()
                        .frame(width: 400, height: 500)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .frame(minWidth: showSplash ? 400 : 600, minHeight: showSplash ? 500 : 700)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Select Folder") {
                    NotificationCenter.default.post(name: Notification.Name("SelectFolder"), object: nil)
                }
                .keyboardShortcut("O", modifiers: .command)
            }
            CommandGroup(replacing: .appInfo) {
                Button("About FileFairy") {
                    NSApp.orderFrontStandardAboutPanel(options: [
                        NSApplication.AboutPanelOptionKey.applicationIcon: NSImage(contentsOfFile: Bundle.main.path(forResource: "FileFairyIcons", ofType: "icns") ?? "") ?? NSImage(),
                        NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                            string: "FileFairy helps you rename folders exported from Apple Photos, placing dates first for easy chronological sorting.",
                            attributes: [
                                .foregroundColor: NSColor.textColor,
                                .font: NSFont.systemFont(ofSize: 11)
                            ]
                        ),
                        NSApplication.AboutPanelOptionKey.version: "",
                        NSApplication.AboutPanelOptionKey.applicationName: "FileFairy",
                    ])
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.center()
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
