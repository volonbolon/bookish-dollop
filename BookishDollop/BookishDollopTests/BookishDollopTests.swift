//
//  BookishDollopTests.swift
//  BookishDollopTests
//
//  Created by Ariel Rodriguez on 16/02/2018.
//  Copyright © 2018 Ariel Rodriguez. All rights reserved.
//

import XCTest
@testable import BookishDollop

class NetworkSessionMock: NetworkSession {
    var data: Data?
    var error: NetworkControllerError?

    func fetch(request: URLRequest, completionHandler: @escaping NetworkSession.FetchCompletionHandler) {
        if let error = self.error {
            let payload = Either<NetworkControllerError, Data>.left(error)
            completionHandler(payload)
            return
        }
    }
}

class WizelineChallengeTestTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFetchShouldFail() {
        let exp = expectation(description: "request should fail")

        let testNetworkSession = NetworkSessionMock()
        let error = NetworkControllerError.invalidURL("This is not a URL")
        testNetworkSession.error = error

        // By injecting a custom session, we can easily test different network scenarios
        let networkManager = NetworkManager(session: testNetworkSession)

        networkManager.fetchFilms { (result: Either<NetworkControllerError, NetworkManager.RawFilms>) in
            switch result {
            case .left(let error):
                XCTAssertNotNil(error)
                exp.fulfill()
            case .right:
                XCTFail("It should not fail")
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }
}
