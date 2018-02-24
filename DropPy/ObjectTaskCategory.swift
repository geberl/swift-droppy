//
//  ObjectTaskCategory.swift
//  DropPy
//
//  Created by Günther Eberl on 24.02.18.
//  Copyright © 2018 Günther Eberl. All rights reserved.
//

import Cocoa

class ObjectTaskCategory: NSObject {
    let name: String
    var children = [ObjectTask]()
    
    init(name: String) {
        self.name = name
        
        let taskOne = ObjectTask(name: "First",
                                 author: "guenther@droppyapp.com",
                                 documentationUrl: "https://docs.droppyapp.com/Tasks/first")
        self.children.append(taskOne)
        
        let taskTwo = ObjectTask(name: "Second",
                                 author: "guenther@droppyapp.com",
                                 documentationUrl: "https://docs.droppyapp.com/Tasks/second")
        self.children.append(taskTwo)
        
        let taskThree = ObjectTask(name: "Third",
                                   author: "guenther@droppyapp.com",
                                   documentationUrl: "https://docs.droppyapp.com/Tasks/third")
        self.children.append(taskThree)
    }

}
