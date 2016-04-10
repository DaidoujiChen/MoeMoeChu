//
//  DaiFileManager.swift
//  DaiFileManagerSwift
//
//  Created by DaidoujiChen on 2015/11/10.
//  Copyright © 2015年 DaidoujiChen. All rights reserved.
//

import Foundation

// MARK: DaiFileManagerItems
struct DaiFileManagerItems {
    
    // 檔案或是資料夾列表
    private var items: [String] = []
    
    // 不想給外面的人存取
    private init() {
    }
    
    // 列出所有 item
    func all() -> [String] {
        return self.items
    }
    
    // 過濾 item
    func filter(contants: String) -> [String] {
        var filterItems: [String] = []
        for item in self.items {
            if item.containsString(contants) {
                filterItems.append(item)
            }
        }
        return filterItems
    }
    
}

// MARK: --------------------------------------------------

// MARK: Instance Method - IO
extension DaiFileManagerPath {
    
    // 在當前路徑下寫入檔案
    func write(data: NSData) -> Bool {
        return data.writeToFile(self.path, atomically: true)
    }
    
    // 讀取當前路徑的檔案
    func read() -> NSData? {
        return DaiFileManager.defaultManager.contentsAtPath(self.path)
    }
    
    // 刪除當前路徑 / 檔案
    func delete() {
        do {
            try DaiFileManager.defaultManager.removeItemAtPath(self.path)
        }
        catch {
            print("Delete Fail : ", error)
        }
    }
    
    // 移動
    func move(toPath: DaiFileManagerPath) {
        do {
            try DaiFileManager.defaultManager.moveItemAtPath(self.path, toPath: toPath.path)
        }
        catch {
            print("Move Fail : ", error)
        }
    }
    
    // 複製
    func copy(toPath: DaiFileManagerPath) {
        do {
            try DaiFileManager.defaultManager.copyItemAtPath(self.path, toPath: toPath.path)
        }
        catch {
            print("Copy Fail : ", error)
        }
    }
    
}

// MARK: Private Instance Method
extension DaiFileManagerPath {
    
    // 建立資料夾
    private func createFolder(path: String) {
        if !DaiFileManager.isExistIn(path) {
            do {
                try DaiFileManager.defaultManager.createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
            }
            catch {
                // 拿掉這個 log ... 太會跳了
                //print("Create Fail : ", error)
            }
        }
    }
    
    // 列出資料夾或是檔案們
    private func folderList(isFolder: Bool) -> DaiFileManagerItems {
        var items = DaiFileManagerItems()
        
        guard let safeItems = try? DaiFileManager.defaultManager.contentsOfDirectoryAtPath(self.path) else {
            print("Path Fail")
            return items
        }
        
        var isDirectory: ObjCBool = false
        for item in safeItems {
            let itemPath = self.path + "/" + item
            DaiFileManager.defaultManager.fileExistsAtPath(itemPath, isDirectory: &isDirectory)
            
            if isDirectory.boolValue == isFolder {
                items.items.append(item)
            }
        }
        return items
    }
    
}

// MARK: Read Only Variable
extension DaiFileManagerPath {
    
    // 只列出檔案們
    var files: DaiFileManagerItems {
        get {
            return self.folderList(false)
        }
    }
    
    // 只列出資料夾們
    var folders: DaiFileManagerItems {
        get {
            return self.folderList(true)
        }
    }
    
    // 吐出當前路徑
    var path: String {
        get {
            return self.paths.joinWithSeparator("/") + (self.isFolder ? "/" : "")
        }
    }
    
}

// MARK: DaiFileManagerPath
struct DaiFileManagerPath {
    
    // 儲存路徑
    private var paths: [String] = []
    
    // 由 subscript 輸入的最後一個字元判斷, 當前 path 是否以檔案夾來看待
    private var isFolder: Bool = true
    
    // 不想給外面的人存取
    private init() {
    }
    
    // 加入一個讓物件可以 [] 的功能
    // 比方 document["/Daidouji/"].files.all() 路徑會在 document/Daidouji 資料夾下的所有檔案
    // 如果結尾不以 / 結束的話如, document["hello"] 則單只 document 資料夾下的 hello 檔案
    // 預設會自動補齊中間缺少的資料夾
    subscript(path: String) -> DaiFileManagerPath {
        var newDaiFileManagerPath = self
        newDaiFileManagerPath.isFolder = path.characters.last == "/"
        let splitPath = path.componentsSeparatedByString("/").filter { (eachPath) -> Bool in
            return (eachPath.characters.count > 0)
        }
        for eachPath in splitPath {
            newDaiFileManagerPath.paths.append(eachPath)
            if eachPath != splitPath.last {
                newDaiFileManagerPath.createFolder(newDaiFileManagerPath.path)
            }
            else {
                if newDaiFileManagerPath.isFolder {
                    newDaiFileManagerPath.createFolder(newDaiFileManagerPath.path)
                }
            }
        }
        return newDaiFileManagerPath
    }
    
}

// MARK: --------------------------------------------------

// MARK: Read Only Variable
extension DaiFileManager {
    
    // documentPath
    static var document: DaiFileManagerPath {
        get {
            var newFileManager = DaiFileManagerPath()
            guard let safeDocumentPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first else {
                print("Get Document Path Fail")
                return newFileManager
            }
            newFileManager.paths.append(safeDocumentPath)
            return newFileManager
        }
    }
    
    // application support path
    static var applicationSupport: DaiFileManagerPath {
        get {
            var newFileManager = DaiFileManagerPath()
            guard let safeDocumentPath = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true).first else {
                print("Get Document Path Fail")
                return newFileManager
            }
            newFileManager.paths.append(safeDocumentPath)
            return newFileManager
        }
    }
    
    // resourcePath
    static var resource: DaiFileManagerPath {
        get {
            var newFileManager = DaiFileManagerPath()
            newFileManager.paths.append(NSBundle.mainBundle().bundlePath)
            return newFileManager
        }
    }
    
    static func custom(paths: [String]) -> DaiFileManagerPath {
        var newFileManager = DaiFileManagerPath()
        for path in paths {
            if path == paths.first {
                newFileManager.paths.append("/" + path)
            }
            else {
                newFileManager.paths.append(path)
            }
        }
        return newFileManager
    }
    
}

// MARK: DaiFileManager
struct DaiFileManager {
    
    // 公用的 NSFileManager
    private static let defaultManager = NSFileManager.defaultManager()
    
    // 不想給外面的人存取
    private init() {
    }
    
    // 判斷檔案是否存在
    static func isExistIn(path: String) -> Bool {
        return self.defaultManager.fileExistsAtPath(path)
    }
    
}
