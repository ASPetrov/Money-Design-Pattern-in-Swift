//
//  ViewController.swift
//  TestFrameworkApp
//
//  Created by Aleksandar Petrov on 10/28/15.
//  Copyright © 2015 Aleksandar Petrov. All rights reserved.
//

import UIKit

import MoneyFramework

// Dummy Data Source
enum CurrencyTypes: String {
    case
    
    USDollar = "USD",
    EuropeanEuro = "EUR",
    BulgarianLev = "BGN",
    JapaneseYen = "JPY"
    
    static func allValues() -> [String] {
        return [USDollar.rawValue,
            EuropeanEuro.rawValue,
            BulgarianLev.rawValue,
            JapaneseYen.rawValue]
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var amountTitleLabel: UILabel!
    @IBOutlet weak var fromCurrencyTitleLabel: UILabel!
    @IBOutlet weak var toCurrencyTitleLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    
    @IBOutlet weak var amountTextField: UITextField!
    
    @IBOutlet weak var fromCurrencySegmentControl: UISegmentedControl!
    @IBOutlet weak var toCurrencySegmentControl: UISegmentedControl!
    
    @IBOutlet weak var resultContainerView: UIView!
    
    //
    // MARK: Actions
    //
    
    func doneButtonAction() {
        self.amountTextField.resignFirstResponder()
    }
    
    @IBAction func fromCurrencyChanged(sender: UISegmentedControl) {
        self.clearAmountFractionIfNeeded()
        self.convert()
    }
    
    @IBAction func toCurrencyChanged(sender: UISegmentedControl) {
        self.convert()
    }
    
    //
    // MARK: Lifecycle
    //

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //
    // MARK: Private
    //
    
    let maximumWholeDigits : Int = 10
    
    var maximumFractionDigits : Int {
        get {
            let fromCurrency =
                self.currencyForSegmentControlSelectedIndex(self.fromCurrencySegmentControl)
            return fromCurrency!.maximumFractionDigits
        }
    }
    
    func convert() {
        if self.amountTextField.text == nil || self.amountTextField.text!.characters.count == 0 {
            return
        }
        
        if self.fromCurrencySegmentControl.selectedSegmentIndex == UISegmentedControlNoSegment {
            return
        }
        
        if self.toCurrencySegmentControl.selectedSegmentIndex == UISegmentedControlNoSegment {
            return
        }
        
        let toCurrency = self.currencyForSegmentControlSelectedIndex(self.toCurrencySegmentControl)
        let fromCurrency = self.currencyForSegmentControlSelectedIndex(self.fromCurrencySegmentControl)

        let fromMoney = Money(amount: self.amountTextField.text!, currency: fromCurrency!);

        if fromCurrency == toCurrency {
            let toMoney = Money(amount: self.amountTextField.text!, currency: toCurrency!);
            self.resultLabel.text =
                "\(fromMoney)" + NSLocalizedString(" is ", comment: "") + "\(toMoney)"
        } else {
            self.resultLabel.text = NSLocalizedString("Fetching Rates ...", comment: "Final Conversion Amount Label")
            self.exchangeRate(fromCurrency!.code, toCurrency: toCurrency!.code, completion: { (result) -> Void in
                if let amount = result {
                    let toMoney = fromMoney.convertTo(toCurrency!, usingExchangeRate: amount)
                    self.resultLabel.text =
                        "\(fromMoney)" + NSLocalizedString(" is ", comment: "") + "\(toMoney)"
                } else {
                    self.resultLabel.text = NSLocalizedString("...", comment: "Final Conversion Amount Label")
                }
            })
        }
    }
    
    func currencyForSegmentControlSelectedIndex(control: UISegmentedControl) -> Currency? {
        let currencyTypeRaw = CurrencyTypes.allValues()[control.selectedSegmentIndex]
        return Currency.currencyWithCurrencyCode(currencyCode: currencyTypeRaw)
    }
    
    func clearAmountFractionIfNeeded() {
        let decimalSeparator: String =
            NSLocale.currentLocale().objectForKey(NSLocaleDecimalSeparator) as! String
        let separatorRange = self.amountTextField.text?.rangeOfString(decimalSeparator)
        if separatorRange != .None && self.maximumFractionDigits == 0 {
            let range = separatorRange!.startIndex..<self.amountTextField.text!.endIndex
            let substr = self.amountTextField.text![range]
            self.amountTextField.text = self.amountTextField.text?.stringByReplacingOccurrencesOfString(substr, withString: "")
        }
    }
    
    func setup() {
        self.navigationItem.title = NSLocalizedString("Currency Converter", comment: "App Title")
        
        self.setupAmountTextField()
        self.setupResultContainerView()
        self.setupNavigationController()
        self.setupCurrencySegmentControls()
        
        self.resultLabel.text = NSLocalizedString("...", comment: "Final Conversion Amount Label")
    }
    
    func setupAmountTextField() {
        self.addDoneButtonOnKeyboard()
        self.amountTextField.delegate = self
        self.amountTextField.placeholder =
            NSLocalizedString("Enter Amount ", comment: "Placeholder text")
    }
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))

        let flexSpace =
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace,
                target: nil, action: nil)
        let done: UIBarButtonItem =
            UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done,
                target: self, action: Selector("doneButtonAction"))
        
        let items = [flexSpace, done]
        
        doneToolbar.barStyle = UIBarStyle.BlackTranslucent
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.amountTextField.inputAccessoryView = doneToolbar
        
    }
    
    func setupNavigationController() {
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.barStyle = .Black
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSForegroundColorAttributeName : UIColor.whiteColor()]
    }
    
    func setupResultContainerView() {
        self.resultContainerView.layer.borderColor = UIColor.whiteColor().CGColor
        self.resultContainerView.layer.borderWidth = 2.0 / UIScreen.mainScreen().scale
        self.resultContainerView.layer.cornerRadius = 8.0
    }
    
    func setupCurrencySegmentControls() {
        self.setupCurrencySegmentControl(self.toCurrencySegmentControl)
        self.setupCurrencySegmentControl(self.fromCurrencySegmentControl)
        
        self.fromCurrencySegmentControl.selectedSegmentIndex = 0
    }
    
    func setupCurrencySegmentControl(control: UISegmentedControl) {
        control.tintColor = UIColor.whiteColor()
        
        control.removeAllSegments()
        for (index, code) in CurrencyTypes.allValues().enumerate() {
            control.insertSegmentWithTitle(code, atIndex: index, animated: false)
        }
    }
}

extension ViewController : UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {        
        self.convert()
        return true;
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // Allowing Backspace and other non-visible characters
        if range.length > 0 && string.characters.count == 0 {
            return true
        }
        
        // Decimal separator should not be first
        let decimalSeparator: String =
            NSLocale.currentLocale().objectForKey(NSLocaleDecimalSeparator) as! String
        if self.maximumFractionDigits == 0 && string == decimalSeparator {
            return false
        }
        if range.location == 0 && string == decimalSeparator {
            textField.text = "0\(string)"
            return false
        }
        
        // Allowing only a specified set of characters to be entered into a given text field
        let validCharacters: String = "0123456789\(decimalSeparator)"
        let disallowedCharacterSet: NSCharacterSet =
            NSCharacterSet(charactersInString: validCharacters).invertedSet
        let replacementStringIsLegal: Bool =
            (string.rangeOfCharacterFromSet(disallowedCharacterSet) == .None)
        if !replacementStringIsLegal {
            return false;
        }
        
        // Handle first char 0
        if textField.text == "0" && string != decimalSeparator {
            textField.text = string
            return false;
        }
        
        // Limiting the number of characters that can be entered into a given text field
        let prospectiveText: String = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        let separatorRange = prospectiveText.rangeOfString(decimalSeparator)
        let maxTextLenght = self.maximumWholeDigits + ((separatorRange == .None) ? 0 : (1 + self.maximumFractionDigits))
        let resultingStringLengthIsLegal: Bool = (prospectiveText.characters.count <= maxTextLenght)
        if !resultingStringLengthIsLegal {
            return false
        }
        
        // Limiting the number of characters that can be entered  after the decimal separator
        if separatorRange != .None {
            let fractionalCharactersCountIsLegal: Bool =
                (range.location <= (prospectiveText.startIndex.distanceTo(separatorRange!.startIndex) + self.maximumFractionDigits));
            if !fractionalCharactersCountIsLegal {
                return false;
            }
        }
        
        // Confirming that the value entered into a text field is numeric
        let scanner: NSScanner = NSScanner(string: prospectiveText)
        let resultingTextIsNumeric: Bool = (scanner.scanDecimal(nil) && scanner.atEnd)
        if !resultingTextIsNumeric {
            return false;
        }
        
        return true
    }
}

//
// MARK: Communication
//

extension ViewController {
    func exchangeRate(fromCurrency: String, toCurrency: String, completion: ((result: NSDecimalNumber?) -> Void)!) {
        let baseURL = "https://query.yahooapis.com/v1/public/yql?q="
        let query = "select * from yahoo.finance.xchange where pair in (\"\(fromCurrency)\(toCurrency)\")" +
            "&format=json&env=store://datatables.org/alltableswithkeys&callback="
        
        let urlString = baseURL + query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        if let url = NSURL(string: urlString) {
            NSURLSession.sharedSession().dataTaskWithURL(url) { data, response, error in
                if error != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(result: nil)
                    }
                    return;
                }
                
                do {
                    guard let serverData = data,
                          let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(serverData, options: NSJSONReadingOptions(rawValue: 0)) as? NSDictionary,
                          let queryResults = jsonDictionary["query"] as? NSDictionary,
                          let results = queryResults["results"] as? NSDictionary,
                          let rate = results["rate"] as? NSDictionary,
                          let exchangeRate = rate["Rate"] as? String else {
                            completion(result: nil)
                            return;
                    }

                    dispatch_async(dispatch_get_main_queue()) {
                        let result = NSDecimalNumber(string: exchangeRate)
                        completion(result: result)
                    }
                } catch {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(result: nil)
                    }
                }
            }.resume()
        }
    }
}

