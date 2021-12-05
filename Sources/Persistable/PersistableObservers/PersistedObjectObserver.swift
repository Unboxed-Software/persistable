//
//  PersistedObjectObserver.swift
//
//  Created by James Pacheco on 11/11/21.
//

import Foundation

import Combine

fileprivate let queue = DispatchQueue(label: "PersistedObjectObserver")

struct WeakAnyObject {
    weak var value: AnyObject?
}

// TODO: this will lead URLs as they will not get cleaned up when the WeakAnyObjects are de-alocated.
fileprivate var weakStore: [URL: WeakAnyObject] = [:]

public class PersistedObjectObserver<T: Persistable>: ObservableObject {
    @Published
    public var value: T = T.placeholder
    
    @Published
    public var readError: Error?
    
    public var context: T.LookupContext? {
        didSet {
            if let context = context {
                load(context: context)
                replaceFileMonitor(for: context)
            } else {
                fileMonitor = nil
            }
        }
    }
    
    @Published
    public var state: State = .placeholder
    
    @Published
    public var loading: Bool = false
    
    public enum State: Equatable {
        case placeholder
        case unmodified
    }
    
    private var _valueObserver: AnyCancellable?
    
    private var fileMonitor: FileMonitor?
    
    public init(at context: T.LookupContext? = nil) {
        self.context = context
        
        guard let context = context else { return }
        replaceFileMonitor(for: context)
    }
    
    func replaceFileMonitor(for context: T.LookupContext) {
        guard let url = try? T.url(for: context) else { return }
        
        let fileMonitor: FileMonitor
        
        if let monitor = weakStore[url]?.value as? FileMonitor {
            fileMonitor = monitor
        } else {
            fileMonitor = FileMonitor(url: url)
            weakStore[url] = WeakAnyObject(value: fileMonitor)
        }
        
        if let m = self.fileMonitor {
            m.stopMonitoring()
        }
        
        self.fileMonitor = fileMonitor
        _valueObserver = fileMonitor.objectWillChange.sink { [weak self] _ in
            self?.load(context: context)
        }
        
        try? fileMonitor.startMonitoring()
    }
}

public extension PersistedObjectObserver where T.LookupContext == EmptyContext {
    convenience init() {
        self.init(at: .shared)
    }
}

public extension PersistedObjectObserver {
    func load(
        context: T.LookupContext,
        force: Bool = false
    ) {
        loading = true
        queue.async { [weak self] in
            guard let self = self,
                  context == self.context,
                  let value = try? T.load(from: context) else {
                DispatchQueue.main.async {
                    self?.loading = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self.value = value
                self.state = .unmodified
                self.loading = false
            }
        }
    }
}

