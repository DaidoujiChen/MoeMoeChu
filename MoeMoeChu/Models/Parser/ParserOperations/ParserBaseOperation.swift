//
//  ParserBaseOperation.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/8.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation

// for Dictionary operator
func += <KeyType, ValueType> (inout left: [KeyType: ValueType], right: [KeyType: ValueType]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

// MARK: ParserBaseOperation
class ParserBaseOperation: BaseOperation {

    var targetURL: NSURL?
    var completion: ((result: [Int: String?]) -> Void)?
    var retryCount: Int = 0
    
}
