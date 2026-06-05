//
//  FileService.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

struct FileService {
    
    // 获取沙盒目录
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    // 保存数据
    static func save(data: Data, to filename: String, in directory: URL = documentsDirectory) throws -> URL {
        let fileURL = directory.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL // 返回路径
    }
    
    // 读取数据
    static func load(from filename: String, in directory: URL = documentsDirectory) -> Data? {
        let fileURL = directory.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }
    
    // 删除文件
    static func delete(filename: String, in directory: URL = documentsDirectory) {
        let fileURL = directory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // 计算缓存大小 (配合之前的 SettingsViewModel)
    static func getCacheSizeString() -> String {
        guard let urls = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return "0 KB"
        }
        
        var totalSize: Int64 = 0
        for url in urls {
            if let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    // 清理缓存
    static func clearCache() {
        guard let urls = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
