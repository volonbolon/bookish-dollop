//
//  ManagedObject.swift
//  BookishDollop
//
//  Created by Ariel Rodriguez on 16/02/2018.
//  Copyright © 2018 Ariel Rodriguez. All rights reserved.
//

import Foundation
import CoreData

enum ManagedObjectError: Error {
    case sortingError
    case illFormattedInput
}

/**
 A closure handle to the caller in order to populate the managed object.
 If data is corrupted, it should throw `.illFormattedInput`
 */
typealias ConfigureClosure = (ManagedObject) throws -> Void

/**
 Helper protocol for NSmanagedObject
 */
protocol ManagedObject: class, NSFetchRequestResult {
    static var entityName: String { get }
    /**
     List of basic descriptors used in queries
     */
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
    var managedObjectContext: NSManagedObjectContext? { get }
}

/**
 Default Implementation of `ManagedObject` protocol
 */
extension ManagedObject {
    /**
     By default, the list is empty. Specific managed objects that
     adopt the protocol should return valid descriptors.
     */
    public static var defaultSortDescriptors: [NSSortDescriptor] { return [] }

    static var sortedFetchRequest: NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: self.entityName)
        request.sortDescriptors = self.defaultSortDescriptors
        return request
    }
}

extension ManagedObject where Self: NSManagedObject {
    /**
     Helper closure that gives the caller the chance to configure the request
     */
    typealias FetchRequestConfigureClosure = (NSFetchRequest<Self>) -> Void
    /**
     Perform the fetch in the given context
     - parameters:
     - context: Instance of a context used to perform the fetch
     - configure: a closure invoqued with the freshly created request to let
     the caller perform additional configuration
     - returns:
     A collection of Managed objects
     - throws:
     rethrows request
     */
    static func fetch(context: NSManagedObjectContext, configure: FetchRequestConfigureClosure?) throws -> [Self] {
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        if let configureBlock = configure {
            configureBlock(request)
        }
        let objects = try context.fetch(request)
        return objects
    }

    static func findOrCreate(context: NSManagedObjectContext, predicate: NSPredicate, configure: ConfigureClosure) -> Self? {
        guard let object = self.fireFaultOrFetch(context: context, predicate: predicate) else {
            let object: Self = context.insertObject()
            do {
                try configure(object)
            } catch {
                // If input is incorrect, instead of having an ill formatted object, we remove it.
                context.delete(object)
                return nil
            }
            return object
        }
        return object
    }

    /**
     It a fault managed is found, we load it up.
     Otherwise, we try to fetch it from store.
     */
    static func fireFaultOrFetch(context: NSManagedObjectContext, predicate: NSPredicate) -> Self? {
        guard let object = self.fireFault(context: context, predicate: predicate) else {
            do {
                let objects = try self.fetch(context: context, configure: { (request: NSFetchRequest<Self>) in
                    request.predicate = predicate
                    request.returnsObjectsAsFaults = false
                    request.fetchLimit = 1
                })
                return objects.first
            } catch {
                return nil
            }
        }
        return object
    }

    /**
     Loads a faulted managed object
     */
    static func fireFault(context: NSManagedObjectContext, predicate: NSPredicate) -> Self? {
        for object in context.registeredObjects where !object.isFault {
            guard let result = object as? Self, predicate.evaluate(with: result) else {
                continue
            }
            return result
        }
        return nil
    }
}
