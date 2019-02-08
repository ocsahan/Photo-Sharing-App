//
//  WelcomeLastStepController.swift
//  Bowntz
//
//  Created by Cagri Sahan on 3/12/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import UIKit

class WelcomeLastStepController: UIViewController {
    
    // MARK: Variables
    var nextStoryboard: UIStoryboard?
    var nextVC: UIViewController?
    var pvc: UIPageViewController?
    let defaults = UserDefaults.standard
    
    
    // MARK: Functions
    
    @objc func showSettingsScreen() {
        performSegue(withIdentifier: "settingsSegue", sender: nil)
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextStoryboard = UIStoryboard(name: "Main", bundle: nil)
        nextVC = nextStoryboard?.instantiateViewController(withIdentifier: "MainRoot")
        
        pvc = self.parent as? UIPageViewController
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(showSettingsScreen))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
    }
}
