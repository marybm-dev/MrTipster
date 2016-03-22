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
    @IBOutlet weak var splitOneLabel: UILabel!
    @IBOutlet weak var splitTwoLabel: UILabel!
    @IBOutlet weak var splitThreeLabel: UILabel!
    @IBOutlet weak var splitFourLabel: UILabel!
    @IBOutlet weak var splitFiveLabel: UILabel!

    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // prevent the colored uiview from creeping under nav bar
        self.edgesForExtendedLayout = UIRectEdge.None
        
        self.shouldAnimate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // make the number pad open by default
        billTextField.delegate = self
        billTextField.becomeFirstResponder()
        
        // get stored defaults and display on UI
        self.setupView()
    }
    
    // MARK: App Logic
    func setupView() {
        
        // retrieve defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        let index = defaults.integerForKey("controlIndex")
        let percent = defaults.doubleForKey("percent")
        let minutes = defaults.integerForKey("minutes")
        var amount: Double = 0
        
        // if less than 10 minutes, reload the amount
        if minutes < 10 {
            amount = defaults.doubleForKey("amount")
            self.loadAmount(amount)
        }
        
        // update selected segment
        tipControl.selectedSegmentIndex = index
        
        // update the amount labels
        self.updateLabels(percent, amount: amount)
    }
    
    func updateLabels(percent: Double, amount: Double) {
        
        // recalculate the amounts
        let tip = amount * percent
        let total = amount + tip
        
        splitOneLabel.text = String(format: "$%.2f", total)
        splitTwoLabel.text = String(format: "$%.2f", total / 2)
        splitThreeLabel.text = String(format: "$%.2f", total / 3)
        splitFourLabel.text = String(format: "$%.2f", total / 4)
        splitFiveLabel.text = String(format: "$%.2f", total / 5)
    }
    
    func saveAmount(amount: Double) {
        defaults.setDouble(amount, forKey: "amount")
        defaults.synchronize()
    }
    
    func loadAmount(amount: Double) {
        billTextField.text = String(format: "%.2f", amount)
    }
    
    func shouldAnimate() {
        self.tipControl.alpha = 0
        self.splitOneLabel.alpha = 0
        self.splitTwoLabel.alpha = 0
        self.splitThreeLabel.alpha = 0
        self.splitFourLabel.alpha = 0
        self.splitFiveLabel.alpha = 0
        
        UIView.animateWithDuration(0.75, animations: {
            self.tipControl.alpha = 1
            self.splitOneLabel.alpha = 1
            self.splitTwoLabel.alpha = 1
            self.splitThreeLabel.alpha = 1
            self.splitFourLabel.alpha = 1
            self.splitFiveLabel.alpha = 1
        })
    }
    
    // MARK: IBActions
    @IBAction func onEditingChanged(sender: AnyObject) {
        
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

    @IBAction func onTap(sender: AnyObject) {
        view.endEditing(true)
    }
}