//
//  OpenWeatherMapClient.swift
//  WeatherForecastNetworking
//
//  Created by LAP14503 on 09/11/2021.
//

import Foundation

private let defaultBaseUrl = "https://api.openweathermap.org/data/2.5/forecast/daily"

/// A type that represents error of a weather forecast client.
public enum WeatherForecastClientError: Error {
    /// The forecast data matching the request was not found.
    case notFound(message: String?)

    /// A request was cancelled by the client.
    case requestCancelled(identifier: AnyHashable)

    /// Internal HTTP client error.
    case httpClientError(underlyingError: HttpClientError)
}

/// A request for weather forecast data.
public protocol WeatherForecastRequest {
    /// The stable identifier of the request.
    var identifier: AnyHashable { get }

    /// Cancels the request.
    func cancel()
}

/// A type that perform requests to obtain weather forecasts.
public protocol WeatherForecastClient {
    @discardableResult func getWeatherForecasts(
        for city: String,
        completionHandler: @escaping (Result<OpenWeatherMapResponse, WeatherForecastClientError>) ->
            Void
    ) -> WeatherForecastRequest

    func weatherIconUrl(forIdentifier id: String) -> URL
}

/// An HTTP client that interfaces with OpenWeatherMap API.
public struct OpenWeatherMapClient: WeatherForecastClient {
    let httpClient: HttpClient
    let baseUrl: String
    let decoder = JSONDecoder()

    public init(baseUrl: String? = nil, httpClient: HttpClient) {
        self.baseUrl = baseUrl ?? defaultBaseUrl
        self.httpClient = httpClient
    }

    @discardableResult public func getWeatherForecasts(
        for city: String,
        completionHandler: @escaping (Result<OpenWeatherMapResponse, WeatherForecastClientError>) ->
            Void
    ) -> WeatherForecastRequest {
        let parameters = OpenWeatherMapRequestParameters(city: city)

        let request = httpClient.get(
            baseUrl,
            parameters: parameters,
            of: OpenWeatherMapResponse.self
        ) {
            response in

            let result = response.result.mapError { error -> WeatherForecastClientError in
                switch error {
                case HttpClientError.responseValidationFailed(
                    reason: .unacceptableStatusCode(code: let code)
                ) where code == 404:
                    // Is this an OpenWeatherMap 404 response?
                    if let data = response.data,
                        let notFoundResponse = try? decoder.decode(
                            OpenWeatherMapNotFoundResponse.self,
                            from: data
                        )
                    {
                        return WeatherForecastClientError.notFound(
                            message: notFoundResponse.message
                        )
                    }

                    return WeatherForecastClientError.notFound(message: nil)
                case HttpClientError.explicitlyCancelled:
                    return WeatherForecastClientError.requestCancelled(
                        identifier: AnyHashable(parameters)
                    )
                default:
                    return WeatherForecastClientError.httpClientError(underlyingError: error)
                }
            }

            completionHandler(result)
        }

        return Request(identifier: parameters, request: request)
    }

    public func weatherIconUrl(forIdentifier id: String) -> URL {
        let baseUrl = URL(string: "https://openweathermap.org/img/wn")!
        let iconPath = "\(id)@2x.png"

        return baseUrl.appendingPathComponent(iconPath)
    }
}

extension OpenWeatherMapClient {
    /// A RAII wrapper for the ``HttpClientRequest`` the underlying HTTP client makes.
    final class Request: WeatherForecastRequest {
        let identifier: AnyHashable
        weak var request: HttpClientRequest?

        init<ID: Hashable>(identifier: ID, request: HttpClientRequest) {
            self.identifier = AnyHashable(identifier)
            self.request = request
        }

        func cancel() {
            request?.cancel()
        }

        deinit {
            cancel()
        }
    }
}
