//
//  NSManagedObjectContext+Helpers.swift
//  BookishDollop
//
//  Created by Ariel Rodriguez on 16/02/2018.
//  Copyright © 2018 Ariel Rodriguez. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    func insertObject<T: NSManagedObject>() -> T where T: ManagedObject {
        guard let object = NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: self) as? T else {
            fatalError()
        }
        return object
    }
}
