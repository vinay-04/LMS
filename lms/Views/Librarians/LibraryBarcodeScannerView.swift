
//
//  LibraryBarcodeScannerView.swift
//  lms
//
//  Created by user@30 on 03/05/25.
//


import SwiftUI
import AVFoundation

// MARK: - Library Barcode Scanner View
struct LibraryBarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("❌ No video capture device available")
            return viewController
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("❌ Failed to initialize camera: \(error.localizedDescription)")
            return viewController
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            print("❌ Cannot add video input to capture session")
            return viewController
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .qr, .code128, .code39]
            print("📷 Barcode scanner configured with supported formats: EAN-8, EAN-13, QR, Code 128, Code 39")
        } else {
            print("❌ Cannot add metadata output to capture session")
            return viewController
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)
        
        // Add scan area overlay
        let overlayView = UIView(frame: viewController.view.bounds)
        overlayView.backgroundColor = UIColor.clear
        
        // Semi-transparent background
        let backgroundView = UIView(frame: overlayView.bounds)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.addSubview(backgroundView)
        
        // Scan area
        let scanAreaSize = CGSize(width: 250, height: 100)
        let scanAreaX = (overlayView.bounds.width - scanAreaSize.width) / 2
        let scanAreaY = (overlayView.bounds.height - scanAreaSize.height) / 2
        let scanAreaRect = CGRect(x: scanAreaX, y: scanAreaY, width: scanAreaSize.width, height: scanAreaSize.height)
        
        // Create a path for the background with a hole for the scan area
        let path = UIBezierPath(rect: overlayView.bounds)
        let scanAreaPath = UIBezierPath(rect: scanAreaRect)
        path.append(scanAreaPath)
        path.usesEvenOddFillRule = true
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        backgroundView.layer.mask = maskLayer
        
        // Scan area border
        let borderView = UIView(frame: scanAreaRect)
        borderView.layer.borderColor = UIColor.yellow.cgColor
        borderView.layer.borderWidth = 3
        borderView.backgroundColor = UIColor.clear
        overlayView.addSubview(borderView)
        
        // Label
        let label = UILabel()
        label.text = "Scan ISBN Barcode"
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.sizeToFit()
        label.frame = CGRect(
            x: scanAreaRect.midX - label.frame.width / 2,
            y: scanAreaRect.minY - label.frame.height - 10,
            width: label.frame.width + 20,
            height: label.frame.height + 10
        )
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        overlayView.addSubview(label)
        
        // Add close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.frame = CGRect(x: 20, y: 40, width: 44, height: 44)
        closeButton.addTarget(context.coordinator, action: #selector(Coordinator.closeButtonTapped), for: .touchUpInside)
        overlayView.addSubview(closeButton)
        
        viewController.view.addSubview(overlayView)
        
        context.coordinator.captureSession = captureSession
        context.coordinator.overlayView = overlayView
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
            print("📷 Library barcode scanner started")
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: LibraryBarcodeScannerView
        var captureSession: AVCaptureSession?
        var overlayView: UIView?
        
        init(_ parent: LibraryBarcodeScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                      let stringValue = readableObject.stringValue else { return }
                
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                print("📷 Scanned barcode: \(stringValue)")
                
                // Stop scanning
                captureSession?.stopRunning()
                
                // Update scanned code on main thread
                DispatchQueue.main.async {
                    self.parent.scannedCode = stringValue
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        
        @objc func closeButtonTapped() {
            print("📷 Scanner manually closed")
            captureSession?.stopRunning()
            DispatchQueue.main.async {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
