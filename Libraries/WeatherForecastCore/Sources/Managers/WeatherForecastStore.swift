//
//  WeatherForecastStore.swift
//  WeatherForecastCore
//
//  Created by LAP14503 on 10/11/2021.
//

import Foundation
import WeatherForecastNetworking

public enum WeatherForecastDataProviderError: Error {
    case cityNotFound(_ city: String, message: String?)
    case requestCancelled
    case clientError(underlyingError: WeatherForecastClientError)
}

/// A type that provides weather forecast data.
public protocol WeatherForecastDataProviding {
    typealias Request = WeatherForecastRequest

    var forecasts: [WeatherForecastModel] { get }

    func fetchWeatherForecasts(
        for city: String,
        completionHandler: @escaping (
            Result<[WeatherForecastModel], WeatherForecastDataProviderError>
        ) -> Void
    ) -> WeatherForecastRequest
}

/// A concrete weather forecast data provider.
public final class WeatherForecastStore: WeatherForecastDataProviding {
    public let client: WeatherForecastClient
    public private(set) var forecasts: [WeatherForecastModel] = []

    public init(client: WeatherForecastClient) {
        self.client = client
    }

    public func fetchWeatherForecasts(
        for city: String,
        completionHandler: @escaping (
            Result<[WeatherForecastModel], WeatherForecastDataProviderError>
        ) -> Void
    ) -> Request {
        client.getWeatherForecasts(for: city) { [weak self] response in
            let result: Result<[WeatherForecastModel], WeatherForecastDataProviderError> =
                response.map { Array(apiResponse: $0) }.mapError { error in
                    switch error {
                    case WeatherForecastClientError.notFound(let message):
                        return WeatherForecastDataProviderError.cityNotFound(city, message: message)
                    case WeatherForecastClientError.requestCancelled:
                        return WeatherForecastDataProviderError.requestCancelled
                    default:
                        return WeatherForecastDataProviderError.clientError(underlyingError: error)
                    }
                }

            if case .success(let forecasts) = result {
                self?.forecasts = forecasts
            }

            completionHandler(result)
        }
    }
}

// MARK: - Model Conversion

extension Array where Element == WeatherForecastModel {
    init(apiResponse: OpenWeatherMapResponse) {
        let forecasts = apiResponse.forecasts
        self.init(
            forecasts.compactMap { forecast in
                let date = Date(timeIntervalSince1970: forecast.timestamp)
                let averageTemperature = forecast.temperature.day
                guard let weather = forecast.weather.first else {
                    return nil
                }

                return WeatherForecastModel(
                    city: apiResponse.city.name,
                    date: date,
                    averageTemperature: averageTemperature,
                    pressure: forecast.pressure,
                    humidity: forecast.humidity,
                    weatherDescription: weather.description,
                    iconName: weather.icon
                )
            }
        )
    }
}
