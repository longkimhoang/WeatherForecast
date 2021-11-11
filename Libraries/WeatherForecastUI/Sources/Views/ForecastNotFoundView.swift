//
//  ForecastNotFoundView.swift
//  WeatherForecastUI
//
//  Created by LAP14503 on 11/11/2021.
//

import UIKit

class ForecastNotFoundView: UIView {
    @IBOutlet weak var messageLabel: UILabel!
    
    func setMessage(_ message: String?) {
        messageLabel.isHidden = message == nil
        messageLabel.text = message
    }
}
