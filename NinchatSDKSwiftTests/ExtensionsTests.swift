//
// Copyright (c) 13.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import UIKit
import XCTest
import NinchatLowLevelClient
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
        let target: [String:AnyHashable] = ["key1":"value1", "key2":"^[1-5]$"]

        let dictionary_1: [String:AnyHashable] = ["key1":"value1", "invalid1":"value1", "key2":"value2", "invalid2":"value2"]
        XCTAssertEqual(dictionary_1.filter(based: target, keys: keys), ["key1":"value1"])

        let dictionary_2: [String:AnyHashable] = ["key1":"value1", "invalid1":"value1", "key2":"2", "invalid2":"value2"]
        XCTAssertEqual(dictionary_2.filter(based: target, keys: keys), ["key1":"value1", "key2":"2"])

        let dictionary_3: [String:AnyHashable] = [:]
        XCTAssertNil(dictionary_3.filter(based: target, keys: keys))

        let dictionary_4: [String:AnyHashable] = ["key2":"2"]
        XCTAssertEqual(dictionary_4.filter(based: target, keys: keys), ["key2":"2"])

        let dictionary_5: [String:AnyHashable] = ["key2":"invalid"]
        XCTAssertNil(dictionary_5.filter(based: target, keys: keys))
    }
    
    func test_find_key_nested_dictionary() {
        let dict1 = ["key1":"value1"]
        let dict1_bro = ["key1":"value2"]
        let dict1_parent1 = ["pkey1": dict1]
        let dict1_parent2 = ["pkey2": dict1_parent1]
        let dict1_parent3: [String:Any] = ["pkey3": dict1_parent2, "pkey3_bro": dict1_bro]
        let dict_mixed: [String:Any] = ["mkey1": dict1_parent3, "mkey2": 2, "k": 3.5]
        
        var res: [String] = ["":""].find("key1")
        XCTAssertEqual(res, [])
        
        res = dict1.find("key1")
        XCTAssertEqual(res, ["value1"])
        
        res = dict1_parent1.find("key1")
        XCTAssertEqual(res, ["value1"])
        
        res = dict1_parent2.find("key1")
        XCTAssertEqual(res, ["value1"])
        
        res = dict1_parent3.find("key1")
        XCTAssertEqual(res.sorted(), ["value1", "value2"])
        
        res = dict_mixed.find("key1")
        XCTAssertEqual(res.sorted(), ["value1", "value2"])
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

    func test_userDefaults_swiftTypes() {
        let value: [String:Any] = ["key-1": "value-1", "key-2": ["key-21": "value-21", "key-31": 2], "key-3": 5.5]
        UserDefaults.save(value, key: .metadata)

        let fetchedValue: [String:Any]? = UserDefaults.load(forKey: .metadata)
        XCTAssertNotNil(fetchedValue)
        XCTAssertEqual(fetchedValue!["key-1"] as? String, "value-1")
        XCTAssertEqual((fetchedValue!["key-2"] as? [String:Any])?["key-21"] as? String, "value-21")
        XCTAssertEqual((fetchedValue!["key-2"] as? [String:Any])?["key-31"] as? Int, 2)
        XCTAssertEqual(fetchedValue!["key-3"] as? Double, 5.5)
    }

    func test_userDefaults_lowLevelTypes() {
        let error: NSErrorPointer = nil
        let metadata = NINLowLevelClientProps.initiate(metadata: ["key-21": "value-21", "key-31": 2]).marshalJSON(error)
        XCTAssertNil(error)
        UserDefaults.save(["key-1": metadata], key: .metadata)

        let fetchedValue: [String:Any]? = UserDefaults.load(forKey: .metadata)
        XCTAssertNotNil(fetchedValue)
        XCTAssertEqual(fetchedValue?["key-1"] as? String, "{\"key-21\":\"value-21\",\"key-31\":2}")

        let fetchedMetadata = NINLowLevelClientProps.initiate()
        XCTAssertNoThrow(try fetchedMetadata.unmarshalJSON(fetchedValue?["key-1"] as? String))
        XCTAssertEqual(try? fetchedMetadata.getString("key-21"), "value-21")
    }
    
    func test_ordered_set() {
        let array = [1, 3, 1, 4, 2, 3, 6, 1]
        let expected = [1, 3, 4, 2, 6]
        
        XCTAssertEqual(array.uniqued(), expected)
    }
}
