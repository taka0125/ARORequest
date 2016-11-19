//
//  ApiRequestable.swift
//
//  Created by Takahiro Ooishi
//  Copyright (c) 2016 Takahiro Ooishi. All rights reserved.
//  Released under the MIT license.
//

import Foundation
import Alamofire
import RxSwift
import ObjectMapper

public protocol RequestStatusObservable {
  var requestStatus: BehaviorSubject<RequestState> { get }
}

public protocol ApiRequestable {
  func request<ResponseParser: ResponseParserProtocol>(
    sessionManager: SessionManager,
    url: URLConvertible,
    method: HTTPMethod,
    parameters: Parameters?,
    parameterEncoding: ParameterEncoding,
    headers: HTTPHeaders?,
    responseParser: ResponseParser)
    -> Observable<ResponseParser.SuccessResponse>
  
  func uploadRequest<ResponseParser: ResponseParserProtocol>(
    sessionManager: SessionManager,
    multipartFormData: @escaping (MultipartFormData) -> Void,
    usingThreshold: UInt64,
    to: URLConvertible,
    method: HTTPMethod,
    headers: HTTPHeaders?,
    responseParser: ResponseParser)
    -> Observable<ResponseParser.SuccessResponse>
  
  func updateRequestStatus(_ requestState: RequestState)
}

public extension ApiRequestable {
  public func request<ResponseParser: ResponseParserProtocol>(
    sessionManager: SessionManager,
    url: URLConvertible,
    method: HTTPMethod = .get,
    parameters: Parameters? = nil,
    parameterEncoding: ParameterEncoding = URLEncoding.default,
    headers: HTTPHeaders? = nil,
    responseParser: ResponseParser)
    -> Observable<ResponseParser.SuccessResponse>
  {
    return callApiTask(
      sessionManager: sessionManager,
      url: url,
      method: method,
      parameters: parameters,
      parameterEncoding: parameterEncoding,
      headers: headers,
      responseParser: responseParser
    )
    .flatMap { self.parseSuccessResponseTask(responseParser: responseParser, response: $0) }
    .do(
      onError: { _ in self.updateRequestStatus(.error) },
      onCompleted: { _ in self.updateRequestStatus(.success) }
    )
  }
  
  public func uploadRequest<ResponseParser: ResponseParserProtocol>(
    sessionManager: SessionManager,
    multipartFormData: @escaping (MultipartFormData) -> Void,
    usingThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
    to: URLConvertible,
    method: HTTPMethod = .post,
    headers: HTTPHeaders? = nil,
    responseParser: ResponseParser)
    -> Observable<ResponseParser.SuccessResponse>
  {
    return callUploadApiTask(
      sessionManager: sessionManager,
      multipartFormData: multipartFormData,
      usingThreshold: usingThreshold,
      to: to,
      method: method,
      headers: headers,
      responseParser: responseParser
    )
    .flatMap { self.parseSuccessResponseTask(responseParser: responseParser, response: $0) }
    .do(
      onError: { _ in self.updateRequestStatus(.error) },
      onCompleted: { _ in self.updateRequestStatus(.success) }
    )
  }

  public func updateRequestStatus(_ requestState: RequestState) {
  }
  
  private func callApiTask<ResponseParser: ResponseParserProtocol>(
    sessionManager: SessionManager,
    url: URLConvertible,
    method: HTTPMethod,
    parameters: Parameters?,
    parameterEncoding: ParameterEncoding,
    headers: HTTPHeaders?,
    responseParser: ResponseParser)
    -> Observable<DataResponse<String>>
  {
    return Observable.create { observer in
      self.updateRequestStatus(.requesting)

      sessionManager.request(
        url,
        method: method,
        parameters: parameters,
        encoding: parameterEncoding,
        headers: headers
      )
      .validate()
      .responseString(completionHandler: { response in
        self.handleResponse(response: response, responseParser: responseParser, observer: observer)
      })

      return Disposables.create()
    }
  }
  
  private func callUploadApiTask<ResponseParser: ResponseParserProtocol>(
    sessionManager: SessionManager,
    multipartFormData: @escaping (MultipartFormData) -> Void,
    usingThreshold: UInt64,
    to url: URLConvertible,
    method: HTTPMethod,
    headers: HTTPHeaders?,
    responseParser: ResponseParser)
    -> Observable<DataResponse<String>>
  {
    return Observable.create { observer in
      self.updateRequestStatus(.requesting)
      
      sessionManager.upload(
        multipartFormData: multipartFormData,
        usingThreshold: usingThreshold,
        to: url,
        method: method,
        headers: headers,
        encodingCompletion: { (result) in
          switch result {
          case .success(request: let request, streamingFromDisk: _, streamFileURL: _):
            request.validate()
              .responseString(completionHandler: { response in
                self.handleResponse(response: response, responseParser: responseParser, observer: observer)
              })
          case .failure(let error):
            observer.onError(error)
          }
        }
      )
      
      return Disposables.create()
    }
  }
  
  private func handleResponse<ResponseParser: ResponseParserProtocol>(response: DataResponse<String>, responseParser: ResponseParser, observer: AnyObserver<DataResponse<String>>) {
    guard response.result.isSuccess else {
      if let result = responseParser.parseErrorResponse(response: response) {
        observer.onError(result)
      } else {
        observer.onError(AROError.requestFailed(response: response))
      }
      
      return
    }
    
    observer.onNext(response)
    observer.onCompleted()
  }
  
  private func parseSuccessResponseTask<ResponseParser: ResponseParserProtocol>(responseParser: ResponseParser, response: DataResponse<String>) -> Observable<ResponseParser.SuccessResponse> {
    return Observable.create { observer in
      DispatchQueue.global(qos: .userInteractive).async {
        guard let result = responseParser.parseSuccessResponse(response: response) else {
          observer.onError(AROError.parseSuccessResponseFailed(response: response))
          
          return
        }

        observer.onNext(result)
        observer.onCompleted()
      }
      
      return Disposables.create()
    }
  }
}

public extension ApiRequestable where Self: RequestStatusObservable {
  func updateRequestStatus(_ requestState: RequestState) {
    requestStatus.onNext(requestState)
  }
}
