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
  var searchBar: UISearchBar {
    return searchController.searchBar
  }
  
  var state: AppState = AppState([]) {
    didSet {
      updateTableViewWithState()
      sortButton.isSelected = !state.isSortAscending
      if state.filterText != searchBar.text {
        searchBar.text = state.filterText
        //this will updateSearchResults which will in turn set `state` 
      }
    }
  }
  
  
  ///Solely to be called from `didSet` of `state`
  private func updateTableViewWithState() {
    cityCountLabel.text = state.cities.isEmpty ? AppText.noMatchesFound : AppText.ShowingCities(state.cities.count).displayText
    waitingLabel.isHidden = state.inSearchMode || !state.cities.isEmpty
    // State change reload data
    tableView.reloadData()
  }
  
  
  let searchController = UISearchController(searchResultsController: nil)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Setup the Search Controller
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.searchBarStyle = .minimal
    searchController.searchBar.placeholder = "Search cities"
    definesPresentationContext = true
    searchController.searchBar.delegate = self
    if #available(iOS 11.0, *) {
      //Show the search bar in Navigation Item
      navigationItem.searchController = searchController
    } else {
      //Show the search bar in tableview header
      //Had to mark automaticallyAdjustsScrollViewInsets false
      self.tableView.tableHeaderView = searchController.searchBar
    }
    
    self.tableView.rowHeight = 40
    self.tableView.tableFooterView = cityCountLabel
    
    DataManager.shared.getCities(completion: nil)
    
//    DataManager.shared.getCities(preferDB: true) { [weak self] (cities, error) in
//      if let validCities = cities {
//        self?.state = AppState(validCities)
//      } else {
//        self?.showSimpleAlert(title: AppText.warning, msg: error as? String)
//      }
//    }
    _ = self.tableView.addScrollToEndButton()
    
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextDidSave, object: DataManager.shared.moc, queue: OperationQueue.main) { [unowned self] (note) in
      let validCities = DataManager.shared.getPersistedData(self.state.isSortAscending)
      self.state = AppState(validCities)
    }
    DispatchQueue(label: "background").async { autoreleasepool {
      let abc = 12
      }
    }
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  
  @IBAction func sortPressed(_ sender: Any) {
    state = state.updateSortMode(!state.isSortAscending)
  }
  
  ///Just a fancy action where you can see my website
  @IBAction func showMyProfile(_ sender: Any) {
    guard let myWebsite = URL(string: Constants.myWebsite) else { return }
    UIApplication.shared.open(myWebsite)
//    let safatiVC = SFSafariViewController(url: myWebsite)
//    self.present(safatiVC, animated: true, completion: nil)
  }
  
  @IBAction func cleanDB(_ sender: Any) {
   DataManager.shared.deleteAllData()
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
    if searchController.isActive {
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


//*******************************************************************//
// MARK:- SearchUpdating
//*******************************************************************//
extension CitiesVC: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    state.filterText = searchController.searchBar.text ?? ""
  }
}
