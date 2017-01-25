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
    @IBOutlet weak var splitSixLabel: UILabel!
    @IBOutlet weak var splitSevenLabel: UILabel!

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
        
        // updates the flag to match currency region
        self.setFlag(Variables.Region.USA)
        
        // get stored defaults and display on UI
        self.setupView()
    }
    
    // MARK: App Logic
    func setupView() {
        
        // make the number pad open by default
        billTextField.becomeFirstResponder()
        
        // retrieve defaults
        let index    = Variables.defaults.integer(forKey: "controlIndex")
        let percent  = Variables.defaults.double(forKey: "percent")
        let isLightTheme = Variables.defaults.bool(forKey: "theme")
        
        // first run of app there are no defaults so explicitly set currencySymbol
        currencySymbol = Variables.defaults.string(forKey: "currency") ?? Variables.foreignCurrencies[0]
        
        // reload the previuos tip bill amount
        let amount = self.loadBillAmount()
        
        // update selected segment
        tipControl.selectedSegmentIndex = index
        
        // update the amount labels
        self.updateLabels(for: amount, with: percent)
        
        // update the flag
        self.setFlag(Variables.regionDictionary[currencySymbol!]!)
        
        // set the theme
        self.setTheme(isLightTheme)
    }
    
    func updateLabels(for amount: Double, with percent: Double) {
        
        // recalculate the amounts
        let tip = amount * percent
        let total = amount + tip
        
        splitOneLabel.text   = setLocale(for: total, divideBy: 1)
        splitTwoLabel.text   = setLocale(for: total, divideBy: 2)
        splitThreeLabel.text = setLocale(for: total, divideBy: 3)
        splitFourLabel.text  = setLocale(for: total, divideBy: 4)
        splitFiveLabel.text  = setLocale(for: total, divideBy: 5)
        splitSixLabel.text   = setLocale(for: total, divideBy: 6)
        splitSevenLabel.text = setLocale(for: total, divideBy: 7)
        currencyLabel.text   = currencySymbol
    }
    
    func setLocale(for amount: Double, divideBy quantity: Int) -> String? {
        
        // set the locale for thousands separator
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        
        // determine which to use
        let localeIdentifier = getLocaleIdentifier()
        numberFormatter.locale = Locale(identifier: localeIdentifier)
        
        // calculate per user quantity
        let num = NSNumber(floatLiteral: amount)
        let formattedTotal = num.doubleValue / Double(quantity)
        
        return  numberFormatter.string(from: NSNumber(value: formattedTotal))
    }
    
    func getLocaleIdentifier() -> String {
        let defaultIdentifier = Locale.current.identifier
        if let region = Variables.regionDictionary[currencySymbol] {
            switch region {
            case .USA:
                return "en_US"
            case .UK:
                return "en_GB"
            case .EU:
                return "eu_ES"
            case .Japan:
                return "ja_JP"
            case .India:
                return "en_IN"
            }
        }
        
        return defaultIdentifier
    }
    
    func save(bill amount: Double) {
        Variables.defaults.set(amount, forKey: "amount")
        Variables.defaults.synchronize()
    }
    
    func loadBillAmount() -> Double {
        // determines if app restarted within 10 mins and reuses amount if so
        let minutes  = Variables.defaults.integer(forKey: "minutes")
        let amount = (minutes > 10) ? 0 : Variables.defaults.double(forKey: "amount")
        billTextField.text = (amount < 1) ? "" : String(format: "%.2f", amount)
        
        return amount
    }
    
    func shouldAnimate() {
        self.tipControl.alpha = 0
        self.splitOneLabel.alpha = 0
        self.splitTwoLabel.alpha = 0
        self.splitThreeLabel.alpha = 0
        self.splitFourLabel.alpha = 0
        self.splitFiveLabel.alpha = 0
        self.splitSixLabel.alpha = 0
        self.splitSevenLabel.alpha = 0
        
        UIView.animate(withDuration: 0.75, animations: {
            self.tipControl.alpha = 1
            self.splitOneLabel.alpha = 1
            self.splitTwoLabel.alpha = 1
            self.splitThreeLabel.alpha = 1
            self.splitFourLabel.alpha = 1
            self.splitFiveLabel.alpha = 1
            self.splitSixLabel.alpha = 1
            self.splitSevenLabel.alpha = 1
        })
    }
    
    func setFlag(_ region: Variables.Region) {
        flagButton = UIButton(type: UIButtonType.custom)
        flagButton.setImage(UIImage(named: region.rawValue), for: .normal)
        flagButton.setTitle(region.rawValue, for: .normal)
        flagButton.sizeToFit()
        
        barButtonItem = UIBarButtonItem(customView: flagButton)
        self.navigationItem.leftBarButtonItem = barButtonItem
    }
    
    func setTheme(_ lightTheme: Bool) {
        if lightTheme {
            amountView.backgroundColor = UIColor.white
            amountView.tintColor = UIColor.blue
            billTextField.textColor = UIColor.darkGray
            currencyLabel.textColor = UIColor.darkGray
            tipControl.tintColor = UIColor.customBlue()
        }
        else {
            amountView.backgroundColor = UIColor.customBlue()
            amountView.tintColor = UIColor.white
            billTextField.textColor = UIColor.white
            currencyLabel.textColor = UIColor.white
            tipControl.tintColor = UIColor.white
        }
    }
    
    // MARK: IBActions
    @IBAction func onEditingChanged(_ sender: AnyObject) {
        
        // determine selected percent
        let tipPercentage = Variables.tipPercentages[tipControl.selectedSegmentIndex]

        // update the amount labels
        if let currentAmount = Double(billTextField.text!) {
            
            self.updateLabels(for: currentAmount, with: tipPercentage)
            
            // store the amount to display within 10 mins
            self.save(bill: currentAmount)
        }
    }

    @IBAction func onTap(_ sender: AnyObject) {
        view.endEditing(true)
    }
}
