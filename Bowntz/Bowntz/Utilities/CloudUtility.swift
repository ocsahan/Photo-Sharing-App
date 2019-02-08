//
//  CloudUtility.swift
//  Bowntz
//
//  Created by Cagri Sahan on 6/5/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import CloudKit
import Foundation
import UIKit
import UserNotifications

class CloudUtility {
    
    // MARK: Variables
    static let shared = CloudUtility()
    let container: CKContainer
    let publicDB: CKDatabase
    lazy var userRecordName: String = ""
    
    // MARK: Functions
    private init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        
        let defaults = UserDefaults.standard
        if let userRecordName = defaults.string(forKey: "RecordName") {
            self.userRecordName = userRecordName
        }
    }
    
    func addEntry(_ entry: Bowntz, completion: @escaping (CKRecord?, Error?) -> Void) {
        let record = CKRecord(recordType: "Bowntz")
        let fileManager = FileManager()
        let imageURL = fileManager.temporaryDirectory.appendingPathComponent(record.recordID.recordName)
        let data = UIImageJPEGRepresentation(entry.image, 0.5)
        try! data?.write(to: imageURL)
        
        record["date"] = entry.date as NSDate
        record["image"] = CKAsset(fileURL: imageURL)
        record["recipient"] = entry.recipientRecordName as NSString
        record["sender"] = entry.authorRecordName as NSString
        
        if let location = entry.location {
            record["location"] = location
        }
        if let message = entry.message {
            record["message"] = message as NSString
        }
        
        let publicDB = container.publicCloudDatabase
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        publicDB.save(record) { (record, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            completion(record, error)
        }
    }
    
    func fetchSingleRecordMeta(recordID: CKRecordID, completion: @escaping (BowntzMetaData) -> Void) {
        print("Will fetch metadata")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        publicDB.fetch(withRecordID: recordID, completionHandler: { (record, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            print("Received recordID")
            guard error == nil else { print(error!); return }
            guard let record = record else { print("No record found"); return }
            
            let author = record["sender"] as! String
            let date = record["date"] as! Date
            let recipient = record["recipient"] as! String
            let meta = BowntzMetaData(authorRecordName: author, recipientRecordName: recipient, date: date)
            
            print("Created Metadata")
            completion(meta)
        })
    }
    
    func fetchSingleRecordByName(recordName: String, completion: @escaping (Bowntz) -> Void) {
        let recordID = CKRecordID(recordName: recordName)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        publicDB.fetch(withRecordID: recordID) { (record, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            guard error == nil else { print(error!); return }
            guard let record = record else { print("No record found"); return }
            
            let date = record["date"] as! Date
            let recipient = record["recipient"] as! String
            let sender = record["sender"] as! String
            
            let imageURL = record["image"] as! CKAsset
            let imageData = try! Data(contentsOf: imageURL.fileURL)
            let image = UIImage(data: imageData)
            
            var location: CLLocation? = nil
            var message: String? = nil
            
            if let locationOpt = record["location"] as? CLLocation {
                location = locationOpt
            }
            
            if let messageOpt = record["message"] as? String {
                message = messageOpt
            }
            
            let bowntz = Bowntz(image: image!, location: location, message: message, date: date, authorRecordName: sender, recipientRecordName: recipient)
            
            completion(bowntz)
        }
    }
    
    func getRandomBowntzID(completion: @escaping (CKRecordID) -> Void) {
        let predicate = NSPredicate(format: "recipient = %@", userRecordName)
        let query = CKQuery(recordType: "Bowntz", predicate: predicate)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        publicDB.perform(query, inZoneWith: nil, completionHandler: { (records, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            guard error == nil else { print(error!); return }
            guard let records = records else { print("No record found"); return }
            guard records.count > 0 else { print("No bowntz taken yet"); return }
            
            let randomIndex = Int(arc4random_uniform(UInt32(records.count)))
            let record = records[randomIndex]
            let recordID = record.recordID
            completion(recordID)
        })
    }
    
    func registerForSubscriptions() {
        let identifier = "newEntry"
        let info = CKNotificationInfo()
        info.shouldSendContentAvailable = true
        info.desiredKeys = []
        let predicate = NSPredicate(format: "recipient = %@", userRecordName)
        let subscription = CKQuerySubscription(recordType: "Bowntz", predicate: predicate, subscriptionID: identifier, options: [.firesOnRecordCreation])
        subscription.notificationInfo = info
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        publicDB.save(subscription, completionHandler: { record, error in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            guard error == nil else { print("Could not add subscription \(String(describing: error))"); return }
            print("subscription added!")
        })
    }
    
    func scheduleBowntz(recordID: CKRecordID, completion: @escaping () -> Void) {
        print("Begin scheduling")
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        fetchSingleRecordMeta(recordID: recordID) { meta in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            print("Bowntz metadata received")
            let date = meta.date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            let dateString = dateFormatter.string(from: date)
            
            let content = UNMutableNotificationContent()
            var timeInterval: TimeInterval
            
            let author = meta.authorRecordName
            let recipient = meta.recipientRecordName
            
            // If bounce is not coming from a friend but from a different device
            if author == recipient {
                content.title = "Bowntz Back!"
                content.body = "A memory from \(dateString)"
                
                // Also Calculate the time of next notification
                // Immediately if bounce is from friend, delayed if to self
                // You might find it useful to change this line for grading!
                timeInterval = TimeInterval(arc4random_uniform(UInt32(604800))) + 1
            }
                // If bounce is coming from a friend
            else {
                content.title = "Bowntz!"
                content.body = "A friend sent you a Bowntz!"
                timeInterval = 1
            }
            
            print("Will schedule bowntz")
            content.sound = UNNotificationSound.default()
            content.userInfo = ["recordName": recordID.recordName]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let identifier = UUID.init().uuidString
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            center.add(request, withCompletionHandler: { (error) in
                if error != nil {
                    print("Error scheduling notification")
                    completion()
                }
                else {
                    print("Notification scheduled")
                    completion()
                }
            })
        }
    }
}
