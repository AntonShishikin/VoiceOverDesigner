import Recent
import AppKit
import Document
import Presentation
import SwiftUI

class WindowManager: NSObject {
    
    static var shared = WindowManager()
    
    let documentsPresenter = DocumentPresenterFactory().presenter()
    
    lazy var recentWindowController: RecentWindowController = {
        RecentWindowController.fromStoryboard(delegate: self, presenter: documentsPresenter)
    }()
    
    private var newDocumentIsCreated = false
    
    func start() {
        if newDocumentIsCreated {
            // Document has been created from [NSDocumentController openUntitledDocumentAndDisplay:error:]
            return
        }
        if documentsPresenter.shouldShowThisController {
            showDocumentSelector()
        } else {
            // TODO: Do we need it or document will open automatically?
            showNewDocument()
        }
    }
    
    private func showNewDocument() {
        createNewDocumentWindow(document: VODesignDocument())
    }
     
    private func showDocumentSelector() {
        recentWindowController.embedProjectsViewControllerInWindow()
        recentWindowController.window?.makeKeyAndOrderFront(self)
    }
    
    private func hideDocumentSelector() {
        recentWindowController.window?.close()
    }
}

extension WindowManager: RecentDelegate {
    func createNewDocumentWindow(
        document: VODesignDocument
    ) {
        print("will open \(document.fileURL?.absoluteString ?? "Unkonwn fileURL")")
        newDocumentIsCreated = true
        
        let split = ProjectController(document: document, router: self)
        
        let window = recentWindowController.window!
        recentWindowController.setupToolbarAppearance(title: document.displayName,
                                                      toolbar: split.toolbar)
        window.contentViewController = split
        
        document.addWindowController(recentWindowController)
        window.makeKeyAndOrderFront(self)
    }
}

extension WindowManager: ProjectRouterDelegate {
    func closeProject(document: NSDocument) {
        document.removeWindowController(recentWindowController)
        
        document.save(self)
        document.close()
        
        recentWindowController.embedProjectsViewControllerInWindow()
    }

    func openPresentationMode(document: NSDocument) {
        guard let document = document as? VODesignDocument else {
            return
        }
        document.save(self)

        let hostingController = NSHostingController(rootView: PresentationView(
            document: .init(document)
        ))
        hostingController.title = NSLocalizedString("Presentation", comment: "")
        hostingController.preferredContentSize = .init(
            width: document.imageSize.width + 
                PresentationView.Constants.controlsWidth +
                PresentationView.Constants.windowPadding,
            height: document.imageSize.height + PresentationView.Constants.windowPadding
        )

        let window = NSWindow(contentViewController: hostingController)

        window.makeKeyAndOrderFront(recentWindowController)
    }
}
