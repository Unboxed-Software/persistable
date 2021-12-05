//
//  QueryableObjectsObserver.swift
//
//  Created by James Pacheco on 11/12/21.
//

import Foundation
import SwiftUI
import Combine

fileprivate var weakStore: [URL: WeakAnyObject] = [:]

open class QueryableObjectsObserver<T: Queryable>: ObservableObject {

    @Published
    public var value: [T] = [T.placeholder]

    public var query: T.QueryType? {
        didSet {
            load()
        }
    }
    
    private var _valueObserver: AnyCancellable?
    
    private var folderMonitor: FolderMonitor {
        didSet {
            _valueObserver = folderMonitor.objectWillChange.sink { [weak self] _ in
                self?.load()
            }
            
            oldValue.stopMonitoring()
            folderMonitor.startMonitoring()
        }
    }
    
    private var isFirstLoad = true
    
    @Published
    public var state: State = .placeholder
    
    @Published
    public var loading: Bool = false
    
    @Published
    public var readError: Error?
    
    public enum State: Equatable {
        case placeholder
        case unmodified
    }
    
    public init(for query: T.QueryType? = nil) {
        self.query = query
        
        let folderMonitor: FolderMonitor
        
        if let monitor = weakStore[T.baseDirectory]?.value as? FolderMonitor {
            folderMonitor = monitor
        } else {
            folderMonitor = FolderMonitor(url: T.baseDirectory)
            weakStore[T.baseDirectory] = WeakAnyObject(value: folderMonitor)
        }
        
        self.folderMonitor = folderMonitor
        _valueObserver = folderMonitor.objectWillChange.sink { [weak self] _ in
            self?.load()
        }
        folderMonitor.startMonitoring()
    }
    
    public func load() {
        loading = true
        if isFirstLoad {
            firstLoad()
        }
        
        if let query = query {
            do {
                state = .unmodified
                value = try T.load(with: query)
            } catch {
                value = [T.placeholder]
                state = .placeholder
            }
        } else {
            value = [T.placeholder]
            state = .placeholder
        }
        
        loading = false
    }

    open func firstLoad() {
        isFirstLoad = false
    }
}
