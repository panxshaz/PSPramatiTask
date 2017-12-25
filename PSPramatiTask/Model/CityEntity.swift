//
//  CityEntity.swift
//  PSPramatiTask
//
//  Created by Pankaj Sharma on 20/Dec/17.
//  Copyright © 2017 Pankaj Sharma. All rights reserved.
//

import Foundation
import CoreData

typealias CityCSV = [String]

///This is primary data. Each object represents a City
///Storing only some of the needed info that I'll be using while displaying cities
//Country,City,AccentCity,Region,Population,Latitude,Longitude
class CityEntity: NSObject {
  ///Apparently this is the primary key
  let title: String
  let population: Int
  var country: String?
  var latitude: Double?
  var longitude: Double?
  
  var locationURL: URL? {
    guard let lat = latitude, let lng = longitude else { return nil }
    return URL(string: "http://maps.apple.com/maps?ll=\(lat),\(lng)")
//    UIApplication.shared.openURL(url)
  }

  private enum CityIndexKey: Int {
    case country = 0
    case title = 2
    case population = 4
    case latitude = 5
    case longitude = 6
  }
  
  ///Ideally we should have had a JSON
  init(csv: CityCSV) {
    title = csv[CityIndexKey.title.rawValue]
    population = Int(csv[CityIndexKey.population.rawValue]) ?? 0
    latitude = Double(csv[CityIndexKey.latitude.rawValue])
    longitude = Double(csv[CityIndexKey.longitude.rawValue])
    country = csv[CityIndexKey.country.rawValue]
  }
  
  
  ///Creates and resutls array of `CityEntity` objects from the city CSVs
  static func createCities(fromData citiesCSV: [CityCSV]) -> [CityEntity] {
    var cities = [CityEntity]()
    for cityCSV in citiesCSV {
      cities.append(CityEntity(csv: cityCSV))
    }
    return cities
  }
  
  
  
  #if USE_CORE_DATA
  init(coreEntity: CityCoreEntity) {
    title = coreEntity.title!
    population = Int(coreEntity.population)
    latitude = coreEntity.latitude
    longitude = coreEntity.longitude
    country = coreEntity.country?.countryCode
  }
  #endif
}



#if USE_CORE_DATA
  extension CityCoreEntity {
    func update(with city: CityEntity) throws {
      let coreEntity = self
      coreEntity.title = city.title
      coreEntity.population = Int32(city.population)
      coreEntity.latitude = city.latitude ?? 0
      coreEntity.longitude = city.longitude ?? 0      
      
      //country
      if let validCountryCode = city.country, let context = coreEntity.managedObjectContext {
        let countryFetchRequest: NSFetchRequest<CountryCoreEntity> = CountryCoreEntity.fetchRequest()
        countryFetchRequest.predicate = NSPredicate(format: "countryCode == %@", validCountryCode)
        var countryEntity = try context.fetch(countryFetchRequest).first
        if countryEntity == nil {
          //create new
          countryEntity = CountryCoreEntity(context: context)
          countryEntity?.countryCode = validCountryCode
        }
        coreEntity.country = countryEntity
      }
    }
  }
  
  extension CountryCoreEntity {
    
  }
  
#endif
