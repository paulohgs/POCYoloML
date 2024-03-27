//
//  ViewController.swift
//  POCYoloML
//
//  Created by Paulo Henrique on 21/03/24.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        let captureSession: AVCaptureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(input)
        
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoOutput"))
        captureSession.addOutput(dataOutput)
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        guard let model = try? yolov8s(configuration: .init()).model else {return}
        guard let detector = try? VNCoreMLModel(for: model) else {return}
        let request = VNCoreMLRequest(model: detector, completionHandler: {
            request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation] else {return}
            guard let twoObservations = results.first else {return}
            let (firstLabel, secondLabel) = (twoObservations.labels[0], twoObservations.labels[1])
            let (firstConfidence, secondConfidence) = (twoObservations.labels[0].confidence, twoObservations.labels[1].confidence)
            print("Primeiro palpite: \(firstLabel.identifier) | confidencia: \(firstConfidence)\nsegundo palpite \(secondLabel.identifier) | confidencia: \(secondConfidence)")
            
        })
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
            
        } catch {
            print(error)
        }
    }
}

