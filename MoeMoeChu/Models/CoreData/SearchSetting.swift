//
//  SearchSetting.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/2/4.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation
import CoreData

extension SearchSetting {
    
    @NSManaged var doujinshi: NSNumber
    @NSManaged var nonH: NSNumber
    @NSManaged var manga: NSNumber
    @NSManaged var imageSet: NSNumber
    @NSManaged var artistCG: NSNumber
    @NSManaged var cosplay: NSNumber
    @NSManaged var gameCG: NSNumber
    @NSManaged var asianPorn: NSNumber
    @NSManaged var western: NSNumber
    @NSManaged var misc: NSNumber
    @NSManaged var searchText: String?
    
}

class SearchSetting: NSManagedObject {
    
    // 唯一的一個 setting
    class func shared() -> SearchSetting {
        let fetchRequest = NSFetchRequest(entityName: "SearchSetting")
        if let safeResults = try? CoreData.managedObjectContext.executeFetchRequest(fetchRequest) where safeResults.count > 0 {
            return safeResults.first as! SearchSetting
        }
        else {
            guard let safeSearchSettingEntity = NSEntityDescription.entityForName("SearchSetting", inManagedObjectContext: CoreData.managedObjectContext) else {
                print("Create safeGalleryEntity Fail, 到這邊就世界毀滅的吧...")
                return SearchSetting()
            }
            let newSearchSetting = SearchSetting(entity: safeSearchSettingEntity, insertIntoManagedObjectContext: CoreData.managedObjectContext)
            CoreData.saveContext()
            return newSearchSetting
        }
    }
    
    class func searchString() -> String {
        let shared = self.shared()
        let safeUTF8String = shared.searchText?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) ?? ""
        return "f_doujinshi=\(shared.doujinshi.intValue)&f_manga=\(shared.manga.intValue)&f_artistcg=\(shared.artistCG.intValue)&f_gamecg=\(shared.gameCG.intValue)&f_western=\(shared.western.intValue)&f_non-h=\(shared.nonH.intValue)&f_imageset=\(shared.imageSet.intValue)&f_cosplay=\(shared.cosplay.intValue)&f_asianporn=\(shared.asianPorn.intValue)&f_misc=\(shared.misc.intValue)&f_search=\(safeUTF8String)&f_apply=Apply+Filter&"
    }
    
    class func save() {
        CoreData.saveContext()
    }

}
