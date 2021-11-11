//
//  RootViewController.swift
//  WeatherForecastUI
//
//  Created by LAP14503 on 09/11/2021.
//

import DiffableDataSources
import Foundation
import UIKit
import WeatherForecastCore
import WeatherForecastNetworking

public final class RootViewController: UIViewController {
    enum Section { case main }

    @IBOutlet weak var forecastsTableView: UITableView!

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        controller.searchResultsUpdater = self

        controller.searchBar.delegate = self

        return controller
    }()

    public var viewModel: WeatherForecastViewDataProviding!
    var dataSource: TableViewDiffableDataSource<Section, WeatherForecastModel>!

    var forecastNotFoundNib = UINib(nibName: "ForecastNotFoundView", bundle: nil)
    
    private var sema = DispatchSemaphore(value: 0)

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Setup search controller
        navigationItem.searchController = searchController

        // Setup table view
        forecastsTableView.register(
            UINib(nibName: "ForecastTableViewCell", bundle: nil),
            forCellReuseIdentifier: ForecastTableViewCell.cellIdentifier
        )

        // Setup view model
        viewModel.delegate = self

        // Setup data source
        dataSource = .init(
            tableView: forecastsTableView,
            cellProvider: tableView(_:cellForItemAtIndexPath:withItem:)
        )

        // Initial data
        var snapshot = dataSource.snapshot()
        snapshot.appendSections([.main])

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Responding to data changes

extension RootViewController: WeatherForecastViewDataProvidingDelegate {
    func tableView(
        _ tableView: UITableView,
        cellForItemAtIndexPath indexPath: IndexPath,
        withItem model: WeatherForecastModel
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ForecastTableViewCell.cellIdentifier,
            for: indexPath
        )

        if let forecastCell = cell as? ForecastTableViewCell {
            forecastCell.update(with: model, using: viewModel) { [weak self] model in
                self?.itemsDidUpdate(CollectionOfOne(model))
            }
        }

        return cell
    }

    private func itemsDidUpdate<C: Collection>(_ items: C)
    where C.Element == WeatherForecastModel {
        var snapshot = dataSource.snapshot()
        snapshot.reloadItems(Array(items))

        dataSource.apply(snapshot)
    }

    public func weatherForecastDataProvider(
        _ provider: WeatherForecastViewDataProviding,
        didUpdateForecastDataFrom oldModels: [WeatherForecastModel],
        to models: [WeatherForecastModel]
    ) {
        forecastsTableView.backgroundView = nil
        
        var snapshot = dataSource.snapshot()
        snapshot.deleteItems(oldModels)
        snapshot.appendItems(models, toSection: .main)

        dataSource.apply(snapshot)
    }

    public func weatherForecastDataProvider(
        _ provider: WeatherForecastViewDataProviding,
        didFailFetchingWithError error: Error
    ) {
        switch error {
        case WeatherForecastClientError.notFound(let message):
            showNotFoundErrorScreen(message: message)
        default:
            break
        }
    }

    private func showNotFoundErrorScreen(message: String?) {
        // Remove current items
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        dataSource.apply(snapshot) { [weak self] in
            // Instantiate not found screen
            if let notFoundView =
                self?.forecastNotFoundNib.instantiate(
                    withOwner: nil,
                    options: nil
                ).first
                as? ForecastNotFoundView
            {
                notFoundView.setMessage(message)
                self?.forecastsTableView.backgroundView = notFoundView
            }
        }
    }
}

// MARK: - Searching

extension RootViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        // We only search on return key pressed, so this method is
        // intentionally empty
    }
}

extension RootViewController: UISearchBarDelegate {
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let city = searchBar.text {
            viewModel.fetchWeatherForecasts(for: city)
        }
    }
}
