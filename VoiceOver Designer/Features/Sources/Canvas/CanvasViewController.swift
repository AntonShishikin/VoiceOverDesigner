//
//  ViewController.swift
//  VoiceOver Designer
//
//  Created by Mikhail Rubanov on 30.04.2022.
//

import Cocoa
import Document
import CommonUI

public class CanvasViewController: NSViewController {
    
    public func inject(presenter: CanvasPresenter) {
        self.presenter = presenter
    }
    
    public var presenter: CanvasPresenter!
    
    var trackingArea: NSTrackingArea!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view().dragnDropView.delegate = self
    }
    
    private func addMouseTracking() {
        trackingArea = NSTrackingArea(
            rect: view.bounds,
            options: [.activeAlways,
                      .mouseMoved,
                      .mouseEnteredAndExited,
                      .inVisibleRect],
            owner: self,
            userInfo: nil)
        view.addTrackingArea(trackingArea)
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        view().addImageButton.action = #selector(addImageButtonTapped)
        view().addImageButton.target = self
        
        view.window?.delegate = self
        DispatchQueue.main.async {
            self.presenter.didLoad(
                ui: self.view().controlsView,
                screenUI: self.view()
            )
            
            self.setImage()
            self.addMouseTracking()
            self.addMenuItem()
        }
    }
    
    // TODO: try to extract?
    func addMenuItem() {
        guard let menu = NSApplication.shared.menu, menu.item(withTitle: "Canvas") == nil else { return }
        let canvasMenuItem = NSMenuItem(title: "Canvas", action: nil, keyEquivalent: "")
        let canvasSubMenu = NSMenu(title: "Canvas")
        let addImageItem = NSMenuItem(title: "Add image", action: #selector(addImageButtonTapped), keyEquivalent: "")
        canvasSubMenu.addItem(addImageItem)
        canvasMenuItem.submenu = canvasSubMenu
        menu.addItem(canvasMenuItem)
    }
    
    func setImage() {
        view().setImage(presenter.document.image)
    }
    
    public override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    var highlightedControl: A11yControl? {
        didSet {
            if highlightedControl != nil {
                NSCursor.openHand.push()
            } else {
                NSCursor.openHand.pop()
            }
        }
    }
    public override func mouseMoved(with event: NSEvent) {
        highlightedControl?.isHiglighted = false
        highlightedControl = nil
        
        // TODO: Can crash if happend before document loading
        guard let control = presenter.ui.control(at: location(from: event)) else {
            return
        }
        
        self.highlightedControl = control
        
        control.isHiglighted = true
        
//        NSCursor.current.set = NSImage(
//            systemSymbolName: "arrow.up.and.down.and.arrow.left.and.right",
//            accessibilityDescription: nil)!
    }
    
    func location(from event: NSEvent) -> CGPoint {
        let inWindow = event.locationInWindow
        let inView = view().backgroundImageView.convert(inWindow, from: nil)
        return inView.flippendVertical(in: view().backgroundImageView)
    }
    
    
    // MARK:
    public override func mouseDown(with event: NSEvent) {
        presenter.mouseDown(on: location(from: event))
    }
    
    public override func mouseDragged(with event: NSEvent) {
        presenter.mouseDragged(on: location(from: event))
    }
    
    public override func mouseUp(with event: NSEvent) {
        presenter.mouseUp(on: location(from: event))
    }
    
    func view() -> CanvasView {
        view as! CanvasView
    }
    
    public static func fromStoryboard() -> CanvasViewController {
        let storyboard = NSStoryboard(name: "Canvas", bundle: .module)
        return storyboard.instantiateInitialController() as! CanvasViewController
    }
    
    public func select(_ model: A11yDescription) {
        guard let control = view().controlsView.drawnControls.first(where: { control in
            control.a11yDescription === model
        }) else { return }
        
        presenter.select(control: control)
    }
    
    public func save() {
        presenter.save()
    }
    
    public func delete(model: A11yDescription) {
        presenter.delete(model: model)
    }
    
    @objc func addImageButtonTapped() {
        Task {
            if let image = await requestImage() {
                presentImage(image)
            }
        }
    }
    
    func requestImage() async -> NSImage? {
        guard let window = view.window else { return nil }
        let imagePanel = NSOpenPanel()
        imagePanel.allowedFileTypes = NSImage.imageTypes
        imagePanel.canChooseFiles = true
        imagePanel.canChooseDirectories = false
        imagePanel.allowsMultipleSelection = false
        let modalResponse = await imagePanel.beginSheetModal(for: window)
        guard modalResponse == .OK else { return nil }
        guard let url = imagePanel.url, let image = NSImage(contentsOf: url) else { return nil }
        return image
    }
    
    func presentImage(_ image: NSImage) {
        presenter.update(image: image)
        view().setImage(image)
        view().backgroundImageView.image = image
        presenter.save()
    }
}

// MARK: - Magnifiing
extension CanvasViewController {
    
    @IBAction func reduceMagnifing(sender: Any) {
        view().changeMagnifacation { current in
            current / 2
        }
    }
    
    @IBAction func increaseMagnifing(sender: Any) {
        view().changeMagnifacation { current in
            current * 2
        }
    }
    
    @IBAction func fitMagnifing(sender: Any) {
        view().fitToWindow(animated: true)
    }
}

extension CanvasViewController: NSWindowDelegate {
    public func windowDidResize(_ notification: Notification) {
        view().fitToWindowIfAlreadyFitted()
    }
}

extension CanvasViewController: DragNDropDelegate {
    public func didDrag(image: NSImage) {
        presenter.update(image: image)
        view().setImage(image)
        presenter.save()
    }
    
    public func didDrag(path: URL) {
        // TODO: Add support. Or decline this files
    }
}

extension NSEvent {
    var locationInWindowFlipped: CGPoint {
        return CGPoint(x: locationInWindow.x,
                       y: window!.frame.height
                       - locationInWindow.y
                       - 28 // TODO: Remove toolbar's height
        )
    }
}

extension CGPoint {
    func flippendVertical(in view: NSView) -> CGPoint {
        CGPoint(x: x,
                y: view.frame.height - y
        )
    }
}