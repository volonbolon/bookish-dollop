//
//  URLSession+NetworkInterface.swift
//  BookishDollop
//
//  Created by Ariel Rodriguez on 16/02/2018.
//  Copyright © 2018 Ariel Rodriguez. All rights reserved.
//

import Foundation

// Errors used by Network Session and Manager
enum NetworkControllerError: Error {
    case invalidURL(String)
    case invalidPayload(URL)
    case forwarded(Error)
}

/*
 By encapsulating the session with a protocol, we can easily inject
 our own session into the manger, instead of using the shared singleton.
 This is helpful for tests (and also, for instance, to load items from different sources)
 */
protocol NetworkSession {
    typealias FetchCompletionHandler = (Either<NetworkControllerError, Data>) -> Void
    /**
     Given a request, it will configure and run the approrpiate task.
     - parameters:
        - request: fully configured URL request instance
        - completionHandler: closure that will inform the caller if the task finish successfully,
          and, if available, returns the data.
          The information is encapsulated in an Either construct.
     */
    func fetch(request: URLRequest, completionHandler:@escaping FetchCompletionHandler)
}

extension URLSession: NetworkSession {
    func fetch(request: URLRequest, completionHandler: @escaping NetworkSession.FetchCompletionHandler) {
        let task = self.dataTask(with: request) { (data: Data?, _: URLResponse?, error: Error?) in
            guard error == nil else {
                let networkError = NetworkControllerError.forwarded(error!)
                let payload = Either<NetworkControllerError, Data>.left(networkError)
                completionHandler(payload)

                return
            }

            guard let jsonData = data else {
                let payloadError = NetworkControllerError.invalidPayload(request.url!)
                let payload = Either<NetworkControllerError, Data>.left(payloadError)
                completionHandler(payload)

                return
            }

            let payload = Either<NetworkControllerError, Data>.right(jsonData)
            completionHandler(payload)
        }
        task.resume()
    }
}
