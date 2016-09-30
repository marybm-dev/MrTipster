//
//  SettingsViewController.swift
//  TipCalculator
//
//  Created by Mary Martinez on 3/21/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var percentTextField: UITextField!
    @IBOutlet weak var currencyTextField: UITextField!
    @IBOutlet weak var darkThemeSwitch: UISwitch!

    // used to select data to use in pickerView
    var activeField = UITextField()
    var currentPickerName = String()
    var pickerView = UIPickerView()
    
    // determines index to select in ViewController UISegmentedControl
    var controlIndex = 0
    
    let tipPercentages = [0.18, 0.2, 0.22]
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        
        // setup delegates and datasources
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        
        self.percentTextField.delegate = self
        self.currencyTextField.delegate = self
        
        self.setupPicker()
        self.loadSettings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.saveSettings()
    }
    
    // MARK: Settings Logic
    func loadSettings() {
        
        let percent = defaults.double(forKey: "percent")
        let currency = defaults.string(forKey: "currency")
        let isDarkTheme = defaults.bool(forKey: "theme")
        
        if percent > 0 {
            percentTextField.text = String(format: "%.2f", percent)
        }
        else {
            percentTextField.text = tipPercentages[0].description
        }
        
        if currency == nil {
            currencyTextField.text = Helper.foreignCurrencies[0]
        }
        else {
            currencyTextField.text = currency
        }
        
        darkThemeSwitch.setOn(isDarkTheme, animated: true)
    }
    
    func saveSettings() {
        let percent = Double(percentTextField.text!)
        let controlIndex = self.controlIndex
        let currency = self.currencyTextField.text
        let isDarkTheme = self.darkThemeSwitch.isOn
        
        defaults.set(percent, forKey: "percent")
        defaults.set(controlIndex, forKey: "controlIndex")
        defaults.set(currency, forKey: "currency")
        defaults.set(isDarkTheme, forKey: "theme")
        
        defaults.synchronize()
    }
    
    func setupPicker() {

        percentTextField.inputView = pickerView
        currencyTextField.inputView = pickerView
    }
    
    func updatePicker(_ textField: UITextField) {
        
        if textField == percentTextField {
            currentPickerName = "Percent"
        }
        else if textField == currencyTextField {
            currentPickerName = "Currency"
        }
        else {
            currentPickerName = ""
        }
        
        pickerView.reloadAllComponents()
    }

    // MARK: Text Field Delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
        
        if textField == percentTextField || textField == currencyTextField {
            updatePicker(textField)
        }
    }
    
    // MARK: Picker Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent: Int) -> Int {
        
        if currentPickerName == "Percent" {
            return tipPercentages.count
        }
        else if currentPickerName == "Currency" {
            return Helper.foreignCurrencies.count
        }

        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent: Int) -> String? {
        
        if currentPickerName == "Percent" {
            return String(format: "%d", Int(tipPercentages[row] * 100))
        }
        else if currentPickerName == "Currency" {
            return Helper.foreignCurrencies[row]
        }
        
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent: Int) {
        
        if currentPickerName == "Percent" {
            percentTextField.text = tipPercentages[row].description
            self.controlIndex = row
        }
        else if currentPickerName == "Currency" {
            currencyTextField.text = Helper.foreignCurrencies[row]
        }
    }
    
    // MARK: IBActions
    @IBAction func onTap(_ sender: AnyObject) {
        view.endEditing(true)
    }
    
}
