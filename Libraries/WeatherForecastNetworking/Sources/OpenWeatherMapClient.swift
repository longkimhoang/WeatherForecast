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

    /// Internal HTTP client error.
    case httpClientError(underlyingError: HttpClientError)
}

/// A type that perform requests to obtain weather forecasts.
public protocol WeatherForecastClient {
    func getWeatherForecasts(
        for city: String,
        completionHandler: @escaping (Result<OpenWeatherMapResponse, WeatherForecastClientError>) ->
            Void
    )

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

    public func getWeatherForecasts(
        for city: String,
        completionHandler: @escaping (Result<OpenWeatherMapResponse, WeatherForecastClientError>) ->
            Void
    ) {
        let parameters = OpenWeatherMapRequestParameters(city: city)

        httpClient.get(baseUrl, parameters: parameters, of: OpenWeatherMapResponse.self) {
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
                default:
                    return WeatherForecastClientError.httpClientError(underlyingError: error)
                }
            }

            completionHandler(result)
        }
    }

    public func weatherIconUrl(forIdentifier id: String) -> URL {
        let baseUrl = URL(string: "https://openweathermap.org/img/wn")!
        let iconPath = "\(id)@2x.png"

        return baseUrl.appendingPathComponent(iconPath)
    }
}
