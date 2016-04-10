//
//  CustomRecord.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/7.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation
import CoreData

extension CustomRecord {
    
    @NSManaged var customCategory: String?
    @NSManaged var lastTimePageIndex: NSNumber?
    
}

class CustomRecord: NSManagedObject {
    
}
