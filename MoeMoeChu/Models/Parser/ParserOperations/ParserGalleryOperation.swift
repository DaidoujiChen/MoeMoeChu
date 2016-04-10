//
//  ParserGalleryPagesOperation.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/8.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation
import Ji

// MARK: Private Instance Method
extension ParserGalleryOperation {
    
    private func sendRequest() {
        
        // 最多 retry 三次, 三次之後結束這個 operation
        if (self.retryCount++ < 3) {
            guard
                let safeTargetURL = self.targetURL
                where self.cancelled == false
                else {
                    self.operationFinish()
                    return
            }
            
            self.session.dataTaskWithURL(safeTargetURL, completionHandler: { [weak self] (data, response, error) -> Void in
                
                guard let safeSelf = self else {
                    print("Gallery Pages Require Parameter Missing")
                    return
                }
                
                if let _ = error {
                    print("Network Error : ", error)
                }
                else {
                    
                    // 檢查 data 正常
                    guard
                        let safeData = data,
                        let jiDoc = Ji(htmlData: safeData),
                        let nodes = jiDoc.xPath("//div [@class='gdtm']//a")
                        else {
                            print("Data Parse Fail")
                            safeSelf.sendRequest()
                            return
                    }
                    
                    // parse 到有東西的話, 做頁數跟連結的配置
                    if (nodes.count > 0) {
                        
                        // 一個一個放到 operation queue
                        for (index, node) in nodes.enumerate() {
                            guard
                                let safeHref = node["href"],
                                let safePageURL = NSURL(string: safeHref),
                                let safePageIndex = safeSelf.pageIndex
                                where !safeSelf.cancelled
                                else {
                                    print("Invalidate Pages URL ", node["href"])
                                    continue
                            }
                            
                            // 先算出真正那一頁的 index
                            let currentPageIndex = safePageIndex * 40 + index + 1
                            
                            // 為了怕連結會變, 因此只要沒有圖檔案在硬碟, 我們就重新 parse 一次那個圖片的連結
                            if let safeSpecialPages = safeSelf.specificPages {
                                if safeSpecialPages.contains(currentPageIndex) {
                                    let parserSinglePageOperation = ParserSinglePageOperation(targetURL: safePageURL, pageIndex: currentPageIndex, completion: { (result) -> Void in
                                        safeSelf.result += result
                                    })
                                    safeSelf.queue.addOperation(parserSinglePageOperation)
                                }
                            }
                            else {
                                let parserSinglePageOperation = ParserSinglePageOperation(targetURL: safePageURL, pageIndex: currentPageIndex, completion: { (result) -> Void in
                                    safeSelf.result += result
                                })
                                safeSelf.queue.addOperation(parserSinglePageOperation)
                            }
                        }
                        
                        // 等
                        safeSelf.queue.waitUntilAllOperationsAreFinished()
                        
                        // 如果 completion 有值, callback
                        if let safeCompletion = safeSelf.completion where !safeSelf.cancelled {
                            safeCompletion(result: safeSelf.result)
                        }
                        safeSelf.operationFinish()
                        return
                    }
                }
                safeSelf.sendRequest()
            }).resume()
        }
        else {
            self.operationFinish()
        }
    }
    
}

// MARK: ParserGalleryOperation
class ParserGalleryOperation: ParserBaseOperation {
    
    private var gallery: Gallery?
    private var result: [Int: String?] = [:]
    private let queue = NSOperationQueue()
    private var pageIndex: Int?
    private var specificPages: [Int]?
    
    convenience init(gallery: Gallery, pageIndex: Int, targetURL: NSURL, completion: (result: [Int: String?]) -> Void) {
        self.init()
        self.targetURL = targetURL
        self.completion = completion
        self.gallery = gallery
        self.pageIndex = pageIndex
    }
    
    convenience init(gallery: Gallery, pageIndex: Int, targetURL: NSURL, specificPages: [Int], completion: (result: [Int: String?]) -> Void) {
        self.init()
        self.targetURL = targetURL
        self.completion = completion
        self.gallery = gallery
        self.pageIndex = pageIndex
        self.specificPages = specificPages
    }
    
    override func start() {
        super.start()
        
        // parse 小頁一次只可以兩個
        self.queue.maxConcurrentOperationCount = 4
        self.sendRequest()
    }
    
    override func cancel() {
        self.queue.cancelAllOperations()
    }

}
