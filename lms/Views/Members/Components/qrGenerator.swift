import SwiftUI
import CoreImage.CIFilterBuiltins

extension UIImage {
    static func generateQRCode(from string: String, size: CGFloat = 250) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        // Convert string to data
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // Medium error correction
        
        // Create output image
        guard let outputImage = filter.outputImage else {
            return UIImage(systemName: "qrcode") ?? UIImage()
        }
        
        // Scale the image
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: size / outputImage.extent.width, y: size / outputImage.extent.height))
        
        // Convert to UIImage
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return UIImage(systemName: "qrcode") ?? UIImage()
        }
        
        return UIImage(cgImage: cgImage)
    }
}
