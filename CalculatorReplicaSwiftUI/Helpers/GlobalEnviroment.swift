//
//  GlobalEnviroment.swift
//  CalculatorReplicaSwiftUI
//
//  Created by Alonso on 4/11/20.
//  Copyright © 2020 Alonso. All rights reserved.
//

import Foundation
import Combine

class GlobalEnviroment: ObservableObject {
    @Published var formattedCalculatorDisplay: String = "0"
    
    lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()
    
    var calculatorDisplay: String! {
        didSet {
            guard let largeNumber = Double(calculatorDisplay),
                let formattedNumber = numberFormatter.string(from: NSNumber(value:largeNumber)) else {
                    return
            }
            formattedCalculatorDisplay = formattedNumber
        }
    }
    
    private var resultValue: Double = 0
    
    let calculatorButtons: [[CalculatorOptionProtocol]]
    
    var isEnteringNumbers: Bool = false
    
    private var pendingBinaryOperation: PendingBinaryOperation?
    
    var numberOfButtonsPerRow: Int? {
        return calculatorButtons.first?.count
    }
    
    private var areDisplayCharactersInRange: Bool {
        return calculatorDisplay.filter { $0.isNumber }.count < Constants.maxLimit
    }
    
    // MARK: - Initializers
    
    init(calculatorButtons: [[CalculatorOptionProtocol]]) {
        self.calculatorButtons = calculatorButtons
    }
    
    // MARK: - Utils
    
    func updateDisplay() {
        let isInteger = resultValue.truncatingRemainder(dividingBy: 1) == 0
        let valueToDisplay: CustomStringConvertible = isInteger ? Int(resultValue) : resultValue
        calculatorDisplay = String(valueToDisplay.description)
    }
    
    func updateResultValue() {
        guard let value = Double(calculatorDisplay) else { return }
        resultValue = value
    }
    
    // MARK: - Calculator Operations
    
    func isOptionAlreadyPresent(_ calculatorOption: CalculatorOptionProtocol) -> Bool {
        return calculatorDisplay.contains(calculatorOption.title)
    }
    
    func updateCalculatorDisplay(calculatorOption: CalculatorOptionProtocol) {
        if calculatorOption.shouldShowOnResultDisplay {
            updateDisplay(calculatorOption)
        } else {
            performOperation(calculatorOption)
        }
    }
    
    private func updateDisplay(_ calculatorOption: CalculatorOptionProtocol) {
        if !calculatorOption.isPlainNumber, isOptionAlreadyPresent(calculatorOption) { return }
        if isEnteringNumbers, !areDisplayCharactersInRange { return }
        if resultValue == .zero && !isEnteringNumbers { calculatorDisplay = "" }
        calculatorDisplay += calculatorOption.title
        isEnteringNumbers = true
    }
    
    private func performOperation(_ calculatorOption: CalculatorOptionProtocol) {
        guard let operation = calculatorOption.operation else { return }
        isEnteringNumbers = false
        updateResultValue()
        switch operation {
        case .clear:
            clearDisplay()
        case .unaryOperation(let function):
            resultValue = function(resultValue)
            updateDisplay()
        case .binaryOperation(let function):
            pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: resultValue)
            resultValue = 0
        case .blank, .constant:
            break
        case .equals:
            performPendingBinaryOperation()
            updateDisplay()
            resultValue = 0
        }
    }
    
    private func clearDisplay() {
        resultValue = 0
        updateDisplay()
        pendingBinaryOperation = nil
    }
    
    private func performPendingBinaryOperation() {
        guard let pendingBinaryOperation = pendingBinaryOperation else { return }
        if !pendingBinaryOperation.hasSecondOperand {
            pendingBinaryOperation.setSecondOperand(resultValue)
        }
        resultValue = pendingBinaryOperation.perform()
    }
}

// MARK: - PendingBinaryOperation

extension GlobalEnviroment {
    class PendingBinaryOperation {
        let function: (Double, Double) -> Double
        var firstOperand: Double
        var secondOperand: Double? = nil
        
        init(function: @escaping (Double, Double) -> Double, firstOperand: Double) {
            self.function = function
            self.firstOperand = firstOperand
        }
        
        var hasSecondOperand: Bool {
            return secondOperand != nil
        }
        
        func setSecondOperand(_ secondOperand: Double) {
            self.secondOperand = secondOperand
        }
        
        func perform() -> Double {
            guard let secondOperand = secondOperand else { return 0 }
            let value = function(firstOperand, secondOperand)
            firstOperand = value
            return value
        }
    }
}

// MARK: - Constants

extension GlobalEnviroment {
    struct Constants {
        static let maxLimit = 9
    }
}
