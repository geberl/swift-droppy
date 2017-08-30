//
//  pythonExecutor.swift
//  DropPy
//
//  Created by Günther Eberl on 30.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class PythonExecutor: NSObject {
    
    override init() {
        log.debug("pythonExecutor init started")
        
        // Simple workaround to get delayed execution with no beachball.
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
            log.debug("pythonExecutor init finished")
            NotificationCenter.default.post(name: Notification.Name("executionFinished"), object: nil)
        })
        
        // This locks up your program, beachball appears.
        //sleep(10)

    }

}
