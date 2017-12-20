//
//  ViewController.swift
//  PSPramatiTask
//
//  Created by Pankaj Sharma on 20/Dec/17.
//  Copyright © 2017 Pankaj Sharma. All rights reserved.
//

import UIKit

class CitiesVC: UIViewController {
  
  @IBOutlet weak var waitingLabel: UILabel!
  @IBOutlet weak var sortButton: UIButton!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet var cityCountLabel: UILabel!
  @IBOutlet weak var tableViewTopSpaceToSafeConstaint: NSLayoutConstraint!
  @IBOutlet weak var searchBar: UISearchBar!
  
  var state: AppState = AppState([]) {
    didSet {
      updateTableViewWithState()
      sortButton.isSelected = !state.isSortAscending
      searchBar.text = state.filterText
      searchBar.showsCancelButton = state.inSearchMode
    }
  }
  
  
  
  ///Solely to be called from `didSet` of `state`
  private func updateTableViewWithState() {
//    tableViewTopSpaceToSafeConstaint.priority = state.cities.isEmpty && !state.inSearchMode ? UILayoutPriority.defaultHigh : UILayoutPriority.defaultLow
    cityCountLabel.text = state.cities.isEmpty ? AppText.noMatchesFound : AppText.ShowingCities(state.cities.count).displayText
    
    UIView.animate(withDuration: 0.3) {
      self.tableView.layoutIfNeeded()
    }
    
    waitingLabel.isHidden = state.inSearchMode || !state.cities.isEmpty
    // State change reload data
    tableView.reloadData()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.tableView.rowHeight = 40
//    self.tableView.tableHeaderView = searchBar
    self.tableView.tableFooterView = cityCountLabel
    
    DataManager.shared.getCities(preferDB: true) { [weak self] (cities, error) in
      if let validCities = cities {
        self?.state = AppState(validCities)
      } else {
        self?.showSimpleAlert(title: AppText.warning, msg: error as? String)
      }
    }
    _ = self.tableView.addScrollToEndButton()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  
  @IBAction func sortPressed(_ sender: Any) {
    state = state.updateSortMode(!state.isSortAscending)
  }
}




// MARK:- TableView Delegate, Datasource
//*******************************************************************//
// Cities - UITableViewDelegate, UITableViewDataSource
//*******************************************************************//
extension CitiesVC: UITableViewDelegate, UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return state.cities.count
  }
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CityTVCell", for: indexPath) as! CityTVCell
    // Configure the cell...
    if searchBar.isFirstResponder {
      cell.update(with: state.cities[indexPath.row], highlightText: state.filterText)
    } else {
      cell.update(with: state.cities[indexPath.row])
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cityEntity = state.cities[indexPath.row]
    if let validURL = cityEntity.locationURL, UIApplication.shared.canOpenURL(validURL) {
      UIApplication.shared.open(validURL, options: [:], completionHandler: nil)
    }
    
  }  
}


//*******************************************************************//
// MARK:- Search Bar delegate
//*******************************************************************//
extension CitiesVC: UISearchBarDelegate {
  func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    //Don't enable if no data
    return !state.cities.isEmpty
  }
  
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchBar.showsCancelButton = true
    if let validIndexPaths = tableView.indexPathsForVisibleRows {
      tableView.reloadRows(at: validIndexPaths, with: UITableViewRowAnimation.automatic)
    }

  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    //filter the content
    state.filterText = searchText
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    state.filterText = ""
    searchBar.showsCancelButton = false
    searchBar.resignFirstResponder()
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
    if let validIndexPaths = tableView.indexPathsForVisibleRows {
      tableView.reloadRows(at: validIndexPaths, with: UITableViewRowAnimation.automatic)
    }
  }
}
