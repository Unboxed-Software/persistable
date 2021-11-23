//
//  FileMonitor.swift
//  
//
//  Created by James Pacheco on 11/20/21.
//

import Foundation

public class FileMonitor: ObservableObject {
    /// A file descriptor for the monitored directory.
    private var monitoredFolderFileDescriptor: CInt = -1
    /// A dispatch source to monitor a file descriptor created from the directory.
    private var folderMonitorSource: DispatchSourceFileSystemObject?
    /// A dispatch queue used for sending file changes in the directory.
    private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    deinit {
        stopMonitoring()
    }
    
    public func startMonitoring() throws {
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil) {
                throw NSError()
            }
        }
        
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)
        
        // Define a dispatch source monitoring the folder for additions, deletions, and renamings.
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFolderFileDescriptor, eventMask: .write, queue: folderMonitorQueue)
        
        // Define the block to call when a file change is detected.
        folderMonitorSource?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
        
        // Define a cancel handler to ensure the directory is closed when the source is cancelled.
        folderMonitorSource?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.monitoredFolderFileDescriptor)
            self.monitoredFolderFileDescriptor = -1
            self.folderMonitorSource = nil
        }
        
        // Start monitoring the directory via the source.
        folderMonitorSource?.resume()
    }
    
    public func stopMonitoring() {
        folderMonitorSource?.cancel()
    }
}
