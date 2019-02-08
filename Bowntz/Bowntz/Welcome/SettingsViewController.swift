//
//  SettingsViewController.swift
//  Bowntz
//
//  Created by Cagri Sahan on 6/4/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak var allowButton: UIButton!
    // MARK: Variables
    let setupUtility = SetupUtility.shared
    let defaults = UserDefaults.standard
    
    // MARK: IBActions
    @IBAction func allowButtonPressed(_ sender: Any) {
        allowButton.backgroundColor = .gray
        allowButton.setTitle("Setting Up...", for: .normal)
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat,.autoreverse], animations: { [unowned self] in
            self.allowButton.alpha = 0.25
            }, completion: nil)
        setupUtility.requestInitialAccess() { [unowned self] accepted in
            DispatchQueue.main.sync {
                
                if accepted {
                    print("Setting up discoverability.")
                    self.setupUtility.fetchUserID() { userID in
                        if let userID = userID {
                            self.setupUtility.fetchUserName(forRecordID: userID, completion: { (firstName, lastName) in
                                if let firstName = firstName, let lastName = lastName {
                                    self.defaults.set(firstName, forKey: "FirstName")
                                    self.defaults.set(lastName, forKey: "LastName")
                                    self.defaults.set(userID.recordName, forKey: "RecordName")
                                    
                                    self.setupUtility.fetchContacts(completion: { (userList) in
                                        if let userList = userList {
                                            DispatchQueue.main.sync {
                                                self.setupUtility.saveUsersToStore(userList: userList)
                                                self.setupUtility.saveSelfToStore()
                                            }
                                            self.performSegue(withIdentifier: "accepted", sender: nil)
                                        }
                                        else { self.showErrorDialogue(message: "Can't get contacts"); return }
                                    })
                                }
                                else { self.showErrorDialogue(message: "Can't get user name"); return }
                            })
                        }
                        else { self.showErrorDialogue(message: "Can't get user ID"); return }
                    }
                }
                else { self.showErrorDialogue(message: "You did not accept!") }
            }
        }
    }
    
    // MARK: Functions
    func showErrorDialogue(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let actionOK = UIAlertAction(title: "OK", style: .default, handler: { action in
            self.performSegue(withIdentifier: "rejected", sender: nil)
        })
        alert.addAction(actionOK)
        self.present(alert, animated: true, completion: nil)
    }
}
