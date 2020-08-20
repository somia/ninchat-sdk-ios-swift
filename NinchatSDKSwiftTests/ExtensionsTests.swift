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
        let str = NSMutableAttributedString(string: "The test string").override(font: UIFont.ninchat!)
        XCTAssertNotNil(str)
    }

    func test_plain_string() {
        XCTAssertNotNil("This is an example of simple string".plainString(withFont: .ninchat, alignment: .center, color: .white))
        XCTAssertNotNil("<head>This is an example of html string</head>".plainString(withFont: .ninchat, alignment: .left, color: .black))
    }
    
    func test_html_string() {
        XCTAssertNotNil("This is an example of simple string".htmlAttributedString(withFont: .ninchat, alignment: .center, color: .white, width: nil))
        XCTAssertNotNil("<head>This is an example of html string</head>".htmlAttributedString(withFont: .ninchat, alignment: .left, color: .black, width: 100))
    }
    
    func test_string_with_tags() {
        XCTAssertTrue("This is a string containing a <random> opening tag.".containsTags)
        XCTAssertTrue("abc <tag> ölöl </tag>".containsTags)
        
        XCTAssertFalse("Foo. No tags here.".containsTags)
        XCTAssertFalse("Well, this is <not > a valid tag.".containsTags)
    }

    func test_string_regex() {
        let string_1 = "🇩🇪€4€9"
        XCTAssertNotNil(string_1.extractRegex(withPattern: "[0-9]"))
        XCTAssertEqual(string_1.extractRegex(withPattern: "[0-9]"), ["4", "9"])

        let string_2 = "2"
        XCTAssertNotNil(string_2.extractRegex(withPattern: "^[1-5]$"))
        XCTAssertEqual(string_2.extractRegex(withPattern: "^[1-5]$"), ["2"])
    }

    func test_html_string_utf16() {
        let expect_url = self.expectation(description: "Expected to get back the url from attributed string")
        expect_url.assertForOverFulfill = false

        let expect_style = self.expectation(description: "Expected to get appropriate style from attributed string")
        expect_style.assertForOverFulfill = false

        func test_link1() {
            let url = "https://www.ninchat.com/"
            let text = "<a href=\"https://www.ninchat.com\">salaries_by_field_of_study_2018.pdf</a>"
            let attrString = text.htmlAttributedString(withFont: .ninchat, alignment: .left, color: .black, width: nil)
            XCTAssertNotNil(attrString)
            XCTAssertEqual(attrString?.string, "salaries_by_field_of_study_2018.pdf\n")

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
            let attrString = text.htmlAttributedString(withFont: .ninchat, alignment: .left, color: .black, width: nil)
            XCTAssertNotNil(attrString)
            XCTAssertEqual(attrString?.string, "Pellon kuivatusjärjestelmät ja ravinteiden talteenotto raportti.pdf\n")

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

    func test_dictionary_filter_keys() {
        let keys = ["key1", "key2"]
        let dictionary = ["key1":"value1", "invalid1":"value1", "key2":"value2", "invalid2":"value2"]

        let filtered = dictionary.filter(based: keys)
        XCTAssertEqual(filtered, ["key1":"value1", "key2":"value2"])
    }

    func test_dictionary_filter_dictionary() {
        let keys = ["key1", "key2"]
        let target: [String:String] = ["key1":"value1", "key2":"^[1-5]$"]

        let dictionary_1: [String:String] = ["key1":"value1", "invalid1":"value1", "key2":"value2", "invalid2":"value2"]
        XCTAssertEqual(dictionary_1.filter(based: target, keys: keys), ["key1":"value1"])

        let dictionary_2: [String:String] = ["key1":"value1", "invalid1":"value1", "key2":"2", "invalid2":"value2"]
        XCTAssertEqual(dictionary_2.filter(based: target, keys: keys), ["key1":"value1", "key2":"2"])

        let dictionary_3: [String:String] = [:]
        XCTAssertNil(dictionary_3.filter(based: target, keys: keys))

        let dictionary_4: [String:String] = ["key2":"2"]
        XCTAssertEqual(dictionary_4.filter(based: target, keys: keys), ["key2":"2"])

        let dictionary_5: [String:String] = ["key2":"invalid"]
        XCTAssertNil(dictionary_5.filter(based: target, keys: keys))
    }

    func test_color_to_image() {
        XCTAssertNotNil(UIColor.blueButton.toImage)
        XCTAssertNotNil(UIColor.white.toImage)
    }

    func test_date_time() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let date = formatter.date(from: "2020-06-10 12:30:45")
        XCTAssertNotNil(date)
        XCTAssertNotNil(date?.time)
        XCTAssertEqual(date?.time, "12:30:45")
    }

    func test_layout_priority() {
        let priority = UILayoutPriority.almostRequired
        XCTAssertEqual(priority.rawValue, 999.0)
    }

    func test_thread() {
        XCTAssertTrue(Thread.current.isRunningXCTests)
    }
}
