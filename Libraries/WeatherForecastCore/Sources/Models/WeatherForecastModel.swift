//
//  WeatherForecastModel.swift
//  WeatherForecastCore
//
//  Created by LAP14503 on 10/11/2021.
//

import Foundation

/// An object describing a weather forecast.
public struct WeatherForecastModel: Hashable {
    public init(
        city: String,
        date: Date,
        averageTemperature: Double,
        pressure: Int,
        humidity: Int,
        weatherDescription: String,
        iconName: String
    ) {
        self.city = city
        self.date = date
        self.averageTemperature = averageTemperature
        self.pressure = pressure
        self.humidity = humidity
        self.weatherDescription = weatherDescription
        self.iconName = iconName
    }

    public let city: String
    public let date: Date
    public let averageTemperature: Double
    public let pressure: Int
    public let humidity: Int
    public let weatherDescription: String
    public let iconName: String
}

extension WeatherForecastModel: Identifiable {
    public var id: String {
        "\(city)-\(date.timeIntervalSince1970)"
    }
}
