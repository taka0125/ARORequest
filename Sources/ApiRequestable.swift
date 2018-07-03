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

public protocol RequestableDelegate {
  func requestable(_ requestable:ApiRequestable, didSendRequest request: DataRequest)
  func requestable(_ requestable:ApiRequestable, didUploadRequest request: UploadRequest)
  func requestable(_ requestable:ApiRequestable, didReceiveResponse response: DataResponse<String>)
}

public protocol ApiRequestable {
  func request<ResponseParser: ResponseParserProtocol>(
    sessionManager: SessionManager,
    url: URLConvertible,
    method: HTTPMethod,
    parameters: Parameters?,
    parameterEncoding: ParameterEncoding,
    headers: HTTPHeaders?,
    responseParser: ResponseParser,
    delegate: RequestableDelegate?)
    -> Observable<ResponseParser.SuccessResponse>
  
  func uploadRequest<ResponseParser: ResponseParserProtocol>(
    sessionManager: SessionManager,
    multipartFormData: @escaping (MultipartFormData) -> Void,
    usingThreshold: UInt64,
    to: URLConvertible,
    method: HTTPMethod,
    headers: HTTPHeaders?,
    responseParser: ResponseParser,
    delegate: RequestableDelegate?)
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
    responseParser: ResponseParser,
    delegate: RequestableDelegate? = nil)
    -> Observable<ResponseParser.SuccessResponse>
  {
    return callApiTask(
      sessionManager: sessionManager,
      url: url,
      method: method,
      parameters: parameters,
      parameterEncoding: parameterEncoding,
      headers: headers,
      responseParser: responseParser,
      delegate: delegate
    )
    .flatMap { self.parseSuccessResponseTask(responseParser: responseParser, response: $0) }
    .do(
      onError: { _ in self.updateRequestStatus(.error) },
      onCompleted: { self.updateRequestStatus(.success) }
    )
  }
  
  public func uploadRequest<ResponseParser: ResponseParserProtocol>(
    sessionManager: SessionManager,
    multipartFormData: @escaping (MultipartFormData) -> Void,
    usingThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
    to: URLConvertible,
    method: HTTPMethod = .post,
    headers: HTTPHeaders? = nil,
    responseParser: ResponseParser,
    delegate: RequestableDelegate? = nil)
    -> Observable<ResponseParser.SuccessResponse>
  {
    return callUploadApiTask(
      sessionManager: sessionManager,
      multipartFormData: multipartFormData,
      usingThreshold: usingThreshold,
      to: to,
      method: method,
      headers: headers,
      responseParser: responseParser,
      delegate: delegate
    )
    .flatMap { self.parseSuccessResponseTask(responseParser: responseParser, response: $0) }
    .do(
      onError: { _ in self.updateRequestStatus(.error) },
      onCompleted: { self.updateRequestStatus(.success) }
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
    responseParser: ResponseParser,
    delegate: RequestableDelegate?)
    -> Observable<DataResponse<String>>
  {
    return Observable.create { observer in
      self.updateRequestStatus(.requesting)

      let dataRequest = sessionManager.request(
        url,
        method: method,
        parameters: parameters,
        encoding: parameterEncoding,
        headers: headers
      )
      .validate()
      .responseString(completionHandler: { response in
        self.handleResponse(response: response, responseParser: responseParser, observer: observer, delegate: delegate)
      })
      
      delegate?.requestable(self, didSendRequest: dataRequest)

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
    responseParser: ResponseParser,
    delegate: RequestableDelegate?)
    -> Observable<DataResponse<String>>
  {
    return Observable.create { observer in
      self.updateRequestStatus(.requesting)

      let encodingCompletion:((SessionManager.MultipartFormDataEncodingResult) -> Void)? = { (result) in
        switch result {
        case .success(request: let request, streamingFromDisk: _, streamFileURL: _):
          delegate?.requestable(self, didUploadRequest: request)
          request.validate()
            .responseString(completionHandler: { response in
              self.handleResponse(response: response, responseParser: responseParser, observer: observer, delegate: delegate)
            })
        case .failure(let error):
          observer.onError(error)
        }
      }

      do {
        let urlRequest = try URLRequest(url: url, method: method, headers: headers)

        sessionManager.upload(
          multipartFormData: multipartFormData,
          usingThreshold: usingThreshold,
          with: urlRequest,
          encodingCompletion: encodingCompletion
        )
      } catch {
        DispatchQueue.main.async { encodingCompletion?(.failure(error)) }
      }
      
      return Disposables.create()
    }
  }
  
  private func handleResponse<ResponseParser: ResponseParserProtocol>(response: DataResponse<String>, responseParser: ResponseParser, observer: AnyObserver<DataResponse<String>>, delegate:RequestableDelegate?) {
    guard response.result.isSuccess else {
      if let result = responseParser.parseErrorResponse(response: response) {
        delegate?.requestable(self, didReceiveResponse: response)
        observer.onError(result)
      } else {
        observer.onError(AROError.requestFailed(response: response))
      }
      
      return
    }
    
    delegate?.requestable(self, didReceiveResponse: response)
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
