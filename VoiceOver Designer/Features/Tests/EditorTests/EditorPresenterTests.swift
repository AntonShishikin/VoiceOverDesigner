//
//  EditorPresenterTests.swift
//  VoiceOver DesignerTests
//
//  Created by Mikhail Rubanov on 05.05.2022.
//

import XCTest
@testable import Editor
import Document

class EditorPresenterTests: XCTestCase {

    var sut: EditorPresenter!
    var router: RouterMock!
    var delegate: EditorDelegateMock!
    var controller: EmptyViewController!
    
    override func setUp() {
        super.setUp()
        
        controller = EmptyViewController()
        
        sut = EditorPresenter()
        sut.document = VODesignDocument.testDocument(name: "Test",
                                                     saveImmediately: true)
        
        router = RouterMock()
        delegate = EditorDelegateMock()
        
        sut.didLoad(ui: controller.controlsView,
                    router: router,
                    delegate: delegate)
    }
    
    override func tearDown() {
        try? VODesignDocument.removeTestDocument(name: "Test")
        sut = nil
        router = nil
        controller = nil
        super.tearDown()
    }
    
    private let start10 = CGPoint.coord(10)
    private let end60   = CGPoint.coord(60)
    private let rect10to50  = CGRect(origin: .coord(10), size: .side(50))
    
    // MARK: - Drawning
    // MARK: New
    func test_rectangleDrawnOnTheFly() {
        sut.mouseDown(on: start10)
        
        XCTContext.runActivity(named: "draw on drag") { _ in
            sut.mouseDragged(on: end60)
            
            XCTAssertEqual(controller.controlsView.layer?.sublayers?.first?.frame,
                           rect10to50, "Draw")
            
            XCTAssertNil(sut.document.controls.first, "but not saved yet")
        }
        
        XCTContext.runActivity(named: "saved on release") { _ in
            sut.mouseUp(on: end60)
            XCTAssertEqual(sut.document.controls.first?.frame,
                           rect10to50)
        }
    }
    
    func test_drawRectangle_onMouseUp() {
        sut.mouseDown(on: start10)
        sut.mouseUp(on: end60)
        
        XCTAssertEqual(sut.document.controls.first?.frame,
                       rect10to50)
    }
    
    func test_drawSmallerThanMinimalWidth_shouldIncreaseSizeToMinimal_andKeepCenter() {
        sut.mouseDown(on: start10)
        sut.mouseUp(on: start10.offset(x: 10, y: 50))
        
        XCTAssertEqual(sut.document.controls.first?.frame,
                       CGRect(origin: CGPoint(x: 10 + 5 - 44/2,
                                              y: 10),
                              size: CGSize(width: 44, height: 50)))
    }
    
    func test_drawSmallerThanMinimalHeight_shouldIncreaseSizeToMinimal_andKeepCenter() {
        sut.mouseDown(on: start10)
        sut.mouseUp(on: start10.offset(x: 50, y: 10))
        
        XCTAssertEqual(sut.document.controls.first?.frame,
                       CGRect(origin: CGPoint(x: 10,
                                              y: 10 +  5 - 44/2),
                              size: CGSize(width: 50, height: 44)))
    }
    
    func test_notDrawIfSizeIsSmallerThan5px() {
        sut.mouseDown(on: start10)
        sut.mouseUp(on: start10.offset(x: 4, y: 4))
        
        XCTAssertNil(sut.document.controls.first)
    }
    
    func test_drawInReverseDirection() {
        sut.mouseDown(on: end60)
        sut.mouseUp(on: start10)
        
        XCTAssertEqual(sut.document.controls.first?.frame,
                       rect10to50)
    }
    
    // MARK: Editing
    func test_movementFor5px_shouldTranslateRect() {
        drawRect_10_60()
        
        // Move
        sut.mouseDown(on: .coord(15))
        sut.mouseDragged(on: .coord(17))
        sut.mouseDragged(on: .coord(18))
        sut.mouseDragged(on: .coord(20)) // 5px from start
        
        XCTAssertEqual(sut.document.controls.count, 1)
        XCTAssertEqual(sut.document.controls.first?.frame,
                       rect10to50.offsetBy(dx: 5, dy: 5))
        
        XCTAssertFalse(router.isSettingsShown, "Not open settings at the end of translation")
    }
    
    func test_translateToNegativeCoordinates_shouldTranslate() {
        drawRect_10_60()
        
        // Move
        sut.mouseDown(on: .coord(15))
        sut.mouseUp(on: .coord(5))
        
        XCTAssertEqual(sut.document.controls.first?.frame,
                       rect10to50.offsetBy(dx: -10, dy: -10))
        
        XCTAssertFalse(router.isSettingsShown, "Not open settings at the end of translation")
    }
    
    func test_whenMoveNearLeftEdgeOnAnyElement_shouldPinToLeftEdge() {
        drawRect(from: start10, to: end60)
        drawRect(from: .coord(100),
                 to: .coord(150))
        XCTAssertEqual(sut.document.controls.count, 2)
        
        sut.mouseDown(on: .coord(101)) // 2nd rect
        sut.mouseDragged(on: .coord(11))
        
        XCTAssertEqual(sut.document.controls[1].frame,
                       CGRect(origin: .coord(10), size: .side(50)))
    }
    
    // TODO:
    // - aligned vertically
    // - aligned to 3rd element
    
    // MARK: Routing
    func test_openSettings() {
        drawRect_10_60()
        
        XCTContext.runActivity(named: "click outside") { _ in
            sut.click(coordinate: .coord(0))
            
            XCTAssertNil(sut.selectedControl, "should deselect iten")
            XCTAssertFalse(router.isSettingsShown)
        }
        
        XCTContext.runActivity(named: "open settings after click") { _ in
            sut.mouseDown(on: .coord(10))
            XCTAssertFalse(router.isSettingsShown, "not show settings on touch down")
            
            sut.mouseUp(on: .coord(11)) // Slightly move is possible
            XCTAssertTrue(router.isSettingsShown, "show settings on touch up")
            
            XCTAssertEqual(sut.document.controls.first?.frame,
                           rect10to50, "Keep frame")
            
            XCTAssertNotNil(sut.selectedControl)
        }
    }
    
    // MARK: - DSL
    func drawRect_10_60(deselect: Bool = true) {
        sut.mouseDown(on: start10)
        sut.mouseUp(on: end60)
        
        sut.deselect()
    }
    
    func drawRect(from: CGPoint, to: CGPoint) {
        sut.mouseDown(on: from)
        sut.mouseUp(on: to)
    }
}

extension EditorPresenter {
    func click(coordinate: CGPoint) {
        mouseDown(on: coordinate)
        mouseUp(on: coordinate)
    }
}

class EmptyViewController: NSViewController {
    
    private lazy var contentView = NSView()
    
    let controlsView = ControlsView()
    
    override func loadView() {
        view = contentView
        view.layer = CALayer()
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}

class RouterMock: EditorRouterProtocol {
    
    var isSettingsShown: Bool {
        didShowSettingsForControl != nil
    }
    
    var didShowSettingsForControl: A11yControl?
    func showSettings(
        for control: A11yControl,
        controlSuperview: NSView
    ) {
        didShowSettingsForControl = control
    }
    
    func hideSettings() {
        didShowSettingsForControl = nil
    }
}

extension CGPoint {
    func offset(x: CGFloat, y: CGFloat) -> Self {
        return CGPoint(x: self.x + x,
                       y: self.y + y)
    }
}

class EditorDelegateMock: EditorDelegate {
    func didSelect(control: A11yDescription?) {
        
    }
}