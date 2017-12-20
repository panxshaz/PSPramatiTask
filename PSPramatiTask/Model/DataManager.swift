//
//  DataManager.swift
//  PSPramatiTask
//
//  Created by Pankaj Sharma on 20/Dec/17.
//  Copyright © 2017 Pankaj Sharma. All rights reserved.
//

import Foundation

//singleton
class DataManager {
  
  static let shared = DataManager()
  
  
  let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)

  
  lazy private var context: NSManagedObjectContext? = {
    let mainContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    moc.parent = mainContext
    return moc
  }()
  
  
  
  private init() {
    if Constants.isPersistingData, let _ = context {
      print("Has Valid Context")
    }
  }
  
  typealias ParsingCompletion = (([CityEntity]?, Error?) -> ())
  
  
  func getCities(preferDB: Bool = false, completion: ParsingCompletion?)  {
    if preferDB && Constants.isPersistingData {
      //get saved data
      let cities = getPersistedData()
      if cities.count > 0 {
        completion?(cities, nil)
        return
      }
    }
    parseCSV(named: Constants.cityFilename, completion: completion)
  }
  
  func parseCSV(named filename: String, completion: ParsingCompletion?){
    guard let filepath = Bundle.main.path(forResource: filename, ofType: "txt") else {
      completion?(nil, "Invalid FilePath")
      return
    }
    
    DispatchQueue.global(qos: .utility).async {[unowned self] in
      do {
        var contents = try String(contentsOfFile: filepath, encoding: .ascii)
        contents = self.cleanRows(file: contents)
        let citiesCSVs = self.csv(data: contents)
        let cities = CityEntity.createCities(fromData: citiesCSVs)
        DispatchQueue.main.async {
          completion?(cities, nil)
          #if USE_CORE_DATA
            DispatchQueue.main.async {
              if Constants.isPersistingData {
                self.saveData(entities: cities)
              }
            }
          #endif
        }
      } catch {
        let errorStr = "File Read Error for file \(filepath)"
        DispatchQueue.main.async {
          completion?(nil, errorStr)
        }
      }
    }
  }
  
  
  func cleanRows(file: String) -> String{
    var cleanFile = file
    cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
    cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
    return cleanFile
  }
  
  
  func csv(data: String) -> [CityCSV] {
    var result: [CityCSV] = []
    let rows = data.components(separatedBy: "\n")
    for i in 1..<rows.count {
      let row = rows[i]
      let columns = row.components(separatedBy: ",")
      result.append(columns)
    }
    return result
  }
  
}


//*******************************************************************//
// MARK:- Core Data Extension
//*******************************************************************//
#if USE_CORE_DATA
  import CoreData
  import UIKit
  extension DataManager {
    func getPersistedData(_ ascending: Bool = true) -> [CityEntity] {
      guard let context = self.context else { return []}
      do {
        let fetchRequest: NSFetchRequest<CityCoreEntity> = CityCoreEntity.fetchRequest()
        let sortDesc = NSSortDescriptor(key: #keyPath(CityCoreEntity.title), ascending: ascending)
        fetchRequest.sortDescriptors = [sortDesc]
        let cityCoreEntities = try context.fetch(fetchRequest)
        var cities = [CityEntity]()
        for cityCoreEntity in cityCoreEntities {
          let city = CityEntity(coreEntity: cityCoreEntity)
          cities.append(city)
        }
        return cities
      } catch {
        print("Fetching Failed")
      }
      return []
    }
    
    
    func saveData(entities: [CityEntity]?) {
      guard let context = self.context, let entities = entities else { return }
      context.perform {
        
        
        do {
          let fetchRequest: NSFetchRequest<CityCoreEntity> = CityCoreEntity.fetchRequest()
          //order is important
          for i in 0..<entities.count {
            let entity = entities[i]
            fetchRequest.predicate = NSPredicate(format: "title == %@", entity.title)
            var coreEntity: CityCoreEntity!
            if let cityCoreEntity = (try context.fetch(fetchRequest)).first {
              coreEntity = cityCoreEntity
            } else {
              //create new
              coreEntity = CityCoreEntity(context: context)
            }
            coreEntity.update(with: entity)
          }
          try context.save()
        } catch {
          print ("SaveData Failed", error)
        }
      }
    }
    
    
    
    func deleteAllData() -> Bool {
      let deleteFetch: NSFetchRequest<NSFetchRequestResult> = CityCoreEntity.fetchRequest()
      
      let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
      do {
        try context?.execute(deleteRequest)
        try context?.save()
        return true
      } catch {
        print ("There was an error in deleting")
      }
      return false
      
    }
  }
#endif
