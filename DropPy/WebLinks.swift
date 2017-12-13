//
//  WebLinks.swift
//  DropPy
//
//  Created by Günther Eberl on 07.10.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Foundation
import Cocoa
import os.log


struct droppyappUrls {
    static var main:             URL? = URL(string: "https://droppyapp.com/")
    
    static var versionJson:      URL? = URL(string: "https://download.droppyapp.com/version.json")
    
    static var docs:             URL? = URL(string: "https://docs.droppyapp.com/")
    static var privacy:          URL? = URL(string: "https://docs.droppyapp.com/privacy/")
    static var releaseNotes:     URL? = URL(string: "https://docs.droppyapp.com/release-notes/")
    static var support:          URL? = URL(string: "https://docs.droppyapp.com/support/")
    static var prefsGeneral:     URL? = URL(string: "https://docs.droppyapp.com/preferences/general/")
    static var prefsInterpreter: URL? = URL(string: "https://docs.droppyapp.com/preferences/interpreter/")
    static var prefsEditor:      URL? = URL(string: "https://docs.droppyapp.com/preferences/editor/")
    static var prefsWorkspace:   URL? = URL(string: "https://docs.droppyapp.com/preferences/workspace/")
}


struct servicesUrls {
    static var guentherMail:     URL? = URL(string: "mailto:guenther@droppyapp.com")
    static var twitter:          URL? = URL(string: "https://twitter.com/eberl_se")
    static var keybase:          URL? = URL(string: "https://keybase.io/guenther")
    static var githubRun:        URL? = URL(string: "https://github.com/geberl/droppy-run/")
    static var githubWorkspace:  URL? = URL(string: "https://github.com/geberl/droppy-workspace/")
}


func openWebsite(webUrl: URL?) {
    if let url = webUrl, NSWorkspace.shared.open(url) {
        os_log("Website openened: %@", log: logUi, type: .debug, webUrl!.absoluteString)
    }
}
