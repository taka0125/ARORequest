//
//  ViewController.swift
//  ARORequestSample
//
//  Created by Takahiro Ooishi on 2016/11/19.
//  Copyright © 2016年 Takahiro Ooishi. All rights reserved.
//

import UIKit
import ARORequest
import Alamofire
import RxSwift
import ObjectMapper

struct SuccessResponse: Mappable {
  var id: Int = 0
  var uuid: String = ""
  
  init?(map: Map) {
  }
  
  mutating func mapping(map: Map) {
    id <- map["id"]
    uuid <- map["uuid"]
  }
}

struct ErrorResponse: Mappable, Error {
  var title: String = ""
  var message: String = ""
  
  init?(map: Map) {
  }
  
  mutating func mapping(map: Map) {
    title <- map["title"]
    message <- map["message"]
  }
}

protocol MyApiRequestable: ApiRequestable {
  func headers() -> HTTPHeaders
  func parameterEncoding() -> ParameterEncoding
}

extension MyApiRequestable {
  func request<S: Mappable>(
    url: URLConvertible,
    method: HTTPMethod,
    parameters: Parameters? = nil)
    -> Observable<S> {
    
    let sessionManager = SessionManager.default
    let parser = DefaultResponseParser<S, ErrorResponse>()
    
    return request(
      sessionManager: sessionManager,
      url: url,
      method: method,
      parameters: parameters,
      parameterEncoding: parameterEncoding(),
      headers: headers(),
      responseParser: parser
    )
  }
  
  func request(
    url: URLConvertible,
    method: HTTPMethod,
    parameters: Parameters? = nil)
    -> Observable<NullResponse> {
      let sessionManager = SessionManager.default
      let parser = NullSuccessResponseParser<ErrorResponse>()
      
      return request(
        sessionManager: sessionManager,
        url: url,
        method: method,
        parameters: parameters,
        parameterEncoding: parameterEncoding(),
        headers: headers(),
        responseParser: parser
      )
  }
}

class ViewController: UITableViewController {
  enum Row: Int {
    case successExample
    case errorExample
    case nullResponseExample
    case myApiRequestableSuccessExample
    case myApiRequestableErrorExample
    
    var text: String {
      switch self {
      case .successExample: return "Success Example"
      case .errorExample: return "Error Example"
      case .nullResponseExample: return "Null Response Example"
      case .myApiRequestableSuccessExample: return "My ApiRequestable Success Example"
      case .myApiRequestableErrorExample: return "My ApiRequestable Error Example"
      }
    }
    
    static var count: Int { return myApiRequestableErrorExample.rawValue + 1 }
  }
  
  let disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    tableView.rowHeight = 44.0
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return Row.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let row = Row(rawValue: indexPath.row) else { return UITableViewCell() }
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    cell.textLabel?.text = row.text
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    defer { tableView.deselectRow(at: indexPath, animated: true) }
    
    guard let row = Row(rawValue: indexPath.row) else { return }
    
    switch row {
    case .successExample:
      doSuccessExample()
    case .errorExample:
      doErrorExample()
    case .nullResponseExample:
      doNullResponseExample()
    case .myApiRequestableSuccessExample:
      doMyApiRequestableSuccessExample()
    case .myApiRequestableErrorExample:
      doMyApiRequestableErrorExample()
    }
  }
}

extension ViewController: ApiRequestable {
  fileprivate func doSuccessExample() {
    let sessionManager = SessionManager.default
    let url = "http://localhost:4567/success.json"
    let responseParser = DefaultResponseParser<SuccessResponse, ErrorResponse>()

    request(
      sessionManager: sessionManager,
      url: url,
      method: .get,
      parameters: nil,
      parameterEncoding: URLEncoding.default,
      headers: nil,
      responseParser: responseParser
    ).subscribe { (event) in
      print(event)
    }.addDisposableTo(disposeBag)
  }

  fileprivate func doErrorExample() {
    let sessionManager = SessionManager.default
    let url = "http://localhost:4567/error.json"
    let responseParser = DefaultResponseParser<SuccessResponse, ErrorResponse>()
    
    request(
      sessionManager: sessionManager,
      url: url,
      method: .get,
      parameters: nil,
      parameterEncoding: URLEncoding.default,
      headers: nil,
      responseParser: responseParser
    ).subscribe { (event) in
      print(event)
    }.addDisposableTo(disposeBag)
  }

  fileprivate func doNullResponseExample() {
    let sessionManager = SessionManager.default
    let url = "http://localhost:4567/error.json"
    let responseParser = NullResponseParser()
    
    request(
      sessionManager: sessionManager,
      url: url,
      method: .get,
      parameters: nil,
      parameterEncoding: URLEncoding.default,
      headers: nil,
      responseParser: responseParser
    ).subscribe { (event) in
      print(event)
    }.addDisposableTo(disposeBag)
  }
}

extension ViewController: MyApiRequestable {
  internal func headers() -> HTTPHeaders {
    return ["X-MyApp-Name": "sample"]
  }

  internal func parameterEncoding() -> ParameterEncoding {
    return URLEncoding.default
  }

  fileprivate func doMyApiRequestableSuccessExample() {
    let url = "http://localhost:4567/success.json"
    
    request(url: url, method: .get, parameters: nil).subscribe { (event: Event<SuccessResponse>) in
      print(event)
    }.addDisposableTo(disposeBag)
  }
  
  fileprivate func doMyApiRequestableErrorExample() {
    let url = "http://localhost:4567/error.json"

    request(url: url, method: .get, parameters: nil).subscribe { (event) in
      print(event)
    }.addDisposableTo(disposeBag)
  }
}
