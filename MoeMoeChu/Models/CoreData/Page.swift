//
//  Page.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/7.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation
import CoreData

extension Page {
    
    @NSManaged var index: NSNumber?
    @NSManaged var localPath: String?
    @NSManaged var originalURLPath: String?
    
    // Relationship
    @NSManaged var gallery: Gallery?
    
}

class Page: NSManagedObject {
    
}
