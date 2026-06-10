import UIKit

extension UIImage {

    func resizedToLongEdge(_ maxLength: CGFloat) -> UIImage? {
        let longEdge = max(size.width, size.height)
        guard longEdge > maxLength else { return self }

        let scale = maxLength / longEdge
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        // Default renderer format uses the device screen scale (2x/3x),
        // which would produce a bitmap 4-9x larger than the requested size.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
