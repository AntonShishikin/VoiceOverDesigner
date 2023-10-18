import AppKit
import Document

protocol ProjectRouterDelegate: AnyObject {
    func showRecent()
    func closeProject(document: NSDocument)
}

extension ProjectController: NSToolbarDelegate {
    public func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
//        case .voiceControlLabel: return labelItem()
        case .documentsButtonLabel: return documentsItem()
        case .trailingSidebar: return trailingSideBarItem()
        case .leadingSidebar: return leadingSideBarItem()
        case .shareDocument: return shareDocumentItem()
        case .itemListTrackingSeparator:
            return NSTrackingSeparatorToolbarItem(
                identifier: .itemListTrackingSeparator,
                splitView: splitView,
                dividerIndex: 1
            )
        case .presentation: return presentationSideBarItem()
        case .editor: return editorSideBarItem()
        default: return nil
        }
    }
    
    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            // Title
//            .toggleSidebar,
            .documentsButtonLabel,
            .leadingSidebar,
            .sidebarTrackingSeparator,
            .flexibleSpace,
//            .voiceControlLabel,
            .shareDocument,
            .presentation,
//            .editor,
            .space,
            .trailingSidebar
        ]
    }
    
    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar,
         .sidebarTrackingSeparator,
//            .voiceControlLabel,
         .documentsButtonLabel,
         .presentation,
         .editor,
         .trailingSidebar,
         .leadingSidebar,
         .itemListTrackingSeparator,
         .shareDocument]
    }

    var presentationAllowedItems: [NSToolbarItem.Identifier] {
        [
            .documentsButtonLabel,
            .editor,
            .shareDocument
        ]
    }
}

extension ProjectController {
//    private func labelItem() -> NSToolbarItem {
//        let item = NSToolbarItem(itemIdentifier: .voiceControlLabel)
//        item.label = NSLocalizedString("Labels", comment: "")
//        item.enableLabels()
//        item.target = self
//        item.action = #selector(showLabels(sender:))
//        item.isBordered = true
//        return item
//    }
    
    private func documentsItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .documentsButtonLabel)
        item.label = NSLocalizedString("Recent", comment: "")
        item.target = self
        item.action = #selector(showRecentDidPressed(sender:))
        item.isBordered = true
        item.image = NSImage(systemSymbolName: "rectangle.grid.3x2",
                             accessibilityDescription: "Show recent documents")!
        item.toolTip = NSLocalizedString("Go to my documents", comment: "")
        item.isNavigational = true
        return item
    }
    
    private func shareDocumentItem() -> NSToolbarItem {
        let item = NSSharingServicePickerToolbarItem(itemIdentifier: .shareDocument)
        item.delegate = document
        item.isNavigational = true
        return item
    }
    
    private func leadingSideBarItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .leadingSidebar)
        item.label = NSLocalizedString("Navigator", comment: "")
        item.target = self
        item.action = #selector(leadingSideBarTapped(sender:))
        item.isBordered = true
        item.image = NSImage(systemSymbolName: "sidebar.leading",
                             accessibilityDescription: "Close navigator sidebar")!
        item.toolTip = NSLocalizedString("Close navigator sidebar", comment: "")
        return item
    }
    
    private func trailingSideBarItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .trailingSidebar)
        item.label = NSLocalizedString("Inspector", comment: "")
        item.target = self
        item.action = #selector(trailingSideBarTapped(sender:))
        item.isBordered = true
        item.image = NSImage(systemSymbolName: "sidebar.trailing",
                             accessibilityDescription: "Close inspector sidebar")!
        item.toolTip = NSLocalizedString("Close inspector sidebar", comment: "")
        return item
    }

    private func presentationSideBarItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .presentation)
        item.label = NSLocalizedString("Presentation", comment: "")
        item.target = self
        item.action = #selector(presentationModeTapped(sender:))
        item.isBordered = true
        item.image = NSImage(systemSymbolName: "play.display",
                             accessibilityDescription: "Open presentation mode")!
        item.toolTip = NSLocalizedString("Open presentation mode", comment: "")
        item.isNavigational = true
        return item
    }

    private func editorSideBarItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .editor)
        item.label = NSLocalizedString("Editor", comment: "")
        item.target = self
        item.action = #selector(editorModeTapped(sender:))
        item.isBordered = true
        item.image = NSImage(systemSymbolName: "square.on.square.dashed",
                             accessibilityDescription: "Open editor mode")!
        item.toolTip = NSLocalizedString("Open editor mode", comment: "")
        item.isNavigational = true
        return item
    }

    @objc private func showLabels(sender: NSToolbarItem) {
        sender.action = #selector(hideLabels(sender:))
        canvas.presenter.showLabels()
        
        sender.disableLabels()
    }
    
    @objc private func hideLabels(sender: NSToolbarItem) {
        sender.action = #selector(showLabels(sender:))
        canvas.presenter.hideLabels()
        
        sender.enableLabels()
    }

    @objc private func showRecentDidPressed(sender: NSToolbarItem) {
        router?.showRecent()
    }
    
    @objc private func leadingSideBarTapped(sender: NSToolbarItem) {
        guard let firstSplitView = splitViewItems.first else { return }
        firstSplitView.animator().isCollapsed.toggle()
    }
    
    @objc private func trailingSideBarTapped(sender: NSToolbarItem) {
        guard let lastSplitView = splitViewItems.last else { return }
        lastSplitView.animator().isCollapsed.toggle()
        if lastSplitView.isCollapsed {
            toolbar.removeItem(at: 4)
        } else {
            toolbar.insertItem(withItemIdentifier: .itemListTrackingSeparator, at: 4)
        }
    }

    @objc private func presentationModeTapped(sender: NSToolbarItem) {
        toggle(.presentation)

        guard let toolbar = sender.toolbar else { return }
        Set(toolbarAllowedItemIdentifiers(toolbar))
            .subtracting(presentationAllowedItems)
            .forEach {
                toolbar.removeItem(identifier: $0)
            }

        toolbar.insertItem(withItemIdentifier: .editor, at: toolbar.items.endIndex)
    }

    @objc private func editorModeTapped(sender: NSToolbarItem) {
        toggle(.editor)

        guard let toolbar = sender.toolbar else { return }
        if let prevIndex = toolbar.removeItem(identifier: .editor) {
            toolbar.insertItem(withItemIdentifier: .presentation, at: prevIndex)
        }
    }
}

extension NSToolbarItem {
    func enableLabels() {
        image = NSImage(systemSymbolName: "text.bubble",
                        accessibilityDescription: "Show labels")!
        toolTip = NSLocalizedString("Show labels of elements", comment: "")
        
    }
    
    func disableLabels() {
        image = NSImage(systemSymbolName: "text.bubble.fill",
                        accessibilityDescription: "Hide labels")
        toolTip = NSLocalizedString("Hide labels of elements", comment: "")
    }
}

extension NSToolbarItem.Identifier {
//    static let voiceControlLabel = NSToolbarItem.Identifier(rawValue: "VoiceControlLabel")
    static let documentsButtonLabel = NSToolbarItem.Identifier(rawValue: "DocumentsButtonLabel")
    static let trailingSidebar = NSToolbarItem.Identifier(rawValue: "TrailingSidebar")
    static let presentation = NSToolbarItem.Identifier(rawValue: "Presentation")
    static let editor = NSToolbarItem.Identifier(rawValue: "Editor")
    static let leadingSidebar = NSToolbarItem.Identifier(rawValue: "LeadingSidebar")
    static let itemListTrackingSeparator = NSToolbarItem.Identifier("ItemListTrackingSeparator")
    static let shareDocument = NSToolbarItem.Identifier("ShareDocument")
}

extension VODesignDocument: NSSharingServicePickerToolbarItemDelegate {
    public func items(for pickerToolbarItem: NSSharingServicePickerToolbarItem) -> [Any] {
        [fileURL as Any]
    }
}

private extension NSToolbar {

    @discardableResult
    func removeItem(identifier: NSToolbarItem.Identifier) -> Int? {
        if let index = items
            .firstIndex(where: { $0.itemIdentifier == identifier }) {
            removeItem(at: index)
            return index
        }
        return nil
    }
}
