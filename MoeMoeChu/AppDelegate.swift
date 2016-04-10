//
//  AppDelegate.swift
//  MoeMoeChu
//
//  Created by DaidoujiChen on 2016/4/10.
//  Copyright © 2016年 ChilunChen. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationWillBecomeActive(notification: NSNotification) {
        if var safePasteboardItems = NSPasteboard.generalPasteboard().pasteboardItems {
            for item in safePasteboardItems {
                if let safeURLString = item.stringForType(NSPasteboardTypeString) where safeURLString.containsString("http://g.e-hentai.org/") {
                    NSNotificationCenter.defaultCenter().postNotificationName("MoeMoeChuInPasteboardNotification", object: safeURLString)
                    if let safeIndex = safePasteboardItems.indexOf(item) {
                        safePasteboardItems.removeAtIndex(safeIndex)
                    }
                    break
                }
            }
        }
    }
    
}
