//
//  ViewController.swift
//  TestFrameworkApp
//
//  Created by Aleksandar Petrov on 10/28/15.
//  Copyright © 2015 Aleksandar Petrov. All rights reserved.
//

import UIKit

import MoneyFramework

// MARK: - Dummy Data Source

enum CurrencyTypes: String, CaseIterable {
    case usd = "USD"
    case euro = "EUR"
    case lev = "BGN"
    case yen = "JPY"
}

//

class ViewController: UIViewController {
    @IBOutlet weak var amountTitleLabel: UILabel!
    @IBOutlet weak var fromCurrencyTitleLabel: UILabel!
    @IBOutlet weak var toCurrencyTitleLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!

    @IBOutlet private weak var amountTextField: UITextField!

    @IBOutlet private weak var fromCurrencySegmentControl: UISegmentedControl!
    @IBOutlet weak var toCurrencySegmentControl: UISegmentedControl!

    @IBOutlet private weak var resultContainerView: UIView!

    // MARK: - Actions

    @objc
    private func doneButtonAction() {
        self.amountTextField.resignFirstResponder()
    }

    @IBAction private func fromCurrencyChanged(_ sender: UISegmentedControl) {
        self.clearAmountFractionIfNeeded()
        self.convert()
    }

    @IBAction private func toCurrencyChanged(_ sender: UISegmentedControl) {
        self.convert()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    // MARK: - Helpers

    private func convert() {
        guard let amount = self.amountTextField.text, !amount.isEmpty else {
            return
        }

        guard let fromCurrency = self.currencyForSegmentControlSelectedIndex(self.fromCurrencySegmentControl) else {
            return
        }

        guard let toCurrency = self.currencyForSegmentControlSelectedIndex(self.toCurrencySegmentControl) else {
            return
        }

        let fromMoney = Money(amount: amount, currency: fromCurrency)!

        if fromCurrency == toCurrency {
            let toMoney = Money(amount: amount, currency: toCurrency)
            self.resultLabel.text =
            "\(String(describing: fromMoney)) \(NSLocalizedString("is", comment: "")) \(String(describing: toMoney))"
        } else {
            self.resultLabel.text = NSLocalizedString("Fetching Rates ...", comment: "Final Conversion Amount Label")
            self.exchangeRate(fromCurrency.code, toCurrency: toCurrency.code, completion: { (result) -> Void in
                if let amount = result {
                    let toMoney = try! fromMoney.convertTo(toCurrency, usingExchangeRate: amount)
                    self.resultLabel.text =
                    "\(String(describing: fromMoney)) \(NSLocalizedString("is", comment: "")) \(toMoney)"
                } else {
                    self.resultLabel.text = NSLocalizedString("...", comment: "Final Conversion Amount Label")
                }
            })
        }
    }

    private func clearAmountFractionIfNeeded() {
        let decimalSeparator: String =
            (Locale.current as NSLocale).object(forKey: NSLocale.Key.decimalSeparator) as! String
        let separatorRange = self.amountTextField.text?.range(of: decimalSeparator)
        if separatorRange != .none && self.maximumFractionDigits == 0 {
            let range = separatorRange!.lowerBound..<self.amountTextField.text!.endIndex
            let substr = self.amountTextField.text![range]
            self.amountTextField.text = self.amountTextField.text?.replacingOccurrences(of: substr, with: "")
        }
    }

    // MARK: - Setup

    private func setup() {
        self.navigationItem.title = NSLocalizedString("Currency Converter", comment: "App Title")

        self.setupAmountTextField()
        self.setupResultContainerView()
        self.setupNavigationController()
        self.setupCurrencySegmentControls()

        self.resultLabel.text = NSLocalizedString("...", comment: "Final Conversion Amount Label")
    }

    private func setupAmountTextField() {
        self.addDoneButtonOnKeyboard()
        self.amountTextField.delegate = self
        self.amountTextField.placeholder =
            NSLocalizedString("Enter Amount ", comment: "Placeholder text")
    }

    private func setupNavigationController() {
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.barStyle = .black
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSAttributedStringKey.foregroundColor : UIColor.white]
    }

    private func setupResultContainerView() {
        self.resultContainerView.layer.borderColor = UIColor.white.cgColor
        self.resultContainerView.layer.borderWidth = 2.0 / UIScreen.main.scale
        self.resultContainerView.layer.cornerRadius = 8.0
    }

    // MARK: - Segment Controls

    private func setupCurrencySegmentControls() {
        self.setupCurrencySegmentControl(self.toCurrencySegmentControl)
        self.setupCurrencySegmentControl(self.fromCurrencySegmentControl)

        self.fromCurrencySegmentControl.selectedSegmentIndex = 0
    }

    private func setupCurrencySegmentControl(_ control: UISegmentedControl) {
        control.tintColor = UIColor.white

        control.removeAllSegments()
        for (index, code) in CurrencyTypes.allCases.enumerated() {
            control.insertSegment(withTitle: code.rawValue, at: index, animated: false)
        }
    }

    private func currencyForSegmentControlSelectedIndex(_ control: UISegmentedControl) -> LocaleCurrency? {
        if control.selectedSegmentIndex == UISegmentedControlNoSegment {
            return nil
        }
        let currencyTypeRaw = CurrencyTypes.allCases[control.selectedSegmentIndex].rawValue
        return LocaleCurrency(isoCurrencyCode: currencyTypeRaw)
    }

    // MARK: - Keyboard

    private func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))

        let flexSpace =
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
                            target: nil, action: nil)
        let done: UIBarButtonItem =
            UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done,
                            target: self, action: #selector(doneButtonAction))

        let items = [flexSpace, done]

        doneToolbar.barStyle = UIBarStyle.blackTranslucent
        doneToolbar.items = items
        doneToolbar.sizeToFit()

        self.amountTextField.inputAccessoryView = doneToolbar

    }

    // MARK: - TextField Helpers

    private let maximumWholeDigits : Int = 10

    private var maximumFractionDigits : Int {
        get {
            let fromCurrency = self.currencyForSegmentControlSelectedIndex(self.fromCurrencySegmentControl)
            return fromCurrency!.minorUnits
        }
    }

}

// MARK: - UITextFieldDelegate

extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.convert()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allowing Backspace and other non-visible characters
        if range.length > 0 && string.isEmpty {
            return true
        }

        // Decimal separator should not be first
        let decimalSeparator: String =
            (Locale.current as NSLocale).object(forKey: NSLocale.Key.decimalSeparator) as! String
        if self.maximumFractionDigits == 0 && string == decimalSeparator {
            return false
        }
        if range.location == 0 && string == decimalSeparator {
            textField.text = "0\(string)"
            return false
        }

        // Allowing only a specified set of characters to be entered into a given text field
        let validCharacters: String = "0123456789\(decimalSeparator)"
        let disallowedCharacterSet: CharacterSet =
            CharacterSet(charactersIn: validCharacters).inverted
        let replacementStringIsLegal: Bool =
            (string.rangeOfCharacter(from: disallowedCharacterSet) == .none)
        if !replacementStringIsLegal {
            return false
        }

        // Handle first char 0
        if textField.text == "0" && string != decimalSeparator {
            textField.text = string
            return false
        }

        // Limiting the number of characters that can be entered into a given text field
        let prospectiveText: String = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let separatorRange = prospectiveText.range(of: decimalSeparator)
        let maxTextLenght = self.maximumWholeDigits + ((separatorRange == .none) ? 0 : (1 + self.maximumFractionDigits))
        let resultingStringLengthIsLegal: Bool = (prospectiveText.count <= maxTextLenght)
        if !resultingStringLengthIsLegal {
            return false
        }

        // Limiting the number of characters that can be entered  after the decimal separator
        if separatorRange != .none {
            let fractionalCharactersCountIsLegal: Bool =
                (range.location <= (prospectiveText.distance(from: prospectiveText.startIndex, to: separatorRange!.lowerBound) + self.maximumFractionDigits))
            if !fractionalCharactersCountIsLegal {
                return false
            }
        }

        // Confirming that the value entered into a text field is numeric
        let scanner: Scanner = Scanner(string: prospectiveText)
        let resultingTextIsNumeric: Bool = (scanner.scanDecimal(nil) && scanner.isAtEnd)
        if !resultingTextIsNumeric {
            return false
        }

        return true
    }

}

private extension ViewController {

    // MARK: - Communication

    // TODO: Fixer API update, requires to create an account at https://fixer.io and obtain an API access key
    // NOTE: For more information on how to upgrade please visit our Github Tutorial at: https://github.com/fixerAPI/fixer#readme  
    // yahoo finance xchange is Discontinued as of 2017-11-06
    func exchangeRate(_ fromCurrency: String, toCurrency: String, completion: ((_ result: Decimal?) -> Void)!) {
        let urlString = "https://api.fixer.io/latest?base=\(fromCurrency)&symbols=\(toCurrency)"
        //        let baseURL = "https://query.yahooapis.com/v1/public/yql?q="
        //        let query = "select * from yahoo.finance.xchange where pair in (\"\(fromCurrency)\(toCurrency)\")" +
        //            "&format=json&env=store://datatables.org/alltableswithkeys&callback="
        //
        //        let urlString = baseURL + query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        //
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                if error != nil {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                do {
                    guard let jsonData = data else {
                        DispatchQueue.main.async { completion(nil) }
                        return
                    }

                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .formatted(.apiDateFormatter)
                    let ratesResponse = try decoder.decode(Response.self, from: jsonData)

                    guard let exchangeRate = ratesResponse.rates[toCurrency] else {
                        DispatchQueue.main.async { completion(nil) }
                        return
                    }

                    DispatchQueue.main.async {
                        let result = Decimal(exchangeRate)
                        completion(result)
                    }
                } catch {
                    // Bad JSON Response
                    DispatchQueue.main.async { completion(nil) }
                }
            }) .resume()
        }

    }

}

// MARK: - Helpers

extension DateFormatter {
    static var apiDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }
}

// MARK: - Model

struct Response: Codable {
    var base: String?
    var date: Date?
    var rates: [String: Double]
}
