//
//  ForecastNotFoundView.swift
//  WeatherForecastUI
//
//  Created by LAP14503 on 11/11/2021.
//

import UIKit

class ForecastNotFoundView: UIView {
    @IBOutlet weak var calloutLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    func setMessage(_ message: String?) {
        calloutLabel.text = String.localizedStringWithFormat("City Not Found")
        messageLabel.isHidden = message == nil
        messageLabel.text = message
    }
    
    func setError<E: Error>(_ error: E) {
        calloutLabel.text = String.localizedStringWithFormat("An error occurred")
        messageLabel.isHidden = false
        messageLabel.text = error.localizedDescription
    }
}
