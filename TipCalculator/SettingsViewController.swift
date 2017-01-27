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

    enum Picker: String {
        case Percent = "Percent"
        case Currency = "Currency"
        case Null = ""
    }
    
    // used to select data to use in pickerView
    var activeField = UITextField()
    var pickerView = UIPickerView()
    var currentPickerName: Picker!
    
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
        let percent = Variables.defaults.double(forKey: "percent")
        let currency = Variables.defaults.string(forKey: "currency")
        percentTextField.text = percent > 0 ? String(format: "%.2f", percent) : "\(Variables.tipPercentage)"
        currencyTextField.text = currency == nil ? Variables.foreignCurrencies[0] : currency
    }
    
    func saveSettings() {
        let percent = Double(percentTextField.text!)
        let currency = self.currencyTextField.text
        Variables.defaults.set(percent, forKey: "percent")
        Variables.defaults.set(currency, forKey: "currency")
        Variables.defaults.synchronize()
    }
    
    func setupPicker() {
        currencyTextField.inputView = pickerView
    }
    
    func updatePicker(_ textField: UITextField) {
        currentPickerName = textField == currencyTextField ? .Currency : .Null
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
        return currentPickerName == .Currency ? Variables.foreignCurrencies.count : 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent: Int) -> String? {
        return currentPickerName == .Currency ? Variables.foreignCurrencies[row] : nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent: Int) {
        if currentPickerName == .Currency {
            currencyTextField.text = Variables.foreignCurrencies[row]
        }
    }
    
    // MARK: IBActions
    @IBAction func onTap(_ sender: AnyObject) {
        view.endEditing(true)
    }
    
}
