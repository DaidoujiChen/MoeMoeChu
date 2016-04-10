//
//  Tag.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/11.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation
import CoreData

extension Tag {
    
    @NSManaged var name: String?
    
    // Relationship
    @NSManaged var gallery: Gallery?
    
}

class Tag: NSManagedObject {

}
