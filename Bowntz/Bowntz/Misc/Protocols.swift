//
//  TextInputDelegate.swift
//  Bowntz
//
//  Created by Cagri Sahan on 3/12/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

protocol TextInputPassable: class {
    func passMessageStringAndSubmit(_ message: String)
}

protocol Refreshable: class {
    func refreshBowntz()
}

protocol Messenger: class {
    func passMessage(from: String, to: String)
}
