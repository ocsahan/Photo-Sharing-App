//
//  SendScreenController.swift
//  Bowntz
//
//  Created by Cagri Sahan on 3/12/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import UIKit

class MessageScreenController: UIViewController {
    
    // MARK: Variables
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var textInput: UITextView!
    var delegate: TextInputPassable?
    var textMessage: String?
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        textInput.delegate = self
        textInput.layer.cornerRadius = 5.0
        submitButton.layer.cornerRadius = 5.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let message = textMessage {
            textInput.text = message
        }
    }
    
    // MARK: Functions
    @IBAction func submitButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: { self.delegate?.passMessageStringAndSubmit(self.textInput.text) })
        print("Submit button pressed")
    }
}

// MARK: Extensions
// Attribution: http://www.seemuapps.com/move-uitextfield-when-keyboard-is-presented
extension MessageScreenController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        moveTextField(textView, moveDistance: -120, up: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        moveTextField(textView, moveDistance: -120, up: false)
    }
    
    // Attribution: https://stackoverflow.com/questions/32281651/how-to-dismiss-keyboard-when-touching-anywhere-outside-uitextfield-in-swift
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Move the text field in a pretty animation!
    func moveTextField(_ textField: UITextView, moveDistance: Int, up: Bool) {
        let moveDuration = 0.3
        let movement: CGFloat = CGFloat(up ? moveDistance : -moveDistance)
        
        UIView.beginAnimations("animateTextField", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(moveDuration)
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
    }
}
