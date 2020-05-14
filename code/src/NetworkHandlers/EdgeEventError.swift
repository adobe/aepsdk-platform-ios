//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import Foundation

/// Error or warning information for a sent EdgeRequest
struct EdgeEventError : Codable {
    
    /// Encodes the event to which this error/warning is attached as the index in the events array in EdgeRequest
    let eventIndex: Int?
    
    /// Error message
    let message: String?
    
    /// Error code info
    let code: String?
    
    /// Error namespace info
    let namespace: String?
}

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}