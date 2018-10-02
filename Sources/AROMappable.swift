//
//  AROMappable.swift
//  Alamofire
//
//  Created by Tomoya Hirano on 2018/10/02.
//

import Foundation
import ObjectMapper

public protocol AROMappable {
  static func decode(JSONString json: String) -> Self?
}

extension AROMappable where Self: Mappable {
  public static func decode(JSONString json: String) -> Self? {
    return Mapper<Self>().map(JSONString: json)
  }
}

extension AROMappable where Self: Decodable {
  public static func decode(JSONString json: String) -> Self? {
    guard let data = json.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(self, from: data)
  }
}
