import AlamofireImage
import SwinjectStoryboard
import UIKit
import WeatherForecastCore
import WeatherForecastNetworking
import WeatherForecastUI

@UIApplicationMain
final class AppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return true
    }

}

// MARK: - Inject ViewController dependencies

extension SwinjectStoryboard {
    @objc class func setup() {
        defaultContainer.storyboardInitCompleted(RootViewController.self) { r, c in
            c.viewModel = r.resolve(WeatherForecastViewDataProviding.self)
        }

        defaultContainer.register(HttpClient.self) { _ in
            AlamoFireHTTPClient()
        }
        .inObjectScope(.container)

        defaultContainer.register(WeatherForecastClient.self) { c in
            OpenWeatherMapClient(httpClient: c.resolve(HttpClient.self)!)
        }

        defaultContainer.register(WeatherForecastDataProviding.self) { c in
            WeatherForecastStore(client: c.resolve(WeatherForecastClient.self)!)
        }

        defaultContainer.register(WeatherIconProviding.self) { c in
            WeatherIconStore(
                imageCache: AutoPurgingImageCache(),
                client: c.resolve(WeatherForecastClient.self)!
            )
        }

        defaultContainer.register(WeatherForecastViewDataProviding.self) { c in
            WeatherForecastViewModel(
                forecastDataProvider: c.resolve(WeatherForecastDataProviding.self)!,
                weatherIconProvider: c.resolve(WeatherIconProviding.self)!
            )
        }
    }
}
