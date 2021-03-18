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

import AEPCore
import AEPServices
import Foundation

@objc(AEPMobileEdge)
public class Edge: NSObject, Extension {
    private let LOG_TAG = "Edge" // Tag for logging
    private var networkService: EdgeNetworkService = EdgeNetworkService()
    private var networkResponseHandler: NetworkResponseHandler?
    internal var state: EdgeState?

    // MARK: - Extension
    public let name = EdgeConstants.EXTENSION_NAME
    public let friendlyName = EdgeConstants.FRIENDLY_NAME
    public static let extensionVersion = EdgeConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil
    public let runtime: ExtensionRuntime

    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()

        // set default on init for register/unregister use-case
        networkResponseHandler = NetworkResponseHandler()
        if let hitQueue = setupHitQueue() {
            state = EdgeState(hitQueue: hitQueue)
        }
    }

    public func onRegistered() {
        registerListener(type: EventType.edge,
                         source: EventSource.requestContent,
                         listener: handleExperienceEventRequest)
        registerListener(type: EventType.edgeConsent,
                         source: EventSource.responseContent,
                         listener: handleConsentPreferencesUpdate)
        registerListener(type: EventType.edge,
                         source: EventSource.updateConsent,
                         listener: handleConsentUpdate)
    }

    public func onUnregistered() {
        state?.hitQueue.close()
        print("Extension unregistered from MobileCore: \(EdgeConstants.FRIENDLY_NAME)")
    }

    public func readyForEvent(_ event: Event) -> Bool {
        guard canProcessEvents(event: event) else { return false }

        if event.isExperienceEvent || event.isUpdateConsentEvent {
            let configurationSharedState = getSharedState(extensionName: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                                          event: event)
            let identitySharedState = getXDMSharedState(extensionName: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                                        event: event)

            return configurationSharedState?.status == .set && identitySharedState?.status == .set
        }

        return true
    }

    /// Handler for Experience Edge Request Content events.
    /// Valid Configuration and Identity shared states are required for processing the event (see `readyForEvent`). If a valid Configuration shared state is
    /// available, but no `edge.configId ` is found or `shouldIgnore` returns true, the event is dropped.
    ///
    /// - Parameter event: an event containing ExperienceEvent data for processing
    func handleExperienceEventRequest(_ event: Event) {
        guard !shouldIgnore(event: event) else { return }

        guard let data = event.data, !data.isEmpty else {
            Log.trace(label: LOG_TAG, "Event with id \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        // get IdentityMap from Identity shared state, this should be resolved based on readyForEvent check
        guard let identityState =
                getXDMSharedState(extensionName: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                  event: event)?.value else {
            Log.warning(label: LOG_TAG,
                        "handleExperienceEventRequest - Unable to process the event '\(event.id.uuidString)', " +
                            "Identity shared state is nil.")
            return // drop current event
        }

        let storeResponsePayloadManager = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
        let edgeEntity = EdgeDataEntity(event: event,
                                        identityMap: AnyCodable.from(dictionary: identityState) ?? [:],
                                        storedPayloads: storeResponsePayloadManager.getActiveStores())

        guard let entityData = try? JSONEncoder().encode(edgeEntity) else {
            Log.debug(label: LOG_TAG, "handleExperienceEventRequest - Failed to encode Edge data entity with id: '\(event.id.uuidString)'.")
            return
        }

        Log.debug(label: LOG_TAG, "handleExperienceEventRequest - Queuing event with id \(event.id.uuidString).")
        let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: entityData)
        state?.hitQueue.queue(entity: entity)
    }

    /// Handles the `EventType.consent` -`EventSource.responseContent` event for the collect consent change
    /// - Parameter event: the consent preferences response event
    func handleConsentPreferencesUpdate(_ event: Event) {
        guard let data = event.data, !data.isEmpty else {
            Log.trace(label: LOG_TAG, "Event with id \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        state?.updateCurrentConsent(status: ConsentStatus.getCollectConsentOrDefault(eventData: data))
    }

    /// Handles the Consent Update event
    /// - Parameter event: current event to process
    func handleConsentUpdate(_ event: Event) {
        guard let data = event.data, !data.isEmpty else {
            Log.trace(label: LOG_TAG, "handleConsentUpdate - Event with id \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        // get IdentityMap from Identity shared state, this should be resolved based on readyForEvent check
        guard let identityState =
                getXDMSharedState(extensionName: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                  event: event)?.value else {
            Log.warning(label: LOG_TAG,
                        "handleConsentUpdate - Unable to process the event '\(event.id.uuidString)', " +
                            "Identity shared state is nil.")
            return // drop current event
        }

        let edgeEntity = EdgeDataEntity(event: event,
                                        identityMap: AnyCodable.from(dictionary: identityState) ?? [:],
                                        storedPayloads: nil)

        guard let entityData = try? JSONEncoder().encode(edgeEntity) else {
            Log.debug(label: LOG_TAG, "handleConsentUpdate - Failed to encode Edge data entity with id: '\(event.id.uuidString)'.")
            return
        }

        let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: entityData)
        state?.hitQueue.queue(entity: entity)
    }

    /// Determines if the event should be ignored by the Edge extension. This method should be called after
    /// `readyForEvent` passed.
    ///
    /// - Parameter event: the event to validate
    /// - Returns: true when collect consent is no, false otherwise
    private func shouldIgnore(event: Event) -> Bool {
        let consentForEvent = getConsentForEvent(event)
        if consentForEvent == ConsentStatus.no {
            Log.debug(label: LOG_TAG, "Ignoring event with id \(event.id.uuidString) due to collect consent setting (n) .")
            return true
        }

        return false
    }

    /// Determines if `Edge` is ready to handle events, if the bootup can be executed successfully
    /// - Parameter event: An `Event`
    /// - Returns: true if events can be processed at the moment, false otherwise
    private func canProcessEvents(event: Event) -> Bool {
        guard let state = state else { return false }
        state.bootupIfNeeded(event: event, getXDMSharedState: getXDMSharedState(extensionName:event:))
        return true
    }

    /// Sets up the `PersistentHitQueue` to handle `EdgeHit`s
    private func setupHitQueue() -> HitQueuing? {
        guard let dataQueue = ServiceProvider.shared.dataQueueService.getDataQueue(label: name) else {
            Log.error(label: "\(name):\(#function)", "Failed to create Data Queue, Edge could not be initialized")
            return nil
        }

        guard let networkResponseHandler = networkResponseHandler else {
            Log.warning(label: LOG_TAG, "Failed to create Data Queue, the NetworkResponseHandler is not initialized")
            return nil
        }

        let hitProcessor = EdgeHitProcessor(networkService: networkService,
                                            networkResponseHandler: networkResponseHandler,
                                            getSharedState: getSharedState(extensionName:event:),
                                            getXDMSharedState: getXDMSharedState(extensionName:event:),
                                            readyForEvent: readyForEvent(_:))
        return PersistentHitQueue(dataQueue: dataQueue, processor: hitProcessor)
    }

    /// Retrieves the `ConsentStatus` from the Consent XDM Shared state for current `event`.
    /// - Returns: `ConsentStatus` value from shared state or, if not found, current consent value
    private func getConsentForEvent(_ event: Event) -> ConsentStatus? {
        guard let consentXDMSharedState = getXDMSharedState(extensionName: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME,
                                                            event: event)?.value else {
            Log.debug(label: LOG_TAG, "Consent XDM Shared state is unavailable for event '\(event.id)', using currect consent.")
            return state?.currentCollectConsent
        }

        return ConsentStatus.getCollectConsentOrDefault(eventData: consentXDMSharedState)
    }

}
