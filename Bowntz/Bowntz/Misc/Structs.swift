//
//  File.swift
//  Bowntz
//
//  Created by Cagri Sahan on 3/11/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//
import UIKit
import MapKit

struct Bowntz {
    var image: UIImage
    var location: CLLocation?
    var message: String?
    var date: Date
    var authorRecordName: String
    var recipientRecordName: String
}

struct BowntzMetaData {
    var authorRecordName: String
    var recipientRecordName: String
    var date: Date
}
