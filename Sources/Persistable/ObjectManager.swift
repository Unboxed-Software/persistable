//
//  ObjectManager.swift
//  
//
//  Created by James Pacheco on 11/29/21.
//

import Foundation
import Combine

public protocol PersistedObjectManager: AnyObject {
    associatedtype Object: Persistable
    
    func save(_ object: Object, to context: Object.LookupContext) throws
    
    func load(from context: Object.LookupContext) throws -> Object
    
    func observe(at context: Object.LookupContext) throws -> AnyPublisher<Object, Never>
    
    var baseURL: URL { get }
}

public protocol QueryableObjectManager: PersistedObjectManager where Object: Queryable {
    func load(with query: Object.QueryType) throws -> [Object]
}

public extension PersistedObjectManager {
    func save(_ object: Object) throws where Object: ContextProvidingPersistable {
        try save(object, to: object.context)
    }
    
    func save(_ object: Object, to context: Object.LookupContext) throws {
        let data = try JSONEncoder().encode(object)
        let url = try Object.url(for: context)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
    
    func load(from context: Object.LookupContext) throws -> Object {
        let url = try Object.url(for: context)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Object.self, from: data)
    }
    
    func load(from context: Object.LookupContext, callback: @escaping (Result<Object, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let value: Object = try self.load(from: context)
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
}

public extension QueryableObjectManager {
    func load(with query: Object.QueryType) throws -> [Object] {
        let urls = try Object.urls(for: query)
        let data = try urls.map { try Data(contentsOf: $0) }
        let decoder = JSONDecoder()
        return try data.compactMap { try decoder.decode(Object.self, from: $0) }
    }
}

open class BaseObjectManager<T: Persistable>: PersistedObjectManager {
    
    public init() { }
    
    public func observe(at context: T.LookupContext) throws -> AnyPublisher<T, Never> where T : Persistable {
        fatalError()
    }
    
    public var baseURL: URL {
        try! FileManager.default.url(
            for: FileManager.SearchPathDirectory.applicationSupportDirectory,
            in: FileManager.SearchPathDomainMask.userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("db")
    }
}

extension BaseObjectManager: QueryableObjectManager where T: Queryable { }
