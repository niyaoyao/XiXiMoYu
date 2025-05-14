//
//  ttstests.swift
//  ttstests
//
//  Created by NY on 2025/5/14.
//

import XCTest
@testable import tts

final class ttstests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Optional: Add any setup code if needed
    }
    
    override func tearDown() {
        // Optional: Add any cleanup code if needed
        super.tearDown()
    }
    
    func testConvertValidDictionary() {
        let dict: [String: Any] = ["name": "John", "age": 30, "isStudent": false]
        let result = JSONUtils.convertToJsonOpts(dict)
        
        XCTAssertTrue(result.contains("\"name\":\"John\""), "JSON should contain name key")
        XCTAssertTrue(result.contains("\"age\":30"), "JSON should contain age key")
        XCTAssertTrue(result.contains("\"isStudent\":false"), "JSON should contain isStudent key")
        NYSSEManager.shared.send(urlStr: "", body: [:])
        
    }
    
    func testConvertWithPrettyPrinted() {
        let dict: [String: Any] = ["name": "John", "age": 30]
        let result = JSONUtils.convertToJsonOpts(dict, opts: [.prettyPrinted])
        
        XCTAssertTrue(result.contains("\n"), "Pretty-printed JSON should contain newlines")
        XCTAssertTrue(result.contains("  "), "Pretty-printed JSON should contain indentation")
        XCTAssertTrue(result.contains("\"name\" : \"John\""), "JSON should contain formatted name key")
    }
    
    func testConvertEmptyDictionary() {
        let dict: [String: Any] = [:]
        let result = JSONUtils.convertToJsonOpts(dict)
        
        XCTAssertEqual(result, "{}", "Empty dictionary should convert to {}")
    }
    
    func testInvalidObject() {
        // Function object is not JSON serializable
        let invalidObject: Any = { print("test") }
        let result = JSONUtils.convertToJsonOpts(invalidObject)
        
        XCTAssertEqual(result, "", "Invalid object should return empty string")
    }
    
    func testInvalidEncoding() {
        // NSNull is valid in JSON, so test ensures proper handling
        let dict: [String: Any] = ["key": NSNull()]
        let result = JSONUtils.convertToJsonOpts(dict)
        
        XCTAssertFalse(result.isEmpty, "Valid JSON object should not return empty string")
        XCTAssertTrue(result.contains("null"), "JSON should contain null value")
    }
    
    func testConcurrentConversion() {
        let dict: [String: Any] = ["name": "John", "age": 30, "id": UUID().uuidString]
        let iterations = 100
        let queue = DispatchQueue(label: "com.test.jsonutils", attributes: .concurrent)
        let expectation = XCTestExpectation(description: "Concurrent JSON conversions")
        var results: [String] = []
//        let lock = NSLock() // To safely append results
        
        for _ in 0..<iterations {
            queue.async {
                let result = JSONUtils.convertToJsonOpts(dict)
//                lock.lock()
                results.append(result)
//                lock.unlock()
            }
        }
        
        // Wait for all tasks to complete
        queue.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertEqual(results.count, iterations, "All iterations should complete")
            for result in results {
                XCTAssertTrue(result.contains("\"name\":\"John\""), "JSON should contain name key")
                XCTAssertTrue(result.contains("\"age\":30"), "JSON should contain age key")
                XCTAssertTrue(result.contains("\"id\":"), "JSON should contain id key")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }

}
// Assuming the function is in a class named JSONUtils
class JSONUtils {
    static func convertToJsonOpts(_ object: Any, opts: JSONSerialization.WritingOptions = []) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: opts)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            } else {
                return ""
            }
        } catch _ {
            return ""
        }
    }
}
