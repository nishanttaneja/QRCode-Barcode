//
//  ViewController.swift
//  QRCode-Barcode
//
//  Created by Nishant Taneja on 01/03/21.
//

import UIKit

class ViewController: UIViewController {
    // IBOutlet
    @IBOutlet private weak var inputTextField: UITextField!
    @IBOutlet private weak var codeSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var generateCodeButton: UIButton!
    @IBOutlet weak var codeImageView: UIImageView!
    
    // Variables
    private var selectedCodeType: CodeType? {
        if codeSegmentedControl.selectedSegmentIndex == 0 { return .QRCode }
        else if codeSegmentedControl.selectedSegmentIndex == 1 { return .Barcode }
        return nil
    }
    private var code: UIImage? {
        willSet {
            DispatchQueue.main.async {
                self.codeImageView.image = newValue
            }
        }
    }
    private var qrCode: UIImage?
    private var barcode: UIImage?
    private var imageForSelectedSegmentedControl: UIImage? {
        if selectedCodeType == .QRCode { return qrCode }
        else if selectedCodeType == .Barcode { return barcode }
        return nil
    }
    
    // IBAction
    @IBAction private func codeSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        // Update Image for selected CodeType
        updateUI()
    }
    @IBAction private func generateCodeButtonAction(_ sender: UIButton) {
        // Generate Image for selected CodeType
        guard let text = inputTextField.text,
              let data = text.data(using: .ascii, allowLossyConversion: false) else { return }
        generateCodes(from: data)
        updateUI()
    }
}

private extension ViewController {
    func updateUI() {
        DispatchQueue.main.async {
            self.codeImageView.image = self.imageForSelectedSegmentedControl
        }
    }
    
    func generateCodes(from data: Data) {
        CodeType.allCases.forEach { (codeType) in
            generateCode(ofType: codeType, fromData: data)
        }
    }
    
    func generateCode(ofType codeType: CodeType, fromData data: Data) {
        guard let filter = filter(forCodeType: codeType) else { return }
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        if let ciImage = filter.outputImage?.transformed(by: transform) {
            let image = UIImage(ciImage: ciImage)
            if codeType == .QRCode { qrCode = image }
            else if codeType == .Barcode { barcode = image }
            print(codeType)
        }
    }
    
    func filter(forCodeType codeType: CodeType) -> CIFilter? {
        switch codeType {
        case .QRCode: return CIFilter(name: "CIQRCodeGenerator")
        case .Barcode: return CIFilter(name: "CICode128BarcodeGenerator")
        }
    }
}


fileprivate enum CodeType: CaseIterable {
    case QRCode
    case Barcode
}
