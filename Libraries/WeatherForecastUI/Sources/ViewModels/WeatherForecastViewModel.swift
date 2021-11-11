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
    var delegate: WeatherForecastViewDataProvidingDelegate? { get set }

    var forecasts: [WeatherForecastModel] { get }

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
        didUpdateForecastDataFrom oldModels: [WeatherForecastModel],
        to models: [WeatherForecastModel]
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

    private(set) public var forecasts = [WeatherForecastModel]()

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
                    let oldForecasts = self.forecasts
                    self.forecasts = forecasts
                    self.delegate?.weatherForecastDataProvider(
                        self,
                        didUpdateForecastDataFrom: oldForecasts,
                        to: forecasts
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
