//
//  debounceAndRemoveDuplicatesPublisherTests.swift
//  UsingCombineTests
//
//  Created by Joseph Heck on 7/11/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import XCTest
import Combine

class debounceAndRemoveDuplicatesPublisherTests: XCTestCase {

    func testRemoveDuplicates() {
        let simplePublisher = PassthroughSubject<String, Error>()

        var mostRecentlyReceivedValue: String? = nil
        var receivedValueCount = 0

        let _ = simplePublisher
            .removeDuplicates()
            .print(self.debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case .failure(let anError):
                    print(".sink() received completion error: ", anError)
                    XCTFail("no error should be received")
                    break
                case .finished:
                    break
                }
            }, receiveValue: { stringValue in
                print(".sink() received \(stringValue)")
                mostRecentlyReceivedValue = stringValue
                receivedValueCount += 1
            })

        // initial state before sending anything
        XCTAssertNil(mostRecentlyReceivedValue)
        XCTAssertEqual(receivedValueCount, 0)

        // first value is processed through the pipeline
        simplePublisher.send("onefish")
        XCTAssertEqual(mostRecentlyReceivedValue, "onefish")
        XCTAssertEqual(receivedValueCount, 1)
        // resend of that same value isn't received by .sink
        simplePublisher.send("onefish")
        XCTAssertEqual(mostRecentlyReceivedValue, "onefish")
        XCTAssertEqual(receivedValueCount, 1)

        // a new value that doesn't match the previous value gets passed through
        simplePublisher.send("twofish")
        XCTAssertEqual(mostRecentlyReceivedValue, "twofish")
        XCTAssertEqual(receivedValueCount, 2)
        // resend of that same value isn't received by .sink
        simplePublisher.send("twofish")
        XCTAssertEqual(mostRecentlyReceivedValue, "twofish")
        XCTAssertEqual(receivedValueCount, 2)

        // An earlier value will get passed through as long as
        // it's not the one that just recently was seen
        simplePublisher.send("onefish")
        XCTAssertEqual(mostRecentlyReceivedValue, "onefish")
        XCTAssertEqual(receivedValueCount, 3)

        simplePublisher.send(completion: Subscribers.Completion.finished)
    }


    func testRemoveDuplicatesWithoutEquatable() {
        struct AnExampleStruct {
            let id: Int
        }

        let simplePublisher = PassthroughSubject<AnExampleStruct, Error>()

        var mostRecentlyReceivedValue: AnExampleStruct? = nil
        var receivedValueCount = 0

        let _ = simplePublisher
            .removeDuplicates(by: { first, second -> Bool in
                first.id == second.id
            })
            .print(self.debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case .failure(let anError):
                    print(".sink() received completion error: ", anError)
                    XCTFail("no error should be received")
                    break
                case .finished:
                    break
                }
            }, receiveValue: { someValue in
                print(".sink() received \(someValue)")
                mostRecentlyReceivedValue = someValue
                receivedValueCount += 1
            })

        // initial state before sending anything
        XCTAssertNil(mostRecentlyReceivedValue)
        XCTAssertEqual(receivedValueCount, 0)

        // first value is processed through the pipeline
        simplePublisher.send(AnExampleStruct(id: 1))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 1)
        XCTAssertEqual(receivedValueCount, 1)
        // resend of that same value isn't received by .sink
        simplePublisher.send(AnExampleStruct(id: 1))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 1)
        XCTAssertEqual(receivedValueCount, 1)

        // a new value that doesn't match the previous value gets passed through
        simplePublisher.send(AnExampleStruct(id: 2))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 2)
        XCTAssertEqual(receivedValueCount, 2)
        // resend of that same value isn't received by .sink
        simplePublisher.send(AnExampleStruct(id: 2))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 2)
        XCTAssertEqual(receivedValueCount, 2)

        // An earlier value will get passed through as long as
        // it's not the one that just recently was seen
        simplePublisher.send(AnExampleStruct(id: 1))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 1)
        XCTAssertEqual(receivedValueCount, 3)

        simplePublisher.send(completion: Subscribers.Completion.finished)
    }

    func testTryRemoveDuplicates() {
        struct AnExampleStruct {
            let id: Int
        }

        enum TestFailure: Error {
            case boom
        }

        let simplePublisher = PassthroughSubject<AnExampleStruct, Error>()

        var mostRecentlyReceivedValue: AnExampleStruct? = nil
        var receivedValueCount = 0
        var receivedError = false

        let _ = simplePublisher
            .tryRemoveDuplicates(by: { first, second -> Bool in
                if (first.id == 5 || second.id == 5) {
                    // a contrived example showing the exception
                    throw TestFailure.boom
                }
                return first.id == second.id
            })
            .print(self.debugDescription)
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion:", String(describing: completion))
                switch completion {
                case .failure(let anError):
                    print(".sink() received completion error: ", anError)
                    receivedError = true
                    break
                case .finished:
                    XCTFail("no completion should be received")
                    break
                }
            }, receiveValue: { someValue in
                print(".sink() received \(someValue)")
                mostRecentlyReceivedValue = someValue
                receivedValueCount += 1
            })

        // initial state before sending anything
        XCTAssertNil(mostRecentlyReceivedValue)
        XCTAssertEqual(receivedValueCount, 0)
        XCTAssertFalse(receivedError)

        // first value is processed through the pipeline
        simplePublisher.send(AnExampleStruct(id: 1))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 1)
        XCTAssertEqual(receivedValueCount, 1)
        XCTAssertFalse(receivedError)

        // resend of that same value isn't received by .sink
        simplePublisher.send(AnExampleStruct(id: 1))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 1)
        XCTAssertEqual(receivedValueCount, 1)
        XCTAssertFalse(receivedError)

        // a new value that doesn't match the previous value gets passed through
        simplePublisher.send(AnExampleStruct(id: 2))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 2)
        XCTAssertEqual(receivedValueCount, 2)
        XCTAssertFalse(receivedError)

        // resend of that same value isn't received by .sink
        simplePublisher.send(AnExampleStruct(id: 2))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 2)
        XCTAssertEqual(receivedValueCount, 2)
        XCTAssertFalse(receivedError)

        // We send a value that causes an exception to be thrown
        simplePublisher.send(AnExampleStruct(id: 5))
        XCTAssertEqual(mostRecentlyReceivedValue?.id, 2)
        XCTAssertEqual(receivedValueCount, 2)
        XCTAssertTrue(receivedError)

        simplePublisher.send(completion: Subscribers.Completion.finished)
    }
}
