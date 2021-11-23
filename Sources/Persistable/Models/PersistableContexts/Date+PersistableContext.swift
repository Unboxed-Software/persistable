//
//  Date+PersistableContext.swift
//  
//
//  Created by James Pacheco on 11/21/21.
//

import Foundation

extension Date: PersistableContextType {
    public init(fileName: String) {
        self = try! Date(fileName, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }
    
    public var fileName: String {
        self.ISO8601Format(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }
}
