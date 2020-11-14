//
//  ViewController.swift
//  QNota
//
//  Created by Rafael Ferreira Rodrigues on 13/11/20.
//

import UIKit
import Vision
import CoreML

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    private var imagePickerController = UIImagePickerController()
    
    @IBOutlet weak var resultLabel: UILabel!
    private var gotNewImage = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = .camera //Use camera instead of Photo Library
        
    }
    
    
    @IBAction func onShareTapped(_ sender: UIBarButtonItem) {

        // if no image has been captured yet
        if !gotNewImage {
            return
        }

        // set up activity view controller
        let imageToShare = [ imageView.image ]
        let activityViewController = UIActivityViewController(activityItems: imageToShare as [Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash

        
        // exclude some activity types from the list
        activityViewController.excludedActivityTypes = [ .addToReadingList,
                                                         .assignToContact,
                                                         .openInIBooks,
                                                         .markupAsPDF]

        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func onCameraTapped(_ sender: UIBarButtonItem) {
        present(imagePickerController, animated: true, completion: nil)
    }
    
// MARK: - ImagePicker Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage { //346
            imageView.image = image
            guard let ciImage = CIImage(image: image) else {
                fatalError("Error converting image")
            }
            gotNewImage = true
            print("Detecting image " + ciImage.description)
            detectBill(billImage: ciImage)
            
        } //346
        
        imagePickerController.dismiss(animated: true, completion: nil)
    }
// MARK: -Core ML CNN
    
    func detectBill(billImage: CIImage) {
        guard let model = try? VNCoreMLModel(for: BillClassifier_1().model) else {
            fatalError("Failed loading model.")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation], let topResult = results.first else {
                fatalError("Unable to create request for observation.")
            }
            print(topResult.identifier)
            
            let topClassifications = results.prefix(2).map {
              (confidence: $0.confidence, identifier: $0.identifier)
            }
            self.resultLabel.text = "Top classifications: \(topClassifications)"
            print("Top classifications: \(topClassifications)")
            self.resultLabel.isHidden = false
        }
        let handler = VNImageRequestHandler(ciImage: billImage)
        
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
    }
}

