//
//  ViewController.swift
//  QRCode-Barcode
//
//  Created by Nishant Taneja on 01/03/21.
//

import UIKit
import PhotosUI

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
    @IBAction func didSelectShareBarButtonItem(_ sender: UIBarButtonItem) {
        guard let image = codeImageView.image else {
            displayAlert(withTitle: "Invalid Image", message: "Image is not available.")
            return
        }
        shareImage(image)
    }
    @IBAction func didSelectScanQRCodeButtonItem(_ sender: UIBarButtonItem) {
        selectImage()
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


fileprivate extension ViewController {
    // Displays alert if image is not found
    func displayAlert(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // Displays Share Sheet
    func shareImage(_ image: UIImage) {
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
}


// MARK: - Scan QR
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
    // Provide an option to select image from Files App or Photos App
    private func selectImage() {
        let alert = UIAlertController(title: "Select Image", message: "Select an image from Files App or Photos App", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Files App", style: .default, handler: { _ in
            self.selectImageFromFiles()
        }))
        alert.addAction(UIAlertAction(title: "Photos App", style: .default, handler: { _ in
            // Get Authorisation before accessing photos
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let status = PHPhotoLibrary.authorizationStatus()
                if status == .notDetermined {
                    PHPhotoLibrary.requestAuthorization { status in
                        if status == .authorized {
                            self.selectImageFromPhotos()
                        } else {
                            // display alert
                            let alert = UIAlertController(title: "Photos Access Denied", message: "Please provide access to photos in settings", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            DispatchQueue.main.async { [weak self] in
                                self?.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                } else if status == .authorized {
                    self.selectImageFromPhotos()
                } else {
                    // display alert
                    let alert = UIAlertController(title: "Photos Access Denied", message: "Please provide access to photos in settings", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    DispatchQueue.main.async { [weak self] in
                        self?.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // Select an image from Files App
    private func selectImageFromFiles() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.image], asCopy: true)
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    // DocumentPicker Delegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedImageURL = urls.first else { return }
        guard let selectedImageData = try? Data(contentsOf: selectedImageURL) else { return }
        guard let selectedImage = UIImage(data: selectedImageData) else { return }
        codeImageView.image = selectedImage
        scanQRCode(from: selectedImage)
    }
    
    // Select an Image from Photos App
    private func selectImageFromPhotos() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    // Scan the QR Code from image
    private func scanQRCode(from image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        let context = CIContext(options: nil)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage)
        if let feature = features?.first as? CIQRCodeFeature {
            let scannedValue = feature.messageString
            inputTextField.text = scannedValue
        }
    }
    
    // ImagePickerController Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            codeImageView.image = selectedImage
            scanQRCode(from: selectedImage)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
