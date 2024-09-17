//
//  FileFairyLogic.swift
//  FileFairy
//
//  Created by Marc Hoag on 9/11/24.
//

import Foundation
import os

struct FileFairyLogic {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.filefairy", category: "FileFairyLogic")
    
    static func processDirectory(_ url: URL) -> (String, Bool) {
        let fileManager = FileManager.default
        var outputLines: [String] = []
        
        logger.info("Processing directory: \(url.path)")
        
        // Request permission to access the directory
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Check folder permissions
        let permissionsInfo = checkFolderPermissions(url)
        logger.info("Folder permissions: \(permissionsInfo)")
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            
            logger.info("Found \(contents.count) items in directory")
            
            let folders = contents.filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
            }
            
            logger.info("Found \(folders.count) folders in directory")
            
            var count = 0
            let totalFolders = folders.count
            
            for folderURL in folders {
                let item = folderURL.lastPathComponent
                logger.info("Processing folder: \(item)")
                
                if let (datePart, eventName) = extractDateAndEvent(from: item) {
                    if let formattedDate = convertDate(datePart) {
                        let newName = eventName.isEmpty ? formattedDate : "\(formattedDate) - \(eventName)"
                        if newName != item {
                            if fileManager.fileExists(atPath: url.appendingPathComponent(newName).path) {
                                outputLines.append("Will skip: \(item) (new name already exists)")
                                logger.info("Will skip: \(item) (new name already exists)")
                            } else {
                                outputLines.append("Will rename: \(item) -> \(newName)")
                                count += 1
                                logger.info("Will rename: \(item) -> \(newName)")
                            }
                        } else {
                            outputLines.append("Will skip: \(item) (already in correct format)")
                            logger.info("Will skip: \(item) (already in correct format)")
                        }
                    } else {
                        outputLines.append("Will skip: \(item) (date conversion failed)")
                        logger.info("Will skip: \(item) (date conversion failed)")
                    }
                } else {
                    outputLines.append("Will skip: \(item) (unrecognized format)")
                    logger.info("Will skip: \(item) (unrecognized format)")
                }
            }
            
            outputLines.sort()
            
            var output = "Total folders scanned: \(totalFolders)\n"
            output += "Total folders to rename: \(count)\n\n"
            output += outputLines.joined(separator: "\n")
            
            logger.info("Processed \(totalFolders) items, found \(count) folders to rename")
            
            return (output, false)
        } catch {
            logger.error("Failed to access directory contents: \(url.path), error: \(error.localizedDescription)")
            return ("Failed to access directory: \(error.localizedDescription)", false)
        }
    }
    
    static func checkFolderPermissions(_ url: URL) -> String {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return "Not a directory"
        }
        
        var attributes: [FileAttributeKey : Any]
        do {
            attributes = try fileManager.attributesOfItem(atPath: url.path)
        } catch {
            return "Error getting attributes: \(error.localizedDescription)"
        }
        
        let permissions = attributes[.posixPermissions] as? Int ?? 0
        let ownerID = attributes[.ownerAccountID] as? Int ?? 0
        let groupID = attributes[.groupOwnerAccountID] as? Int ?? 0
        
        return "Permissions: \(String(format:"%o", permissions)), Owner: \(ownerID), Group: \(groupID)"
    }
    
    static func renameFolders(_ url: URL, preview: String, progress: @escaping (Double) -> Void) -> String {
        let fileManager = FileManager.default
        var outputLines: [String] = []
        var renamedCount = 0
        var totalFolders = 0
        var renamedFolders: [RenamedFolder] = []
        
        let lines = preview.split(separator: "\n")
        let totalLines = lines.count
        
        // Request permission to access the directory
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        for (index, line) in lines.enumerated() {
            if line.starts(with: "Will rename:") {
                totalFolders += 1
                let parts = line.split(separator: "->").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 {
                    let originalName = String(parts[0].dropFirst("Will rename:".count).trimmingCharacters(in: .whitespaces))
                    let newName = parts[1]
                    
                    let originalURL = url.appendingPathComponent(originalName)
                    let newURL = url.appendingPathComponent(newName)
                    
                    do {
                        try fileManager.moveItem(at: originalURL, to: newURL)
                        outputLines.append("Renamed: \(originalName) -> \(newName)")
                        renamedFolders.append(RenamedFolder(original: originalName, new: newName))
                        renamedCount += 1
                        logger.info("Renamed folder: \(originalName) to \(newName)")
                    } catch {
                        outputLines.append("Error: Failed to rename \(originalName): \(error.localizedDescription)")
                        logger.error("Failed to rename folder: \(originalName), error: \(error.localizedDescription)")
                    }
                }
            }
            
            progress(Double(index + 1) / Double(totalLines))
        }
        
        outputLines.sort()
        
        var output = "Renaming folders:\n\n"
        output += "Total folders processed: \(totalFolders)\n"
        output += "Total folders renamed: \(renamedCount)\n\n"
        output += outputLines.joined(separator: "\n")
        
        // Store the renamed folders information for potential undo
        UserDefaults.standard.set(try? JSONEncoder().encode(renamedFolders), forKey: "RenamedFolders")
        UserDefaults.standard.set(url.path, forKey: "RenamedFoldersPath")
        
        logger.info("Completed renaming. Total processed: \(totalFolders), Total renamed: \(renamedCount)")
        
        return output
    }
    
    static func undoRenames() -> String {
        guard let renamedFoldersData = UserDefaults.standard.data(forKey: "RenamedFolders"),
              let path = UserDefaults.standard.string(forKey: "RenamedFoldersPath"),
              let renamedFolders = try? JSONDecoder().decode([RenamedFolder].self, from: renamedFoldersData) else {
            return "No rename information found to undo."
        }
        
        let fileManager = FileManager.default
        var outputLines: [String] = []
        var undoneCount = 0
        
        for folder in renamedFolders.reversed() {
            let currentPath = (path as NSString).appendingPathComponent(folder.new)
            let originalPath = (path as NSString).appendingPathComponent(folder.original)
            
            do {
                try fileManager.moveItem(atPath: currentPath, toPath: originalPath)
                outputLines.append("Undone: \(folder.new) -> \(folder.original)")
                undoneCount += 1
                logger.info("Undid rename: \(folder.new) to \(folder.original)")
            } catch {
                outputLines.append("Error: Failed to undo \(folder.new)")
                logger.error("Failed to undo rename: \(folder.new), error: \(error.localizedDescription)")
            }
        }
        
        outputLines.sort()
        
        var output = "Undoing changes:\n\n"
        output += "Total folders processed: \(renamedFolders.count)\n"
        output += "Total folders undone: \(undoneCount)\n\n"
        output += outputLines.joined(separator: "\n")
        
        // Clear the stored rename information
        UserDefaults.standard.removeObject(forKey: "RenamedFolders")
        UserDefaults.standard.removeObject(forKey: "RenamedFoldersPath")
        
        logger.info("Completed undoing. Total processed: \(renamedFolders.count), Total undone: \(undoneCount)")
        
        return output
    }
    
    private static func extractDateAndEvent(from folderName: String) -> (String, String)? {
        let patterns: [(String, (String) -> (String, String)?)] = [
            (#"(?i)^(.+), ([A-Za-z]+ \d{1,2}, \d{4})$"#, { match in
                let components = match.components(separatedBy: ", ")
                let datePart = components.suffix(2).joined(separator: ", ")
                let eventName = components.dropLast(2).joined(separator: ", ")
                return (datePart, eventName)
            }),
            (#"(?i)^([A-Za-z]+ \d{1,2}, \d{4})$"#, { match in
                return (match, "")
            }),
            (#"^(\d{1,2}-\d{1,2}-\d{4})$"#, { match in
                return (match, "")
            }),
            (#"^(\d{4}-\d{1,2}-\d{1,2})$"#, { match in
                return (match, "")
            })
        ]
        
        for (pattern, handler) in patterns {
            if let range = folderName.range(of: pattern, options: [.regularExpression, .caseInsensitive]),
               let result = handler(String(folderName[range])) {
                return result
            }
        }
        
        return nil
    }
    
    private static func convertDate(_ dateStr: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let formats = [
            "MMMM d, yyyy",
            "M-d-yyyy",
            "yyyy-M-d"
        ]
        
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateStr) {
                dateFormatter.dateFormat = "yyyy-MM-dd"
                return dateFormatter.string(from: date)
            }
        }
        
        return nil
    }
}

struct RenamedFolder: Codable {
    let original: String
    let new: String
}
