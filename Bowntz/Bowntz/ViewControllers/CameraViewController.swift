//
//  ViewController.swift
//  Bowntz
//
//  Created by Cagri Sahan on 3/11/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation

class CameraViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak var sendBowntzButton: UIButton!
    @IBOutlet weak var textMessageButton: UIButton!
    @IBOutlet weak var previewView: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    
    // MARK: Variables
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var capturePhotoOutput: AVCapturePhotoOutput?
    var photoSettings: AVCapturePhotoSettings?
    var cameraLaunchSuccess = true
    var locationManager = CLLocationManager()
    var textMessage: String?
    var image: UIImage?
    var sender: String?
    var recipient: String?
    let application = UIApplication.shared
    var identifier: UIBackgroundTaskIdentifier?
    
    // MARK: Lifecycle
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "textInputSegue":
                let vc = segue.destination as! MessageScreenController
                vc.delegate = self
                vc.textMessage = textMessage
                self.captureSession?.stopRunning()
            case "recipientPickerSegue":
                let vc = segue.destination as! RecipientPickerViewController
                vc.delegate = self
            default:
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        locationManager.delegate = self
        checkLocationPermissions()
        refreshBowntz()
    }
    
    // MARK: Functions
    func showErrorDialogue(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(actionOK)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func captureButtonPressed(_ sender: Any) {
        guard let capturePhotoOutput = self.capturePhotoOutput else { showErrorDialogue(message: "Could not initialize output"); return }
        
        print("Capture button pressed")
        initializePhotoSettings()
        capturePhotoOutput.capturePhoto(with: photoSettings!, delegate: self)
    }
    
    func prepareCamera(camera: AVCaptureDevice) {
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            // Set up input from camera
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            // Set up output from session
            capturePhotoOutput = AVCapturePhotoOutput()
            capturePhotoOutput?.isHighResolutionCaptureEnabled = true
            captureSession?.addOutput(capturePhotoOutput!)
            
            // Set up preview
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayer?.frame = view.layer.bounds
            previewView.layer.addSublayer(previewLayer!)
            
            // Show capture button
            prepareButtonsForCapture()
        } catch {
            cameraLaunchSuccess = false
        }
    }
    
    func initializePhotoSettings() {
        photoSettings = AVCapturePhotoSettings()
        photoSettings?.isAutoStillImageStabilizationEnabled = true
        photoSettings?.isHighResolutionPhotoEnabled = true
        photoSettings?.flashMode = .off
    }
    
    func startPreview(session: AVCaptureSession) {
        session.startRunning()
    }
    
    func prepareButtonsForCapture() {
        captureButton.isHidden = false
        sendBowntzButton.isHidden = true
        textMessageButton.isHidden = true
    }
    
    func prepareButtonsForBowntz() {
        captureButton.isHidden = true
        sendBowntzButton.isHidden = false
        textMessageButton.isHidden = false
    }
    
    func checkLocationPermissions() {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        else { return }
    }
    
    
}


// MARK: Extensions
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { showErrorDialogue(message: "Could not take photo"); return }
        prepareButtonsForBowntz()
        let imageData = photo.fileDataRepresentation()!
        image = UIImage(data: imageData)
        previewLayer?.removeFromSuperlayer()
        previewView.image = image
    }
}

extension CameraViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        showErrorDialogue(message: "Could not get location data. Will send without location.")
        let bowntz = Bowntz(image: image!, location: nil, message: textMessage, date: Date(), authorRecordName: sender!, recipientRecordName: recipient!)
        CloudUtility.shared.addEntry(bowntz) { record, error in
            guard error == nil else { self.showErrorDialogue(message: "Could not send Bowntz."); return }
            print("Sent successfully!")
            self.application.endBackgroundTask(self.identifier!)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        if let location = locations.last {
            print("Got location data")
            let bowntz = Bowntz(image: image!, location: location, message: textMessage, date: Date(), authorRecordName: sender!, recipientRecordName: recipient!)
            CloudUtility.shared.addEntry(bowntz) { record, error in
                guard error == nil else { self.showErrorDialogue(message: "Could not send Bowntz."); return }
                print("Sent successfully!")
                self.application.endBackgroundTask(self.identifier!)
                DispatchQueue.main.sync{
                    self.previewView.layer.removeAllAnimations()
                    self.previewView.alpha = 1.0
                    self.refreshBowntz()
                }
            }
        }
    }
}

extension CameraViewController: TextInputPassable {
    func passMessageStringAndSubmit(_ message: String) {
        self.textMessage = message
    }
}

extension CameraViewController: Messenger {
    func passMessage(from: String, to: String) {
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat,.autoreverse], animations: { [unowned self] in
            self.previewView.alpha = 0.1
            }, completion: nil)
        sender = from
        recipient = to
        identifier = application.beginBackgroundTask {
            self.application.endBackgroundTask(self.identifier!)
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        locationManager.requestLocation()
    }
}

extension CameraViewController: Refreshable {
    func refreshBowntz() {
        guard let defaultCamera = AVCaptureDevice.default(for: .video) else { cameraLaunchSuccess = false; return }
        prepareCamera(camera: defaultCamera)
        prepareButtonsForCapture()
        guard cameraLaunchSuccess else { showErrorDialogue(message: "Could not launch camera"); return }
        startPreview(session: captureSession!)
        image = nil
        textMessage = nil
    }
}
