//
//  RCCustomCamera.swift
//  Take A Photo App
//
//  Created by Rahul Chopra on 10/12/20.
//  Copyright © 2020 MAC. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Photos

class RCCustomCamera: UIView {
    
    var captureSession = AVCaptureSession()
    var cameraPosition: AVCaptureDevice.Position = .back {
        didSet {
            self.flipCameraPosition()
        }
    }
    var torchMode: AVCaptureDevice.FlashMode = .off {
        didSet {
            self.toggleFlash()
        }
    }
    var flashMode: AVCaptureDevice.FlashMode = .on {
        didSet {
            
        }
    }
    private var sessionQueue: DispatchQueue!
    var captureDevice : AVCaptureDevice!
    var cameraInput: AVCaptureDeviceInput!
    var backCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    private var cameraOutput: AVCapturePhotoOutput!
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.perform(#selector(setupCamera), with: nil, afterDelay: 0.1)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.perform(#selector(setupCamera), with: nil, afterDelay: 0.1)
    }
    
    @objc func setupCamera() {
        self.setupCaptureSession()
        self.setupDevice()
        self.setupInput()
        self.setupPreviewLayer()
        self.startRunningCaptureSession()
    }
    
    private func setupCaptureSession() {
        captureSession.sessionPreset = .photo
        sessionQueue = DispatchQueue(label: "session queue")
    }
    
    private func setupDevice(usingFrontCamera: Bool = false){
        sessionQueue.async {
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
            let devices = deviceDiscoverySession.devices
            for device in devices {
                if usingFrontCamera && device.position == .front {
                    self.captureDevice = device
                } else if device.position == .back {
                    self.captureDevice = device
                }
            }
        }
    }
    
    private func setupInput() {
        sessionQueue.async {
            do {
                let captureDeviceInput = try AVCaptureDeviceInput(device: self.captureDevice)
                if self.captureSession.canAddInput(captureDeviceInput) {
                    self.captureSession.addInput(captureDeviceInput)
                }
                self.cameraOutput = AVCapturePhotoOutput()
                self.cameraOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format:[AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
                if self.captureSession.canAddOutput(self.cameraOutput) {
                    self.captureSession.addOutput(self.cameraOutput)
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func setupPreviewLayer() {
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer.videoGravity = .resizeAspectFill
        cameraPreviewLayer.connection?.videoOrientation = .portrait
        cameraPreviewLayer.frame = UIScreen.main.bounds
        layer.insertSublayer(cameraPreviewLayer, at: 0)
    }
    
    private func startRunningCaptureSession() {
        captureSession.startRunning()
    }
    
    
    private func flipCameraPosition() {
        captureSession.beginConfiguration()
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                captureSession.removeInput(input)
            }
        }
        self.setupCaptureSession()
        self.setupDevice(usingFrontCamera: cameraPosition == .front ? true : false)
        self.setupInput()
        self.captureSession.commitConfiguration()
        self.startRunningCaptureSession()
    }
    
    private func toggleFlash() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let device = deviceDiscoverySession.devices.first else { return }

        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                let on = device.isTorchActive
                if on != true && device.isTorchModeSupported(.on) {
                    try device.setTorchModeOn(level: 1.0)
                } else if device.isTorchModeSupported(.off){
                    device.torchMode = .off
                } else {
                    print("Torch mode is not supported")
                }
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        settings.flashMode = flashMode
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }

}


extension RCCustomCamera: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Capture failed: \(error.localizedDescription)")
        } else {
            if let imageData = photo.fileDataRepresentation(),
                let image = UIImage(data: imageData) {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { (status, error) in
                    print(status)
                }
            }
        }
    }
}


extension UIApplication {
    static func rootVC() -> UIViewController {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first!.rootViewController!
        } else {
            return UIApplication.shared.keyWindow!.rootViewController!
        }
    }
}
