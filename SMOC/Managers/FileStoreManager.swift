//
//  FileManager.swift
//  SMOC
//
//  Created by Javier Calatrava on 15/1/25.
//

import Foundation

protocol FileManagerProtocol {
    func clearTemporaryDirectory() async
}

@globalActor
actor GlobalManager {
    static var shared = GlobalManager()
}

@GlobalManager
final class FileStoreManager: FileManagerProtocol {
    
    
@MainActor
 init() {
}

    @GlobalManager
     func clearTemporaryDirectory() async {
        let fileManager = FileManager.default
            let tempDirectoryURL = fileManager.temporaryDirectory
            
            do {
                let tempFiles = try fileManager.contentsOfDirectory(at: tempDirectoryURL, includingPropertiesForKeys: nil, options: [])
                for file in tempFiles {
                    try fileManager.removeItem(at: file)
                }
            } catch {
                print("Error on removing temporal folder: \(error.localizedDescription)")
            }
    }
}
