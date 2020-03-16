//
// Copyright (c) 13.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
@testable import NinchatSDKSwift

final class ExtensionsTests: XCTestCase {
    func test_font() {
        XCTAssertNotNil(UIFont.ninchat)
    }
    
    func test_mutableString_font() {
        let str = NSMutableAttributedString(string: "The test string")
        str.override(font: UIFont.ninchat!)
        XCTAssertTrue(true)
    }

    func test_plain_string() {
        XCTAssertNotNil("This is an example of simple string".plainString(withFont: .ninchat, alignment: .center, color: .white))
        XCTAssertNotNil("<head>This is an example of html string</head>".plainString(withFont: .ninchat, alignment: .left, color: .black))
    }
    
    func test_html_string() {
        XCTAssertNotNil("This is an example of simple string".htmlAttributedString(withFont: .ninchat, alignment: .center, color: .white))
        XCTAssertNotNil("<head>This is an example of html string</head>".htmlAttributedString(withFont: .ninchat, alignment: .left, color: .black))
    }
    
    func test_string_with_tags() {
        XCTAssertTrue("This is a string containing a <random> opening tag.".containsTags)
        XCTAssertTrue("abc <tag> ölöl </tag>".containsTags)
        
        XCTAssertFalse("Foo. No tags here.".containsTags)
        XCTAssertFalse("Well, this is <not > a valid tag.".containsTags)
    }
    
    func test_dictionary_to_data() {
        let dic: [AnyHashable:Any] = ["Key": 1, "Key2": "Key", "2": "Key"]
        XCTAssertNotNil(dic.toData)
    }
}