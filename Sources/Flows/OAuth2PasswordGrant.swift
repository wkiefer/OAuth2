//
//  OAuth2PasswordGrant.swift
//  OAuth2
//
//  Created by Tim Sneed on 6/5/15.
//  Copyright (c) 2015 Pascal Pfiffner. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
#if !NO_MODULE_IMPORT
import Base
#endif


/**
A class to handle authorization for clients via password grant.
*/
open class OAuth2PasswordGrant: OAuth2 {
	
	override open class var grantType: String {
		return "password"
	}
	
	/// Username to use during authentication.
	open var username: String
	
	/// The user's password.
	open var password: String
	
	/**
	Adds support for the "password" & "username" setting.
	*/
	override public init(settings: OAuth2JSON) {
		username = settings["username"] as? String ?? ""
		password = settings["password"] as? String ?? ""
		super.init(settings: settings)
	}
	
	override open func doAuthorize(params: [String : String]? = nil) {
		self.obtainAccessToken(params: params) { params, error in
			if let error = error {
				self.didFail(withError: error)
			}
			else {
				self.didAuthorize(withParameters: params ?? OAuth2JSON())
			}
		}
	}
	
	/**
	Create a token request and execute it to receive an access token.
	
	- parameter callback: The callback to call after the request has returned
	*/
	func obtainAccessToken(params: OAuth2StringDict? = nil, callback: ((_ params: OAuth2JSON?, _ error: Error?) -> Void)) {
		do {
			let post = try tokenRequest(params: params).asURLRequest(for: self)
			logger?.debug("OAuth2", msg: "Requesting new access token from \(post.url?.description ?? "nil")")
			
			perform(request: post) { data, status, error in
				do {
					guard let data = data else {
						throw error ?? OAuth2Error.noDataInResponse
					}
					
					let dict = try self.parseAccessTokenResponse(data: data)
					if let status = status, status < 400 {
						self.logger?.debug("OAuth2", msg: "Did get access token [\(nil != self.clientConfig.accessToken)]")
						callback(dict, nil)
					}
					else {
						callback(dict, OAuth2Error.responseError("The username or password is incorrect"))
					}
				}
				catch let error {
					self.logger?.debug("OAuth2", msg: "Error parsing response: \(error)")
					callback(nil, error)
				}
			}
		}
		catch let err {
			callback(nil, err)
		}
	}
	
	/**
	Creates a POST request with x-www-form-urlencoded body created from the supplied URL's query part.
	*/
	open func tokenRequest(params: OAuth2StringDict? = nil) throws -> OAuth2AuthRequest {
		if username.isEmpty{
			throw OAuth2Error.noUsername
		}
		if password.isEmpty{
			throw OAuth2Error.noPassword
		}
		
		let req = OAuth2AuthRequest(url: (clientConfig.tokenURL ?? clientConfig.authorizeURL))
		req.params["grant_type"] = type(of: self).grantType
		req.params["username"] = username
		req.params["password"] = password
		if let clientId = clientConfig.clientId {
			req.params["client_id"] = clientId
		}
		if let scope = clientConfig.scope {
			req.params["scope"] = scope
		}
		req.addParams(params: params)
		
		return req
	}
}

