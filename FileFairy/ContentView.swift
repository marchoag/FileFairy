//
//  ContentView.swift
//  FileFairy
//
//  Created by Marc Hoag on 9/11/24.
//

import SwiftUI

struct ContentView: View {
    @State private var directoryURL: URL?
    @State private var previewText: String = ""
    @State private var isProcessing: Bool = false
    @State private var showConfirmation: Bool = false
    @State private var showUndoConfirmation: Bool = false
    @State private var renamedFolders: String = ""
    @State private var isHoveringDirectory: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @State private var hasRenamed: Bool = false
    @State private var renameResult: String = ""
    @State private var isUndoComplete: Bool = false
    @State private var progress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(NSColor.windowBackgroundColor)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 15) {
                    headerView
                    
                    if directoryURL == nil {
                        selectDirectoryButton
                    } else {
                        selectedDirectoryView
                        previewView
                        actionButtons
                    }
                    
                    Spacer()
                    
                    footerView
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 600, minHeight: 700)
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("Does this look good?"),
                message: Text("Do you want to proceed with renaming the folders?"),
                primaryButton: .default(Text("Yes")) {
                    renameFolders()
                },
                secondaryButton: .cancel(Text("No"))
            )
        }
        .alert(isPresented: $showUndoConfirmation) {
            Alert(
                title: Text("Keep Changes?"),
                message: Text("Do you want to keep these changes?"),
                primaryButton: .default(Text("Yes")) {
                    // Do nothing, changes are already applied
                },
                secondaryButton: .destructive(Text("No")) {
                    undoRenames()
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SelectFolder"))) { _ in
            selectDirectory()
        }
    }
    
    var headerView: some View {
        VStack(spacing: 10) {
            Text("FileFairy*")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Easily organize your exported folders from Apple Photos")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    var selectDirectoryButton: some View {
        HoverableButton(action: selectDirectory) {
            VStack(spacing: 15) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 50))
                Text("Select Directory")
                    .font(.system(size: 20, weight: .medium))
            }
            .frame(maxWidth: .infinity, maxHeight: 200)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
        } onHover: { _ in }
    }
    
    var selectedDirectoryView: some View {
        Button(action: selectDirectory) {
            HStack {
                Image(systemName: "folder")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                Text(directoryURL?.path ?? "")
                    .font(.system(size: 16))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isHoveringDirectory ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHoveringDirectory = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    var previewView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if previewText.isEmpty {
                emptyPreviewPlaceholder
            } else {
                ScrollView(.vertical) {
                    Text(AttributedString(colorCodedPreview()))
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                }
                .frame(height: 250)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    var emptyPreviewPlaceholder: some View {
        VStack {
            Image(systemName: "text.alignleft")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Preview will appear here")
                .font(.system(size: 20))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var actionButtons: some View {
        VStack(spacing: 12) {
            if previewText.isEmpty {
                CustomButton(title: "Preview Changes", systemImage: "eye", action: processFiles, color: .blue)
                    .disabled(directoryURL == nil || isProcessing)
            } else if !hasRenamed && !isUndoComplete {
                Text("Does this look good?")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 2)
                
                HStack(spacing: 20) {
                    CustomButton(title: "Punch it!", systemImage: "checkmark.circle", action: renameFolders, color: .green)
                    CustomButton(title: "Nope", systemImage: "xmark.circle", action: { previewText = ""; hasRenamed = false }, color: .red)
                }
                
                Text("Don't worry, you'll have a chance to undo all changes if you don't like the results.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 2)
            } else if hasRenamed {
                Text("Renaming completed!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.bottom, 2)
                
                CustomButton(title: "Undo Changes", systemImage: "arrow.uturn.backward", action: undoRenames, color: .orange)
                CustomButton(title: "Start Over", systemImage: "arrow.counterclockwise", action: resetState, color: .blue)
            } else if isUndoComplete {
                Text("Changes undone!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.orange)
                    .padding(.bottom, 2)
                
                CustomButton(title: "Start Over", systemImage: "arrow.counterclockwise", action: resetState, color: .blue)
            }
            
            if isProcessing {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 16)
            }
        }
    }
    
    var footerView: some View {
        VStack(spacing: 3) {
            Text("FileFairy helps you rename folders exported from Apple Photos,")
                .font(.system(size: 13))
            Text("placing dates first for easy chronological sorting.")
                .font(.system(size: 13))
            Text("Example: \"2023-09-15 - Summer Vacation\"")
                .font(.system(size: 13, weight: .medium))
                .padding(.top, 3)
        }
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    
    func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK {
            if let url = panel.url {
                // Request permission to access the directory
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                // Create a security-scoped bookmark
                if let bookmarkData = try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil) {
                    UserDefaults.standard.set(bookmarkData, forKey: "SelectedDirectoryBookmark")
                }
                
                directoryURL = url
                previewText = "" // Clear preview when changing directory
            }
        }
    }
    
    func processFiles() {
        guard let url = directoryURL else { return }
        isProcessing = true
        DispatchQueue.global(qos: .userInitiated).async {
            let (preview, _) = FileFairyLogic.processDirectory(url)
            DispatchQueue.main.async {
                previewText = preview
                isProcessing = false
                
                // Check if there was an error accessing the directory
                if preview.starts(with: "Failed to access directory") {
                    showErrorAlert(message: preview)
                } else if preview == "Total folders scanned: 0\nTotal folders to rename: 0\n\n" {
                    showErrorAlert(message: "No folders found in the selected directory. Please check the folder contents and try again.")
                }
            }
        }
    }
    
    func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func renameFolders() {
        guard let url = directoryURL else { return }
        isProcessing = true
        progress = 0
        DispatchQueue.global(qos: .userInitiated).async {
            let result = FileFairyLogic.renameFolders(url, preview: previewText) { progressValue in
                DispatchQueue.main.async {
                    self.progress = progressValue
                }
            }
            DispatchQueue.main.async {
                renameResult = result
                previewText = result
                isProcessing = false
                hasRenamed = true
            }
        }
    }
    
    func undoRenames() {
        isProcessing = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = FileFairyLogic.undoRenames()
            DispatchQueue.main.async {
                previewText = result
                isProcessing = false
                hasRenamed = false
                isUndoComplete = true
            }
        }
    }
    
    func resetState() {
        directoryURL = nil
        previewText = ""
        hasRenamed = false
        renameResult = ""
        isUndoComplete = false
        progress = 0
    }
    
    func colorCodedPreview() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: previewText)
        let lines = previewText.components(separatedBy: .newlines)
        
        var currentIndex = 0
        for line in lines {
            let range = NSRange(location: currentIndex, length: line.count)
            if line.contains("Will rename:") || line.contains("Renamed:") {
                attributedString.addAttribute(.foregroundColor, value: NSColor.systemGreen, range: range)
            } else if line.contains("Will skip:") || line.contains("Error:") {
                attributedString.addAttribute(.foregroundColor, value: NSColor.systemRed, range: range)
            } else if line.contains("Undone:") {
                attributedString.addAttribute(.foregroundColor, value: NSColor.systemOrange, range: range)
            }
            currentIndex += line.count + 1 // +1 for the newline character
        }
        
        return attributedString
    }
}

struct CustomButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    let color: Color
    
    @State private var isHovering = false
    
    var body: some View {
        HoverableButton(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 18, weight: .medium))
            .padding()
            .frame(minWidth: 150)
            .background(isHovering ? color.opacity(0.8) : color)
            .foregroundColor(.white)
            .cornerRadius(10)
        } onHover: { hovering in
            isHovering = hovering
        }
    }
}

struct HoverableButton<Content: View>: View {
    let action: () -> Void
    let content: () -> Content
    let onHover: (Bool) -> Void
    
    init(action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content, onHover: @escaping (Bool) -> Void) {
        self.action = action
        self.content = content
        self.onHover = onHover
    }
    
    var body: some View {
        Button(action: action) {
            content()
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
            onHover(hovering)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
