//
//  DownloadObserverIdentify.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/19.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation

func ==(lhs: ObserverIdentify, rhs: ObserverIdentify) -> Bool {
    return (lhs.gid == rhs.gid) && (lhs.uniqueKey == rhs.uniqueKey)
}

// MARK: Hashable
extension ObserverIdentify: Hashable {
    
    var hashValue: Int {
        get {
            return "\(self.gid)-\(self.uniqueKey)".hashValue
        }
    }
    
}

// MARK: ObserverIdentify
struct ObserverIdentify {
    
    var gid: String = ""
    var uniqueKey: String = ""
    
    init(gid: String, uniqueKey: String) {
        self.gid = gid
        self.uniqueKey = uniqueKey
    }
    
}
