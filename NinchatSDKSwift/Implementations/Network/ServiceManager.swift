//
// Copyright (c) 17.3.2020 Somia Reality Oy. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//

import Foundation

enum ServiceResultError: Error {
    case invalidRequest
    case noData
    case invalidStatusCode(Int)
}

struct ServiceManager {
    private var session: URLSession?
    private var configuration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = true
        configuration.httpShouldSetCookies = true
        configuration.httpShouldUsePipelining = true
        configuration.timeoutIntervalForRequest = 20.0
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        return configuration
    }
    
    mutating func perform<T: ServiceRequest>(_ request: T, completion: @escaping (NINResult<T.ReturnType>) -> Void) {
        guard let request = self.request(request) else {
            completion(.failure(ServiceResultError.invalidRequest)); return
        }
        
        if let session = self.session { session.invalidateAndCancel() }
        session = URLSession(configuration: configuration)
        
        self.session?.dataTask(with: request) { [self] responseData, response, responseError in
            switch self.validate(responseData, response: response, responseError: responseError) {
            case .success:
                completion(self.parse(responseData))
            case .failure(let error):
                completion(.failure(error))
            }
        }.resume()
        session?.finishTasksAndInvalidate()
    }
    
    private func request<T: ServiceRequest>(_ request: T) -> URLRequest? {
        guard let url = URL(string: request.url) else { return nil }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.httpMethod.rawValue
        urlRequest.allHTTPHeaderFields = request.headers
        urlRequest.httpBody = request.body
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.allowsCellularAccess = true
        urlRequest.httpShouldUsePipelining = true
        
        return urlRequest
    }
    
    private func validate(_ responseData: Data?, response: URLResponse?, responseError: Error?) -> NINResult<Void> {
        if let responseError = responseError {
            return .failure(responseError)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(ServiceResultError.noData)
        }
        guard 200 ... 299 ~= httpResponse.statusCode else {
            return .failure(ServiceResultError.invalidStatusCode(httpResponse.statusCode))
        }
        
        return .success(())
    }
    
    private func parse<T: Decodable>(_ data: Data?) -> NINResult<T> {
        guard let data = data else {
            return .failure(ServiceResultError.noData)
        }
        do {
            let result = try JSONDecoder().decode(T.self, from: data)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
}
