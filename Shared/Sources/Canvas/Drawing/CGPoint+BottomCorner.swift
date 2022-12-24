import CoreGraphics

extension CGPoint {
    func nearBottomRightCorner(of rect: CGRect) -> Bool {
        let threshold = Config().resizeMarkerSize
        return abs(x - rect.bottomCorner.x) < threshold
            && abs(y - rect.bottomCorner.y) < threshold
    }
}

extension CGRect {
    var bottomCorner: CGPoint {
        return CGPoint(x: maxX, y: maxY)
    }
    
    func isCorner(
        at point: CGPoint,
        size: CGFloat
    ) -> RectCorner? {
        for corner in RectCorner.allCases {
            let frame = frame(corner: corner, size: size)
            if frame.contains(point) {
                return corner
            }
        }
        
        return nil
    }
    
    func frame(
        corner: RectCorner,
        size: CGFloat
    ) -> CGRect {
        let center = point(at: corner)
        let origin = CGPoint(x: center.x - size/2,
                             y: center.y - size/2)
        
        let size = CGSize(width: size, height: size)
        let frame = CGRect(origin: origin, size: size)
        
        return frame
    }
    
    /// Top left origin of coordinate system
    func point(at corner: RectCorner) -> CGPoint {
        switch corner {
        case .bottomLeft:
            return CGPoint(x: minX, y: maxY)
        case .bottomRight:
            return CGPoint(x: maxX, y: maxY)
        case .topLeft:
            return CGPoint(x: minX, y: minY)
        case .topRight:
            return CGPoint(x: maxX, y: minY)
        }
    }
    
    func move(
        corner: RectCorner,
        to newLocation: CGPoint
    ) -> CGRect {
        
        switch corner {
        case .bottomLeft: return .zero
        case .bottomRight: return .zero
        case .topLeft:
            let offset = CGPoint(
                x: newLocation.x - origin.x,
                y: newLocation.y - origin.y)
            
            let size = CGSize(width: width - offset.x,
                              height: width - offset.y)
            
            return CGRect(origin: newLocation, size: size)
            
        case .topRight:
            let size = CGSize(
                width: newLocation.x - origin.x,
                height: newLocation.y - origin.y)
            
            return CGRect(origin: origin, size: size)
        }
    }
}

public enum RectCorner: CaseIterable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}
