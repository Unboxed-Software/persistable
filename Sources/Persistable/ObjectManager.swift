//
//  ObjectManager.swift
//  
//
//  Created by James Pacheco on 11/29/21.
//

import Foundation
import Combine

public protocol ObjectManager: BaseObjectManager {
    func save<T: Persistable>(_ object: T, to context: T.LookupContext) throws
    
    func load<T: Persistable>(from context: T.LookupContext) throws -> T
    
    func observe<T: Persistable>(at context: T.LookupContext) throws -> AnyPublisher<T, Never>
    
    func load<T: Queryable>(with query: T.QueryType) throws -> [T]
    
    static var `default`: ObjectManager { get }
    
    var baseURL: URL { get }
}

public extension ObjectManager {
    func save<T: ContextProvidingPersistable>(_ object: T) throws {
        try save(object, to: object.context)
    }
    
    func save<T: Persistable>(_ object: T, to context: T.LookupContext) throws {
        let data = try JSONEncoder().encode(object)
        let url = try T.url(for: context)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
    
    func load<T: Persistable>(from context: T.LookupContext) throws -> T {
        let url = try T.url(for: context)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func load<T: Persistable>(from context: T.LookupContext, callback: @escaping (Result<T, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let value: T = try self.load(from: context)
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
    
    func load<T: Queryable>(with query: T.QueryType) throws -> [T] {
        let urls = try T.urls(for: query)
        let data = try urls.map { try Data(contentsOf: $0) }
        let decoder = JSONDecoder()
        return try data.compactMap { try decoder.decode(T.self, from: $0) }
    }
    
    
}

open class BaseObjectManager: ObjectManager {
    public static let `default`: ObjectManager = BaseObjectManager()
    
    public func observe<T>(at context: T.LookupContext) throws -> AnyPublisher<T, Never> where T : Persistable {
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

// Persistable should have (with empty default implementation):
// func beforeSave()
// func afterSave()
// func beforeLoad()
// func afterLoad()
