//
//  ParserSinglePageOperation.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/8.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation
import Ji

// MARK: Private Instance Method
extension ParserSinglePageOperation {
    
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
                    return
                }
                
                guard
                    let safeCompletion = safeSelf.completion,
                    let safePageIndex = safeSelf.pageIndex
                    where !safeSelf.cancelled
                    else {
                        print("Parse Single Page Require Parameter Missing")
                        safeSelf.sendRequest()
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
                        let nodes = jiDoc.xPath("//img")
                        else {
                            print("Data Parse Fail")
                            safeSelf.sendRequest()
                            return
                    }
                    
                    if (nodes.count > 0) {
                        for node in nodes {
                            if let safeSrc = node["src"], let _ = node["style"] {
                                if !safeSelf.cancelled {
                                    safeCompletion(result: [safePageIndex: safeSrc])
                                }
                                safeSelf.operationFinish()
                                return
                            }
                        }
                    }
                }
                safeSelf.sendRequest()
            }).resume()
        }
        else {
            print("Parse Fail : \(self.targetURL) at index : \(self.pageIndex)")
            if let safeCompletion = self.completion, let safePageIndex = self.pageIndex {
                safeCompletion(result: [safePageIndex: nil])
            }
            self.operationFinish()
        }
    }
    
}

// MARK: ParserSinglePageOperation
class ParserSinglePageOperation: ParserBaseOperation {
    
    private var pageIndex: Int?
    
    convenience init(targetURL: NSURL, pageIndex: Int, completion: (result: [Int: String?]) -> Void) {
        self.init()
        self.targetURL = targetURL
        self.completion = completion
        self.pageIndex = pageIndex
    }
    
    override func start() {
        super.start()
        self.sendRequest()
    }

}
