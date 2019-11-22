import XCTest

import codegen_testTests

var tests = [XCTestCaseEntry]()
tests += codegen_testTests.allTests()
XCTMain(tests)
