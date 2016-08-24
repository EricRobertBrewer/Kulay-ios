//
//  ColorViewController.swift
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

let kMax = 255

let kGoogleClientID = "688434233474-70pa7hhgrbd7a21si64viku0is07guv7.apps.googleusercontent.com"

class ColorViewController: UIViewController, UITextFieldDelegate, FIRAuthUIDelegate {
    
    // MARK: Properties
    
    // Input
    @IBOutlet weak var redInput: UITextField!
    @IBOutlet weak var greenInput: UITextField!
    @IBOutlet weak var blueInput: UITextField!
    var inputs = [UITextField]()
    
    var gradients = [CAGradientLayer]()
    @IBOutlet weak var redSlider: UISlider!
    @IBOutlet weak var greenSlider: UISlider!
    @IBOutlet weak var blueSlider: UISlider!
    var sliders = [UISlider]()
    
    // Output
    @IBOutlet weak var whiteTextLabel: UILabel!
    @IBOutlet weak var grayTextLabel: UILabel!
    @IBOutlet weak var darkGrayTextLabel: UILabel!
    @IBOutlet weak var blackTextLabel: UILabel!
    @IBOutlet weak var whiteBackgroundLabel: UILabel!
    @IBOutlet weak var grayBackgroundLabel: UILabel!
    @IBOutlet weak var darkGrayBackgroundLabel: UILabel!
    @IBOutlet weak var blackBackgroundLabel: UILabel!
    
    // UIBarButtonItems
    @IBOutlet weak var loginButton: UIBarButtonItem!
    
    var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // Control state
    var currentFavoriteColor: UIColor? = nil
    var favoriteColorBeforeSignIn: UIColor? = nil
    
    // MARK: Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sliders += [redSlider, greenSlider, blueSlider]
        let colors = [UIColor.redColor(), UIColor.greenColor(), UIColor.blueColor()]
        for (index, slider) in sliders.enumerate() {
            let gradient = CAGradientLayer()
            gradient.frame = slider.bounds
            gradient.colors = [UIColor.blackColor().CGColor, colors[index].CGColor]
            gradient.startPoint = CGPointMake(0, 0.5)
            gradient.endPoint = CGPointMake(1, 0.5)
            slider.layer.insertSublayer(gradient, atIndex: 0)
            gradients += [gradient]
        }
        inputs += [redInput, greenInput, blueInput]
        for (index, input) in inputs.enumerate() {
            onSliderValueChanged(sliders[index])
            input.delegate = self
        }
        activityIndicatorView = UIActivityIndicatorView.init(activityIndicatorStyle: .Gray)
        navigationItem.rightBarButtonItems = [saveButton, UIBarButtonItem.init(customView: activityIndicatorView)]
        
        if let currentUser = FIRAuth.auth()?.currentUser {
            startBackgroundActivity()
            loadFavoriteColor(currentUser)
            loginButton.title = "Logout"
        } else {
            randomizeColor()
        }
        
        updateOutputs()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateGradientFrames()
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        updateGradientFrames()
    }
    
    func updateGradientFrames() {
        for index in 0..<3 {
            gradients[index].frame = sliders[index].bounds
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Color
    
    func colorFromSliders() -> UIColor {
        return colorWithRGBA0To255(Int(redSlider.value), green: Int(greenSlider.value), blue: Int(blueSlider.value), alpha: kMax)
    }
    
    func colorWithRGBA(rgba: Int) -> UIColor {
        // change to Int64 to allow alpha and suppress this error on iOS version < 7.
        let alpha = 255 // (rgba & 0xFF000000) >> 24
        let red = (rgba & 0x00FF0000) >> 16
        let green = (rgba & 0x0000FF00) >> 8
        let blue = rgba & 0x000000FF
        return colorWithRGBA0To255(red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Change a color like 0xFF808080 to a UIColor
    func colorWithRGBA0To255(red: Int, green: Int, blue: Int, alpha: Int) -> UIColor {
        return UIColor(colorLiteralRed: Float(red) / 255.0, green: Float(green) / 255.0, blue: Float(blue) / 255.0, alpha: Float(alpha) / 255.0)
    }
    
    /// Change a UIColor to an integer-based color value like 0xFFC0C0C0
    func intWithColor(color: UIColor) -> Int? {
        var fRed: CGFloat = 0
        var fGreen: CGFloat = 0
        var fBlue: CGFloat = 0
        var fAlpha: CGFloat = 0
        if color.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            // (Bits 24-31 are alpha, 16-23 are red, 8-15 are green, 0-7 are blue).
            return (Int(fAlpha * 255.0) << 24) + (Int(fRed * 255.0) << 16) + (Int(fGreen * 255.0) << 8) + Int(fBlue * 255.0)
        } else { // Could not extract RGBA components:
            return nil
        }
    }
    
    func intColorFromInt64(modelColor: Int64) -> Int {
        var color = modelColor
        if color >= 0x100000000 {
            color -= 0x100000000
        }
        return Int(color)
    }
    
    func positiveColorFromInt(color: Int) -> Int64 {
        return color < 0 ? Int64(color) + 0x100000000 : Int64(color)
    }
    
    // MARK: Update UI
    
    func updateGradients(exceptForIndex: Int) {
        for (position, gradient) in gradients.enumerate() {
            if exceptForIndex != position {
                gradient.colors![0] = gradientColor(position, isLow: true)
                gradient.colors![1] = gradientColor(position, isLow: false)
            }
        }
    }
    
    func gradientColor(position: Int, isLow: Bool) -> CGColor {
        return colorWithRGBA0To255(gradientColorValue(position, dimension: 0, isLow: isLow),
                                   green: gradientColorValue(position, dimension: 1, isLow: isLow),
                                   blue: gradientColorValue(position, dimension: 2, isLow: isLow),
                                   alpha: kMax).CGColor
    }
    
    func gradientColorValue(position: Int, dimension: Int, isLow: Bool) -> Int {
        return position == dimension ? (isLow ? 0 : kMax) : Int(sliders[dimension].value);
    }
    
    func updateInputs(color: UIColor?) {
        var dimensions = [0, 0, 0, 0] as [CGFloat]
        if (color?.getRed(&dimensions[0], green: &dimensions[1], blue: &dimensions[2], alpha: &dimensions[3])) != nil {
            for (index, slider) in sliders.enumerate() {
                slider.value = Float(dimensions[index] * 255.0)
                inputs[index].text = String(Int(slider.value))
            }
        }
    }
    
    func updateOutputs() {
        let color = colorFromSliders()
        whiteTextLabel.backgroundColor = color
        grayTextLabel.backgroundColor = color
        darkGrayTextLabel.backgroundColor = color
        blackTextLabel.backgroundColor = color
        whiteBackgroundLabel.textColor = color
        grayBackgroundLabel.textColor = color
        darkGrayBackgroundLabel.textColor = color
        blackBackgroundLabel.textColor = color
    }
    
    func randomizeColor() {
        for slider in sliders {
            slider.value = Float(random() % (kMax + 1))
        }
        updateInputs(colorFromSliders())
        updateGradients(-1)
    }
    
    func startBackgroundActivity() {
        activityIndicatorView.startAnimating()
        saveButton.enabled = false
    }
    
    func stopBackgroundActivity() {
        activityIndicatorView.stopAnimating()
        saveButton.enabled = true
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
        
        updateGradients(index)
        updateOutputs()
    }
    
    @IBAction func onSaveButtonTapped(sender: UIBarButtonItem) {
        let favoriteUIColor = colorFromSliders()
        
        let currentUser = FIRAuth.auth()?.currentUser
        if currentUser == nil {
            favoriteColorBeforeSignIn = favoriteUIColor
            presentLoginViewController(nil)
        } else if currentFavoriteColor != nil {
            if !(currentFavoriteColor?.isEqual(favoriteUIColor))! {
                let ref = FIRDatabase.database().reference()
                if let favoriteColor = intWithColor(currentFavoriteColor!) {
                    startBackgroundActivity()
                    
                    let positiveFavoriteColor = positiveColorFromInt(favoriteColor)
                    ref.child("colors").child("\(positiveFavoriteColor)").child("\(currentUser!.uid)").removeValueWithCompletionBlock({ (error, ref) in
                        if error == nil {
                            self.saveFavoriteColor(currentUser!, favoriteUIColor: favoriteUIColor)
                        } else {
                            self.stopBackgroundActivity()
                        }
                    })
                }
            } else {
                // color is the same as current favorite color
            }
        } else {
            startBackgroundActivity()
            saveFavoriteColor(currentUser!, favoriteUIColor: favoriteUIColor)
        }
    }
    
    func saveFavoriteColor(currentUser: FIRUser, favoriteUIColor: UIColor) {
        if let favoriteColor = intWithColor(favoriteUIColor) {
            let ref = FIRDatabase.database().reference()
            let timestamp = Int64(NSDate().timeIntervalSince1970 * 1000)
            let positiveFavoriteColor = positiveColorFromInt(favoriteColor)
            
            let userPath = "/users/\(currentUser.uid)"
            let userValues = ["favoriteColor": NSNumber(longLong: positiveFavoriteColor), "timestamp": NSNumber(longLong: timestamp)]
            
            let userColorPath = "/user-colors/\(currentUser.uid)/\(timestamp)"
            let userColorValues = ["favoriteColor": NSNumber(longLong: positiveFavoriteColor)]
            
            let colorPath = "/colors/\(positiveFavoriteColor)/\(currentUser.uid)"
            let colorValues = ["timestamp": NSNumber(longLong: timestamp)]
            
            let updates = [userPath: userValues, userColorPath: userColorValues, colorPath: colorValues];
            ref.updateChildValues(updates, withCompletionBlock: {(error, reference) in
                if error == nil {
                    self.currentFavoriteColor = favoriteUIColor
                }
                self.stopBackgroundActivity()
            })
        } else {
            stopBackgroundActivity()
        }
    }
    
    func loadFavoriteColor(user: FIRUser) {
        FIRDatabase.database().reference().child("users").child(user.uid).observeSingleEventOfType(.Value, withBlock: {(snapshot) in
            if let savedColor = snapshot.value!["favoriteColor"] as! NSNumber? {
                self.currentFavoriteColor = self.colorWithRGBA(Int(savedColor))
                self.updateInputs(self.currentFavoriteColor)
                self.updateGradients(-1)
                self.updateOutputs()
                self.stopBackgroundActivity()
            } else {
                self.randomizeColor()
            }
            }, withCancelBlock: {(error) in
                // an error occurred
                self.stopBackgroundActivity()
        })
    }
    
    @IBAction func onLoginButtonTapped(sender: UIBarButtonItem) {
        if FIRAuth.auth()?.currentUser != nil {
            do {
                try FIRAuth.auth()!.signOut()
                loginButton.title = "Sign In"
            } catch {
                // couldn't logout
            }
        } else {
            favoriteColorBeforeSignIn = nil
            presentLoginViewController(nil)
        }
    }
    
    func presentLoginViewController(completion: (() -> Void)?) {
        let authUI = FIRAuthUI.authUI()
        authUI?.delegate = self
        let googleAuthUI = FIRGoogleAuthUI(clientID: kGoogleClientID)!
        authUI?.signInProviders = [googleAuthUI]
        let authViewController = authUI!.authViewController()
        presentViewController(authViewController, animated: true, completion: completion)
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidEndEditing(textField: UITextField) {
        let index = inputs.indexOf(textField)! as Int
        let slider = sliders[index]
        if let value = Float(textField.text ?? "0") {
            slider.value = value
            updateGradients(index)
        } else {
            textField.text = String(Int(slider.value))
        }
        updateOutputs()
    }
    
    // MARK: FIRAuthUIDelegate
    
    func authUI(authUI: FIRAuthUI, didSignInWithUser user: FIRUser?, error: NSError?) {
        if error != nil {
            print(error)
        } else if user != nil {
            startBackgroundActivity()
            if favoriteColorBeforeSignIn != nil {
                saveFavoriteColor(user!, favoriteUIColor: favoriteColorBeforeSignIn!)
            } else {
                loadFavoriteColor(user!)
            }
            loginButton.title = "Logout"
        }
    }
}

