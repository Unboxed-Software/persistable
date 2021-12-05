//
//  Persistable.swift
//
//  Created by James Pacheco on 11/11/21.
//

import Foundation

public protocol Persistable: Codable {
    associatedtype LookupContext: PersistableContextType
    associatedtype Manager: PersistedObjectManager where Manager.Object == Self
    
    static var manager: Manager { get }
    static var baseDirectory: URL { get }
    static func url(for context: LookupContext) throws -> URL
    
    static var placeholder: Self { get }
}

public extension Persistable {
    static var baseDirectory: URL {
        manager.baseURL.appendingPathComponent("\(Self.self)")
    }
    
    static func url(for context: LookupContext) throws -> URL {
        baseDirectory.appendingPathComponent(context.fileName).appendingPathExtension("json")
    }
    
    func save(to context: LookupContext) throws {
        try Self.manager.save(self, to: context)
    }
    
    static func load(from context: LookupContext) throws -> Self {
        try Self.manager.load(from: context)
    }
}

/// A Persistable that is able to provide its own context
public protocol ContextProvidingPersistable: Persistable {
    var context: LookupContext { get }
}

extension ContextProvidingPersistable {
    func save() throws {
        try Self.manager.save(self, to: context)
    }
}

/// A Persistable that has no lookup context
public protocol SingletonPersistable: ContextProvidingPersistable where LookupContext == EmptyContext {
    
    static var context: LookupContext { get }
    
    static func load() throws -> Self
}

public extension SingletonPersistable {
    var context: LookupContext {
        Self.context
    }
    
    static var context: LookupContext {
        return .shared
    }
    
    static func load() throws -> Self {
        return try manager.load(from: context)
    }
}

public extension ContextProvidingPersistable where LookupContext == EmptyContext {
    var context: LookupContext { .shared }
}

public struct EmptyContext: PersistableContextType {
    public static let shared = EmptyContext()
    public var fileName = "default"
    public init(fileName: String) { }
    public init() { }
}


// MARK: Load callback

public extension Persistable {
    static func clear(with context: LookupContext) throws {
        let url = try Self.url(for: context)
        try FileManager.default.removeItem(at: url)
    }
    
    static func clearAll() throws {
        try FileManager.default.removeItem(at: baseDirectory)
    }
}
