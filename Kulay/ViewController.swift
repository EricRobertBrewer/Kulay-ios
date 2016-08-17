//
//  ViewController.swift
//  Kulay
//
//  Created by Eric Brewer on 8/12/16.
//  Copyright © 2016 Bunga. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseAuthUI
import FirebaseGoogleAuthUI

let kGoogleClientID = "688434233474-70pa7hhgrbd7a21si64viku0is07guv7.apps.googleusercontent.com"

class ViewController: UIViewController, UITextFieldDelegate, FIRAuthUIDelegate {
    
    // MARK: Properties
    
    // Input
    @IBOutlet weak var redInput: UITextField!
    @IBOutlet weak var greenInput: UITextField!
    @IBOutlet weak var blueInput: UITextField!
    var inputs = [UITextField]()
    @IBOutlet weak var redSlider: UISlider!
    @IBOutlet weak var greenSlider: UISlider!
    @IBOutlet weak var blueSlider: UISlider!
    var sliders = [UISlider]()
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // Output
    @IBOutlet weak var whiteTextLabel: UILabel!
    @IBOutlet weak var grayTextLabel: UILabel!
    @IBOutlet weak var darkGrayTextLabel: UILabel!
    @IBOutlet weak var blackTextLabel: UILabel!
    @IBOutlet weak var whiteBackgroundLabel: UILabel!
    @IBOutlet weak var grayBackgroundLabel: UILabel!
    @IBOutlet weak var darkGrayBackgroundLabel: UILabel!
    @IBOutlet weak var blackBackgroundLabel: UILabel!
    
    // MARK: Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sliders += [redSlider, greenSlider, blueSlider]
        for slider in sliders {
            slider.value = Float(random() % 255)
        }
        inputs += [redInput, greenInput, blueInput]
        for (index, input) in inputs.enumerate() {
            onSliderValueChanged(sliders[index])
            input.delegate = self
        }
        updateOutputs()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateOutputs() {
        let color = UIColor(colorLiteralRed: redSlider.value / 255.0, green: greenSlider.value / 255.0, blue: blueSlider.value / 255.0, alpha: 1.0)
        whiteTextLabel.backgroundColor = color
        grayTextLabel.backgroundColor = color
        darkGrayTextLabel.backgroundColor = color
        blackTextLabel.backgroundColor = color
        whiteBackgroundLabel.textColor = color
        grayBackgroundLabel.textColor = color
        darkGrayBackgroundLabel.textColor = color
        blackBackgroundLabel.textColor = color
    }
    
    // MARK: Actions

    @IBAction func onRedSliderValueChanged(sender: AnyObject) {
        onSliderValueChanged(sender as! UISlider)
    }

    @IBAction func onGreenSliderValueChanged(sender: AnyObject) {
        onSliderValueChanged(sender as! UISlider)
    }
    
    @IBAction func onBlueSliderValueChanged(sender: AnyObject) {
        onSliderValueChanged(sender as! UISlider)
    }
    
    func onSliderValueChanged(slider: UISlider) {
        let index = sliders.indexOf(slider)! as Int
        inputs[index].text = String(Int(slider.value))
        updateOutputs()
    }
    
    @IBAction func onSaveButtonTapped(sender: UIBarButtonItem) {
        if let currentUser = FIRAuth.auth()?.currentUser {
            print("User \(currentUser.displayName) is signed in!")
        } else {
            let authUI = FIRAuthUI.authUI()
            authUI?.delegate = self
            let googleAuthUI = FIRGoogleAuthUI(clientID: kGoogleClientID)!
            authUI?.signInProviders = [googleAuthUI]
            let authViewController = authUI!.authViewController()
            presentViewController(authViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidEndEditing(textField: UITextField) {
        let index = inputs.indexOf(textField)! as Int
        let slider = sliders[index]
        if let value = Float(textField.text ?? "0") {
            slider.value = value
        } else {
            textField.text = String(Int(slider.value))
        }
        updateOutputs()
    }
    
    // MARK: FIRAuthUIDelegate
    
    func authUI(authUI: FIRAuthUI, didSignInWithUser user: FIRUser?, error: NSError?) {
        if error != nil {
            print(error)
        }
    }
}

