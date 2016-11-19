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
  associatedtype SuccessResponse: Mappable
  associatedtype ErrorResponse: Mappable, Error
  
  func parseSuccessResponse(response: DataResponse<String>) -> SuccessResponse?
  func parseErrorResponse(response: DataResponse<String>) -> ErrorResponse?
}

public extension ResponseParserProtocol {
  public func parseSuccessResponse(response: DataResponse<String>) -> SuccessResponse? {
    guard let value = response.result.value else { return nil }
    guard let result = Mapper<SuccessResponse>().map(JSONString: value) else { return nil }
    return result
  }
  
  public func parseErrorResponse(response: DataResponse<String>) -> ErrorResponse? {
    guard let data = response.data else { return nil }
    guard let JSONString = String(data: data, encoding: .utf8) else { return nil }
    guard let result = Mapper<ErrorResponse>().map(JSONString: JSONString) else { return nil }
    return result
  }
}

public struct NullResponse: Mappable {
  public init?(map: Map) {
  }
  
  public mutating func mapping(map: Map) {
  }
}

public struct NullErrorResponse: Mappable, Error {
  public init?(map: Map) {
  }
  
  public mutating func mapping(map: Map) {
  }
}

public struct NullSuccessResponseParser<E: Mappable & Error>: ResponseParserProtocol {
  public typealias SuccessResponse = NullResponse
  public typealias ErrorResponse = E

  public init() {
  }
}

public struct NullErrorResponseParser<S: Mappable>: ResponseParserProtocol {
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

public struct DefaultResponseParser<S: Mappable, E: Mappable & Error>: ResponseParserProtocol {
  public typealias SuccessResponse = S
  public typealias ErrorResponse = E

  public init() {
  }
}
