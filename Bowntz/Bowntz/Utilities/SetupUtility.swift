//
//  SetupUtility.swift
//  Bowntz
//
//  Created by Cagri Sahan on 6/4/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import CloudKit
import UIKit
import CoreData

class SetupUtility {
    
    // MARK: Variables
    static let shared = SetupUtility()
    let container = CKContainer.default()
    let defaults = UserDefaults.standard
    
    
    // MARK: Functions
    private init() {}
    
    func saveSelfToStore() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let firstName = defaults.value(forKey: "FirstName")
        let lastName = defaults.value(forKey: "LastName")
        let recordName = defaults.value(forKey: "RecordName")
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "User", in: managedContext)!
        let person = NSManagedObject(entity: entity, insertInto: managedContext)
        
        person.setValue(firstName, forKey: "firstName")
        person.setValue(lastName, forKey: "lastName")
        person.setValue(recordName, forKey: "recordName")
        
        do {
            try managedContext.save()
            print("Saved user to store")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func checkDiscoveryPermission(completion: @escaping (CKApplicationPermissionStatus) -> Void) {
        self.container.status(forApplicationPermission: CKApplicationPermissions.userDiscoverability, completionHandler: { (status, error) in
            guard error == nil else { completion(.couldNotComplete); return }
            completion(status)
        })
    }
    
    func requestInitialAccess(completion: @escaping (Bool) -> Void) {
        self.container.requestApplicationPermission(.userDiscoverability) { (status, error) in
            guard error == nil else { completion(false); return }
            if status == .granted {
                completion(true)
            }
            else { completion(false) }
        }
    }
    
    func fetchUserID(completion: @escaping (CKRecordID?) -> Void) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.container.fetchUserRecordID { (recordID, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            guard error == nil else { completion(nil); return }
            completion(recordID)
        }
    }
    
    func fetchUserName(forRecordID recordID: CKRecordID, completion: @escaping (String?, String?) -> Void) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.container.discoverUserIdentity(withUserRecordID: recordID) { (userIdentity, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            guard error == nil else { completion(nil, nil); return}
            
            if let identity = userIdentity, let name = identity.nameComponents {
                completion(name.givenName, name.familyName)
            }
            else {  completion(nil, nil); return }
        }
    }
    
    func fetchContacts(completion: @escaping ([CKUserIdentity]?) -> Void) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.container.discoverAllIdentities { (userIdentities, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            guard error == nil else { print(error!); completion(nil); return }
            completion(userIdentities)
        }
    }
    
    func saveUsersToStore(userList: [CKUserIdentity]) {
    
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "User", in: managedContext)!
        
        let processedList = userList.compactMap {
            if let name = $0.nameComponents {
                let result = [name.givenName, name.familyName, $0.userRecordID?.recordName] as [String?]
                return result
            }
            return nil
        } as [[String?]]
        
        for entry in processedList {
            let person = NSManagedObject(entity: entity, insertInto: managedContext)
            person.setValue(entry[0], forKey: "firstName")
            person.setValue(entry[1], forKey: "lastName")
            person.setValue(entry[2], forKey: "recordName")
        }
        
        do {
            try managedContext.save()
            print("Saved contacts to store")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}
