//
//  Persistable.swift
//
//  Created by James Pacheco on 11/11/21.
//

import Foundation

public protocol Persistable: Codable {
    associatedtype LookupContext: PersistableContextType
    
    static var baseDirectory: URL { get }
    static func url(for context: LookupContext) throws -> URL
    
    func save(to context: LookupContext) throws
    static func load(from context: LookupContext) throws -> Self
    static func load(from url: URL) throws -> Self
    
    static var placeholder: Self { get }
}

public extension Persistable {
    func save(to context: LookupContext) throws {
        let data = try JSONEncoder().encode(self)
        let url = try Self.url(for: context)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
    
    static func load(from context: LookupContext) throws -> Self {
        let url = try Self.url(for: context)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Self.self, from: data)
    }
    
    static func load(from url: URL) throws -> Self {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Self.self, from: data)
    }
    
    static var baseURL: URL {
        try! FileManager.default.url(
            for: FileManager.SearchPathDirectory.applicationSupportDirectory,
            in: FileManager.SearchPathDomainMask.userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("db")
    }
    
    static var baseDirectory: URL {
        baseURL.appendingPathComponent("\(Self.self)")
    }
    
    static func url(for context: LookupContext) throws -> URL {
        baseDirectory.appendingPathComponent(context.fileName).appendingPathExtension("json")
    }
}

/// A Persistable that is able to provide its own context
public protocol ContextProvidingPersistable: Persistable {
    var context: LookupContext { get }
    
    func save() throws
}

public extension ContextProvidingPersistable {
    func save() throws {
        try save(to: self.context)
    }
}


/// A Persistable that has no lookup context
public protocol SingletonPersistable: ContextProvidingPersistable {
    static var context: LookupContext { get }
    
    static func load() throws -> Self
}

public extension SingletonPersistable {
    var context: LookupContext {
        Self.context
    }
    
    static func load() throws -> Self {
        let url = try Self.url(for: Self.context)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Self.self, from: data)
    }
}



// MARK: Handle Context Empty


public extension Persistable where LookupContext == EmptyContext {
    func save() throws {
        let data = try JSONEncoder().encode(self)
        let url = try Self.url(for: .shared )
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
    
    static func load() throws -> Self {
        let url = try Self.url(for: .shared)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Self.self, from: data)
    }
}

public extension ContextProvidingPersistable where LookupContext == EmptyContext {
    var context: LookupContext { .shared }
}

public extension SingletonPersistable where LookupContext == EmptyContext {
    static var context: LookupContext { .shared }
}

public struct EmptyContext: PersistableContextType {
    public static let shared = EmptyContext()
    public var fileName = "default"
    public init(fileName: String) { }
    public init() { }
}


// MARK: Load callback

public extension Persistable {
    static func load(from context: LookupContext, callback: @escaping (Result<Self, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let value = try Self.load(from: context)
                DispatchQueue.main.async {
                    callback(.success(value))
                }
            } catch {
                DispatchQueue.main.async {
                    callback(.failure(error))
                }
            }
        }
    }
    
    static func clear(with context: LookupContext) throws {
        let url = try Self.url(for: context)
        try FileManager.default.removeItem(at: url)
    }
}
