//
//  ViewController.swift
//  CoreML Image Classification
//
//  Created by Vardhan Agrawal on 10/23/17.
//  Copyright © 2017 Vardhan Agrawal. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController {
  
  // MARK: - Interface Builder Connctions
  @IBOutlet weak var objectLabel: UILabel!
  @IBOutlet weak var confidenceLabel: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  
  // MARK: - Initial Load
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Configures AVCaptureSession and adds it as a sublayer of an imageView
    setupSession()
  }
  
  // MARK: - CoreML
  // Tells the delegate when a new frame is created from the live view
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    // Creates a pixel buffer from the passed in media (from the delegate)
    guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    // Instantiates the MobileNet model for use in the code
    guard let model = try? VNCoreMLModel(for: MobileNet().model) else { return }
    
    // Creates a request using the model declared above
    let request = VNCoreMLRequest(model: model) { (data, error) in
      
      // Checks if thd data is in the correct format and assigns it to results
      guard let results = data.results as? [VNClassificationObservation] else { return }
      // Assigns the first result (if it exists) to firstObject
      guard let firstObject = results.first else { return }
      
      // Gets called when the CoreML request has data
      DispatchQueue.main.async {
        // Checks if the program is at least 50% sure of the object
        if firstObject.confidence * 100 >= 50 {
          // Displays the label on screen
          self.objectLabel.text = firstObject.identifier.capitalized
          // Displays the confidence on screen
          self.confidenceLabel.text = String(firstObject.confidence * 100) + "%"
        }
      }
    }
    // Attempts to process the image
    try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
  }
}

// MARK: - AVCaptureSession
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  // Configures AVCaptureSession and adds it as a sublayer of an imageView
  func setupSession() {
    
    // Checks if current device has a camera
    guard let device = AVCaptureDevice.default(for: .video) else { return }
    // Creates an AVCaptureDeviceInput (camera input) from the device above
    guard let input = try? AVCaptureDeviceInput(device: device) else { return }
    
    // Creates an AVCaptureSession
    let session = AVCaptureSession()
    // Sets bitrate and quality to UHD (3840 x 2160 pixels)
    session.sessionPreset = .hd4K3840x2160
    
    // Creates a layer so that input can be viewed
    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
    // Makes the preview layer appear fullscreen
    previewLayer.frame = view.frame
    // Adds the input to an imageView
    imageView.layer.addSublayer(previewLayer)
    
    // Creates an instance of AVCaptureVideoDataOutput()
    let output = AVCaptureVideoDataOutput()
    // Sets the sample buffer (frame rate, etc.) to the current thread
    output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
    // Adds the output to the AVCapture session
    session.addOutput(output)
    
    // Sets the input of the AVCaptureSession to the device's camera input
    session.addInput(input)
    // Starts the capture session
    session.startRunning()
  }
}
