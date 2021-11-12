//
//  WeatherForecastStore.swift
//  WeatherForecastCore
//
//  Created by LAP14503 on 10/11/2021.
//

import Foundation
import WeatherForecastNetworking

public typealias NetworkError = WeatherForecastNetworking.HttpClientError

/// A type that provides weather forecast data.
public protocol WeatherForecastDataProviding {
    var forecasts: [WeatherForecastModel] { get }
    
    func fetchWeatherForecasts(
        for city: String,
        completionHandler: @escaping (Result<[WeatherForecastModel], Error>) -> Void
    )
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
        completionHandler: @escaping (Result<[WeatherForecastModel], Error>) -> Void
    ) {
        client.getWeatherForecasts(for: city) { [weak self] response in
            let result =
                response
                .map { Array(apiResponse: $0) }
                .mapError { $0 as Error }

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
        self.init(forecasts.compactMap { forecast in
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
        })
    }
}
