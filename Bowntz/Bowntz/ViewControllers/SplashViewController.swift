//
//  SplashViewController.swift
//  Bowntz
//
//  Created by Cagri Sahan on 3/12/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
