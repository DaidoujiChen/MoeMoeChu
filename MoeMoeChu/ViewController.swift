//
//  ViewController.swift
//  MoeMoeChu
//
//  Created by DaidoujiChen on 2016/4/10.
//  Copyright © 2016年 ChilunChen. All rights reserved.
//

import Cocoa

// MARK: NSTableViewDataSource
extension ViewController: NSTableViewDataSource {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if let safeTimer = self.timer where Downloader.queue.operations.count == 0 {
            safeTimer.invalidate()
        }
        return Downloader.queue.operations.count
    }
    
}

// MARK: NSTableViewDelegate
extension ViewController: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let safeTableColumn = tableColumn {
            let cell = tableView.makeViewWithIdentifier(safeTableColumn.identifier, owner: self) as! NSTableCellView
            
            if safeTableColumn.identifier == "NSTableNameCellView" {
                if let operation = Downloader.queue.operations[row] as? DownloaderGalleryOperation {
                    cell.textField?.stringValue = operation.gallery?.betterTitle ?? ""
                }
            }
            else {
                if let operation = Downloader.queue.operations[row] as? DownloaderGalleryOperation {
                    var percentString: String
                    if operation.totalCount == 0 {
                        percentString = "等待下載中"
                    }
                    else {
                        percentString = String(format: "%.0f%%", (Float(operation.currentCount) / Float(operation.totalCount)) * 100)
                    }
                    cell.textField?.stringValue = "\(operation.currentCount) / \(operation.totalCount) - \(percentString)"
                }
            }
            
            return cell
        }
        return nil
    }
    
}

// MARK: IBAction
extension ViewController {
    
    @IBAction func onStoragePathAction(sender: AnyObject) {
        self.defaultPathPanel { [weak self] (result, panel) -> Void in
            guard
                let safeSelf = self,
                safeURL = panel.URL
                where result == NSFileHandlingPanelOKButton
                else {
                    print("Source Path Set Fail")
                    return
            }
            
            safeSelf.storagePathControl.URL = safeURL
        }
    }
    
    @IBAction func onDownloadPress(sender: AnyObject) {
        let downloadPath = self.downloadPath.stringValue
        self.downloadPath.stringValue = ""
        if let safeLocalPath = self.storagePathControl.URL {
            Parser.specialGalleriesBy([downloadPath]) { [weak self] (status, galleries) -> Void in
                guard let safeSelf = self else {
                    return
                }
                
                if let safeGalleries = galleries where safeGalleries.count > 0 {
                    if let newGallery = Gallery.add(safeGalleries[0]) {
                        safeSelf.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: safeSelf.tableView, selector: "reloadData", userInfo: nil, repeats: true)
                        newGallery.downloadType = .Download
                        Downloader.download(newGallery, localPath: safeLocalPath) { (gallery) -> Void in
                            gallery.downloadType = .None
                            gallery.remove()
                        }
                    }
                }
            }
        }
    }
    
}

// MARK: Private Instance Method
extension ViewController {
    
    // 建立一個資料夾選擇器
    private func defaultPathPanel(handler: (Int, NSOpenPanel) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.resolvesAliases = true
        panel.title = "選擇下載路徑"
        panel.prompt = "確定"
        panel.beginWithCompletionHandler { (result) -> Void in
            handler(result, panel)
        }
    }
    
    // 接收剪貼簿來的連結
    dynamic func urlStringFromPasteboard(notification: NSNotification) {
        self.downloadPath.stringValue = (notification.object as? String) ?? ""
    }
    
}

class ViewController: NSViewController {
    
    @IBOutlet weak var downloadPath: NSTextField!
    @IBOutlet weak var storagePathControl: NSPathControl!
    @IBOutlet weak var tableView: NSTableView!
    private var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "urlStringFromPasteboard:", name: "MoeMoeChuInPasteboardNotification", object: nil)
    }
    
}

