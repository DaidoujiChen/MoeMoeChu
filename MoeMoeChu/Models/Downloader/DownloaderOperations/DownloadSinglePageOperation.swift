//
//  DownloadSinglePageOperation.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/12.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation
import AppKit

// MARK: Private Instance Method
extension DownloadSinglePageOperation {
    
    // 從 NSURL 切細為 String 陣列
    private func pathsFrom(urlPath: NSURL) -> [String] {
        let safePath = urlPath.absoluteString.componentsSeparatedByString("/")
        return self.pathsFrom(safePath)
    }
    
    // 從 String 切細為 String 陣列
    private func pathsFrom(path: String) -> [String] {
        let safePath = path.componentsSeparatedByString("/")
        return self.pathsFrom(safePath)
    }
    
    // 從切細過後的陣列, 過濾出不需要的部份
    private func pathsFrom(originPaths: [String]) -> [String] {
        var paths: [String] = []
        for path in originPaths {
            if path.characters.count != 0 && path != "file:" {
                paths.append(path)
            }
        }
        return paths
    }
    
    // 如果已經抓過, 則直接回傳檔案位置
    private func checkIfFileExist() {
        guard
            let safeGallery = self.gallery,
            let safeTitle = safeGallery.betterTitle,
            let safePageIndex = self.pageIndex,
            let safeCompletion = self.completion,
            let safeLocalPath = self.localPath
            else {
                return
        }
        let localPath = String(format: "/%@/%04d.jpg", safeTitle, safePageIndex)
        if DaiFileManager.isExistIn(DaiFileManager.custom(self.pathsFrom(safeLocalPath))[localPath].path) {
            safeCompletion([ safePageIndex: localPath ])
            self.operationFinish()
        }
    }
    
    private func downloadImage() {
        
        // 最多 retry 三次, 三次之後結束這個 operation
        if (self.retryCount++ < 3) {
            guard let safeTargetURL = self.targetURL else {
                self.operationFinish()
                return
            }
            
            self.session.dataTaskWithURL(safeTargetURL, completionHandler: { [weak self] (data, response, error) -> Void in
                
                guard let safeSelf = self else {
                    return
                }
                
                guard
                    let safeGallery = safeSelf.gallery,
                    let safeTitle = safeGallery.betterTitle,
                    let safePageIndex = safeSelf.pageIndex,
                    let safeCompletion = safeSelf.completion,
                    let safeData = data,
                    let safeLocalPath = safeSelf.localPath
                    else {
                        print("Download Single Page Require Parameter Missing")
                        safeSelf.downloadImage()
                        return
                }
                
                if let _ = error {
                    print("Network Error : ", error)
                    safeSelf.downloadImage()
                }
                else {
                    let localPath = String(format: "/%@/%04d.jpg", safeTitle, safePageIndex)
                    
                    // 這邊先做一個確認, 看抓下來的檔案是不是可以正常的被使用, 才做寫入動作
                    if NSImage(data: safeData) != nil {
                        DaiFileManager.custom(safeSelf.pathsFrom(safeLocalPath))[localPath].write(safeData)
                        safeCompletion([ safePageIndex: localPath ])
                    }
                    else {
                        safeCompletion([ safePageIndex: nil ])
                    }
                    safeSelf.operationFinish()
                }
            }).resume()
        }
        else {
            print("Dwonload Fail : \(self.targetURL) at index : \(self.pageIndex)")
            if let safeCompletion = self.completion, let safePageIndex = self.pageIndex {
                safeCompletion([ safePageIndex: nil ])
            }
            self.operationFinish()
        }
    }
    
}

// MARK: DownloadSinglePageOperation
class DownloadSinglePageOperation: BaseOperation {
    
    private var pageIndex: Int?
    private var targetURL: NSURL?
    private var completion: ([Int: String?] -> Void)?
    private var retryCount: Int = 0
    private var gallery: Gallery?
    private var localPath: NSURL?
    
    convenience init(gallery: Gallery, targetURL: NSURL, localPath: NSURL, pageIndex: Int, completion: [Int: String?] -> Void) {
        self.init()
        self.gallery = gallery
        self.targetURL = targetURL
        self.pageIndex = pageIndex
        self.completion = completion
        self.localPath = localPath
    }
    
    override func start() {
        super.start()
        self.checkIfFileExist()
        self.downloadImage()
    }

}
