import Foundation
import Samples

class SamplesDocumentsPresenter: DocumentBrowserPresenterProtocol {
    weak var delegate: DocumentsProviderDelegate?
    
    func numberOfItemsInSection(_ section: Int) -> Int {
        items.count
    }
    
    func item(at indexPath: IndexPath) -> CollectionViewItem? {
        items[indexPath.item]
    }
    
    var shouldShowThisController: Bool = true
    
    private var items = [CollectionViewItem]()
    
    var possibleLanguages = [String]()
    var structure: SamplesStructure?
    
    func load() {
        Task {
            do {
                let structure = try await SamplesLoader().loadStructure()
                self.structure = structure
                self.possibleLanguages = structure.languages.map { pair in String(pair.key) }
                
                let language = language(from: possibleLanguages) // Remember last selected language
                
                await MainActor.run(body: {
                    presentProjects(with: language)
                })
                
            } catch let error {
                // TODO: Add retry button
                print(error)
            }
        }
    }
    
    private func language(from possibleLanguages: [String]) -> String {
        if let currentCode = currentUserLanguage,
           possibleLanguages.contains(currentCode)
        {
            return currentCode
        } else {
            return possibleLanguages.first!
        }
    }
    
    private var currentUserLanguage: String? {
        if #available(macOS 13, *) {
            return Locale.current.language.languageCode?.identifier
        } else {
            return Locale.current.languageCode
        }
    }
}

extension SamplesDocumentsPresenter: LanguageSource {
    func presentProjects(with language: String) {
        let projects = structure!.languages[language]!
        
        self.items = projects.first!.documents.map({ document in
            CollectionViewItem.sample(
                DownloadableDocument(path: document,
                                     isCached: false) // TODO: Change
            )
        })
        
        delegate?.didUpdateDocuments()
    }
}
