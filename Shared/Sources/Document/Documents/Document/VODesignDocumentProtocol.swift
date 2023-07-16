import Foundation
import Combine

public protocol VODesignDocumentProtocol: AnyObject {
    
    // MARK: - Data
    var artboard: Artboard { get set }
    
    // MARK: - Services
    /// An undo manager that records operations on document
    /// - Renamed as `NSDocument` and `UIDocument` have different `UndoManager` signature
    var undo: UndoManager? { get }
    
    var documentWrapper: FileWrapper { get set }
    
    var previewSource: PreviewSourceProtocol? { get set }
}

extension VODesignDocumentProtocol {
    @available(*, deprecated, message: "Use `artboard`")
    public var controls: [any ArtboardElement] {
        get {
            artboard.controlsWithoutFrames
        }
        
        set {
            artboard.controlsWithoutFrames = newValue
        }
    }
}

extension VODesignDocumentProtocol {
    public func addFrame(
        with newImage: Image,
        origin: CGPoint
    ) {
        let frame = Frame(image: newImage,
                          frame: CGRect(origin: origin,
                                        size: newImage.size))
        artboard.frames.append(frame)
        
        invalidateWrapperIfPossible(fileInRoot: FolderName.quickLook)
    }
    
    public func update(image: ImageLocation, for frame: Frame) {
        switch frame.imageLocation {
            
        case .file(name: let name):
            if let existedWrapper = imagesFolderWrapper.fileWrappers?[name] {
                imagesFolderWrapper.removeFileWrapper(existedWrapper)
            }
        case .url(url: _):
            fatalError("Don't know is some code is needed here")
        case .tmp(name: let name, data: _):
            if let existedWrapper = imagesFolderWrapper.fileWrappers?[name] {
                imagesFolderWrapper.removeFileWrapper(existedWrapper)
            }
        }
        
        frame.imageLocation = image
    }
}

extension Artboard {
    
    public func suggestOrigin() -> CGPoint {
        guard let lastFrame = frames.last?.frame
        else { return .zero }
        
        let origin = CGPoint(x: lastFrame.maxX + lastFrame.width * 0.2,
                             y: lastFrame.minY)
        return origin
    }
    func suggestFrame(for size: CGSize) -> CGRect {
        return CGRect(origin: suggestOrigin(), size: size)
    }
}

import CoreGraphics
public protocol PreviewSourceProtocol: AnyObject {
    func previewImage() -> Image?
}

extension Frame {
    public convenience init(image: Image, frame: CGRect) {
        let name = UUID().uuidString // TODO: Create fancy name

//        let frame = CGRect(origin: .zero, size: image.size)
        
        self.init(label: name,
                  imageLocation: .cache(image: image),
                  frame: frame,
                  elements: [])
    }
}
