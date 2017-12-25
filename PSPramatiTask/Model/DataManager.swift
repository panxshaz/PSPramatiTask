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
  
  
  lazy private var context2: NSManagedObjectContext? = {
//    var context2 = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    let container = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    return container?.newBackgroundContext()
  }()
  
  lazy private var context: NSManagedObjectContext? = {
    let mainContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    moc.parent = mainContext
    return moc
  }()
  
  
  
  private init() {
    if Constants.isPersistingData, let _ = context {
      print("Has Valid Context")
    }
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextWillSave, object: nil, queue: nil) { (note) in
      print("Note \(note)")
    }
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextDidSave, object: nil, queue: nil) { (note) in
//      self.context2!.mergeChanges(fromContextDidSave: note)
      print("Note \(note)")
    }
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: nil, queue: nil) { (note) in
      print("Note \(note)")
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
          //          #if USE_CORE_DATA
          //            DispatchQueue.main.async {
          //              if Constants.isPersistingData {
          //                self.saveData(entities: cities)
          //              }
          //            }
          //          #endif
        }
        #if USE_CORE_DATA
          if Constants.isPersistingData {
            let citiesCount = cities.count
            DispatchQueue.global(qos: .background).async {
              let cities1stQuarter = Array(cities[0...citiesCount/4])
              self.saveData(entities: cities1stQuarter)
            }
            
            DispatchQueue.global(qos: .background).async {
              let cities2ndQuarter = Array(cities[(1+citiesCount/4)...citiesCount/2])
              self.saveData(entities: cities2ndQuarter)
            }
            
            DispatchQueue.global(qos: .background).async {
              let cities2ndHalf = Array(cities.dropFirst(citiesCount/2))
              self.saveData(entities: cities2ndHalf)
            }
//            self.saveData(entities: cities)
          }
        #endif
        
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
            try coreEntity.update(with: entity)
          }
          try context.save()
        } catch {
          print ("SaveData Failed", error)
        }
      }
    }
    
    
    
    //Batch deletes disregard delete rules
    //https://stackoverflow.com/questions/32915874/can-i-use-nsbatchdeleterequest-on-entities-with-relationships-that-have-delete-r
    func deleteAllData() -> Bool {
      let deleteFetch: NSFetchRequest<NSFetchRequestResult> = CountryCoreEntity.fetchRequest()
      let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
      
      //delete the cities as well. because "NSBatchDeleteRequest" disregard delete rules
      let deleteCitiesFetch: NSFetchRequest<NSFetchRequestResult> = CityCoreEntity.fetchRequest()
      let deleteCititesRequest = NSBatchDeleteRequest(fetchRequest: deleteCitiesFetch)
      
      do {
        try context?.execute(deleteRequest)
        try context?.execute(deleteCititesRequest)
        try context?.save()
        print("All Deleted!")
        return true
      } catch {
        print ("There was an error in deleting")
      }
      return false
      
    }
  }
#endif
