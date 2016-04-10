//
//  BaseOperation.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/11.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation

// MARK: Instance Method
extension BaseOperation {
    
    func operationStart() {
        self.executing = true
        self.finished = false
    }
    
    func operationFinish() {
        self.executing = false
        self.finished = true
    }
    
    override func start() {
        if (self.cancelled) {
            self.operationFinish()
            return
        }
        self.operationStart()
    }
    
}

// MARK: BaseOperation
class BaseOperation: NSOperation {
    
    private var _executing: Bool = false
    override var executing: Bool {
        get {
            return _executing
        }
        set {
            if _executing != newValue {
                willChangeValueForKey("isExecuting")
                _executing = newValue
                didChangeValueForKey("isExecuting")
            }
        }
    }
    
    private var _finished: Bool = false;
    override var finished: Bool {
        get {
            return _finished
        }
        set {
            if _finished != newValue {
                willChangeValueForKey("isFinished")
                _finished = newValue
                didChangeValueForKey("isFinished")
            }
        }
    }
    
    private var _asynchronous: Bool = true
    
    lazy var session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 20
        let session = NSURLSession(configuration: configuration)
        return session
    }()
    
}