//
//  Parser.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/7.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation
import CoreData
import Ji
import SwiftyJSON

enum ParserStatus {
    case Success, Fail
}

// MARK: Private Class Method
extension Parser {
    
    private class func galleryDetailFrom(urls: [String], completion: (status: ParserStatus, list: [JSON]?) -> Void) {
        
        // http://g.e-hentai.org/g/618395/0439fa3666/
        //                 -3(618395) -2(0439fa3666) -1(空白)
        // 切割所需要的 id
        var splitIDs: [[String]] = []
        for url in urls {
            let splitStrings = url.componentsSeparatedByString("/")
            let splitCount = splitStrings.count
            splitIDs.append([splitStrings[splitCount - 3], splitStrings[splitCount - 2]])
        }
        
        // 製作要發出的 post request
        let jsonDictionary: [String: AnyObject] = [ "method": "gdata", "gidlist": splitIDs ]
        guard let safeRequest = self.postRequestBy(jsonDictionary) else {
            print("Make Json Reqest Fail")
            completion(status: .Fail, list: nil)
            return
        }
        
        NSURLSession.sharedSession().dataTaskWithRequest(safeRequest) { (data, response, error) -> Void in
            if let _ = error {
                completion(status: .Fail, list: nil)
            }
            else {
                guard let safeData = data else {
                    print("Hentai API Data Fail")
                    return
                }
                
                let json = JSON(data: safeData)
                completion(status: .Success, list: json["gmetadata"].array)
            }
        }.resume()
    }
    
    // 製作 post request 取得每個 gallery 完整內容
    private class func postRequestBy(jsonDictionary: [String: AnyObject]) -> NSMutableURLRequest? {
        guard
            let jsonData = try? NSJSONSerialization.dataWithJSONObject(jsonDictionary, options: .PrettyPrinted),
            let safeURL = NSURL(string: "http://g.e-hentai.org/api.php")
            else {
                print("Convert Json Data Fail or URL Fail")
                return nil
        }
        
        let request = NSMutableURLRequest(URL:safeURL)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(jsonData.length)", forHTTPHeaderField: "Content-Length")
        request.HTTPBody = jsonData
        return request
    }
    
}

// MARK: Class Method
extension Parser {
    
    class func listFrom(filterURL: NSURL, completion: (status: ParserStatus, galleries: [Gallery]?) -> Void) {
        
        // 預先做好導回主線程回傳失敗的 closure
        let callbackFailToMainThread = { () -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                completion(status: .Fail, galleries: nil)
            }
        }
        
        NSURLSession.sharedSession().dataTaskWithURL(filterURL) { (data, response, error) -> Void in
            
            // 如果網路失敗
            if let _ = error {
                callbackFailToMainThread()
            }
            else {
                
                // 檢查 data 正常
                guard
                    let safeData = data,
                    let jiDoc = Ji(htmlData: safeData),
                    let nodes = jiDoc.xPath("//div [@class='it5']//a")
                    else {
                        print("Data Parse Fail")
                        callbackFailToMainThread()
                        return
                }
                
                // node 數必須大於 0 才有 parse 到東西
                if (nodes.count > 0) {
                    
                    // 取得 parse 到的網址連結們
                    var urlStrings: [String] = []
                    for node in nodes {
                        guard let safeHref = node["href"] else {
                            continue
                        }
                        urlStrings.append(safeHref)
                    }
                    
                    // 丟給 e hentai api 抓取每個連結詳細的資料
                    self.galleryDetailFrom(urlStrings, completion: { (status, items) -> Void in
                        guard let safeitems = items where status == .Success else {
                            print("Hentai API Fail")
                            callbackFailToMainThread()
                            return
                        }
                        
                        var galleries: [Gallery] = []
                        for item in safeitems {
                            if let safeFindGallery = Gallery.find(item["gid"].stringValue), let safeClone = safeFindGallery.clone() {
                                galleries.append(safeClone)
                            }
                            else if let safeGallery = Gallery.new(item) {
                                galleries.append(safeGallery)
                            }
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(status: .Success, galleries: galleries)
                        }
                    })
                }
                else {
                    callbackFailToMainThread()
                }
            }
        }.resume()
    }
    
    class func specialGalleriesBy(urlStrings: [String], completion: (status: ParserStatus, galleries: [Gallery]?) -> Void) {
        
        // 預先做好導回主線程回傳失敗的 closure
        let callbackFailToMainThread = { () -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                completion(status: .Fail, galleries: nil)
            }
        }
        
        // 丟給 e hentai api 抓取每個連結詳細的資料
        self.galleryDetailFrom(urlStrings, completion: { (status, items) -> Void in
            guard let safeitems = items where status == .Success else {
                print("Hentai API Fail")
                callbackFailToMainThread()
                return
            }
            
            var galleries: [Gallery] = []
            for item in safeitems {
                if let safeFindGallery = Gallery.find(item["gid"].stringValue), let safeClone = safeFindGallery.clone() {
                    galleries.append(safeClone)
                }
                else if let safeGallery = Gallery.new(item) {
                    galleries.append(safeGallery)
                }
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                completion(status: .Success, galleries: galleries)
            }
        })
    }
    
}

// MARK: Parser
class Parser {
    
    static let shared = Parser()
    let queue = NSOperationQueue()
    var cancelled = false
    
    func imagesFrom(gallery: Gallery, completion: (status: ParserStatus, gallery: Gallery) -> Void) {
        self.imagesFrom(gallery, specificPages: nil, completion: completion)
    }
    
    func imagesFrom(gallery: Gallery, specificPages: [Int]?, completion: (status: ParserStatus, gallery: Gallery) -> Void) {
        
        guard
            let safeFileCount = gallery.filecount,
            let fileCount = Int(safeFileCount),
            let safeGid = gallery.gid,
            let safeToken = gallery.token
            else {
                print("Gallery Data Missing")
                return
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak self] () -> Void in
            
            guard let safeSelf = self else {
                return
            }
            
            // 最後要回傳的全部內容
            var imageURLStrings: [Int: String?] = [:]
            
            // parser 一次處理一個頁面
            safeSelf.queue.maxConcurrentOperationCount = 2
            
            // 計算總共有幾頁, 預設一個頁有 40 個圖
            let pageCount = (fileCount - 1) / 40
            
            // 基本網址
            //http://g.e-hentai.org/g/793143/1a99ca59ae/?nw=always
            let baseURLString = "http://g.e-hentai.org/g/\(safeGid)/\(safeToken)/"
            
            // 開始跑全部的頁面
            for index in 0...pageCount {
                var pagesURLString: String
                if index == 0 {
                    pagesURLString = "\(baseURLString)?nw=always"
                }
                else {
                    pagesURLString = "\(baseURLString)?p=\(index)"
                }
                
                guard let safePagesURL = NSURL(string: pagesURLString) else {
                    print("Invalidate Pages URL ", pagesURLString)
                    continue
                }

                var parserGalleryOperation: ParserGalleryOperation
                if let safeSpecificPages = specificPages {
                    parserGalleryOperation = ParserGalleryOperation(gallery: gallery, pageIndex: index, targetURL: safePagesURL, specificPages: safeSpecificPages, completion: { (result) -> Void in
                        imageURLStrings += result
                    })
                }
                else {
                    parserGalleryOperation = ParserGalleryOperation(gallery: gallery, pageIndex: index, targetURL: safePagesURL, completion: { (result) -> Void in
                        imageURLStrings += result
                    })
                }
                if !safeSelf.cancelled {
                    safeSelf.queue.addOperation(parserGalleryOperation)
                }
            }
            
            // 等
            safeSelf.queue.waitUntilAllOperationsAreFinished()
            
            if !safeSelf.cancelled {
                dispatch_async(dispatch_get_main_queue()) {
                    gallery.updatePagesURL(imageURLStrings)
                    completion(status: .Success, gallery: gallery)
                }
            }
        }
    }
    
    func cancelParseImages() {
        self.cancelled = true
        self.queue.cancelAllOperations()
    }
    
}
