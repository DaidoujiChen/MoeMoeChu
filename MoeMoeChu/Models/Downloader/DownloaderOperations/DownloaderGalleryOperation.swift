//
//  DownloaderGalleryOperation.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/12.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation

@objc protocol DownloaderGalleryOperationDelegate {
    
    optional func onSuccessDownload(gallery: Gallery, currentCount: Int, totalCount: Int)
    
}

// MARK: Instance Method
extension DownloaderGalleryOperation {
    
    func progress() -> (currentCount: Int, totalCount: Int) {
        return (self.currentCount, self.totalCount)
    }
    
}

// MARK: DownloaderGalleryOperation
class DownloaderGalleryOperation: BaseOperation {
    
    weak var delegate: DownloaderGalleryOperationDelegate?
    var gallery: Gallery?
    private var completion: ((gallery: Gallery) -> Void)?
    private var localPath: NSURL?
    private let queue = NSOperationQueue()
    var currentCount = 0
    var totalCount = 0
    
    convenience init(gallery: Gallery, localPath: NSURL, completion: (gallery: Gallery) -> Void) {
        self.init()
        self.gallery = gallery
        self.completion = completion
        self.localPath = localPath
    }

    override func start() {
        super.start()
        
        // 最多一次 download 兩個項目
        self.queue.maxConcurrentOperationCount = 4
        
        guard let safeGallery = self.gallery else {
            self.operationFinish()
            return
        }
        
        // 先取得該部作品所有頁面連結
        Parser.shared.imagesFrom(safeGallery) { [weak self] (status, gallery) -> Void in
            guard let safeSelf = self else {
                return
            }
            
            guard
                let safePages = gallery.pages,
                let safeFileCount = gallery.filecount,
                let safeCount = Int(safeFileCount),
                let safeLocalPath = safeSelf.localPath
                else {
                    safeSelf.operationFinish()
                    return
            }
            safeSelf.totalCount = safeCount
            
            // 拆開兩段寫, 避免列舉的同時, 列舉對象被改變
            var downloadURLs: [Int: NSURL] = [:]
            for (_, page) in safePages.enumerate() {
                guard
                    let safeIndex = page.index?.integerValue,
                    let safeURLString = page.originalURLPath,
                    let safeURL = NSURL(string: safeURLString)
                    else {
                        continue
                }
                downloadURLs += [ safeIndex: safeURL]
            }
            
            // 加入 queue 下載
            var localPaths: [Int: String?] = [:]
            for (index, url) in downloadURLs {
                let downloadSinglePageOperation = DownloadSinglePageOperation(gallery: gallery, targetURL: url, localPath: safeLocalPath, pageIndex: index, completion: { (result) -> Void in
                    guard let safeGallery = safeSelf.gallery else {
                        return
                    }
                    localPaths += result
                    
                    if let safeDelegate = safeSelf.delegate, let safeFunction = safeDelegate.onSuccessDownload {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            safeSelf.currentCount = localPaths.count
                            safeFunction(safeGallery, currentCount: localPaths.count, totalCount: safeCount)
                        })
                    }
                })
                safeSelf.queue.addOperation(downloadSinglePageOperation)
            }
            
            // 等
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                safeSelf.queue.waitUntilAllOperationsAreFinished()
                
                guard
                    let safeGallery = safeSelf.gallery,
                    let safeCompletion = safeSelf.completion
                    else {
                        safeSelf.operationFinish()
                        return
                }
                
                // 在 main thread 寫路徑, 避免多執行緒寫入的問題
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    safeGallery.updatePagesPath(localPaths)
                    if let safeDelegate = safeSelf.delegate, let safeFunction = safeDelegate.onSuccessDownload {
                        safeFunction(safeGallery, currentCount: safeCount, totalCount: safeCount)
                    }
                    safeCompletion(gallery: safeGallery)
                })
                safeSelf.operationFinish()
            }
        }
    }
    
}
