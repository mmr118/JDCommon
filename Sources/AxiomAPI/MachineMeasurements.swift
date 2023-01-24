//
//  MachineMeasurements.swift
//
//
//  Created by Chahare Vinit on 01/08/22.
//

import Foundation
import JDCommonAPIClient

public typealias MeasurementDefinitionId = String

public extension MeasurementDefinitionId {
    static let fuelTankLevel = "A61BBD49-9345-5109-F7F2-AECBCC3D2D57"
    static let defTankLevel = "9B824A21-EAB8-C903-0B4C-CAC41073477A"
    static let combineSeparatorHours = "9d790cda-e533-470f-babc-87a8eb03c8c4"
}


/// Represents the value(s) associated with an individual machine measurement, e.g. "Average Ground Speed". Depending on the
/// requested date range and aggregation options the measurement may include values for multiple intervals and each interval can
/// potentially have values "bucketed" based on different classifications.
public struct MachineMeasurementValueDTO: CustomDebugStringConvertible {
        
    /// - Note: Only included if associated 'embed' parameter is passed in API request. However, if the embed is not requested the
    /// returned values don't appear to have any identifying information and are not even returned in the same order as requested, so
    /// using this API without requesting the measurementDefinition embed appears to be impractical, and thus for implementation
    /// simplicity we will mark this as required (assuming we will only make requests that embed it).
    public let definition: MeasurementDefinition
    /// The method by which the telematic information was uploaded.
    public let networkType: NetworkType
    public let series: MachineMeasurementValueDTO.Series  // More explicit to avoid future naming collisions
    
    public var debugDescription: String {
        
        return "Measurement \(definition), \(series.description(using: definition))"
    }
    
    /// Convenience method for returning this measurement's Interval instances sorted in ascending order.
    /// - Warning: This method `throws` if each of the `Interval` instances don't have an associated DateInterval, which may not be
    /// the case if the `SeriesLevel` aggregation type was `.aggregated`.
    public func sortedIntervals() throws -> [Interval] {
        
        // If there is >1 interval we expect that each Interval will have start/end dates associated with it
        guard series.intervals.allSatisfy({ $0.interval != nil }) else { throw MachineMeasurementError.intervalDatesMissing }
        
        let sortedIntervals = series.intervals.sorted { lhs, rhs in
            
            guard let lhsInterval = lhs.interval, let rhsInterval = rhs.interval else { return false }
            return lhsInterval < rhsInterval
        }
        
        return sortedIntervals
    }
    
    /// Convenience method for retrieving the latest (or only) `Interval` instance.
    /// - Note: This method should be safe to call even when `SeriesLevel == .aggregated` and only one `Interval` instance is returned, but
    /// it may `throw` if multiple `Intervals` are returned and each doesn't have an associated DateInterval.
    public func latestInterval() throws -> Interval {
        
        if series.intervals.count == 1, let theInterval = series.intervals.first {
            return theInterval
        } else {
            guard let theLatestInterval = try sortedIntervals().last else { throw MachineMeasurementError.intervalsMissing }
            return theLatestInterval
        }
    }
    
    /// Convenience method for directly returning a scalar Double value associated with the last received ("last known") data point.
    /// - Warning: This method intentionally can only be used for measurements with aggregation type `.last` and will `throw` for other aggregation
    /// types. The purpose is to make clear, at the point of use, when the returned value is known to be the last-received value vs. when the returned value has
    /// been summed / averaged / etc. over a range of dates.
    /// - Parameter bucketSequenceNumber: Can be nil if there is only one bucket, otherwise throws an error if nil when there are multiple buckets.
    public func lastReceivedValue(bucket sequenceNumber: String? = nil) throws -> Double {
        
        // TODO: Is there value in being able to request the newest value when a series of intervals is returned?
        guard definition.aggregationType == .last else { throw MachineMeasurementError.invalidAggregationType }
        
        return try latestInterval().value(bucket: sequenceNumber)
    }
}

// MARK: - MachineMeasurementValue Nested ENUMs
extension MachineMeasurementValueDTO {
    
    enum MachineMeasurementError: Error {
        case invalidAggregationType
        case intervalDatesMissing
        case intervalsMissing
        case bucketChoiceRequired
        case invalidBucketSequenceNumber
    }
    
    public enum NetworkType: String, Decodable {
        case cellular = "CELLULAR"
        case satellite = "SATELLITE"
    }
    
    /// Identifies how the measurement value has been aggregated over the requested date range
    public enum AggregationType: String, Decodable {
        /// Represents the last-received value within a given date range (not aggregated)
        case last = "LAST"
        /// Sum of values within a given date range
        case sum = "SUM"
        /// Maximum value observed within a given date range
        case max = "MAX"
        /// Weighted average of a value within a given date range
        case weightedAverage = "WEIGHTED_AVERAGE"
    }
    
    /// Identifies how many `Interval` instances should be returned to cover the requested date range
    public enum SeriesLevel: String, Decodable, CustomStringConvertible {
        /// Return a single `Interval` instance covering the entire requested date range
        case aggregated
        /// Return `Interval` instances for each day within the requested date range
        case daily
        /// Return `Interval` instances for each month within the requested date range
        case monthly
        /// Return `Interval` instances for each year within the requested date range
        case yearly
        
        public var description: String {
            
            switch self {
            case .aggregated: return "aggregated over requested time interval"
            case .daily: return "aggregated by day"
            case .monthly: return "aggregated by month"
            case .yearly: return "aggregated by year"
            }
        }
    }
}

// MARK: - MachineMeasurementValue Nested Objects
extension MachineMeasurementValueDTO {
    
    /// Metadata identifying each measurement instance
    public struct MeasurementDefinition: CustomStringConvertible {
        
        /// Human-readable name for the measurement.
        public let name: String
        
        /// A "measurementDescriptionId" that can be used to specify which particular measurements to return from the API endpoint.
        public let id: String
        
        /// A shorthand identifier of the unit of measure for the Double values in the associated Bucket instances.
        public let unitOfMeasure: String
        
        /// Identifies what mathematical operation was used to aggregate values within the associated date range, or in the case of `.last`
        /// that the value has not been aggregated and you're receiving the last-known value.
        public let aggregationType: AggregationType
        
        /// Nested definitions for each of the associated measurement "Buckets".
        public let bucketDefinitions: [BucketDefinition]?
        
        /// A dictionary representation of `bucketDefinitions` for easy lookup of Bucket definition by identifier
        private let bucketDefinitionsBySequenceNumber: [String : BucketDefinition]?
        
        public var description: String {
            
            let aggregationDescription: String
            switch aggregationType {
            case .last: aggregationDescription = "last received value within time range"
            case .max: aggregationDescription = "maximum received value within time range"
            case .sum: aggregationDescription = "sum of values received within time range"
            case .weightedAverage: aggregationDescription = "weighted average of values received within time range"
            }
            
            return "'\(name)', unit: '\(unitOfMeasure)', \(aggregationDescription)"
        }
        
        /// A convenience method for getting a human-readable description of a Bucket using metadata in the MeasurementDefinition.
        public func description(for bucket: Bucket) -> String? {
            
            guard let definitionsBySequenceNumber = bucketDefinitionsBySequenceNumber else { return nil }
            guard let theDefinition = definitionsBySequenceNumber[bucket.sequenceNumber] else { return nil }
            
            return theDefinition.description
        }
        
        /// A convenience method for looking up the "sequenceNumber", a.k.a. identifier, of a Bucket using it's human-readable name.
        public func sequenceNumber(forBucketDescription bucketDescription: String) -> String? {
            
            return bucketDefinitions?.first(where: { $0.description == bucketDescription })?.sequenceNumber
        }
    }
    
    /// Metadata identifying a particular measurement `Bucket`
    public struct BucketDefinition: Decodable {
        
        /// Human-readable description of the classification associated with the bucketed value
        public let description: String
        
        /// An identifier for the bucket used to match the definition to the actual bucket
        public let sequenceNumber: String
        
        // Omitted, unclear what values are and whether they're needed
//        public let minimumValue: Double
//        public let maximumValue: Double
//        public let rangeIndicator: Bool
    }
    
    /// Container for an array of `Interval` instances covering the date range supplied in the API request
    public struct Series: Decodable, CustomStringConvertible {
        
        /// Re-states what interval size was requested in the API request
        public let level: SeriesLevel
        
        /// Array of intervals returned within the requested date range. The order should match their order in the API response
        /// but no guarantee is given about the sorting.
        public let intervals: [Interval]
        
        public var description: String {
            
            return description(using: nil)
        }
        
        public func description(using measurementDefinition: MeasurementDefinition?) -> String {
            
            let intervalsString = intervals.map({ "\t" + $0.description(using: measurementDefinition) }).joined(separator: ",\n")
            
            return "\(level), intervals: [\n\(intervalsString)]"
        }
    }
    
    /// The representation of a date interval over which a value has been aggregated. If the value has been bucketed the total value may
    /// be split across several Bucket instances associated with different operating states.
    public struct Interval: CustomStringConvertible {
        
        /// If the API request uses a Series "aggregationLevel" other than `.aggregated` then the requested date range may be broken
        /// up into more than one Interval instance, where each Instance reports the sub-range of that total requested date range that it
        /// represents.
        /// - Note: This value will be nil if the API request's `SeriesLevel == .aggregated`
        public let interval: DateInterval?
        
        /// Some measurements will aggregate a given value into different "Buckets" depending on operating state at the time the data
        /// point was recorded. For example, "Average Fuel Consumption" while working vs. idle. If a value is not bucketed there will only
        /// be one item in this array.
        public let buckets: [Bucket]
        
        public var description: String {
            
            return description(using: nil)
        }
        
        public func description(using measurementDefinition: MachineMeasurementValueDTO.MeasurementDefinition?) -> String {
            
            let bucketsString: String
            if buckets.count == 1, let onlyBucket = buckets.first {
                bucketsString = "value: \(onlyBucket.value.formatted(.number.precision(.fractionLength(2)))) (reported \(onlyBucket.count)x)"
            } else {
                bucketsString = "buckets: [" + buckets.map({ $0.description(using: measurementDefinition) }).joined(separator: ", ") + "]"
            }
            
            if let theInterval = interval {
                let formatter = DateIntervalFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                return "Interval from \(formatter.string(from: theInterval) ?? "N/A"), \(bucketsString)"
            } else {
                return bucketsString
            }
        }
        
        /// - Parameter bucketSequenceNumber: Can be nil if there is only one bucket, otherwise throws an error if nil when there are multiple buckets.
        public func value(bucket sequenceNumber: String? = nil) throws -> Double {
                        
            if sequenceNumber == nil {
                guard buckets.count == 1, let theOnlyBucket = buckets.first else { throw MachineMeasurementError.bucketChoiceRequired }
                return theOnlyBucket.value
            } else {
                guard let theBucket = buckets.first(where: { $0.sequenceNumber == sequenceNumber }) else { throw MachineMeasurementError.invalidBucketSequenceNumber }
                return theBucket.value
            }
        }
    }
    
    /// A "Bucket" represents a scoped fraction of a larger value. For example, the measurement "Average Ground Speed" may be broken up into
    /// separate "buckets" for Idle, Working, and Transport where each bucket represents the average ground speed while the vehicle was
    /// classified as being either "Idle", "Working", or "Transporting".
    public struct Bucket: CustomStringConvertible {
        
        /// This date range appears to be more specific than the DateInterval of its parent Interval object. It may represent the boundaries of
        /// the actual data observations that have been aggregated together into the `value`.
        /// - Note: This value will be nil if the API request's `SeriesLevel == .aggregated`
        public let actualDateInterval: DateInterval?
        /// The aggregated value over either the explicit `actualDateInterval` (if present) or an interval implied by the request settings.
        public let value: Double  // NOTE: Endpoint YAML says this is an integer, but reponses clearly include floating point values (!?)
        /// An identifier for the Bucket used to match it with its BucketDefinition metadata (unique within a measurement instance)
        public let sequenceNumber: String
        /// The number of data points aggreaged into the `value`.
        public let count: String
        
        public var description: String {
            // Return the description without converting `sequenceNumber` into plain english description using MeasurementDefinition
            return description(using: nil)
        }
        
        public func description(using measurementDefinition: MachineMeasurementValueDTO.MeasurementDefinition?) -> String {
            
            // TODO: Add display of actual date range?
            
            let bucketDescription = measurementDefinition?.description(for: self) ?? sequenceNumber
            return "'\(bucketDescription)': \(value.formatted(.number.precision(.fractionLength(2)))) (reported \(count)x)"
        }
    }
}


// MARK: - Customized Decodable implementations
extension MachineMeasurementValueDTO: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case definition = "machineMeasurementDefinition"
        case networkType
        case series
    }
}

extension MachineMeasurementValueDTO.MeasurementDefinition: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case name
        case id
        case unitOfMeasure
        case aggregationType
        case bucketDefinitions
    }
    
    enum AggregationTypeCodingKeys: String, CodingKey {
        case id
        case value
    }
    
    public init(from decoder: Decoder) throws {
        
        let measDefinitionContainer = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try measDefinitionContainer.decode(String.self, forKey: CodingKeys.name)
        self.id = try measDefinitionContainer.decode(String.self, forKey: CodingKeys.id)
        self.unitOfMeasure = try measDefinitionContainer.decode(String.self, forKey: CodingKeys.unitOfMeasure)
        
        // Flatten the JSON schema by extrating the .aggregationType.value
        let aggregationTypeContainer = try measDefinitionContainer.nestedContainer(keyedBy: AggregationTypeCodingKeys.self, forKey: CodingKeys.aggregationType)
        self.aggregationType = try aggregationTypeContainer.decode(MachineMeasurementValueDTO.AggregationType.self, forKey: AggregationTypeCodingKeys.value)
        
        // Flatten the JSON schema by collapsing the .bucketDefinitions.bucketDefinitions structure
        let outerDefinitionsContainer = try measDefinitionContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.bucketDefinitions)
        let bucketDefinitions = try outerDefinitionsContainer.decodeIfPresent([MachineMeasurementValueDTO.BucketDefinition].self, forKey: CodingKeys.bucketDefinitions)
        self.bucketDefinitions = bucketDefinitions
        
        if let theBucketDefinitions = bucketDefinitions {
            let tuples: [(String, MachineMeasurementValueDTO.BucketDefinition)] = theBucketDefinitions.map { ($0.sequenceNumber, $0)}
            self.bucketDefinitionsBySequenceNumber = Dictionary(uniqueKeysWithValues: tuples)
        } else {
            self.bucketDefinitionsBySequenceNumber = nil
        }
    }
}

extension MachineMeasurementValueDTO.Interval: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case intervalStartDate
        case intervalEndDate
        case buckets
    }
    
    public init(from decoder: Decoder) throws {
        
        let intervalContainer = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intervalStartDate = try intervalContainer.decodeIfPresent(Date.self, forKey: CodingKeys.intervalStartDate),
           let intervalEndDate = try intervalContainer.decodeIfPresent(Date.self, forKey: CodingKeys.intervalEndDate) {
            self.interval = DateInterval(start: intervalStartDate, end: intervalEndDate)
        } else {
            self.interval = nil
        }
        
        // Flatten the JSON schema by collapsing the .buckets.buckets structure
        let outerBucketsContainer = try intervalContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.buckets)
        self.buckets = try outerBucketsContainer.decode([MachineMeasurementValueDTO.Bucket].self, forKey: CodingKeys.buckets)
    }
}


extension MachineMeasurementValueDTO.Bucket: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case actualStartDate
        case actualEndDate
        case value
        case sequenceNumber
        case count
    }
    
    public init(from decoder: Decoder) throws {
        
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intervalStartDate = try keyedContainer.decodeIfPresent(Date.self, forKey: CodingKeys.actualStartDate),
           let intervalEndDate = try keyedContainer.decodeIfPresent(Date.self, forKey: CodingKeys.actualEndDate) {
            self.actualDateInterval = DateInterval(start: intervalStartDate, end: intervalEndDate)
        } else {
            self.actualDateInterval = nil
        }
        
        self.value = try keyedContainer.decode(Double.self, forKey: CodingKeys.value)
        self.sequenceNumber = try keyedContainer.decode(String.self, forKey: CodingKeys.sequenceNumber)
        self.count = try keyedContainer.decode(String.self, forKey: CodingKeys.count)
    }
}


// MARK: - API Requests
/// Request a machine measurement for a perticular machine.
public struct GetMachineMeasurementRequest: ConfigurableAPIRequest, JSONDeserializableResponse, AxiomPagination {
   
    public typealias ResponseType = AxiomV3List<MachineMeasurementValueDTO>
    
    public var baseURLByEnvironment: [DeereAPIEnvironment : URL?] = axiomBaseURLs
    public var urlComponents: URLComponents?
    public var additionalHTTPHeadersFields: [String : String]?
    
    public let startingItemIndex: Int = 0
    public let itemsPerPage: Int = 100
    
    /// - Parameter machineId: Identifier of the machine instance for which the measurements should be requested. Only telematically-enabled machines will have data available.
    /// - Parameter interval: The range of dates for which the measurements should be fetched. The way in which data is
    /// grouped within this date range depends on the value of the `series` parameter.
    /// - Parameter series: Specifies how the measurements should be grouped/aggregated over the given date range. When
    /// `.aggregated` is selected, the response will not report any date ranges and there will only be a single interval. Other choices
    /// will usually break up the requested date range into multiple intervals and each interval will identify what range of dates it covers.
    /// - Parameter measurementIds: An optional list of "measurementDefinitionIds" specifying explicitly which measurements should be returned. If nil, all possible measurements are returned.
    /// - Note: It was chosen to make `interval` required even though the API endpoint doesn't require startDate/endDate
    /// to be supplied. The API documentation says that the default behavior when no date range is given is the range from Jan 1st
    /// of the current year up until the time of the request. This default behavior is not likely to be the intended behavior, so we require
    /// that the caller explicitly provide a date range to make sure it aligns with expectations at the usage site.
    public init(machineId: String, interval: DateInterval, series: MachineMeasurementValueDTO.SeriesLevel = .aggregated, measurementIds: [MeasurementDefinitionId]? = nil) {
        
        var queryItems = [URLQueryItem]()
        
        // NOTE: This API endpoint appears to be un-usable for >1 measurement without embedding
        //  'measurementDefinition' because, without the embed, each measurement is returned without identifiers (?!?!)
        queryItems.append(URLQueryItem(name: "embed", value: "measurementDefinition"))
        queryItems.append(URLQueryItem(name: "interval", value: series.rawValue))
        
        let dateFormatter = ISO8601DateFormatter()
        queryItems.append(URLQueryItem(name: "startDate", value: dateFormatter.string(from: interval.start)))
        queryItems.append(URLQueryItem(name: "endDate", value: dateFormatter.string(from: interval.end)))
        
        // Join measurementDefinitionIds together into comma-separated string
        if let theMeasurementIds = measurementIds {
            let measurementIdsString = theMeasurementIds.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "measurementDefinitionId", value: measurementIdsString))
        }
        
        // TODO: Research what happens if results need to be paged
        urlComponents = URLComponents(string: "machines/\(machineId)/machineMeasurements", queryItems: queryItems)
    }
    
    /// Convenience initializer that synthesizes the requested date range as a specified duration immediately preceeding the time of the request.
    /// - Parameter machineId: Identifier of the machine instance for which the measurements should be requested. Only telematically-enabled machines will have data available.
    /// - Parameter component: The calendar component to use when computing the preceeding date range over which to request measurement data. The `endDate` will
    /// automatically be set as the time of the request and the `startDate` will be computed as some multiple of the supplied Calendar.Component earlier than `endDate`. For
    /// example, choosing `.day` with a value of 7 will compute a date range of the 7 days leading up to the request.
    /// - Parameter value: The multiple to be used with the given `Calendar.component` when computing the preceeding date range over which to retrieve measurements.
    /// - Parameter series: Specifies how the measurements should be grouped/aggregated over the given date range. When
    /// `.aggregated` is selected, the response will not report any date ranges and there will only be a single interval. Other choices
    /// will usually break up the requested date range into multiple intervals and each interval will identify what range of dates it covers.
    /// - Parameter measurementIds: An optional list of "measurementDefinitionIds" specifying explicitly which measurements should be returned. If nil, all possible measurements are returned.
    public init?(machineId: String, dateRangeComponent component: Calendar.Component, value: Int, series: MachineMeasurementValueDTO.SeriesLevel = .aggregated, measurementIds: [MeasurementDefinitionId]? = nil) {
        
        let endingDate = Date()  // Now
        guard let startingDate = Calendar.current.date(byAdding: component, value: -1 * value, to: endingDate) else { return nil }
        
        self.init(machineId: machineId, interval: DateInterval(start: startingDate, end: endingDate), series: series, measurementIds: measurementIds)
    }
}


extension Array where Element == MachineMeasurementValueDTO {
    
    /// Simplifies access to a specific measurement instance, identified by its MeasurementDefinitionId, from the array returned by
    /// the MachineMeasurements API.
    public subscript(id: MeasurementDefinitionId) -> MachineMeasurementValueDTO? {
        
        return self.first(where: { $0.definition.id == id })
    }
}
