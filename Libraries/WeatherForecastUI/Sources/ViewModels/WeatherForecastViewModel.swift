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

    public init(
        forecastDataProvider: WeatherForecastDataProviding,
        weatherIconProvider: WeatherIconProviding
    ) {
        self.forecastDataProvider = forecastDataProvider
        self.weatherIconProvider = weatherIconProvider
    }

    public func fetchWeatherForecasts(for city: String) {
        delegate?.weatherForecastDataProviderDidBeginFetching(self)

        forecastDataProvider.fetchWeatherForecasts(for: city) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let forecasts):
                DispatchQueue.main.async {
                    self.delegate?.weatherForecastDataProvider(
                        self,
                        didUpdateForecastDataWith: forecasts
                    )
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.weatherForecastDataProvider(
                        self,
                        didFailFetchingWithError: error
                    )
                }
            }
        }
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
