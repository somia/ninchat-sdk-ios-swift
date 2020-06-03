//
// Copyright (c) 13.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
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

    func test_html_string_utf16() {
        let expect_url = self.expectation(description: "Expected to get back the url from attributed string")
        expect_url.expectedFulfillmentCount = 2

        let expect_style = self.expectation(description: "Expected to get appropriate style from attributed string")
        expect_style.expectedFulfillmentCount = 2

        func test_link1() {
            let url = "https://www.ninchat.com/"
            let text = "<a href=\"https://www.ninchat.com\">salaries_by_field_of_study_2018.pdf</a>"
            let attrString = text.htmlAttributedString(withFont: .ninchat, alignment: .left, color: .black)
            XCTAssertNotNil(attrString)
            XCTAssertEqual(attrString?.string, "salaries_by_field_of_study_2018.pdf")

            attrString!.enumerateAttributes(in: NSMakeRange(0, attrString!.length)) { attributes, range, stopped in
                attributes.forEach { key, value in
                    switch key {
                    case NSAttributedString.Key.link:
                        XCTAssertEqual((value as! URL).absoluteString, url)
                        expect_url.fulfill()
                    case NSAttributedString.Key.paragraphStyle:
                        XCTAssertEqual((value as! NSParagraphStyle).alignment, .left)
                        expect_style.fulfill()
                    default:
                        break
                    }
                }
            }
        }

        func test_link2() {
            let url = "https://www.ninchat.com/"
            let text = "<a href=\"https://www.ninchat.com\">Pellon kuivatusjärjestelmät ja ravinteiden talteenotto raportti.pdf</a>"
            let attrString = text.htmlAttributedString(withFont: .ninchat, alignment: .left, color: .black)
            XCTAssertNotNil(attrString)
            XCTAssertEqual(attrString?.string, "Pellon kuivatusjärjestelmät ja ravinteiden talteenotto raportti.pdf")

            attrString!.enumerateAttributes(in: NSMakeRange(0, attrString!.length)) { attributes, range, stopped in
                attributes.forEach { key, value in
                    switch key {
                    case NSAttributedString.Key.link:
                        XCTAssertEqual((value as! URL).absoluteString, url)
                        expect_url.fulfill()
                    case NSAttributedString.Key.paragraphStyle:
                        XCTAssertEqual((value as! NSParagraphStyle).alignment, .left)
                        expect_style.fulfill()
                    default:
                        break
                    }
                }
            }
        }

        test_link1()
        test_link2()

        waitForExpectations(timeout: 5.0)
    }

    func test_dictionary_to_data() {
        let dic: [AnyHashable:Any] = ["Key": 1, "Key2": "Key", "2": "Key"]
        XCTAssertNotNil(dic.toData)
    }

    func test_color_to_image() {
        XCTAssertNotNil(UIColor.blueButton.toImage)
        XCTAssertNotNil(UIColor.white.toImage)
    }
}
