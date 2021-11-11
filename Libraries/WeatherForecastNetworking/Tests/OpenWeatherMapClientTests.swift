//
//  OpenWeatherMapClientTests.swift
//  WeatherForecastNetworking
//
//  Created by LAP14503 on 09/11/2021.
//

import Swinject
import XCTest

@testable import WeatherForecastNetworking

let dummyJson =
    """
    {"city":{"id":1580578,"name":"Ho Chi Minh City","coord":{"lon":106.6667,"lat":10.8333},"country":"VN","population":0,"timezone":25200},"cod":"200","message":0.0651787,"cnt":7,"list":[{"dt":1636516800,"sunrise":1636498035,"sunset":1636540039,"temp":{"day":29.13,"min":23.57,"max":31.2,"night":24.55,"eve":27.87,"morn":23.57},"feels_like":{"day":33.41,"night":25.44,"eve":31.78,"morn":24.36},"pressure":1010,"humidity":72,"weather":[{"id":501,"main":"Rain","description":"moderate rain","icon":"10d"}],"speed":2.43,"deg":10,"gust":4.53,"clouds":52,"pop":0.97,"rain":4.9},{"dt":1636603200,"sunrise":1636584456,"sunset":1636626432,"temp":{"day":27.03,"min":23.81,"max":29.13,"night":24.34,"eve":26.69,"morn":23.9},"feels_like":{"day":29.71,"night":25.28,"eve":29.46,"morn":24.75},"pressure":1010,"humidity":79,"weather":[{"id":501,"main":"Rain","description":"moderate rain","icon":"10d"}],"speed":2.17,"deg":10,"gust":6.29,"clouds":100,"pop":1,"rain":8.99},{"dt":1636689600,"sunrise":1636670877,"sunset":1636712826,"temp":{"day":25.94,"min":23.54,"max":29.01,"night":24.35,"eve":28.6,"morn":23.54},"feels_like":{"day":26.84,"night":25.11,"eve":32.91,"morn":24.48},"pressure":1011,"humidity":86,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"speed":2.6,"deg":60,"gust":4.91,"clouds":100,"pop":1,"rain":4.36},{"dt":1636776000,"sunrise":1636757299,"sunset":1636799222,"temp":{"day":24.35,"min":23.64,"max":24.35,"night":23.67,"eve":24.33,"morn":23.64},"feels_like":{"day":25.27,"night":24.57,"eve":25.3,"morn":24.44},"pressure":1011,"humidity":93,"weather":[{"id":502,"main":"Rain","description":"heavy intensity rain","icon":"10d"}],"speed":2.44,"deg":118,"gust":7.88,"clouds":100,"pop":0.97,"rain":22.91},{"dt":1636862400,"sunrise":1636843722,"sunset":1636885618,"temp":{"day":27.25,"min":22.92,"max":29.01,"night":24.04,"eve":28.13,"morn":22.92},"feels_like":{"day":30.09,"night":24.9,"eve":32.43,"morn":23.77},"pressure":1011,"humidity":78,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"speed":3.21,"deg":102,"gust":5.77,"clouds":97,"pop":0.88,"rain":3.55},{"dt":1636948800,"sunrise":1636930145,"sunset":1636972016,"temp":{"day":27.57,"min":23.16,"max":27.57,"night":23.87,"eve":24.31,"morn":23.16},"feels_like":{"day":30.8,"night":24.82,"eve":25.3,"morn":24.04},"pressure":1010,"humidity":78,"weather":[{"id":501,"main":"Rain","description":"moderate rain","icon":"10d"}],"speed":1.83,"deg":181,"gust":2.54,"clouds":86,"pop":1,"rain":7.73},{"dt":1637035200,"sunrise":1637016569,"sunset":1637058414,"temp":{"day":27.97,"min":23.21,"max":28.67,"night":24.35,"eve":25.69,"morn":23.21},"feels_like":{"day":31.72,"night":25.3,"eve":26.66,"morn":24.15},"pressure":1008,"humidity":78,"weather":[{"id":501,"main":"Rain","description":"moderate rain","icon":"10d"}],"speed":1.99,"deg":334,"gust":3.71,"clouds":94,"pop":0.96,"rain":14.79}]}
    """

let errorJson =
    """
    {"cod": "404", "message": "city not found"}
    """

struct DummyHttpClient: HttpClient {
    let decoder = JSONDecoder()

    func get<U, P, T>(
        _ url: U,
        parameters: P,
        of type: T.Type,
        completionHandler: @escaping (HttpClientResponse<T>) -> Void
    ) where U: URLConvertible, P: Encodable, T: Decodable {
        // We will provide specializations for ease of testing
        guard type is OpenWeatherMapResponse.Type else {
            return
        }

        guard let jsonData = dummyJson.data(using: .utf8),
            let responseData = try? decoder.decode(OpenWeatherMapResponse.self, from: jsonData)
        else {
            return
        }

        var cityNotFound = false

        if let parameters = parameters as? OpenWeatherMapRequestParameters {
            let city = parameters.city
            if city == "$test_notFound" {
                cityNotFound = true
            }
        }

        let response = HttpClientResponse(
            request: nil,
            response: nil,
            data: cityNotFound ? errorJson.data(using: .utf8) : nil,
            metrics: nil,
            serializationDuration: 0,
            result: cityNotFound
                ? .failure(.responseValidationFailed(reason: .unacceptableStatusCode(code: 404)))
                : .success(responseData)
        )

        completionHandler(response as! HttpClientResponse<T>)
    }
}

private let container = Container()

final class OpenWeatherMapClientTests: XCTestCase {
    override class func setUp() {
        container.register(HttpClient.self) { _ in
            DummyHttpClient()
        }

        container.register(WeatherForecastClient.self) { c in
            OpenWeatherMapClient(httpClient: c.resolve(HttpClient.self)!)
        }
    }

    func testResponseDecodedCorrectly() {
        let expectation = expectation(description: "Response decoded to OpenWeatherMapResponse")

        guard let client = container.resolve(WeatherForecastClient.self) else {
            XCTFail("Cannot resolve client")
            return
        }

        client.getWeatherForecasts(for: "Ho Chi Minh City") { result in
            XCTAssertNotNil(try? result.get())

            if case .success(let response) = result, let firstForecast = response.forecasts.first {
                XCTAssertEqual(firstForecast.timestamp, 1_636_516_800)
                XCTAssertEqual(firstForecast.weather.first?.id, 501)
                XCTAssertEqual(firstForecast.temperature.day, 29.13)

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testThrowNotFoundErrorCorrectly() {
        let expectation = expectation(description: "Response should throw notFound")

        guard let client = container.resolve(WeatherForecastClient.self) else {
            XCTFail("Cannot resolve client")
            return
        }

        client.getWeatherForecasts(for: "$test_notFound") { result in
            switch result {
            case .failure(WeatherForecastClientError.notFound(let message)):
                XCTAssertEqual(message, "city not found")
                expectation.fulfill()
            default:
                break
            }
        }

        wait(for: [expectation], timeout: 1)
    }
}
