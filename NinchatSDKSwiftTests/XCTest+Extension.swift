//
// Copyright (c) 2.6.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest

extension XCTest {
    func openAsset(forResource name: String, ofType type: String = "json") throws -> [String:AnyHashable]? {
        let bundle = Bundle(for: QuestionnaireConverterTests.self)
        if let path = bundle.path(forResource: name, ofType: type) {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            return jsonResult as? [String:AnyHashable]
        }
        return nil
    }
}
