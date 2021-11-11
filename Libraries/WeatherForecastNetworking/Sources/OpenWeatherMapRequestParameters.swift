//
//  OpenWeatherMapRequestParameters.swift
//  WeatherForecastNetworking
//
//  Created by LAP14503 on 09/11/2021.
//

import Foundation

public struct OpenWeatherMapRequestParameters: Encodable {
    public enum TemperatureUnit: String, Encodable {
        case `default` = "kelvin"
        case metric = "metric"
        case imperial = "fahrenheit"
    }

    // Do not change
    static let apiKey = "60c6fbeb4b93ac653c492ba806fc346d"

    public let city: String
    public let days: Int
    public let unit: TemperatureUnit

    let appId: String

    public init(city: String, days: Int = 7, unit: TemperatureUnit = .metric) {
        self.city = city
        self.days = days
        self.unit = unit
        self.appId = Self.apiKey
    }

    public enum CodingKeys: String, CodingKey {
        case city = "q"
        case days = "cnt"
        case unit = "units"
        case appId = "appid"
    }
}
