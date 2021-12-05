//
//  Int+PersistableContext.swift
//  
//
//  Created by James Pacheco on 12/3/21.
//

import Foundation

extension Int: PersistableContextType {
    public var fileName: String {
        "\(self)"
    }
    
    public init(fileName: String) {
        self = Int(fileName)!
    }
}
