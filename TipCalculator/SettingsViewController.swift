//
//  SettingsViewController.swift
//  TipCalculator
//
//  Created by Mary Martinez on 3/21/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var percentTextField: UITextField!

    var percentPicker = UIPickerView()
    let tipPercentages = [0.18, 0.2, 0.22]
    var controlIndex = 0
    
    override func viewDidLoad() {
        self.setupPicker()
        self.loadSettings()
    }
    
    // MARK: Settings Logic
    func setupPicker() {
        percentPicker.delegate = self
        percentPicker.dataSource = self
        percentTextField.inputView = percentPicker
    }
    
    func loadSettings() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let percent = defaults.doubleForKey("percent")
        percentTextField.text = String(format: "%.2f", percent)
    }
    
    func saveSettings() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setDouble(Double(percentTextField.text!)!, forKey: "percent")
        defaults.setInteger(self.controlIndex, forKey: "controlIndex")
        defaults.synchronize()
    }
    
    // MARK: Picker Delegate
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent: Int) -> Int {
        return tipPercentages.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent: Int) -> String? {
        return String(format: "%d", Int(tipPercentages[row] * 100))
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent: Int) {
        percentTextField.text = tipPercentages[row].description
        self.controlIndex = row
    }
    
    // MARK: IBActions
    @IBAction func onTap(sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func onCancelButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    @IBAction func onSaveButtonPressed(sender: AnyObject) {
        self.saveSettings()
        self.dismissViewControllerAnimated(true, completion: {})
    }
}