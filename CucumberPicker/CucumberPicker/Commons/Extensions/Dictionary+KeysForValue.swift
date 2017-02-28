//
//  Dictionary+KeysForValue.swift
//  CucumberPicker
//
//  Created by gabmarfer on 28/02/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//
//  Downloaded from https://gist.github.com/ijoshsmith/a411775b78f107f1c51152c6eda9d665#file-dictionary-keysforvalue-swift

import Foundation

extension Dictionary where Value: Equatable {
    /// Returns all keys mapped to the specified value.
    /// ```
    /// let dict = ["A": 1, "B": 2, "C": 3]
    /// let keys = dict.keysForValue(2)
    /// assert(keys == ["B"])
    /// assert(dict["B"] == 2)
    /// ```
    func keysForValue(value: Value) -> [Key] {
        return flatMap { (key: Key, val: Value) -> Key? in
            value == val ? key : nil
        }
    }
}
