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
        if let data = self.data {
            let payload = Either<NetworkControllerError, Data>.right(data)
            completionHandler(payload)
            return
        }
    }
}

class BookishDollopTests: XCTestCase {

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
                XCTFail("It should fail")
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testFetchSucceed() {
        // Composing the fake data
        let dataString = "{\"data\":[[1,\"E832AF7F-E37B-48E4-8C35-FCDBB9582914\",1,1509143469,\"881420\",1509143469,\"881420\",null,\"180\",\"2011\",\"Epic Roasthouse (399 Embarcadero)\",null,\"SPI Cinemas\",null,\"Jayendra\",\"Umarji Anuradha, Jayendra, Aarthi Sriram, & Suba \",\"Siddarth\",\"Nithya Menon\",\"Priya Anand\"]]}"
        let data = dataString.data(using: String.Encoding.utf8)

        let exp = expectation(description: "request should fail")

        // Building the mock session
        let testNetworkSession = NetworkSessionMock()
        testNetworkSession.data = data

        let networkManager = NetworkManager(session: testNetworkSession)

        networkManager.fetchFilms { (result: Either<NetworkControllerError, NetworkManager.RawFilms>) in
            switch result {
            case .left:
                XCTFail("It should not fail")
            case .right(let films):
                XCTAssertNotNil(films)
                XCTAssertTrue(films.count == 1, "There should be 1 film")
                exp.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }
}
