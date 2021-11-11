//
//  WeatherIconStore.swift
//  WeatherForecastCore
//
//  Created by LAP14503 on 10/11/2021.
//

import Alamofire
import AlamofireImage
import Foundation
import WeatherForecastNetworking

public typealias WeatherIcon = AlamofireImage.Image

public typealias WeatherIconRequestError = AFIError

/// A type that provides image resources that describes a weather condition.
public protocol WeatherIconProviding {
    /// Gets an icon if it already exists locally.
    func getWeatherIcon(withIdentifier id: String) -> WeatherIcon?

    /// Fetch an icon remotely, identified by `identifier`.
    func fetchWeatherIcon(
        withIdentifier id: String,
        completionHandler: @escaping (Result<WeatherIcon, Error>) -> Void
    )
}

/// A concrete weather icon provider that supports caching requested icons.
public final class WeatherIconStore: WeatherIconProviding {
    let imageCache: ImageRequestCache
    let client: WeatherForecastClient
    let downloader: ImageDownloader

    public init(imageCache: ImageRequestCache, client: WeatherForecastClient) {
        self.imageCache = imageCache
        self.client = client
        self.downloader = ImageDownloader(imageCache: imageCache)
    }

    public func getWeatherIcon(withIdentifier id: String) -> WeatherIcon? {
        imageCache.image(withIdentifier: id)
    }

    public func fetchWeatherIcon(
        withIdentifier id: String,
        completionHandler: @escaping (Result<WeatherIcon, Error>) -> Void
    ) {
        let request = URLRequest(url: client.weatherIconUrl(forIdentifier: id))
        downloader.download(
            request,
            cacheKey: id,
            completion: { response in
                let result = response.result.mapError { $0 as Error }
                completionHandler(result)
            }
        )
    }
}
