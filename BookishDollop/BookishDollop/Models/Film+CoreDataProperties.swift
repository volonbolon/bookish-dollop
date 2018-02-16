//
//  Film+CoreDataProperties.swift
//  BookishDollop
//
//  Created by Ariel Rodriguez on 16/02/2018.
//  Copyright © 2018 Ariel Rodriguez. All rights reserved.
//
//

import Foundation
import CoreData

extension Film {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Film> {
        return NSFetchRequest<Film>(entityName: "Film")
    }

    @NSManaged public var cast: String?
    @NSManaged public var director: String?
    @NSManaged public var lastTouched: NSDate?
    @NSManaged public var theaters: String?
    @NSManaged public var title: String?
    @NSManaged public var year: String?
}
