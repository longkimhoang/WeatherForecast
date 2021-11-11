//
//  ForecastTableViewCell.swift
//  WeatherForecastUI
//
//  Created by LAP14503 on 10/11/2021.
//

import UIKit
import WeatherForecastCore

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, dd MMM YYYY"

    return formatter
}()

private let temperatureFormatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.numberFormatter.maximumFractionDigits = 1
    
    return formatter
}()

public class ForecastTableViewCell: UITableViewCell {
    static let cellIdentifier = "com.longkh.WeatherForecast.forecast-cell"

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    @IBOutlet weak var iconImageView: UIImageView!

    func update(
        with model: WeatherForecastModel,
        using dataProvider: WeatherForecastViewDataProviding,
        completionHandler: @escaping () -> Void
    ) {
        dateLabel.text = "Date: \(dateFormatter.string(from: model.date))"
        temperatureLabel.text =
            "Average Temperature: \(formatTemperature(value: model.averageTemperature))"
        pressureLabel.text = "Pressure: \(model.pressure)"
        humidityLabel.text = "Humidity: \(model.humidity)%"
        descriptionLabel.text = "Description: \(model.weatherDescription)"
        if let iconImage = dataProvider.getWeatherIcon(forIdentifier: model.iconName) {
            // Set image if already in cache
            iconImageView.image = iconImage
        }
        else {
            // Otherwise, load over the network and cache
            dataProvider.fetchWeatherIcon(forIdentifier: model.iconName) { image in
                guard image != nil else {
                    // TODO: Maybe show an error state image?
                    return
                }

                // Just request reload cell, image will be in cache by now
                // meaning this code path will not be reached.
                completionHandler()
            }
        }
    }

    private func formatTemperature(value: Double) -> String {
        let temperature = Measurement(value: value, unit: UnitTemperature.celsius)
        return temperatureFormatter.string(from: temperature)
    }
}
