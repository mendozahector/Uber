//
//  ViewController.swift
//  Uber
//
//  Created by Hector Mendoza on 11/2/18.
//  Copyright © 2018 Hector Mendoza. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var riderDriverSwitch: UISwitch!
    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    
    @IBOutlet weak var topButton: UIButton!
    @IBOutlet weak var bottomButton: UIButton!
    
    var signUpMode: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    @IBAction func topTapped(_ sender: UIButton) {
        
        if emailTextField.text == "" || passwordTextField.text == "" {
            displayAlert(title: "Missing Information", message: "Email and password required.")
        } else {
            let email = emailTextField.text!
            let password = passwordTextField.text!
            
            if signUpMode == true {
                //SIGN UP
                Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
                    if error != nil {
                        self.displayAlert(title: "Error", message: error!.localizedDescription)
                    } else {
                        
                        if self.riderDriverSwitch.isOn {
                            let request = Auth.auth().currentUser?.createProfileChangeRequest()
                            request?.displayName = "Driver"
                            request?.commitChanges(completion: nil)
                            self.performSegue(withIdentifier: "driverSegue", sender: nil)
                        } else {
                            let request = Auth.auth().currentUser?.createProfileChangeRequest()
                            request?.displayName = "Rider"
                            request?.commitChanges(completion: nil)
                            self.performSegue(withIdentifier: "riderSegue", sender: nil)
                        }
                        
                    }
                }
            } else {
                //LOGIN
                Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                    if error != nil {
                        self.displayAlert(title: "Error", message: error!.localizedDescription)
                    } else {
                        
                        if user?.user.displayName == "Driver" {
                            //DRIVER
                            self.performSegue(withIdentifier: "driverSegue", sender: nil)
                        } else {
                            //RIDER
                            self.performSegue(withIdentifier: "riderSegue", sender: nil)
                        }
                    }
                    
                }
            }
        }
        
    }
    
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func bottomTapped(_ sender: UIButton) {
        
        if signUpMode == true {
            riderLabel.isHidden = true
            driverLabel.isHidden = true
            riderDriverSwitch.isHidden = true

            topButton.setTitle("Login", for: .normal)
            bottomButton.setTitle("Switch to Sign Up", for: .normal)
            signUpMode = false
        } else {
            riderLabel.isHidden = false
            driverLabel.isHidden = false
            riderDriverSwitch.isHidden = false

            topButton.setTitle("Sign Up", for: .normal)
            bottomButton.setTitle("Switch to Login", for: .normal)
            signUpMode = true
        }
        
    }
    
    
}

