//
//  PersistableContext.swift
//  
//
//  Created by James Pacheco on 11/21/21.
//

import Foundation

public protocol PersistableContextType: Codable, Equatable {
    init(fileName: String)
    var fileName: String { get }
}

public extension PersistableContextType {
    init(_ fileName: String) {
        self.init(fileName: fileName)
    }
}
