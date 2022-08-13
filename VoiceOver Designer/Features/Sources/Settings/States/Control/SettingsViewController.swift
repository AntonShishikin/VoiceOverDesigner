//
//  SettingsViewController.swift
//  VoiceOver Designer
//
//  Created by Mikhail Rubanov on 30.04.2022.
//

import AppKit
import Document

class TraitCheckBox: NSButton {
    var trait: A11yTraits!
}

public class SettingsViewController: NSViewController {

    public var presenter: SettingsPresenter!
    
    var descr: A11yDescription {
        presenter.model
    }
    
    @IBOutlet weak var resultLabel: NSTextField!
    
    @IBOutlet weak var value: NSTextField!
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var hint: NSTextField!
    
    // MARK: Type trait
    @IBOutlet weak var buttonTrait: TraitCheckBox!
    @IBOutlet weak var headerTrait: TraitCheckBox!

    @IBOutlet weak var linkTrait: TraitCheckBox!
    @IBOutlet weak var staticTextTrait: TraitCheckBox!
    @IBOutlet weak var imageTrait: TraitCheckBox!
    @IBOutlet weak var searchFieldTrait: TraitCheckBox!
    @IBOutlet weak var tabTrait: TraitCheckBox!
    
    @IBOutlet weak var selectedTrait: TraitCheckBox!
    @IBOutlet weak var summaryElementTrait: TraitCheckBox!
    @IBOutlet weak var playSoundTrait: TraitCheckBox!
    @IBOutlet weak var allowsDirectInteraction: TraitCheckBox!
    @IBOutlet weak var startMediaSession: TraitCheckBox!
    @IBOutlet weak var disabledTrait: TraitCheckBox!
    @IBOutlet weak var updatesFrequently: TraitCheckBox!
    @IBOutlet weak var causesPageTurn: TraitCheckBox!
    @IBOutlet weak var keyboardKey: TraitCheckBox!
    
    @IBOutlet weak var isAccessibilityElement: NSButton!
    
    // MARK: behaviourTrait
    // TODO: Add
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setup(from: descr)
    }
    
    private func setup(from descr: A11yDescription) {
        label.stringValue = descr.label
        hint.stringValue  = descr.hint
        isAccessibilityElement.state = descr.isAccessibilityElement ? .on: .off
        
        updateText(isUserAction: false)
        
        buttonTrait.trait = .button
        headerTrait.trait = .header
        linkTrait.trait = .link
        staticTextTrait.trait = .staticText
        imageTrait.trait = .image
        searchFieldTrait.trait = .searchField
        tabTrait.trait = .tab
        
        selectedTrait.trait = .selected
        summaryElementTrait.trait = .summaryElement
        playSoundTrait.trait = .playsSound
        allowsDirectInteraction.trait = .allowsDirectInteraction
        startMediaSession.trait = .startsMediaSession
        disabledTrait.trait = .notEnabled
        updatesFrequently.trait = .updatesFrequently
        causesPageTurn.trait = .causesPageTurn
        keyboardKey.trait = .keyboardKey
        
        let allTraitsButtons: [TraitCheckBox] = [
            buttonTrait,
            headerTrait,
            linkTrait,
            staticTextTrait,
            imageTrait,
            searchFieldTrait,
            tabTrait,
            
            selectedTrait,
            summaryElementTrait,
            playSoundTrait,
            allowsDirectInteraction,
            startMediaSession,
            disabledTrait,
            updatesFrequently,
            causesPageTurn,
            keyboardKey,
        ]
        
        for traitButton in allTraitsButtons {
            traitButton.state = descr.trait.contains(traitButton.trait) ? .on: .off
        }
    }
    
    weak var valueViewController: A11yValueViewController?
    weak var actionsViewController: CustomActionsViewController?
    public override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "A11yValueViewController":
            if let valueViewController = segue.destinationController as? A11yValueViewController {
                self.valueViewController = valueViewController
                valueViewController.presenter = presenter
                valueViewController.delegate = self
            }
        case "CustomActionsViewContoller":
            if let customActionViewController = segue.destinationController as? CustomActionsViewController {
                actionsViewController = customActionViewController
                actionsViewController?.presenter = presenter
            }
        default: break
        }
    }
    
    @IBAction func traitDidChange(_ sender: TraitCheckBox) {
        let isOn = sender.state == .on
        
        if isOn {
            descr.trait.formUnion(sender.trait)
        } else {
            descr.trait.subtract(sender.trait)
        }
        updateText(isUserAction: true)
    }
    
    // MARK: Description
    @IBAction func labelDidChange(_ sender: NSTextField) {
        // TODO: if you forgot to call updateColor, the label wouldn't be revalidated
        presenter.updateLabel(to: sender.stringValue)
        updateText(isUserAction: true)
    }
    
    @IBAction func hintDidChange(_ sender: NSTextField) {
        descr.hint = sender.stringValue
        updateText(isUserAction: true)
    }
    
    func updateText(isUserAction: Bool) {
        resultLabel.stringValue = descr.voiceOverText
        
        if isUserAction {
            presenter.delegate?.didUpdateValue()
        }
    }
    
    @IBAction func delete(_ sender: Any) {
        presenter.delegate?.delete(model: presenter.model)
    }
    
    @IBAction func isAccessibleElementDidChanged(_ sender: NSButton) {
        descr.isAccessibilityElement = sender.state == .on
    }
    
    public static func fromStoryboard() -> SettingsViewController {
        let storyboard = NSStoryboard(name: "Settings", bundle: .module)
        return storyboard.instantiateInitialController() as! SettingsViewController
    }
}

extension SettingsViewController: A11yValueDelegate {}