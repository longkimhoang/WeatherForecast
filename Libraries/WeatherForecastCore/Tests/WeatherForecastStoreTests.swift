//
//  WeatherForecastStoreTests.swift
//  WeatherForecastCore-BUCK
//
//  Created by LAP14503 on 11/11/2021.
//

import Foundation
import Swinject
import XCTest

@testable import WeatherForecastCore
@testable import WeatherForecastNetworking

private let container = Container()
private let date = Date()

struct DummyWeatherForecastClient: WeatherForecastClient {
    func getWeatherForecasts(
        for city: String,
        completionHandler: @escaping (Result<OpenWeatherMapResponse, WeatherForecastClientError>) ->
            Void
    ) {
        let response = OpenWeatherMapResponse(
            city: .init(id: 1009, name: city),
            forecasts: [
                .init(
                    timestamp: date.timeIntervalSince1970,
                    weather: [
                        .init(id: 1001, main: "Sunny", description: "sunny", icon: "10d")
                    ],
                    temperature: .init(day: 30, min: 25, max: 35),
                    pressure: 1000,
                    humidity: 66
                )
            ]
        )

        completionHandler(.success(response))
    }

    func weatherIconUrl(forIdentifier id: String) -> URL {
        URL(string: "www.example.com")!
    }
}

final class WeatherForecastStoreTests: XCTestCase {
    override class func setUp() {
        container.register(WeatherForecastClient.self) { _ in
            DummyWeatherForecastClient()
        }
        container.register(WeatherForecastDataProviding.self) { c in
            WeatherForecastStore(client: c.resolve(WeatherForecastClient.self)!)
        }
    }

    func testResponseTransformedCorrectly() {
        guard let store = container.resolve(WeatherForecastDataProviding.self) else {
            XCTFail("Store not found")
            return
        }

        let expectation = expectation(description: "Response transformed correctly")

        store.fetchWeatherForecasts(for: "saigon") { result in
            switch result {
            case .success(let models):
                XCTAssertEqual(models.count, 1)
                let model = models.first!

                XCTAssertEqual(model.city, "saigon")
                XCTAssertEqual(model.averageTemperature, 30, accuracy: 0.1)
                XCTAssertEqual(model.iconName, "10d")
                XCTAssertEqual(
                    model.date.timeIntervalSince1970,
                    date.timeIntervalSince1970,
                    accuracy: 0.1
                )
                XCTAssertEqual(model.weatherDescription, "sunny")

                expectation.fulfill()
            case .failure(let error):
                XCTFail("Encountered error: \(error.localizedDescription)")
            }
        }

        wait(for: [expectation], timeout: 1)
    }
}
