//
//  WeatherForecastViewModel.swift
//  WeatherForecastUI
//
//  Created by LAP14503 on 10/11/2021.
//

import Foundation
import UIKit
import WeatherForecastCore

public protocol WeatherForecastViewDataProviding: AnyObject {
    var forecastDataProvider: WeatherForecastDataProviding { get }

    var weatherIconProvider: WeatherIconProviding { get }

    var delegate: WeatherForecastViewDataProvidingDelegate? { get set }

    func fetchWeatherForecasts(for city: String)

    func getWeatherIcon(forIdentifier id: String) -> UIImage?

    func fetchWeatherIcon(forIdentifier id: String, completionHandler: @escaping (UIImage?) -> Void)
}

public protocol WeatherForecastViewDataProvidingDelegate: AnyObject {
    func weatherForecastDataProviderDidBeginFetching(
        _ provider: WeatherForecastViewDataProviding
    )

    func weatherForecastDataProvider(
        _ provider: WeatherForecastViewDataProviding,
        didUpdateForecastDataWith models: [WeatherForecastModel]
    )

    func weatherForecastDataProvider(
        _ provider: WeatherForecastViewDataProviding,
        didFailFetchingWithError error: Error
    )
}

public final class WeatherForecastViewModel: WeatherForecastViewDataProviding {
    public let forecastDataProvider: WeatherForecastDataProviding
    public let weatherIconProvider: WeatherIconProviding
    weak public var delegate: WeatherForecastViewDataProvidingDelegate?

    private var lastSearchText: String?
    private var currentRequest: (city: String, request: WeatherForecastDataProviding.Request)?

    public init(
        forecastDataProvider: WeatherForecastDataProviding,
        weatherIconProvider: WeatherIconProviding
    ) {
        self.forecastDataProvider = forecastDataProvider
        self.weatherIconProvider = weatherIconProvider
    }

    public func fetchWeatherForecasts(for city: String) {
        guard city.count >= 3 else {
            return
        }
        
        if let currentRequest = currentRequest, currentRequest.city == city {
            // Skip identical requests.
            return
        }
        
        if let lastSearchText = lastSearchText, lastSearchText == city {
            // Skip identical search text.
            return
        }
        
        lastSearchText = city

        delegate?.weatherForecastDataProviderDidBeginFetching(self)

        let request = forecastDataProvider.fetchWeatherForecasts(for: city) {
            [weak self] result in
            guard let self = self else {
                return
            }
            
            // Clean up when done.
            defer { self.currentRequest = nil }

            switch result {
            case .success(let forecasts):
                DispatchQueue.main.async {
                    self.delegate?.weatherForecastDataProvider(
                        self,
                        didUpdateForecastDataWith: forecasts
                    )
                }
            case .failure(WeatherForecastDataProviderError.requestCancelled):
                break
            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.weatherForecastDataProvider(
                        self,
                        didFailFetchingWithError: error
                    )
                }
            }
        }
        
        // Store request so we can ignore identical requests, and cancel
        // the current one when a different request comes.
        currentRequest = (city, request)
    }

    public func getWeatherIcon(forIdentifier id: String) -> UIImage? {
        weatherIconProvider.getWeatherIcon(withIdentifier: id)
    }

    public func fetchWeatherIcon(
        forIdentifier id: String,
        completionHandler: @escaping (UIImage?) -> Void
    ) {
        weatherIconProvider.fetchWeatherIcon(withIdentifier: id) { result in
            completionHandler(try? result.get())
        }
    }
}
