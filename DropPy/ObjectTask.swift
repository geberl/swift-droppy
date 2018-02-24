//
//  ObjectTask.swift
//  DropPy
//
//  Created by Günther Eberl on 24.02.18.
//  Copyright © 2018 Günther Eberl. All rights reserved.
//

import Cocoa

class ObjectTask: NSObject {
    let name: String
    let author: String
    let documentationUrl: String
    
    init(name: String, author: String, documentationUrl: String) {
        self.name = name
        self.author = author
        self.documentationUrl = documentationUrl
    }
}

