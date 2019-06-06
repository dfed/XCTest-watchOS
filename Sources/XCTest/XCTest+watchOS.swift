//
//  XCTest+watchOS.swift
//  Valet
//
//  Created by Dan Federman on 3/3/18.
//  Copyright © 2018 Dan Federman
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if os(watchOS)
import CoreFoundation
import Foundation
import ObjectiveC


// MARK: - XCTestCase

/// A bare-bones re-implementation of XCTestCase for running tests from the watch extension.
/// The below was heavily inspired by https://github.com/apple/swift-corelibs-xctest/
@objcMembers
open class XCTestCase: NSObject {

    // MARK: Class Public

    /// An entry point for running all tests.
    /// Call this from your `WKExtensionDelegate` in your testing host app.
    /// This method can be used to display UI on device if your tests succeed.
    /// - Returns: `true` if tests succeed.
    public class func runAllTests() -> Bool {
        let testClasses = allTestClasses()
        
        for testClass in testClasses {
            let testInstance = testClass.init()
            let testSelectors = allTestSelectors(in: testClass)
            
            testSelectors.forEach { testSelector in
                testInstance.setUp()
                print("Executing \(testClass).\(testSelector)")
                testInstance.perform(testSelector)
                testInstance.tearDown()
                print("- PASSED: \(testClass).\(testSelector)")
            }
            print("\n")
        }
        print("ALL TESTS PASSED")
        return true
    }

    /// An entry point for running all tests.
    /// Call this from your `WKExtensionDelegate` in your testing host app.
    /// This method is best used for running tests in CI.
    public class func runAllTestsAndExit() -> Never {
        if runAllTests() {
            exit(0)
        } else {
            exit(1)
        }
    }
    
    // MARK: Class Private
    
    private class func allTestSelectors(in testClass: XCTestCase.Type) -> [Selector] {
        var testSelectors = [Selector]()
        
        var methodCount: UInt32 = 0
        guard let methodList = class_copyMethodList(testClass, &methodCount) else {
            return testSelectors
        }
        
        for methodIndex in 0..<Int(methodCount) {
            let method = methodList[methodIndex]
            let selector = method_getName(method)
            let selectorName = sel_getName(selector)
            let methodName = String(cString: selectorName, encoding: .utf8)!
            
            guard methodName.hasPrefix("test") else {
                continue
            }
            
            testSelectors.append(selector)
        }
        
        return testSelectors
    }
    
    private class func allTestClasses() -> [XCTestCase.Type] {
        var testClasses = [XCTestCase.Type]()
        let classesCount = objc_getClassList(nil, 0)
        
        guard classesCount > 0 else {
            return testClasses
        }
        
        let testClassDescription = NSStringFromClass(XCTestCase.self)
        let classes = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(classesCount))
        for classIndex in 0..<objc_getClassList(AutoreleasingUnsafeMutablePointer(classes), classesCount) {
            if let currentClass = classes[Int(classIndex)],
                let superclass = class_getSuperclass(currentClass),
                NSStringFromClass(superclass) == testClassDescription
            {
                testClasses.append(currentClass as! XCTestCase.Type)
            }
        }
        
        return testClasses
    }
    
    // MARK: Initialization
    
    public required override init() {}
    
    // MARK: Open
    
    open func setUp() {}
    open func tearDown() {}

    // MARK: Public

    public func expectation(description: String, file: StaticString = #file, line: UInt = #line) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: description, file: file, line: line)
        expectations.append(expectation)
        return expectation
    }
    
    public func waitForExpectations(timeout: TimeInterval, file: StaticString = #file, line: UInt = #line, handler: ((NSError?) -> Void)? = nil) {
        guard !expectations.isEmpty else {
            assertionFailure()
            return
        }
        
        let runLoop = RunLoop.current
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        repeat {
            var expectationsAllFulfilled = true
            expectations.forEach {
                expectationsAllFulfilled = expectationsAllFulfilled && $0.isFulfilled
            }
            
            guard !expectationsAllFulfilled else {
                break
            }
            
            runLoop.run(until: Date(timeIntervalSinceNow: 0.1))
        } while Date() < timeoutDate
        
        var failedExpectations = [XCTestExpectation]()
        expectations.forEach {
            if !$0.isFulfilled {
                failedExpectations.append($0)
                assertionFailure("expectation not met: \($0.description)", file: file, line: line)
            }
            $0.canBeFulfilled = false
        }
        
        expectations = []
        
        handler?(failedExpectations.isEmpty ? nil : NSError(domain: "XCTestCase", code: 0, userInfo: nil))
        // Fulfill the failed expectations so the deinit assert isn't triggered.
        failedExpectations.forEach { $0.forceFulfill() }
    }
    
    // MARK: Private
    
    private var expectations = [XCTestExpectation]()
}

// MARK: - XCTestExpectation

/// A bare-bones re-implementation of XCTestExpectation for running tests from the watch extension.
public class XCTestExpectation {
    
    // MARK: Lifecycle
    
    internal init(description: String, file: StaticString, line: UInt) {
        self.description = description
        self.file = file
        self.line = line
    }
    
    deinit {
        assert(isFulfilled, "expectation deinit without being fulfilled: \(description)", file: file, line: line)
    }
    
    // MARK: Internal
    
    internal let description: String
    internal private(set) var isFulfilled = false
    internal var canBeFulfilled = true
    
    public func fulfill(_ file: StaticString = #file, line: UInt = #line) {
        guard !isFulfilled else {
            assertionFailure("expectation already fulfilled: \(description)", file: file, line: line)
            return
        }
        
        guard canBeFulfilled else {
            assertionFailure("expectation fulfilled after wait completed: \(description)", file: file, line: line)
            return
        }
        
        isFulfilled = true
    }
    
    // MARK: Fileprivate
    
    fileprivate func forceFulfill() {
        isFulfilled = true
    }
    
    // MARK: Private
    
    private let file: StaticString
    private let line: UInt
}

// MARK: – XCTAssert Static Methods

public func XCTAssertTrue(_ expression: @autoclosure () throws -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    do {
        let result = try expression()
        assert(result, message(), file: file, line: line)
    } catch _ {
        assertionFailure(message(), file: file, line: line)
    }
}

public func XCTAssertFalse(_ expression: @autoclosure () throws -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    do {
        let result = try expression()
        assert(!result, message(), file: file, line: line)
    } catch _ {
        assertionFailure(message(), file: file, line: line)
    }
}

public func XCTAssertNil(_ expression: @autoclosure () throws -> Any?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    do {
        let result = try expression()
        assert(result == nil, message(), file: file, line: line)
    } catch _ {
        assertionFailure(message(), file: file, line: line)
    }
}

public func XCTAssertEqual<T: Equatable>(_ expression1: @autoclosure () throws -> T?, _ expression2: @autoclosure () throws -> T?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    do {
        let (value1, value2) = (try expression1(), try expression2())
        assert(value1 == value2, message(), file: file, line: line)
    } catch _ {
        assertionFailure(message(), file: file, line: line)
    }
}

public func XCTAssertNotEqual<T: Equatable>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    do {
        let (value1, value2) = (try expression1(), try expression2())
        assert(value1 != value2, message(), file: file, line: line)
    } catch _ {
        assertionFailure(message(), file: file, line: line)
    }
}

public func XCTFail(_ message: String = "", file: StaticString = #file, line: UInt = #line) {
    assertionFailure(message, file: file, line: line)
}

public func measure(function: String = #function, block: () -> Void) {
    let timesToExecuteBlock = 10
    let measuredTime: [CFAbsoluteTime] = Array(0..<timesToExecuteBlock).map { _ in
        let startTime = CFAbsoluteTimeGetCurrent()
        block()
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        return executionTime
    }
    
    let results = [
        String(format: "average: %.3f", measuredTime.average),
        String(format: "relative standard deviation: %.3f%%", measuredTime.relativeStandardDeviation),
        "values: [\(measuredTime.map({ String(format: "%.6f", $0) }).joined(separator: ", "))]",
        ]
    print("Test Case '\(function)' measured [Time, seconds] \(results.joined(separator: ", "))")
}

// MARK: - Private

private extension Collection where Index: ExpressibleByIntegerLiteral, Iterator.Element == CFAbsoluteTime {

    var average: CFAbsoluteTime {
        return self.reduce(0, +) / Double(Int(count))
    }

    var standardDeviation: CFAbsoluteTime {
        let squaredDifferences = map { pow($0 - average, 2.0) }
        let variance = squaredDifferences.reduce(0, +) / Double(Int(count - 1))
        return sqrt(variance)
    }

    var relativeStandardDeviation: Double {
        return (standardDeviation * 100) / average
    }

}

#endif
