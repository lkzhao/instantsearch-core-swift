//
//  Copyright (c) 2016 Algolia
//  http://www.algolia.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import AlgoliaSearch
import Foundation


/// Match level of a highlight or snippet result (internal version).
private enum MatchLevel_: String {
    case Full = "full"
    case Partial = "partial"
    case None = "none"
}

/// Match level of a highlight or snippet result.
@objc public enum MatchLevel: Int {
    case Full = 2
    case Partial = 1
    case None = 0
}

/// Convert a pure Swift enum into an Objective-C bridgeable one.
private func swift2Objc(matchLevel: MatchLevel_?) -> MatchLevel {
    if let level = matchLevel {
        switch level {
        case .Full: return .Full
        case .Partial: return .Partial
        case .None: return .None
        }
    }
    return .None
}

/// Highlight result for an attribute of a hit.
///
/// **Note:** Wraps the raw JSON returned by the API.
///
@objc public class HighlightResult: NSObject {
    /// The wrapped JSON object.
    @objc public let json: [String: AnyObject]
    
    /// Value of this highlight.
    @objc public var value: String
    
    /// Match level.
    @objc public var matchLevel: MatchLevel
    
    /// List of matched words.
    @objc public var matchedWords: [String]
    
    internal init?(json: [String: AnyObject]) {
        self.json = json
        guard
            let value = json["value"] as? String,
            let matchLevelString = json["matchLevel"] as? String,
            let matchLevel_ = MatchLevel_(rawValue: matchLevelString),
            let matchedWords = json["matchedWords"] as? [String]
        else {
            return nil
        }
        self.value = value
        self.matchLevel = swift2Objc(matchLevel_)
        self.matchedWords = matchedWords
    }
}

/// Snippet result for an attribute of a hit.
///
/// **Note:** Wraps the raw JSON returned by the API.
///
@objc public class SnippetResult: NSObject {
    /// The wrapped JSON object.
    @objc public let json: [String: AnyObject]
    
    /// Value of this snippet.
    @objc public var value: String
    
    /// Match level.
    @objc public var matchLevel: MatchLevel
    
    internal init?(json: [String: AnyObject]) {
        self.json = json
        guard
            let value = json["value"] as? String,
            let matchLevelString = json["matchLevel"] as? String,
            let matchLevel_ = MatchLevel_(rawValue: matchLevelString)
            else {
                return nil
        }
        self.value = value
        self.matchLevel = swift2Objc(matchLevel_)
    }
}

/// Ranking info for a hit.
///
/// **Note:** Wraps the raw JSON returned by the API.
///
@objc public class RankingInfo: NSObject {
    /// The wrapped JSON object.
    @objc public let json: [String: AnyObject]
    
    @objc public var nbTypos: Int { return json["nbTypos"] as? Int ?? 0 }
    @objc public var firstMatchedWord: Int { return json["firstMatchedWord"] as? Int ?? 0 }
    @objc public var proximityDistance: Int { return json["proximityDistance"] as? Int ?? 0 }
    @objc public var userScore: Int { return json["userScore"] as? Int ?? 0 }
    @objc public var geoDistance: Int { return json["geoDistance"] as? Int ?? 0 }
    @objc public var geoPrecision: Int { return json["geoPrecision"] as? Int ?? 0 }
    @objc public var nbExactWords: Int { return json["nbExactWords"] as? Int ?? 0 }
    @objc public var words: Int { return json["words"] as? Int ?? 0 }
    @objc public var filters: Int { return json["filters"] as? Int ?? 0 }
    
    internal init(json: [String: AnyObject]) {
        self.json = json
    }
}

/// A value of a given facet, together with its number of occurrences.
///
@objc public class FacetValue: NSObject {
    @objc public let value: String
    @objc public let count: Int
    
    internal init(value: String, count: Int) {
        self.value = value
        self.count = count
    }
}

/// Statistics for a numerical facet.
/// + NOTE: Since values may either be integers or floats, they are typed as `NSNumber`.
@objc public class FacetStats: NSObject {
    /// The minimum value.
    @objc public let min: NSNumber
    /// The maximum value.
    @objc public let max: NSNumber
    /// The average of all values.
    @objc public let avg: NSNumber
    /// The sum of all values.
    @objc public let sum: NSNumber
    
    internal init(min: NSNumber, max: NSNumber, avg: NSNumber, sum: NSNumber) {
        self.min = min
        self.max = max
        self.avg = avg
        self.sum = sum
    }
}


/// Search results.
///
/// **Note:** Wraps the raw JSON returned by the API.
///
@objc public class SearchResults: NSObject {
    /// The received JSON content.
    @objc public let content: [String: AnyObject]
    
    /// Facets that will be treated as disjunctive (`OR`). By default, facets are conjunctive (`AND`).
    @objc public let disjunctiveFacets: [String]
    
    // MARK: - Fields

    /// Hits.
    @objc public let hits: [[String: AnyObject]]
    
    /// Facets for the last results. Lazily computed; accessed through `facets()`.
    private var facets: [String: [FacetValue]] = [:]

    /// Total number of hits.
    @objc public var nbHits: Int

    /// Last returned page.
    @objc public var page: Int { return content["page"] as? Int ?? 0 }

    /// Total number of pages.
    @objc public var nbPages: Int { return content["nbPages"] as? Int ?? 0 }
    
    /// Number of hits per page.
    @objc public var hitsPerPage: Int { return content["hitsPerPage"] as? Int ?? 0 }
    
    /// Processing time of the last query (in ms).
    @objc public var processingTimeMS: Int
    
    /// Query text that produced these results.
    ///
    /// + NOTE: Should be identical to `params.query`.
    ///
    @objc public var query: String
    
    /// Query that produced these results.
    @objc public var params: Query
    
    /// Whether facet counts are exhaustive.
    @objc public var exhaustiveFacetsCount: Bool { return content["exhaustiveFacetsCount"] as? Bool ?? false }
    
    /// Used to return warnings about the query. Should be nil most of the time.
    @objc public var message: String? { return content["message"] as? String }
    
    /// A markup text indicating which parts of the original query have been removed in order to retrieve a non-empty
    /// result set. The removed parts are surrounded by `<em>` tags.
    ///
    /// + NOTE: Only returned when `removeWordsIfNoResults` is set.
    ///
    @objc public var queryAfterRemoval: String? { return content["queryAfterRemoval"] as? String }

    /// The computed geo location.
    ///
    /// + NOTE: Only returned when `aroundLatLngViaIP` is set.
    ///
    @objc public var aroundLatLng: LatLng? {
        // WARNING: For legacy reasons, this parameter is returned as a string and not an object.
        // Format: `${lat},${lng}`, where the latitude and longitude are expressed as decimal floating point numbers.
        if let stringValue = content["aroundLatLng"] as? String {
            let components = stringValue.componentsSeparatedByString(",")
            if components.count == 2 {
                if let lat = Double(components[0]), let lng = Double(components[1]) {
                    return LatLng(lat: lat, lng: lng)
                }
            }
        }
        return nil
    }
    
    /// The automatically computed radius.
    ///
    /// + NOTE: Only returned for geo queries without an explicitly specified radius (see `aroundRadius`).
    ///
    @objc public var automaticRadius: Int {
        // WARNING: For legacy reasons, this parameter is returned as a string and not an integer.
        if let stringValue = content["automaticRadius"] as? String, let intValue = Int(stringValue) {
            return intValue
        }
        return 0
    }
    
    // MARK: Only when `getRankingInfo` = true

    /// Actual host name of the server that processed the request. (Our DNS supports automatic failover and load
    /// balancing, so this may differ from the host name used in the request.)
    ///
    /// + NOTE: Only returned when `getRankingInfo` is true.
    ///
    @objc public var serverUsed: String? { return content["serverUsed"] as? String }
    
    /// The query string that will be searched, after normalization.
    ///
    /// + NOTE: Only returned when `getRankingInfo` is true.
    ///
    @objc public var parsedQuery: String? { return content["parsedQuery"] as? String }
    
    /// Whether a timeout was hit when computing the facet counts. When true, the counts will be interpolated
    /// (i.e. approximate). See also `exhaustiveFacetsCount`.
    ///
    /// + NOTE: Only returned when `getRankingInfo` is true.
    ///
    @objc public var timeoutCounts: Bool { return content["timeoutCounts"] as? Bool ?? false }
    
    /// Whether a timeout was hit when retrieving the hits. When true, some results may be missing.
    ///
    /// + NOTE: Only returned when `getRankingInfo` is true.
    ///
    @objc public var timeoutHits: Bool { return content["timeoutHits"] as? Bool ?? false }

    // MARK: - Initialization, termination
    
    /// Create search results from an initial response from the API.
    @objc public init(content: [String: AnyObject], disjunctiveFacets: [String]) throws {
        self.content = content
        self.disjunctiveFacets = disjunctiveFacets
        
        // Validate mandatory fields.
        guard let hits = content["hits"] as? [[String: AnyObject]] else {
            throw NSError(domain: ErrorDomain, code: StatusCode.InvalidResponse.rawValue, userInfo: [ NSLocalizedDescriptionKey: "Invalid response: expecting attribute `hits` of type array of objects" ])
        }
        self.hits = hits
        
        guard let nbHits = content["nbHits"] as? Int else {
            throw NSError(domain: ErrorDomain, code: StatusCode.InvalidResponse.rawValue, userInfo: [ NSLocalizedDescriptionKey: "Invalid response: expecting attribute `nbHits` of type `Int`" ])
        }
        self.nbHits = nbHits
        
        guard let processingTimeMS = content["processingTimeMS"] as? Int else {
            throw NSError(domain: ErrorDomain, code: StatusCode.InvalidResponse.rawValue, userInfo: [ NSLocalizedDescriptionKey: "Invalid response: expecting attribute `processingTimeMS` of type `Int`" ])
        }
        self.processingTimeMS = processingTimeMS
        
        guard let query = content["query"] as? String else {
            throw NSError(domain: ErrorDomain, code: StatusCode.InvalidResponse.rawValue, userInfo: [ NSLocalizedDescriptionKey: "Invalid response: expecting attribute `query` of type `String`" ])
        }
        self.query = query
        
        guard let params = content["params"] as? String else {
            throw NSError(domain: ErrorDomain, code: StatusCode.InvalidResponse.rawValue, userInfo: [ NSLocalizedDescriptionKey: "Invalid response: expecting attribute `params` of type `String`" ])
        }
        self.params = Query.parse(params)
    }
    
    // MARK: - Accessors
    
    /// Retrieve the facet values for a given facet.
    ///
    /// - parameter name: Facet name.
    /// - parameter disjunctive: true if this is a disjunctive facet, false if it's a conjunctive facet (default).
    /// - returns: The corresponding facet values.
    ///
    @objc public func facets(name: String) -> [FacetValue]? {
        // Use stored values if available.
        if let values = facets[name] {
            return values
        }
        // If the facet was not requested, return nil.
        else if !(params.facets?.contains(name) ?? false) {
            return nil
        }
        // Otherwise lazily compute the values.
        else {
            let disjunctive = disjunctiveFacets.contains(name)
            guard let returnedFacets = content[disjunctive ? "disjunctiveFacets" : "facets"] as? [String: AnyObject] else { return nil }
            var values = [FacetValue]()
            let returnedValues = returnedFacets[name] as? [String: Int]
            if let returnedValues = returnedValues {
                for (value, count) in returnedValues {
                    values.append(FacetValue(value: value, count: count))
                }
            }
            // Make sure there is a value at least for the refined values.
            let queryHelper = QueryHelper(query: params)
            let facetRefinements = queryHelper.getFacetRefinements() { $0.name == name }
            for facetRefinement in facetRefinements {
                if returnedValues?[facetRefinement.value] == nil {
                    values.append(FacetValue(value: facetRefinement.value, count: 0))
                }
            }
            // Remember values for later use.
            self.facets[name] = values
            return values
        }
    }
    
    /// Retrieve the statistics for a numerical facet.
    ///
    /// - parameter name: The facet's name.
    /// - returns: The statistics for this facet, or nil if this facet does not exist or is not a numerical facet.
    ///
    @objc public func facetStats(name: String) -> FacetStats? {
        guard let allStats = content["facets_stats"] as? [String: AnyObject] else { return nil }
        guard let facetStats = allStats[name] as? [String: AnyObject] else { return nil }
        guard
            let min = facetStats["min"] as? NSNumber,
            let max = facetStats["max"] as? NSNumber,
            let avg = facetStats["avg"] as? NSNumber,
            let sum = facetStats["sum"] as? NSNumber
        else {
            return nil
        }
        return FacetStats(min: min, max: max, avg: avg, sum: sum)
    }
    
    /// Get the highlight result for an attribute of a hit.
    @objc public func highlightResult(index: Int, path: String) -> HighlightResult? {
        return SearchResults.getHighlightResult(hits[index], path: path)
    }

    /// Get the snippet result for an attribute of a hit.
    @objc public func snippetResult(index: Int, path: String) -> SnippetResult? {
        return SearchResults.getSnippetResult(hits[index], path: path)
    }

    /// Get the ranking information for a hit.
    ///
    /// **Note:** Only available when `getRankingInfo` was set to true on the query.
    ///
    /// - parameter index: Index of the hit in the hits array.
    /// - returns: The corresponding ranking information, or nil if no ranking information is available.
    ///
    @objc public func rankingInfo(index: Int) -> RankingInfo? {
        if let rankingInfo = hits[index]["_rankingInfo"] as? [String: AnyObject] {
            return RankingInfo(json: rankingInfo)
        } else {
            return nil
        }
    }
    
    // MARK: - Utils
    
    /// Retrieve the highlight result corresponding to an attribute inside the JSON representation of a hit.
    ///
    /// - parameter hit: The JSON object for a hit.
    /// - parameter path: Path of the attribute to retrieve, in dot notation.
    /// - returns: The highlight result, or nil if not available.
    ///
    @objc public static func getHighlightResult(hit: [String: AnyObject], path: String) -> HighlightResult? {
        guard let highlights = hit["_highlightResult"] as? [String: AnyObject] else { return nil }
        guard let attribute = JSONHelper.valueForKeyPath(highlights, path: path) as? [String: AnyObject] else { return nil }
        return HighlightResult(json: attribute)
    }
    
    /// Retrieve the snippet result corresponding to an attribute inside the JSON representation of a hit.
    ///
    /// - parameter hit: The JSON object for a hit.
    /// - parameter path: Path of the attribute to retrieve, in dot notation.
    /// - returns: The snippet result, or nil if not available.
    ///
    @objc public static func getSnippetResult(hit: [String: AnyObject], path: String) -> SnippetResult? {
        guard let snippets = hit["_snippetResult"] as? [String: AnyObject] else { return nil }
        guard let attribute = JSONHelper.valueForKeyPath(snippets, path: path) as? [String: AnyObject] else { return nil }
        return SnippetResult(json: attribute)
    }
}
