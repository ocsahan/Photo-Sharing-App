//
//  RecipientPickerViewController.swift
//  Bowntz
//
//  Created by Cagri Sahan on 6/5/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import UIKit
import CoreData

class RecipientPickerViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: IBOutlets
    @IBOutlet weak var friendListTable: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    
    // MARK: IBActions
    @IBAction func sendButtonTapped(_ sender: Any) {
        delegate?.passMessage(from: userRecord!, to: recipientRecord!)
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Variables
    let defaults = UserDefaults.standard
    var context: NSManagedObjectContext?
    var userRecord: String?
    var recipientRecord: String?
    var delegate: Messenger?
    
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
        friendListTable.delegate = self
        context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
        
        fetch()
    }
    
    // MARK: Functions
    func fetch() {
        do {
            try self.fetchedResultsController.performFetch()
            friendListTable.reloadData()
        } catch {
            showErrorDialogue(message: "Can't display friends.")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func showErrorDialogue(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(actionOK)
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: Extensions
extension RecipientPickerViewController: UITableViewDataSource {
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

extension RecipientPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        sendButton.isEnabled = true
        sendButton.backgroundColor = #colorLiteral(red: 0.5658612251, green: 0.7979679108, blue: 0.4023602605, alpha: 1)
        let friend = fetchedResultsController.object(at: indexPath)
        recipientRecord = friend.recordName
    }
}
