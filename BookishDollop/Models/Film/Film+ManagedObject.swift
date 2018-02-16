//
//  Film+ManagedObject.swift
//  BookishDollop
//
//  Created by Ariel Rodriguez on 16/02/2018.
//  Copyright © 2018 Ariel Rodriguez. All rights reserved.
//

import Foundation
import CoreData

/*
 Map indices to data title
 */
struct FilmConstants {
    static let titleIndex = 8
    static let directorIndex = 14
    static let releaseYearIndex = 9
    static let locationsIndex = 10
    static let filmIDIndex = 1
}

extension Film: ManagedObject {
    static var entityName: String {
        return "Film"
    }

    static var defaultSortDescriptors: [NSSortDescriptor] {
        let sortByTitle = NSSortDescriptor(key: "title", ascending: true)
        return [sortByTitle]
    }

    static var sortedByTitleFetchRequest: NSFetchRequest<Film> {
        return Film.sortedFetchRequest
    }

    static var sortedByLocationFetchRequest: NSFetchRequest<Film> {
        let request = NSFetchRequest<Film>(entityName: self.entityName)
        let sortByYearOfProduction = NSSortDescriptor(key: "location", ascending: true)
        request.sortDescriptors = [sortByYearOfProduction]
        return request
    }

    static var sortedByDirectorFetchRequest: NSFetchRequest<Film> {
        let request = NSFetchRequest<Film>(entityName: self.entityName)
        let sortByDirector = NSSortDescriptor(key: "director", ascending: true)
        request.sortDescriptors = [sortByDirector]
        return request
    }
}

extension Film { // MARK: - Insert extension
    /*
     Once we import the new films, it's time to delete the staled one
     */
    private static func cleanOldFilms(context: NSManagedObjectContext) -> Bool {
        var success = false
        context.performAndWait {
            let thresholdDate = Date(timeIntervalSinceNow: -60)
            let datePredicate = NSPredicate(format: "lastTouched < %@", thresholdDate as NSDate)
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Film.entityName)
            fetchRequest.predicate = datePredicate
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            // We set the result type to resultTypeObjectIDs to be able to merge the changes later.
            batchDeleteRequest.resultType = .resultTypeObjectIDs

            do {
                let batchResult = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
                if let deletedObjectIDs = batchResult?.result as? [NSManagedObjectID] {

                    let deletedObjectsKeys = [NSDeletedObjectsKey: deletedObjectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: deletedObjectsKeys, into: [context])
                    success = true
                }
            } catch {
                print(error)
            }
        }
        return success
    }

    private static func importBatch(batch: ArraySlice<[Any]>, context: NSManagedObjectContext) -> Bool {
        var success = false
        context.performAndWait {
            for rawFilm in batch {
                guard let filmID = rawFilm[FilmConstants.filmIDIndex] as? String else {
                    return // Early exit if we cannot find the director and the title
                }
                let predicate = NSPredicate(format: "filmID LIKE %@", argumentArray: [filmID])

                // The configure block makes it a little convoluted.
                // We just query Film to find or create a managed object
                // If we get the object back, we just updated the `lastTouched` field
                if let film = Film.findOrCreate(context: context, predicate: predicate, configure: { (managedObject: ManagedObject) in
                    if let film = managedObject as? Film {
                        guard let year = rawFilm[FilmConstants.releaseYearIndex] as? String, let location = rawFilm[FilmConstants.locationsIndex] as? String, let title = rawFilm[FilmConstants.titleIndex] as? String, let director = rawFilm[FilmConstants.directorIndex] as? String else {
                            throw ManagedObjectError.illFormattedInput
                        }
                        film.filmID = filmID
                        film.title = title
                        film.location = location
                        film.director = director
                        film.year = year
                        film.lastTouched = Date.distantPast as NSDate
                    }
                }) {
                    film.lastTouched = Date() as NSDate
                }
            }
            // Save all the changes just made and reset the taskContext to free the cache.
            // Let's save the changes and reset the context to free memory
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Error: \(error)\nCould not save Core Data context.")
                    return
                }
                context.reset()
            }
            success = true
        }
        return success
    }

    /**
     Given an array of arrays with the films data, saves them into the store.
     - parameters:
     - rawObjects: Array of arrays with the raw information retrieved from the endpoint
     - container: NSPersistentContainer used to create the context, it should be attached to the main store.
     - completionBlock: informs the caller if the API went successfully
     */
    static func insertInBulk(rawObjects: [[Any]], container: NSPersistentContainer, completionBlock: (Bool) -> Void) {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil

        let batchSize = 256 // Really conservative, given the nature of the input, we can do everything at once.
        let count = rawObjects.count

        var numBatches = count / batchSize
        numBatches += (count % batchSize) > 0 ? 1 : 0

        for batchNumber in 0 ..< numBatches {
            let batchStart = batchNumber * batchSize
            let batchEnd = batchStart + min(batchSize, count - batchNumber * batchSize)
            let range = batchStart..<batchEnd

            let batch = rawObjects[range]
            let success = Film.importBatch(batch: batch, context: context)
            if !success {
                completionBlock(false)
            }
        }
        let success = Film.cleanOldFilms(context: context)
        completionBlock(success)
    }
}
