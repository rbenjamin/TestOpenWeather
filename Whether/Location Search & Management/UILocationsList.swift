//
//  UILocationsList.swift
//  Whether
//
//  Created by Ben Davis on 11/6/24.
//

import Foundation
import UIKit
import SwiftUI

import SwiftData
import Combine
import CoreLocation
import Contacts

struct UILocationsListRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = UILocationsList
    @ObservedObject var weatherManager: WeatherManager
    @Binding var selectedPlacemark: CLPlacemark?
    @Binding var searchTerm: String
    @Binding var dismiss: Bool

    init(manager: WeatherManager,
         searchTerm: Binding<String>,
         selectedPlacemark: Binding<CLPlacemark?>,
         dismiss: Binding<Bool>) {
        self.weatherManager = manager
        _searchTerm = searchTerm
        _selectedPlacemark = selectedPlacemark
        _dismiss = dismiss
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UILocationsList {
        let list = UILocationsList(postalFormatter: self.weatherManager.postalFormatter)
        list.delegate = context.coordinator
        return list
    }

    func updateUIViewController(_ controller: UILocationsList, context: Context) {
        controller.searchTerm = searchTerm
    }

    class Coordinator: NSObject, UILocationsListDelegate {
        var parent: UILocationsListRepresentable
        var placemarks: [CLPlacemark]?

        init(_ parent: UILocationsListRepresentable) {
            self.parent = parent
        }

        func locationsListDidSelectPlacemark(locationsList: UILocationsList, placemark: CLPlacemark?) {
            self.parent.selectedPlacemark = placemark
            self.parent.dismiss.toggle()
        }

        func locationsListDismissButtonTapped(locationsList: UILocationsList) {
            self.parent.dismiss.toggle()
        }

        func locationsListDidSubmitSearch(locationsList: UILocationsList, searchTerm: String) async -> [CLPlacemark] {
            Task { @MainActor in
                self.parent.searchTerm = searchTerm
            }
            return await self.geocodeLocation(fromString: searchTerm)

        }

        func geocodeLocation(fromString: String) async -> [CLPlacemark] {
            do {
                let placemarks = try await self.parent.weatherManager.reverseGeocode(addressString: fromString)
                return placemarks
            } catch let error {
                Task { @MainActor in
                    self.parent.weatherManager.error = error as? LocalizedError
                }
                print("error reverse geocoding: \(error)")
            }
            return []
        }
    }
}

protocol UILocationsListDelegate: AnyObject {
    /// Updates the SwiftUI side with the selected placemark
    func locationsListDidSelectPlacemark(locationsList: UILocationsList, placemark: CLPlacemark?)

    func locationsListDidSubmitSearch(locationsList: UILocationsList, searchTerm: String) async -> [CLPlacemark]
    func locationsListDismissButtonTapped(locationsList: UILocationsList)
}

class UILocationsList: UIViewController, UICollectionViewDelegate {
    enum Section {
        case main
    }
    var dataSource: UICollectionViewDiffableDataSource<Section, CLPlacemark>! = nil
    var collectionView: UICollectionView! = nil
    var container: ModelContainer?
    var locations = [Section: [CLPlacemark]]()
    weak var delegate: UILocationsListDelegate?
    var searchTerm: String = ""
    var searchBar: UISearchBar! = nil
    var postalFormatter: CNPostalAddressFormatter?

    init(postalFormatter: CNPostalAddressFormatter?) {
        self.postalFormatter = postalFormatter
        super.init(nibName: nil, bundle: nil)
    }

    public func updateListWithPlacemarks(_ placemarks: [CLPlacemark], animated: Bool) {

        self.locations[.main] = placemarks

        for (section, items) in self.locations {
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<CLPlacemark>()
            sectionSnapshot.append(items)
            dataSource.apply(sectionSnapshot, to: section, animatingDifferences: animated)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureDataSource()
    }

    private func configureHierarchy() {
        self.view.backgroundColor = UIColor.clear
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        searchBar = UISearchBar()

        configureSearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
//        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.contentInset, right: 0)
        /// Setup collection view constraints
        NSLayoutConstraint.activate([
            // [search bar]
            // [collection view]
            // [keyboard]
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.topAnchor.constraint(equalTo: view.topAnchor),

            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            collectionView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
        collectionView.selfSizingInvalidation = .enabledIncludingConstraints

        collectionView.delegate = self

        collectionView.backgroundColor = UIColor.clear
        let dismissButton = UIButton(type: .custom)
        dismissButton.addTarget(self, action: #selector(backgroundButtonDidDismiss(id:)), for: .touchUpInside)
//        dismissButton.alpha = 0.0
        dismissButton.backgroundColor = UIColor.clear

        collectionView.backgroundView = dismissButton
    }

    @objc
    func backgroundButtonDidDismiss(id: UIButton) {
        self.delegate?.locationsListDismissButtonTapped(locationsList: self)
    }

    private func configureSearchBar() {
        searchBar.delegate = self
        searchBar.prompt = "New Location"
        searchBar.showsSearchResultsButton = true
        searchBar.setImage(UIImage(systemName: "location.magnifyingglass"), for: .search, state: .normal)
        searchBar.backgroundColor = .clear
        searchBar.showsSearchResultsButton = false
        searchBar.showsScopeBar = false
        searchBar.showsCancelButton = false
    }

    private func createLayout() -> UICollectionViewLayout {
        let config = UICollectionLayoutListConfiguration(appearance: .plain)
        return UICollectionViewCompositionalLayout.list(using: config)
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, CLPlacemark> { (cell, _, location) in
            cell.contentConfiguration = UIHostingConfiguration(content: {
                if let locality = location.locality,
                    let adminArea = location.administrativeArea {
                    HStack {
                        Text(locality)
                        Text(adminArea).foregroundStyle(Color.secondary)
                    }
                } else if let name = location.name {
                    Text(name)
                }
            })
            cell.backgroundColor = UIColor.clear
        }

        dataSource = UICollectionViewDiffableDataSource<Section, CLPlacemark>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: CLPlacemark) -> UICollectionViewListCell? in

            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
}
// UICollectionViewDelegate
//
// MARK: - UICollectionViewDelegate -

extension UILocationsList {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let placemark = locations[.main]?[indexPath.item] else { return }
        self.delegate?.locationsListDidSelectPlacemark(locationsList: self, placemark: placemark)
        collectionView.deselectItem(at: indexPath, animated: true)
    }

}

extension UILocationsList: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        Task { [weak self] in
            guard let `self` = self else { return }
            guard let placemarks = await self.delegate?.locationsListDidSubmitSearch(locationsList: self,
                                                            searchTerm: text) else {
                return
            }
            Task { @MainActor in
                self.updateListWithPlacemarks(placemarks, animated: true)
            }

        }
    }
}
