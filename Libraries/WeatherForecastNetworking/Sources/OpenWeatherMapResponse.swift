//
//  OpenWeatherMapResponse.swift
//  WeatherForecastNetworking
//
//  Created by LAP14503 on 09/11/2021.
//

import Foundation

public struct OpenWeatherMapResponse: Decodable {
    public struct City: Decodable {
        public let id: Int
        public let name: String
    }
    
    public struct Temperature: Decodable {
        public let day: Double
        public let min: Double
        public let max: Double
    }
    
    public struct Weather: Decodable {
        public let id: Int
        public let main: String
        public let description: String
        public let icon: String
    }
    
    public struct Forecast: Decodable {
        public let timestamp: TimeInterval
        public let weather: [Weather]
        public let temperature: Temperature
        public let pressure: Int
        public let humidity: Int
    }
    
    public let city: City
    public let forecasts: [Forecast]
    
    enum CodingKeys: String, CodingKey {
        case city
        case forecasts = "list"
    }
}

extension OpenWeatherMapResponse.Forecast {
    enum CodingKeys: String, CodingKey {
        case timestamp = "dt"
        case weather
        case temperature = "temp"
        case pressure
        case humidity
    }
}

struct OpenWeatherMapNotFoundResponse: Decodable {
    let code: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case code = "cod"
        case message
    }
}
