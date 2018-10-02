//
//  ARORequestTests.swift
//  ARORequestTests
//
//  Created by Tomoya Hirano on 2018/10/02.
//  Copyright © 2018年 Takahiro Ooishi. All rights reserved.
//

import XCTest
import ObjectMapper
@testable import ARORequest

class MappableObject: NSObject, AROMappable, Mappable {
  var title: String = ""
  
  required init?(map: Map) {
    super.init()
    mapping(map: map)
  }
  
  func mapping(map: Map) {
    title <- map["title"]
  }
}

class DecodableObject: AROMappable, Decodable {
  let title: String
}

class ARORequestTests: XCTestCase {
  func testMappingObjectMapper() {
    let object = MappableObject.decode(JSONString: "{\"title\" : \"hoge\"}")
    XCTAssertEqual(object?.title, "hog")
  }
  
  func testMappingDecodable() {
    let object = DecodableObject.decode(JSONString: "{\"title\" : \"hoge\"}")
    XCTAssertEqual(object?.title, "hog")
  }
}

