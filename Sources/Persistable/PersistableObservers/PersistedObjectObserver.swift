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
    
    
    /// This value box is used to share values between mutliple PersistedObjectObservers instances within the app that point to the same data.
    /// A weak refrence to it is stored in the above fileprivate weakStore.
    class ValueBox: ObservableObject {
                
        var value: T {
            willSet {
                self.objectWillChange.send()
            }
        }
        
        let context: T.LookupContext?
        
        init(_ value: T, for context: T.LookupContext?) {
            self.value = value
            self.context = context
        }
        
        static func new(_ value: T, for context: T.LookupContext) -> ValueBox {

            if let url = try? T.url(for: context) {
                if let box = weakStore[url]?.value as? ValueBox, box.context == context {

                    box.value = value
                    return box
                } else {

                    let box = ValueBox(value, for: context)
                    weakStore[url] = WeakAnyObject(value: box)
                    return box
                }
            } else {
                // TODO: Log warning
                return ValueBox(value, for: context)
            }
        }
        
        static func box(for context: T.LookupContext) -> ValueBox? {
            if let url = try? T.url(for: context) {
                if let box = weakStore[url]?.value as? ValueBox, box.context == context {
                    return box
                }
            }
            return nil
        }
    }
    
    public var value: T {
        set {
            self._value.value = newValue
            self.state = .changes(id: UUID())
        }
        
        get {
            self._value.value
        }
    }
    
    @Published
    public var readError: Error?
    
    @Published
    public var writeError: Error?
    
    public var context: T.LookupContext? {
        get {
            self._value.context
        }
        
        set {
            // Context has not changed
            guard _value.context != newValue else {
                return
            }
            
            guard let context = newValue else {
                self._value = ValueBox(.placeholder, for: nil)
                self.state = .placeholder
                return
            }
            
            self.state = .placeholder
            
            // Check if we already have an inmemory box for this
            guard let box = ValueBox.box(for: context) else {
                self.load(context: context)
                return
            }
            self._value = box
            self.state = .unmodified
        }
    }
    
    private var _valueObserver: AnyCancellable?
    private var _value: ValueBox {
        didSet {
            _valueObserver = _value.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
    }
    
    @Published
    public var state: State
    
    @Published
    public var loading: Bool = false
    
    public enum State: Equatable {
        case changes(id: UUID)
        case placeholder
        case unmodified
    }
    
    private var changeID: UUID? {
        switch self.state {
        case .changes(let id):
            return id
        default:
            return nil
        }
    }
    
    public init(_ value: T, at context: T.LookupContext?, hasChanges: Bool = false) {
        if let context = context {
            self._value = .new(value, for: context)
        } else {
            // No context so cant use shared box
            self._value = ValueBox(value, for: context)
        }
        
        if hasChanges {
            self.state = .changes(id: UUID())
        } else {
            self.state = .placeholder
        }
    }
    
    public func set(value: T, forContext context: T.LookupContext) {
        
    }
    
    public func save(force: Bool = false) {
        guard let context = self.context else {
            return
        }
        
        let changeID: UUID? = self.changeID
        
        if !force && changeID == nil  {
            return
        }
        
        let value = self.value
        queue.async { [weak self] in
            do {
                try value.save(to: context)
            } catch {
                print(error)
                // TODO set erro flag
                return
            }
            
            DispatchQueue.main.async {
                if changeID == nil || self?.changeID == changeID {
                    // all changes have beens saved
                    self?.state = .unmodified
                }
            }
        }
    }
}


public extension PersistedObjectObserver where T.LookupContext == EmptyContext {
    convenience init(_ value: T, hasChanges: Bool = false) {
        self.init(value, at: .shared, hasChanges: hasChanges)
    }
}

public extension PersistedObjectObserver {
    convenience init(context: T.LookupContext) {
        self.init(T.placeholder, at: context)
    }
    
    convenience init() {
        self.init(T.placeholder, at: nil)
    }
}

public extension PersistedObjectObserver {
    func load(
        context: T.LookupContext,
        force: Bool = false
    ) {
        loading = true
        queue.async { [weak self] in
            guard let value = try? T.load(from: context) else {
                DispatchQueue.main.async {
                    self?.loading = false
                }
                return
            }
            
            DispatchQueue.main.async {
                
                guard self?.changeID == nil || force || context != self?.context else {
                    self?.loading = false
                    return
                }
                
                // If the context is the same
                if context == self?.context {
                    self?._value.value = value
                } else {
                    self?._value = .new(value, for: context)
                }
                                
                self?.state = .unmodified
                self?.loading = false
            }
        }
    }
}

