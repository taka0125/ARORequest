//
//  AROError.swift
//
//  Created by Takahiro Ooishi
//  Copyright (c) 2016 Takahiro Ooishi. All rights reserved.
//  Released under the MIT license.
//

import Alamofire
import ObjectMapper

public enum AROError: Error {
  case requestFailed(response: DataResponse<String>)
  case parseSuccessResponseFailed(response: DataResponse<String>)
}
