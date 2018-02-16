//
//  NetworkManager.swift
//  BookishDollop
//
//  Created by Ariel Rodriguez on 16/02/2018.
//  Copyright © 2018 Ariel Rodriguez. All rights reserved.
//

import Foundation

class NetworkManager {
    private let session: NetworkSession // here we can insert our own custom session
    typealias RawFilms = [[Any]]
    typealias FilmsCompletionHandler = (Either<NetworkControllerError, RawFilms>) -> Void

    init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }

    func fetchFilms(completionHandler: @escaping FilmsCompletionHandler) {
        let urlString = "https://data.sfgov.org/api/views/yitu-d5am/rows.json"
        guard var URL = URL(string: urlString) else {
            return
        }
        let URLParams = [
            "accessType": "DOWNLOAD"
        ]
        URL = URL.appendingQueryParameters(URLParams)

        var request = URLRequest(url: URL)
        request.httpMethod = HTTPVerbs.GET

        self.session.fetch(request: request) { (result: Either<NetworkControllerError, Data>) in
            switch result {
            case .left(let error):
                let payload = Either<NetworkControllerError, RawFilms>.left(error)
                completionHandler(payload)
            case .right(let data):
                do {
                    if let input = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
                        if let rawFilms = input["data"] as? RawFilms {
                            let payload = Either<NetworkControllerError, RawFilms>.right(rawFilms)
                            completionHandler(payload)
                        } else {
                            let networkError = NetworkControllerError.invalidPayload(URL)
                            let payload = Either<NetworkControllerError, RawFilms>.left(networkError)
                            completionHandler(payload)
                        }
                    }
                } catch {
                    let networkError = NetworkControllerError.forwarded(error)
                    let payload = Either<NetworkControllerError, RawFilms>.left(networkError)
                    completionHandler(payload)
                }
            }
        }
    }
}
