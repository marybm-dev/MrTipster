//
//  ViewController.swift
//  TipCalculator
//
//  Created by Mary Martinez on 3/21/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var billTextField: UITextField!
    @IBOutlet weak var tipControl: UISegmentedControl!
    @IBOutlet weak var amountView: UIView!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var splitOneLabel: UILabel!
    @IBOutlet weak var splitTwoLabel: UILabel!
    @IBOutlet weak var splitThreeLabel: UILabel!
    @IBOutlet weak var splitFourLabel: UILabel!
    @IBOutlet weak var splitFiveLabel: UILabel!

    let defaults = UserDefaults.standard
    
    var flagButton: UIButton!
    var barButtonItem: UIBarButtonItem!
    var currencySymbol: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // prevent the colored uiview from creeping under nav bar
        self.edgesForExtendedLayout = UIRectEdge()
        
        // setup textfield delegate
        billTextField.delegate = self
        
        // display fade animation
        self.shouldAnimate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setFlag(Helper.Region.USA)
        
        // get stored defaults and display on UI
        self.setupView()
    }
    
    // MARK: App Logic
    func setupView() {
        
        // make the number pad open by default
        billTextField.becomeFirstResponder()
        
        // retrieve defaults
        let defaults = UserDefaults.standard
        let index    = defaults.integer(forKey: "controlIndex")
        let percent  = defaults.double(forKey: "percent")
        let minutes  = defaults.integer(forKey: "minutes")
        currencySymbol = defaults.string(forKey: "currency")
        var amount: Double = 0
        
        // if less than 10 minutes, reload the amount
        if minutes < 10 {
            amount = defaults.double(forKey: "amount")
            self.loadAmount(amount)
        }
        
        // update selected segment
        tipControl.selectedSegmentIndex = index
        
        // update the amount labels
        self.updateLabels(percent, amount: amount)
        
        // update the flag
        self.setFlag(Helper.regionDictionary[currencySymbol!]!)
    }
    
    func updateLabels(_ percent: Double, amount: Double) {
        
        // recalculate the amounts
        let tip = amount * percent
        let total = amount + tip
        
        splitOneLabel.text   = String(format: "\(currencySymbol!)%.2f", total)
        splitTwoLabel.text   = String(format: "\(currencySymbol!)%.2f", total / 2)
        splitThreeLabel.text = String(format: "\(currencySymbol!)%.2f", total / 3)
        splitFourLabel.text  = String(format: "\(currencySymbol!)%.2f", total / 4)
        splitFiveLabel.text  = String(format: "\(currencySymbol!)%.2f", total / 5)
        currencyLabel.text   = currencySymbol
    }
    
    func saveAmount(_ amount: Double) {
        defaults.set(amount, forKey: "amount")
        defaults.synchronize()
    }
    
    func loadAmount(_ amount: Double) {
        billTextField.text = String(format: "%.2f", amount)
    }
    
    func shouldAnimate() {
        self.tipControl.alpha = 0
        self.splitOneLabel.alpha = 0
        self.splitTwoLabel.alpha = 0
        self.splitThreeLabel.alpha = 0
        self.splitFourLabel.alpha = 0
        self.splitFiveLabel.alpha = 0
        
        UIView.animate(withDuration: 0.75, animations: {
            self.tipControl.alpha = 1
            self.splitOneLabel.alpha = 1
            self.splitTwoLabel.alpha = 1
            self.splitThreeLabel.alpha = 1
            self.splitFourLabel.alpha = 1
            self.splitFiveLabel.alpha = 1
        })
    }
    
    func setFlag(_ region: Helper.Region) {
        flagButton = UIButton(type: UIButtonType.custom)
        flagButton.setImage(UIImage(named: region.rawValue), for: .normal)
        flagButton.setTitle(region.rawValue, for: .normal)
        flagButton.sizeToFit()
        
        barButtonItem = UIBarButtonItem(customView: flagButton)
        self.navigationItem.leftBarButtonItem = barButtonItem
    }
    
    // MARK: IBActions
    @IBAction func onEditingChanged(_ sender: AnyObject) {
        
        // determine selected percent
        let tipPercentages = [0.18, 0.2, 0.22]
        let tipPercentage = tipPercentages[tipControl.selectedSegmentIndex]

        // update the amount labels
        if let currentAmount = Double(billTextField.text!) {
            
            self.updateLabels(tipPercentage, amount: currentAmount)
            
            // store the amount to display within 10 mins
            self.saveAmount(currentAmount)
        }
    }

    @IBAction func onTap(_ sender: AnyObject) {
        view.endEditing(true)
    }
}
