//
//  Downloader.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/11.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation
import AppKit

enum PagesStatus {
    case Complete, SomeMissing, None
}

// MARK: DownloaderGalleryOperationDelegate
extension Downloader: DownloaderGalleryOperationDelegate {
    
    class func onSuccessDownload(gallery: Gallery, currentCount: Int, totalCount: Int) {
        guard let safeGid = gallery.gid else {
            return
        }

        for (identify, monitor) in self.observerTable {
            if identify.gid == safeGid {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    monitor(currentCount: currentCount, totalCount: totalCount)
                })
            }
        }
    }
    
}

// MARK: Private Class Method
extension Downloader {
    
    private class func findProgress(gallery: Gallery) -> (currentCount: Int, totalCount: Int) {
        for operation in self.queue.operations {
            if
                let safeDownloaderGalleryOperation = operation as? DownloaderGalleryOperation,
                let safeDownloaderGalleryOperationGallery = safeDownloaderGalleryOperation.gallery,
                let safeDownloaderGalleryOperationGalleryGid = safeDownloaderGalleryOperationGallery.gid,
                let safeGid = gallery.gid
                where safeDownloaderGalleryOperationGalleryGid == safeGid {
                    return safeDownloaderGalleryOperation.progress()
            }
        }
        return (0, 0)
    }
    
    private class func isDownloading(gid: String) -> Bool {
        for operation in self.queue.operations {
            if
                let safeDownloaderGalleryOperation = operation as? DownloaderGalleryOperation,
                let safeGallery = safeDownloaderGalleryOperation.gallery,
                let safeOperationGid = safeGallery.gid
                where gid == safeOperationGid {
                    return true
            }
        }
        return false
    }
    
}

// MARK: Class Method
extension Downloader {
    
    class func download(gallery: Gallery, localPath: NSURL, completion: (gallery: Gallery) -> Void) {
        
        // 下載數量限制最多兩個
        self.queue.maxConcurrentOperationCount = 2
        let downloaderGalleryOperation = DownloaderGalleryOperation(gallery: gallery, localPath: localPath, completion: completion)
        downloaderGalleryOperation.delegate = self as? DownloaderGalleryOperationDelegate
        self.queue.addOperation(downloaderGalleryOperation)
    }
    
    class func isDownloading(gallery: Gallery) -> Bool {
        guard let safeGid = gallery.gid else {
            return false
        }
        
        return isDownloading(safeGid)
    }
    
    class func pagesStatus(gallery: Gallery) -> PagesStatus {
        
        // 前處理, 確認每張圖片都是正常的, 把不正常的路徑設回 nil
        if let safePages = gallery.pages {
            for page in safePages {
                if let safePath = page.localPath {
                    let fileManagerPath = DaiFileManager.document[safePath]
                    
                    // 有兩種狀況, 一個是有檔案, 但是檔案是壞的
                    // 另一個是路徑存在, 檔案卻遺失
                    if DaiFileManager.isExistIn(fileManagerPath.path) {
                        if let safeData = fileManagerPath.read() where NSImage(data: safeData) == nil {
                            fileManagerPath.delete()
                            page.localPath = nil
                        }
                    }
                    else {
                        page.localPath = nil
                    }
                }
            }
        }

        // 判斷 page 數量是否與記載數量相符
        if let safePages = gallery.pages, let safeFileCount = gallery.filecount where safePages.count != 0 {
            
            // 如果只是數量不符, 判定為缺頁
            if safePages.count != Int(safeFileCount) {
                return .SomeMissing
            }
            else {
                
                // 只要有其中一個檔案連結不見, 也判定為缺頁
                for page in safePages {
                    guard let _ = page.localPath else {
                        return .SomeMissing
                    }
                }
                
                // 全滿
                return .Complete
            }
        }
        
        // page count == 0 時, 才是真正的第一次
        else {
            return .None
        }
    }
    
    // 加入監看
    class func addDownloadObserver(gallery: Gallery, uniqueKey: String, monitor: (currentCount: Int, totalCount: Int) -> Void) {
        if let safeGid = gallery.gid {
            let identify = ObserverIdentify(gid: safeGid, uniqueKey: uniqueKey)
            self.observerTable[identify] = monitor
            let (currentCount, totalCount) = self.findProgress(gallery)
            monitor(currentCount: currentCount, totalCount: totalCount)
        }
    }
    
    // 移除監看
    class func removeDownloadObserver(uniqueKey: String) {
        var removeIdentifys: [ObserverIdentify] = []
        for (identify, _) in self.observerTable {
            if identify.uniqueKey == uniqueKey {
                removeIdentifys.append(identify)
            }
            else if !isDownloading(identify.gid) {
                removeIdentifys.append(identify)
            }
        }
        
        for removeIdentify in removeIdentifys {
            self.observerTable.removeValueForKey(removeIdentify)
        }
    }
    
}

// MARK: Downloader
class Downloader: NSObject {
    
    static let queue = NSOperationQueue()
    static var observerTable: [ObserverIdentify: (currentCount: Int, totalCount: Int) -> Void] = [:]
    
}
