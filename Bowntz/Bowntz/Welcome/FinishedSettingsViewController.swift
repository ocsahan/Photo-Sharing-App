//
//  FinishedSettingsViewController.swift
//  Bowntz
//
//  Created by Cagri Sahan on 6/4/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import UIKit
import CoreData

class FinishedSettingsViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: IBOutlets
    @IBOutlet weak var friendListTable: UITableView!
    @IBOutlet weak var messageLabel: UILabel!
    
    // MARK: Variables
    let defaults = UserDefaults.standard
    var context: NSManagedObjectContext?
    var userRecord: String?
    
    lazy var fetchedResultsController: NSFetchedResultsController<User> = {
        let fetchRequest = NSFetchRequest<User>(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "TRUEPREDICATE")
        let nameDescriptor = NSSortDescriptor(key: "firstName", ascending: false)
        fetchRequest.sortDescriptors = [nameDescriptor]
        let _fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                   managedObjectContext: self.context!,
                                                                   sectionNameKeyPath: nil,
                                                                   cacheName: nil)
        _fetchedResultsController.delegate = self
        return _fetchedResultsController
    }()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userRecord = defaults.value(forKey: "RecordName") as? String
        friendListTable.dataSource = self
        
        DispatchQueue.main.sync {
            context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
        }
        
        if let userName = defaults.value(forKey: "FirstName") {
            messageLabel.text = "You're all set, \(userName)!"
        }
        
        fetch()
    }
    
    // MARK: Functions
    func fetch() {
        do {
            try self.fetchedResultsController.performFetch()
            friendListTable.reloadData()
        } catch {
            showErrorDialogue(message: "Can't display friends.")
        }
    }
    
    func showErrorDialogue(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(actionOK)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateInitialViewController()
        
        defaults.set(true, forKey: "HAS_LAUNCHED_BEFORE")
        present(vc!, animated: true, completion: nil)
    }
}

// MARK: Extensions
extension FinishedSettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath)
        // Configure the cell...
        let user = fetchedResultsController.object(at: indexPath)
        
        if user.recordName == userRecord {
            cell.textLabel?.text = "\(user.firstName ?? "") \(user.lastName ?? "") (me)"
        }
        else {
            cell.textLabel?.text = "\(user.firstName ?? "") \(user.lastName ?? "")"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return (fetchedResultsController.sections?.first?.numberOfObjects)!
        }
        return 0
    }
}
