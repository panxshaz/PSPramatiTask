//
//  State.swift
//  PSPramatiTask
//
//  Created by Pankaj Sharma on 20/Dec/17.
//  Copyright © 2017 Pankaj Sharma. All rights reserved.
//

import Foundation

///State struct for Cities app
///It mainly has two properties viz. _cities, filterText
struct AppState {
  ///Public interface for getting cities
  var cities: [CityEntity] {
    get { return filterText.isEmpty ? _cities : _filteredCities }
    set { _cities = newValue }
  }
  
  ///Master Array. All data is here (sorted). It can rather be fetched from DB
  private (set) var _cities: [CityEntity]
  
  ///so that We don't have to filter again and again
  private var _filteredCities = [CityEntity]()
  
  ///For locally filtering the cities
  var filterText: String = "" {
    didSet {
      guard !filterText.isEmpty else { self._filteredCities = []; return }
      self._filteredCities = _cities.filter({ (cityEntity: CityEntity) -> Bool in
        cityEntity.title.localizedCaseInsensitiveContains(filterText)      
      })
    }
  }
  
  var inSearchMode: Bool {
    return !filterText.isEmpty
  }

  mutating func updateSortMode(_ sort: Bool) -> AppState {
    if sort == isSortAscending {
      return self
    }
    isSortAscending = sort
    return self
  }
  
  private(set) var isSortAscending = true {
    didSet {
      _cities = _cities.reversed()
      _filteredCities = _filteredCities.reversed()
    }
  }
  
  init(_ cities: [CityEntity]) {
    //initially sort by population
    _cities = cities.sorted { (city1, city2) -> Bool in
      return city1.population < city2.population
    }    
  }
  
  
}
