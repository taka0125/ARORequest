//
//  ApiRequestable.swift
//
//  Created by Takahiro Ooishi
//  Copyright (c) 2016 Takahiro Ooishi. All rights reserved.
//  Released under the MIT license.
//

import Alamofire
import ObjectMapper

public protocol ResponseParserProtocol {
  associatedtype SuccessResponse: AROMappable
  associatedtype ErrorResponse: AROMappable, Error
  
  func parseSuccessResponse(response: DataResponse<String>) -> SuccessResponse?
  func parseErrorResponse(response: DataResponse<String>) -> ErrorResponse?
}

public extension ResponseParserProtocol {
  public func parseSuccessResponse(response: DataResponse<String>) -> SuccessResponse? {
    guard let value = response.result.value else { return nil }
    guard let result = SuccessResponse.decode(JSONString: value) else { return nil }
    return result
  }
  
  public func parseErrorResponse(response: DataResponse<String>) -> ErrorResponse? {
    guard let data = response.data else { return nil }
    guard let JSONString = String(data: data, encoding: .utf8) else { return nil }
    guard let result = ErrorResponse.decode(JSONString: JSONString) else { return nil }
    return result
  }
}

public struct NullResponse: AROMappable, Mappable {
  public init?(map: Map) {
  }
  
  public mutating func mapping(map: Map) {
  }
}

public struct NullErrorResponse: AROMappable, Mappable, Error {
  public init?(map: Map) {
  }
  
  public mutating func mapping(map: Map) {
  }
}

public struct NullSuccessResponseParser<E: AROMappable & Error>: ResponseParserProtocol {
  public typealias SuccessResponse = NullResponse
  public typealias ErrorResponse = E

  public init() {
  }
}

public struct NullErrorResponseParser<S: AROMappable>: ResponseParserProtocol {
  public typealias SuccessResponse = S
  public typealias ErrorResponse = NullErrorResponse
  
  public init() {
  }
}

public struct NullResponseParser: ResponseParserProtocol {
  public typealias SuccessResponse = NullResponse
  public typealias ErrorResponse = NullErrorResponse
  
  public init() {
  }
}

public struct DefaultResponseParser<S: AROMappable, E: AROMappable & Error>: ResponseParserProtocol {
  public typealias SuccessResponse = S
  public typealias ErrorResponse = E

  public init() {
  }
}
