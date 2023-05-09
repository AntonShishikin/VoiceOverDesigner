import XCTest
@testable import Document
import DocumentTestHelpers

import SnapshotTesting
import FolderSnapshot

final class DocumentVersionsTests: XCTestCase {

#if os(macOS)
    
    // MARK: - Beta format
    func test_betaDocument_whenRead_shouldUpdateStructure() throws {
        let document = try XCTUnwrap(Sample().document(name: "BetaVersionFormat", testCase: self))
        
        // Read on file creation
        
        assertSnapshot(matching: document.fileURL!, as: .folderStructure)
    }
    
    func test_betaDocument_whenSave_shouldUpdateStructure() throws {
        let document = try XCTUnwrap(Sample().document(name: "BetaVersionFormat", testCase: self))

        saveDocumentAndRemoveAtTearDown(document: document, name: "BetaFormatNewStructure")
        
        assertSnapshot(matching: document.fileURL!, as: .folderStructure)
    }
    
    func test_betaDocument_whenReads_shouldMoveElementsToFirstFrame() throws {
        let document = try XCTUnwrap(Sample().document(name: "BetaVersionFormat", testCase: self))
        
        let frame = try XCTUnwrap(document.artboard.frames.first)
        
        XCTAssertEqual(frame.elements.count, 12)
        XCTAssertNotNil(document.artboard.imageLoader.image(for: frame))
    }
    
    // MARK: - Frame version
    func test_frameDocument_whenRead_shouldUpdateStructure() throws {
        let document = try XCTUnwrap(Sample().document(name: "FrameVersionFormat", testCase: self))
        
        // Read on file creation
        
        assertSnapshot(matching: document.fileURL!, as: .folderStructure)
    }
    
    func test_frameDocument_whenSave_shouldUpdateStructure() throws {
        let document = try XCTUnwrap(Sample().document(name: "FrameVersionFormat", testCase: self))

        saveDocumentAndRemoveAtTearDown(document: document, name: "FrameFormatNewStructure")
        
        assertSnapshot(matching: document.fileURL!, as: .folderStructure)
    }
    
    func test_canReadFrameFileFormat() throws {
        let document = try XCTUnwrap(Sample().document(name: "FrameVersionFormat", testCase: self))
        
        let frame = try XCTUnwrap(document.artboard.frames.first)
        
        XCTAssertEqual(frame.elements.count, 12)
        XCTAssertNotNil(document.artboard.imageLoader.image(for: frame))
        XCTAssertEqual(frame.frame, CGRect(x: 0, y: 0, width: 390, height: 844), "should scale frame")
        
        assertSnapshot(matching: document.fileURL!, as: .folderStructure)
    }
    
    // MARK: Artboard version
    func test_artboardDocument_whenRead_shouldUpdateStructure() throws {
        let document = try XCTUnwrap(Sample().document(name: "ArtboardFormat", testCase: self))
        
        // Read on file creation
        
        assertSnapshot(matching: document.fileURL!, as: .folderStructure)
    }
    
    func test_artboardDocument_whenSave_shouldUpdateStructure() throws {
        let document = try XCTUnwrap(Sample().document(name: "ArtboardFormat", testCase: self))

        saveDocumentAndRemoveAtTearDown(document: document, name: "ArtboardFormatNewStructure")
        
        assertSnapshot(matching: document.fileURL!, as: .folderStructure)
    }
    
    
    func test_artboardFormat() throws {
        let document = try XCTUnwrap(Sample().document(name: "ArtboardFormat", testCase: self))
        
        let artboard = document.artboard
        XCTAssertEqual(artboard.frames.count, 2)
        XCTAssertEqual(artboard.controlsWithoutFrames.count, 0)
        
        let frame1 = try XCTUnwrap(artboard.frames.first)
        XCTAssertEqual(frame1.elements.count, 10)
        XCTAssertNotNil(document.artboard.imageLoader.image(for: frame1))
        XCTAssertEqual(frame1.frame, CGRect(x: 2340, y: 0, width: 1170, height: 3407), "should scale frame")
        
        let frame2 = try XCTUnwrap(artboard.frames.last)
        XCTAssertEqual(frame2.elements.count, 8)
        XCTAssertNotNil(document.artboard.imageLoader.image(for: frame2))
        XCTAssertEqual(frame2.frame, CGRect(x: 0, y: 0, width: 1170, height: 3372), "should scale frame")
        
        assertSnapshot(matching: document.fileURL!, as: .folderStructure)
    }
    
    // MARK: - Restoration DSL
    private let fileManager = FileManager.default
    
    private func saveDocumentAndRemoveAtTearDown(document: VODesignDocument, name: String) {
        document.save(testCase: self, fileName: name)
        addTeardownBlock {
            let testFilePath = Sample().resourcesPath().appendingPathComponent("\(name).vodesign")
            try? self.fileManager.removeItem(at: testFilePath)
        }
    }

#elseif os(iOS)
    
    func test_canReadDocumentWithoutFrameFolder() async throws {
        let fileName = "BetaVersionFormat"
        let document = try XCTUnwrap(Sample().document(name: fileName))
        
        await document.read()

        await MainActor.run(body: {
            XCTAssertEqual(document.elements.count, 12)
            XCTAssertNotNil(document.image)
            XCTAssertEqual(document.frameInfo.imageScale, 1, "Old format doesn't know about scale")
        })
    }
    
    func test_canReadFrameFileFolrmat() async throws {
        let fileName = "ReleaseVersionFormat"
        let document = try XCTUnwrap(Sample().document(name: fileName))
        
        await document.read()

        await MainActor.run(body: {
            XCTAssertEqual(document.elements.count, 12)
            XCTAssertNotNil(document.image)
            XCTAssertEqual(document.frameInfo.imageScale, 3)
        })
    }
#endif
}

#if os(iOS)
extension Document {
    func read() async {
        await withCheckedContinuation({ continuation in
            open(completionHandler: { _ in
                continuation.resume()
            })
        })
    }
}
#endif
