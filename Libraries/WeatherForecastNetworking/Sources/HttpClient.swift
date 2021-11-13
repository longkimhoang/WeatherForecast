//
//  HttpClient.swift
//  WeatherForecastNetworking
//
//  Created by LAP14503 on 09/11/2021.
//

import Alamofire
import Foundation

/// A type representing a HTTP client error.
public typealias HttpClientError = AFError

/// A type representing a HTTP client request.
public protocol HttpClientRequest: AnyObject {
    func cancel()
}

/// A type representing a HTTP client response.
public typealias HttpClientResponse<T: Decodable> = DataResponse<T, HttpClientError>

/// A type that can be converted to an ``URL``.
public typealias URLConvertible = Alamofire.URLConvertible

/// A type that performs HTTP requests to a remote endpoint and
/// performs response deserialization.
public protocol HttpClient {
    /// Performs a `GET` request.
    @discardableResult func get<U, P, T>(
        _ url: U,
        parameters: P,
        of type: T.Type,
        completionHandler: @escaping (HttpClientResponse<T>) -> Void
    ) -> HttpClientRequest
    where U: URLConvertible, P: Encodable, T: Decodable
}

/// An ``HttpClient`` that uses `Alamofire` to perform requests.
public struct AlamoFireHTTPClient: HttpClient {
    /// A `DispatchQueue` to deliver results to.
    ///
    /// Default is the main queue.
    public var resultQueue = DispatchQueue(label: "com.longkh.WeatherForecast.network-queue")

    public init(resultQueue: DispatchQueue? = nil) {
        if let resultQueue = resultQueue {
            self.resultQueue = resultQueue
        }
    }

    public func get<U, P, T>(
        _ url: U,
        parameters: P,
        of type: T.Type,
        completionHandler: @escaping (HttpClientResponse<T>) -> Void
    ) -> HttpClientRequest
    where U: URLConvertible, P: Encodable, T: Decodable {
        AF.request(url, parameters: parameters)
            .validate(statusCode: 200..<300)
            .responseDecodable(
                of: type,
                queue: resultQueue
            ) {
                response in
                completionHandler(response)
            }
    }
}

extension DataRequest: HttpClientRequest {
    public func cancel() {
        (self as Request).cancel()
    }
}
