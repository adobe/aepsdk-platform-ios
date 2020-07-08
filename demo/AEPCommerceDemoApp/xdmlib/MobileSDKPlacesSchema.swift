/*
 Copyright 2020 Adobe. All rights reserved.

 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.

----
 XDM Schema Swift Object Generated 2020-07-07 16:48:21.241396 -0700 PDT m=+1.762172267 by XDMTool

 Title			:	Mobile SDK Places Schema
 Version		:	1.0
 Description	:	
 ID				:	https://ns.adobe.com/acopprod3/schemas/43fc93e999c435c25ad73ee9c4043f959514a97e3dbd72a0
 Alt ID			:	_acopprod3.schemas.43fc93e999c435c25ad73ee9c4043f959514a97e3dbd72a0
 Type			:	schemas
 IMS Org		:	FAF554945B90342F0A495E2C@AdobeOrg
----
*/

import Foundation
import AEPExperiencePlatform

public struct MobileSDKPlacesSchema : XDMSchema {
	public let schemaVersion = "1.0"
	public let schemaIdentifier = "https://ns.adobe.com/acopprod3/schemas/43fc93e999c435c25ad73ee9c4043f959514a97e3dbd72a0"
	public let datasetIdentifier = "5f050933d1f9ff19159196da"
	
	public init() {}

	public var Acopprod3: Acopprod3?
	public var eventMergeId: String?
	public var eventType: String?
	public var identityMap: IdentityMap?
	public var timestamp: Date?

	enum CodingKeys: String, CodingKey {
		case Acopprod3 = "_acopprod3"
		case eventMergeId = "eventMergeId"
		case eventType = "eventType"
		case identityMap = "identityMap"
		case timestamp = "timestamp"
	}	
}

extension MobileSDKPlacesSchema {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = Acopprod3 { try container.encode(unwrapped, forKey: .Acopprod3) }
		if let unwrapped = eventMergeId { try container.encode(unwrapped, forKey: .eventMergeId) }
		if let unwrapped = eventType { try container.encode(unwrapped, forKey: .eventType) }
		if let unwrapped = identityMap { try container.encode(unwrapped, forKey: .identityMap) }
		if let unwrapped = XDMFormatters.dateToISO8601String(from: timestamp) { try container.encode(unwrapped, forKey: .timestamp) }
	}
}