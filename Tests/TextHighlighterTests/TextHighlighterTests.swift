import XCTest
@testable import TextHighlighter

final class TextHighlighterTests: XCTestCase {
    
    func testCreateAndRetrieveHighlight() throws {
        let config = HighlightConfiguration(autoSave: false) // ahora es público
        let manager = HighlightManager(configuration: config)

        let uuid = UUID().uuidString
        let text = "Verso de prueba"
        
        try manager.setHighlight(
            uuid: uuid,
            color: HighlightColorScheme.blue,
            text: text,
            note: "Nota de prueba",
            tags: ["ejemplo", "test"]
        )
        
        let recuperado = manager.getHighlight(uuid: uuid)
        XCTAssertNotNil(recuperado)
        XCTAssertEqual(recuperado?.text, text)
        XCTAssertEqual(recuperado?.note, "Nota de prueba")
        XCTAssertEqual(recuperado?.tags, ["ejemplo", "test"])
    }
    
    func testDeleteHighlight() throws {
        let config = HighlightConfiguration(autoSave: false)
        let manager = HighlightManager(configuration: config)
        let uuid = UUID().uuidString
        
        try manager.setHighlight(
            uuid: uuid,
            color: HighlightColorScheme.green,
            text: "Texto a eliminar"
        )
        
        XCTAssertTrue(manager.hasHighlight(uuid: uuid))
        try manager.removeHighlight(uuid: uuid)
        XCTAssertFalse(manager.hasHighlight(uuid: uuid))
    }
    
    func testUpdateHighlight() throws {
        let config = HighlightConfiguration(autoSave: false)
        let manager = HighlightManager(configuration: config)
        let uuid = UUID().uuidString
        
        try manager.setHighlight(
            uuid: uuid,
            color: HighlightColorScheme.pink,
            text: "Texto original",
            note: "Nota inicial"
        )
        
        try manager.updateHighlight(uuid: uuid, note: "Nota actualizada", tags: ["nuevo"])
        
        let actualizado = manager.getHighlight(uuid: uuid)
        XCTAssertEqual(actualizado?.note, "Nota actualizada")
        XCTAssertEqual(actualizado?.tags, ["nuevo"])
    }
}
