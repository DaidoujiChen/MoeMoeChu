//
//  Gallery.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/7.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

enum CategoryType: String {
    case Doujinshi = "Doujinshi"
    case NonH = "Non-H"
    case Manga = "Manga"
    case ImageSet = "Image Sets"
    case ArtistCG = "Artist CG Sets"
    case Cosplay = "Cosplay"
    case GameCG = "Game CG Sets"
    case AsianPorn = "Asian Porn"
    case Western = "Western"
    case Misc = "Misc"
    
    var name: String {
        return "\(self)"
    }
}

enum DownloadType {
    case Download, Cache, None
}

enum FavoriteType {
    case Favorite, NotFavorite
}

enum PageUpdateType {
    case URL, Path
}

extension Gallery {
    
    @NSManaged var archiver_key: String?
    @NSManaged var category: String?
    @NSManaged var expunged: String?
    @NSManaged var filecount: String?
    @NSManaged var filesize: String?
    @NSManaged var gid: String?
    @NSManaged var posted: String?
    @NSManaged var rating: String?
    @NSManaged var thumb: String?
    @NSManaged var title: String?
    @NSManaged var title_jpn: String?
    @NSManaged var token: String?
    @NSManaged var torrentcount: String?
    @NSManaged var uploader: String?
    @NSManaged var download: NSNumber?
    @NSManaged var favorite: NSNumber?
    
    // Relationship
    @NSManaged var custom: CustomRecord?
    @NSManaged var pages: Set<Page>?
    @NSManaged var tags: Set<Tag>?
    
}

// MARK: Private Class Method
extension Gallery {
    
    private class func primaryKeyFrom(gallery: Gallery) -> Int {
        let originalString = gallery.objectID.URIRepresentation().absoluteString
        return Int(originalString.componentsSeparatedByString("/p").last ?? "0") ?? 0
    }
    
    private class func allRecords(format: String) -> [Gallery] {
        let fetchRequest = NSFetchRequest(entityName: "Gallery")
        fetchRequest.predicate = NSPredicate(format: format)
        
        guard
            let safeResults = try? CoreData.managedObjectContext.executeFetchRequest(fetchRequest) as? [Gallery] ?? []
            where safeResults.count > 0
            else {
                return []
        }
        return safeResults.sort { (galleryA, galleryB) -> Bool in
            return self.primaryKeyFrom(galleryA) > self.primaryKeyFrom(galleryB)
        }
    }
    
}

// MARK: Class Method
extension Gallery {
    
    // 用 gid 去找 Gallery
    class func find(gid: String) -> Gallery? {
        let fetchRequest = NSFetchRequest(entityName: "Gallery")
        fetchRequest.predicate = NSPredicate(format: "gid = %@", gid)
        guard
            let safeResults = try? CoreData.managedObjectContext.executeFetchRequest(fetchRequest)
            where safeResults.count > 0
            else {
                return nil
        }
        return safeResults.first as? Gallery
    }
    
    class func new(gallery: JSON) -> Gallery? {
        guard let safeGalleryEntity = NSEntityDescription.entityForName("Gallery", inManagedObjectContext: CoreData.managedObjectContext) else {
            print("Create Gallery Fail")
            return nil
        }
        let newGallery = Gallery(entity: safeGalleryEntity, insertIntoManagedObjectContext: nil)
        
        // 填入基本資料
        newGallery.archiver_key = gallery["archiver_key"].stringValue
        newGallery.category = gallery["category"].stringValue
        newGallery.expunged = gallery["expunged"].stringValue
        newGallery.filecount = gallery["filecount"].stringValue
        newGallery.filesize = gallery["filesize"].stringValue
        newGallery.gid = gallery["gid"].stringValue
        newGallery.posted = gallery["posted"].stringValue
        newGallery.rating = gallery["rating"].stringValue
        newGallery.thumb = gallery["thumb"].stringValue
        newGallery.title = gallery["title"].stringValue
        newGallery.title_jpn = gallery["title_jpn"].stringValue
        newGallery.token = gallery["token"].stringValue
        newGallery.torrentcount = gallery["torrentcount"].stringValue
        newGallery.uploader = gallery["uploader"].stringValue
        
        // 建立 tags 標籤
        let tags = gallery["tags"].arrayValue
        for tag in tags {
            guard let safeTagEntity = NSEntityDescription.entityForName("Tag", inManagedObjectContext: CoreData.managedObjectContext) else {
                print("Create Tag Fail")
                continue
            }
            let newTag = Tag(entity: safeTagEntity, insertIntoManagedObjectContext: nil)
            newTag.name = tag.stringValue
            newTag.gallery = newGallery
            newGallery.mutableSetValueForKey("tags").addObject(newTag)
        }
        
        return newGallery
    }
    
    // 添加一個新的 gallery, 回傳建立好, 或是已經有的訊息
    class func add(gallery: Gallery) -> Gallery? {
        guard let safeGid = gallery.gid else {
            print("GID Missing")
            return nil
        }
        
        if let gallery = self.find(safeGid) {
            print("Already Have This Gallery")
            
            // 寫入硬碟
            CoreData.saveContext()
            return gallery
        }
        else {
            if let clone = gallery.clone() {
                
                // 先把 tags 放到資料庫
                if let safeTags = clone.tags {
                    for (_, tag) in safeTags.enumerate() {
                        CoreData.managedObjectContext.insertObject(tag)
                    }
                }
                
                // 再放主體
                CoreData.managedObjectContext.insertObject(clone)
                
                // 寫入硬碟
                CoreData.saveContext()
                return clone
            }
            else {
                print("Add Clone Fail")
                return nil
            }
        }
    }
    
    /*
    // 找出所有已下載項目, 並反向列出
    class func allDownloads() -> [Gallery] {
        var predicate = "download = 1"
        if Locker.status() != .Pass {
            predicate += " AND title CONTAINS '餘筆'"
        }
        return self.allRecords(predicate)
    }
    
    // 列出所有看過的項目
    class func allHistories() -> [Gallery] {
        var predicate = "download = 0"
        if Locker.status() != .Pass {
            predicate += " AND title CONTAINS '餘筆'"
        }
        return self.allRecords(predicate)
    }
    
    // 列出加到最愛的項目
    class func allFavorites() -> [Gallery] {
        var predicate = "favorite = 1"
        if Locker.status() != .Pass {
            predicate += " AND title CONTAINS '餘筆'"
        }
        return self.allRecords(predicate)
    }*/
    
}

// MARK: Private Instance Method
extension Gallery {
    
    private func update(imageURLStrings: [Int: String?], type: PageUpdateType) {
        
        // 先找出硬碟裡面全部的頁面
        var existPages = self.existPages()
        for (index, value) in imageURLStrings {
            
            // 比對該 index 是否在硬碟中
            var foundPage: Page? = nil
            for existPage in existPages {
                if let safeExistPageIndex = existPage.index where safeExistPageIndex == index {
                    foundPage = existPage
                    break
                }
            }
            
            // 如果有找到, 且內容不同的話, 則改變其內容
            if let safeFoundPage = foundPage {
                switch type {
                case .URL:
                    if safeFoundPage.originalURLPath != value {
                        safeFoundPage.originalURLPath = value
                    }
                    
                case .Path:
                    if safeFoundPage.localPath != value {
                        safeFoundPage.localPath = value
                    }
                }
            }
            
            // 如果沒找到, 重新寫一份到硬碟
            else {
                guard let newPage = NSEntityDescription.insertNewObjectForEntityForName("Page", inManagedObjectContext: CoreData.managedObjectContext) as? Page else {
                    print("Insert Page Fail")
                    return
                }
                newPage.index = NSNumber(integer: index)
                switch type {
                case .URL:
                    newPage.originalURLPath = value
                    
                case .Path:
                    newPage.localPath = value
                }
                newPage.gallery = self
                self.mutableSetValueForKey("pages").addObject(newPage)
            }
            
            if let safeFoundPage = foundPage, let safeIndex = existPages.indexOf(safeFoundPage) {
                existPages.removeAtIndex(safeIndex)
            }
        }
        CoreData.saveContext()
    }
    
    // 用 gid 去找相對應的 pages
    private func existPages() -> [Page] {
        guard let safeGid = self.gid else {
            print("GID Missing")
            return []
        }
        
        let fetchRequest = NSFetchRequest(entityName: "Page")
        fetchRequest.predicate = NSPredicate(format: "gallery.gid = %@", safeGid)
        
        guard
            let safeResults = try? CoreData.managedObjectContext.executeFetchRequest(fetchRequest)
            where safeResults.count > 0
            else {
                return []
        }
        return (safeResults as? [Page]) ?? []
    }
    
}

// MARK: Instance Method
extension Gallery {
    
    func updatePagesURL(imageURLStrings: [Int: String?]) {
        self.update(imageURLStrings, type: .URL)
    }
    
    func updatePagesPath(imagePaths: [Int: String?]) {
        self.update(imagePaths, type: .Path)
    }
    
    func removePages() {
        if let safeTitle = self.title {
            let fileManager = DaiFileManager.document["Downloaded/\(safeTitle)"]
            if DaiFileManager.isExistIn(fileManager.path) {
                fileManager.delete()
            }
        }
        self.downloadType = .None
        self.pages?.removeAll()
    }
    
    func remove() {
        if !self.isNeedAlive() {
            CoreData.managedObjectContext.deleteObject(self)
        }
        CoreData.saveContext()
    }
    
    func isNeedAlive() -> Bool {
        if self.downloadType == .None && self.favoriteType == .NotFavorite {
            return false
        }
        return true
    }
    
    func clone() -> Gallery? {
        guard let safeGalleryEntity = NSEntityDescription.entityForName("Gallery", inManagedObjectContext: CoreData.managedObjectContext) else {
            print("Create Gallery Fail")
            return nil
        }
        let clone = Gallery(entity: safeGalleryEntity, insertIntoManagedObjectContext: nil)
        
        // 填入基本資料
        clone.archiver_key = self.archiver_key
        clone.category = self.category
        clone.expunged = self.expunged
        clone.filecount = self.filecount
        clone.filesize = self.filesize
        clone.gid = self.gid
        clone.posted = self.posted
        clone.rating = self.rating
        clone.thumb = self.thumb
        clone.title = self.title
        clone.title_jpn = self.title_jpn
        clone.token = self.token
        clone.torrentcount = self.torrentcount
        clone.uploader = self.uploader
        
        // 建立 tags 標籤
        if let safeTags = self.tags {
            for (_, tag) in safeTags.enumerate() {
                guard let safeTagEntity = NSEntityDescription.entityForName("Tag", inManagedObjectContext: CoreData.managedObjectContext) else {
                    print("Create Tag Fail")
                    continue
                }
                let newTag = Tag(entity: safeTagEntity, insertIntoManagedObjectContext: nil)
                newTag.name = tag.name
                newTag.gallery = clone
                clone.mutableSetValueForKey("tags").addObject(newTag)
            }
        }
        
        return clone
    }
    
}

// MARK: Gallery
class Gallery: NSManagedObject {
    
    var downloadType: DownloadType {
        get {
            if let safeDownload = self.download {
                if safeDownload.boolValue {
                    return .Download
                }
                else {
                    return .Cache
                }
            }
            else {
                return .None
            }
        }
        set {
            switch newValue {
            case .Download:
                self.download = NSNumber(bool: true)
                
            case .Cache:
                self.download = NSNumber(bool: false)
                
            case .None:
                self.download = nil
            }
        }
    }
    
    var favoriteType: FavoriteType {
        get {
            if let safeFavorite = self.favorite where safeFavorite.boolValue == true {
                return .Favorite
            }
            return .NotFavorite
        }
        set {
            switch newValue {
            case .Favorite:
                self.favorite = NSNumber(bool: true)
                
            case .NotFavorite:
                self.favorite = nil
            }
        }
    }
    
    // 如果有日文名稱的 title 則選用日文名稱
    var betterTitle: String? {
        if let safeTitleJPN = self.title_jpn where safeTitleJPN.characters.count > 0 {
            return safeTitleJPN
        }
        else if let safeTitle = self.title where safeTitle.characters.count > 0 {
            return safeTitle
        }
        return nil
    }
    
}
