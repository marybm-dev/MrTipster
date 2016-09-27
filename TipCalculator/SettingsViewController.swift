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

    var percentPicker = UIPickerView()
    let tipPercentages = [0.18, 0.2, 0.22]
    var controlIndex = 0
    
    override func viewDidLoad() {
        self.setupTableView()
        self.setupPicker()
        self.loadSettings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.saveSettings()
    }
    
    // MARK: Settings Logic
    func setupTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
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
        Helper.saveSettings(Double(percentTextField.text!)!, self.controlIndex)
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
    
}
