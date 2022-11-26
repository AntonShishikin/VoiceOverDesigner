//
//  DocumentSaveService.swift
//  VoiceOver Designer
//
//  Created by Mikhail Rubanov on 30.04.2022.
//

import Foundation

protocol DataProvier {
    func save(data: Data) throws
    func read() throws -> Data
}

class URLDataProvider: DataProvier {
    func save(data: Data) throws {
        try data.write(to: fileURL)
    }
    
    func read() throws -> Data {
        try Data(contentsOf: fileURL)
    }
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    private let fileURL: URL
}

class DocumentSaveService {
    
    // For production use
    init(fileURL: URL) {
        self.dataProvier = URLDataProvider(fileURL: fileURL)
    }
    
    // For test purpose
    init(dataProvier: DataProvier) {
        self.dataProvier = dataProvier
    }
    
    private let dataProvier: DataProvier
    
    func save(controls: [any AccessibilityView]) throws {
        let data = try data(from: controls)
        try dataProvier.save(data: data)
    }
    
    func data(from controls: [any AccessibilityView]) throws -> Data {
        let encodableWrapper = controls.map(AccessibilityViewDecodable.init(view:))
        let data = try! JSONEncoder().encode(encodableWrapper)
        return data
    }
    
    func loadControls() throws -> [any AccessibilityView] {
        let data = try dataProvier.read()
        let controls = try JSONDecoder().decode([AccessibilityViewDecodable].self, from: data)
        
        return controls.map(\.view)
    }
}

class AccessibilityViewDecodable: Codable {
    init(view: any AccessibilityView) {
        self.view = view
    }
    
    var view: any AccessibilityView
    
    // MARK: Codable
    enum CodingKeys: CodingKey {
        case type
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = (try? container.decode(AccessibilityViewType.self, forKey: .type)) ?? .element // Default value is element
        
        switch type {
        case .element:
            self.view = try A11yDescription(from: decoder)
        case .container:
            self.view = try A11yContainer(from: decoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        switch view.type {
        case .element:
            try (view as? A11yDescription).encode(to: encoder)
        case .container:
            try (view as? A11yContainer).encode(to: encoder)
        }
    }
}
