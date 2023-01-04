import SwiftUI
import Document



public struct ElementSettingsView: View {
    
    @Environment(\.dismiss) private var dismissAction
    @ObservedObject var element: A11yDescription
    
    var deleteAction: () -> Void
    
    public init(element: A11yDescription, deleteAction: @escaping () -> Void) {
        self.element = element
        self.deleteAction = deleteAction
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Text(element.voiceOverText)
                    .font(.largeTitle)
                
                TextValue(title: "Label", value: $element.label)
                ValueView(value: $element.value, adjustableOptions: $element.adjustableOptions, traits: $element.trait)
                TraitsView(selection: $element.trait)
                
                
                
                CustomActionsView(selection: $element.customActions)
                CustomDescriptionView(selection: $element.customDescriptions)
                TextValue(title: "Hint", value: $element.hint)
                Toggle("Is accessible?", isOn: $element.isAccessibilityElement)
                
                
            }
            .toolbar {
                ToolbarItem(placement: .destructiveAction, content: {
                    Button(role: .destructive, action: delete, label: {
                        Text("Delete")
                    })
                    .foregroundColor(.red)
                })
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func delete() {
        deleteAction()
        dismissAction()
    }
}

struct SectionTitle: View {
    
    let title: LocalizedStringKey
    
    init(_ title: LocalizedStringKey) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.headline)
    }
}

struct TextValue: View {
    
    let title: LocalizedStringKey
    @Binding var value: String
    
    
    public var body: some View {
        Section(content: {
            TextField(title, text: $value)
                
        }, header: {
            SectionTitle(title)
        })
    }
}






struct ElementSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ElementSettingsView(element: .empty(frame: .zero), deleteAction: {})
    }
}

