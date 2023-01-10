import Recent
import AppKit
import Document

class WindowManager: NSObject {
    
    static var shared = WindowManager()
    
    let recentPresenter = RecentPresenter()
    lazy var recentWindowController: RecentWindowController = {
        RecentWindowController.fromStoryboard(delegate: self, presenter: recentPresenter)
    }()
    
    private var newDocumentIsCreated = false
    
    func start() {
        if newDocumentIsCreated {
            // Document has been created from [NSDocumentController openUntitledDocumentAndDisplay:error:]
            return
        }
        if recentPresenter.shouldShowThisController {
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
        print("will open \(document.fileURL)")
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
        
        recentWindowController.embedProjectsViewControllerInWindow()
    }
}
