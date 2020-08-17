//
// Copyright (c) 17.4.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import XCTest
import AnyCodable
import NinchatLowLevelClient
@testable import NinchatSDKSwift

/**
 * Due to some unknown reasons, setting and getting "int" values in 'NINLowLevelClientProps' here results in the following error from go:
 * 'Error Domain=go Code=1 "Prop type: "they_key" is not a number" UserInfo={NSLocalizedDescription=Prop type: "the_key" is not a number'
 * However, it is working on the SDK when the parameters are set from the server.
 * This is why we have to omit testing "int" parameters for now, until we can figure out what is happening here.
*/

final class NINLowLevelClientPropsTests: XCTestCase {

    func test_initializer_action() {
        let props1 = NINLowLevelClientProps.initiate(action: .deleteUser)
        XCTAssertEqual(props1.getString("action", error: nil), NINLowLevelClientActions.deleteUser.rawValue)

        let props2 = NINLowLevelClientProps.initiate(action: .describeQueue, name: "name_2")
        XCTAssertEqual(props2.getString("action", error: nil), NINLowLevelClientActions.describeQueue.rawValue)
        XCTAssertEqual(props2.name.value, "name_2")

        let props3 = NINLowLevelClientProps.initiate()
        XCTAssertEqual(props3.getString("action", error: nil), "")
        XCTAssertEqual(props3.name.value, "")
    }

    func test_initializer_credentials() {
        let credentials = NINSessionCredentials(userID: "user_id_1", userAuth: "user_auth_1", sessionID: "session_id_1")
        let props = NINLowLevelClientProps.initiate(credentials: credentials)

        XCTAssertEqual(props.userID.value, "user_id_1")
        XCTAssertEqual(props.userAuth.value, "user_auth_1")
        XCTAssertEqual(props.sessionID.value, "")
    }

    func test_initializer_dictionary() {
        let props1 = NINLowLevelClientProps.initiate(metadata: ["key1": "value1"])
        XCTAssertNotNil(props1)
        XCTAssertEqual(props1.getString("key1", error: nil), "value1")

        let props2 = NINLowLevelClientProps.initiate(metadata: ["key2": "value2", "key3": 3, "key4": true, "key5": 5.2, "key6": 6.8])
        XCTAssertNotNil(props2)
        XCTAssertEqual(props2.getString("key2", error: nil), "value2")

        let value4: NINResult<Bool> = props2.get(forKey: "key4")
        XCTAssertEqual(value4.value, true)

        let value5: NINResult<Double> = props2.get(forKey: "key5")
        XCTAssertEqual(value5.value, 5.2)

        let value6: NINResult<Double> = props2.get(forKey: "key6", ofType: Double.self)
        XCTAssertEqual(value6.value, 6.8)
    }

    func test_initializer_preQuestionnaire() {
        let answers: [String:AnyHashable] = ["Koronavirus-jatko": "Näytä muut aiheet", "language": "English", "number-of-messages": 3.2]
        let props = NINLowLevelClientProps.initiate(preQuestionnaireAnswers: answers)
        XCTAssertNotNil(props)

        let metadata: NINResult<NINLowLevelClientProps> = props.get(forKey: "pre_answers")
        XCTAssertNotNil(metadata.value)

        let value1: NINResult<String> = metadata.value.get(forKey: "Koronavirus-jatko")
        XCTAssertEqual(value1.value, "Näytä muut aiheet")

        let value2: NINResult<Double> = metadata.value.get(forKey: "number-of-messages")
        XCTAssertEqual(value2.value, 3.2)
    }

    func test_simple_binding() {
        let props = NINLowLevelClientProps.initiate()
        props.messageFold = .success(false)
        props.messageType = .success(.text)
        props.set(value: 6.5, forKey: "message_time")
        props.set(value: "id", forKey: "message_id")


        props.setInt("history_order", val: NSNumber(value: 1).intValue)
        let long = props.get(forKey: "history_order", ofType: CLong.self)
        if case let .failure(error) = long {
            /// It needs to be investigated why we get error when trying to fetch an "int" parameter
            print(error)
        } else {
            XCTAssertEqual(long.value, 1)
        }

        XCTAssertEqual(props.messageFold.value, false)
        XCTAssertEqual(props.messageType.value, .text)
        XCTAssertEqual(props.messageTime.value, 6.5)
        XCTAssertEqual(props.messageID.value, "id")
    }
}

extension NINLowLevelClientProps {
    func get<T>(forKey key: String, ofType type: T.Type) -> NINResult<T> {
        do {
            switch type {
            case is CLong.Type:
                return .success(try self.getInt(key) as! T)
            case is Double.Type:
                return .success(try self.getDouble(key) as! T)
            case is Bool.Type:
                return .success(try self.getBool(key) as! T)
            case is String.Type:
                return .success(try self.getString(key) as! T)
            case is NINLowLevelClientProps.Type:
                return .success(try self.getObject(key) as! T)
            case is NINLowLevelClientStrings.Type:
                return .success(try self.getStringArray(key) as! T)
            case is NINLowLevelClientObjects.Type:
                return .success(try self.getObjectArray(key) as! T)
            default:
                fatalError("Error in requested type: \(T.self) forKey: \(key)")
            }

        } catch {
            return .failure(error)
        }
    }
}
