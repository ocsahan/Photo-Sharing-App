//
//  NotificationViewController.swift
//  Bowntz
//
//  Created by Cagri Sahan on 3/13/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class NotificationViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var senderLabel: UILabel!
    
    // MARK: Variables
    var bowntz: Bowntz?
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Swipe up to dismiss
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissView))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        // Get the name of the sender
        let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<User>(entityName: "User")
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "recordName = %@", bowntz!.authorRecordName)
        let results = try! context?.fetch(fetchRequest)
        let sender = results?.first
        
        if bowntz?.authorRecordName == bowntz?.recipientRecordName {
            senderLabel.text = "From: Me"
        }
        else {
            let firstName = sender?.value(forKey: "firstName")
            let lastName = sender?.value(forKey: "lastName")
            senderLabel.text = "From: \(firstName!) \(lastName!)"
        }
        
        // Do any additional setup after loading the view.
        imageView.image = bowntz?.image
        
        // Update date label
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: (bowntz?.date)!)
        dateLabel.text = dateString
        
        // Find city name
        if let location = bowntz?.location {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location, completionHandler: { [unowned self] placemarks, error in
                guard error == nil else { return }
                
                print("Geocoding")
                self.locationLabel.text = "Location Unknown"
                let placemark = placemarks?.first
                
                if let city = placemark?.locality {
                    if let neighborhood = placemark?.subLocality {
                        self.locationLabel.text = "\(neighborhood), \(city)"
                    }
                    else { self.locationLabel.text = city}
                }
                else if let country = placemark?.country {
                    self.locationLabel.text = country
                }
            })
        }
        
        if let message = bowntz?.message {
            messageLabel.text = message
        }
        else {
            messageLabel.isHidden = true
        }
    }
    
    // MARK: Functions
    @objc func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
}
