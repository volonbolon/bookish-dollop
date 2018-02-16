//
//  Either.swift
//  BookishDollop
//
//  Created by Ariel Rodriguez on 16/02/2018.
//  Copyright © 2018 Ariel Rodriguez. All rights reserved.
//

import Foundation

/**
 Since *right* is synonymn with *correct*, if everything goes as expected, we populate the
 right case.
 */
public enum Either<T1, T2> {
    case left(T1)
    case right(T2)
}
