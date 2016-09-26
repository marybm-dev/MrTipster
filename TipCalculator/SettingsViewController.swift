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
        let defaults = UserDefaults.standard
        let percent = defaults.double(forKey: "percent")
        
        if percent > 0 {
            percentTextField.text = String(format: "%.2f", percent)
        }
        else {
            percentTextField.text = tipPercentages[0].description
        }
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(Double(percentTextField.text!)!, forKey: "percent")
        defaults.set(self.controlIndex, forKey: "controlIndex")
        defaults.synchronize()
    }
    
    // MARK: Picker Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent: Int) -> Int {
        return tipPercentages.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent: Int) -> String? {
        return String(format: "%d", Int(tipPercentages[row] * 100))
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent: Int) {
        percentTextField.text = tipPercentages[row].description
        self.controlIndex = row
    }
    
    // MARK: IBActions
    @IBAction func onTap(_ sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func onCancelButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: {})
    }
    
    @IBAction func onSaveButtonPressed(_ sender: AnyObject) {
        self.saveSettings()
        self.dismiss(animated: true, completion: {})
    }
}
