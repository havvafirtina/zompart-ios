import UIKit

extension UIImage {

    func resizedToLongEdge(_ maxLength: CGFloat) -> UIImage? {
        let longEdge = max(size.width, size.height)
        guard longEdge > maxLength else { return self }

        let scale = maxLength / longEdge
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
