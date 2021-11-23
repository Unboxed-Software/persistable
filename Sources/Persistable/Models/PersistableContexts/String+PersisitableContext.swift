//
//  String+PersistableContext.swift
//  
//
//  Created by James Pacheco on 11/21/21.
//

import Foundation

extension String: PersistableContextType {
    public var fileName: String {
        return self
    }
    
    public init(fileName: String) {
        self = fileName
    }
}
