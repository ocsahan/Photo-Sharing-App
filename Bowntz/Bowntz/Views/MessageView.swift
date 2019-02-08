//
//  MessageView.swift
//  Bowntz
//
//  Created by Cagri Sahan on 3/12/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import UIKit

@IBDesignable class MessageView: UIView {
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
}

