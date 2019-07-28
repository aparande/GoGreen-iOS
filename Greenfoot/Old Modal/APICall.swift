//
//  APICall.swift
//  Greenfoot
//
//  Created by Anmol Parande on 8/10/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation

class APICall {
    //Parameter variables
    let uniqId: String
    let successFunction: ((NSDictionary) -> Void)?
    let failureFunction: ((NSDictionary) -> Void)?
    private let endpoint: String
    private let base: URL
    private let parameters: [String:Any]
    private let delegate: APIRequestManager
    
    //Computed variables
    private var request:URLRequest
    
    init(_ delegate:APIRequestManager, atEndpoint endpoint:String, onURL base:URL, withParameters parameters:[String:Any], andSuccessFunction function: ((NSDictionary) -> Void)?, andFailureFunction failure:((NSDictionary) -> Void)?) {
        self.delegate = delegate
        self.endpoint = endpoint
        self.base = base
        self.parameters = parameters
        self.successFunction = function
        self.failureFunction = failure
        
        let url = URL(string: endpoint, relativeTo: base)!
        request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        uniqId = UUID().uuidString
        
        let bodyData = bodyFromParameters(parameters: parameters)
        request.httpBody = bodyData.data(using: String.Encoding.utf8)
    }
    
    init(_ delegate:APIRequestManager, atEndpoint endpoint:String, onURL base:URL, withParameters parameters:[String:Any], identifiedBy uID:String, andSuccessFunction success:((NSDictionary) -> Void)?, andFailureFunction failure:((NSDictionary) -> Void)?) {
        self.delegate = delegate
        self.endpoint = endpoint
        self.base = base
        self.parameters = parameters
        self.successFunction = success
        self.failureFunction = failure
        
        let url = URL(string: endpoint, relativeTo: base)!
        request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        uniqId = uID
        
        let bodyData = bodyFromParameters(parameters: parameters)
        request.httpBody = bodyData.data(using: String.Encoding.utf8)
    }
    
    func run() {
        print("Running " + uniqId)
        
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) in
            
            if error != nil {
                guard let description = error? .localizedDescription else {
                    self.delegate.apiCall(self, finishedWithError: .unknown, andMessage: nil)
                    return
                }
                self.delegate.apiCall(self, finishedWithError: .special, andMessage: description)
                return
            }
            
            if let HTTPResponse = response as? HTTPURLResponse {
                let statusCode = HTTPResponse.statusCode
                if statusCode != 200 {
                    self.delegate.apiCall(self, finishedWithError: .connectionFailure, andMessage: "Couldn't connect error because status not 200 its \(statusCode)")
                    return
                }
            }
            
            do  {
                let retVal = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                if retVal!["Success"]! as! Bool == true {
                    self.delegate.apiCall(self, sucessfullyReturnedData: retVal!)
                } else {
                    self.delegate.apiCall(self, finishedWithError: .serverFailure, andMessage: retVal!["Message"] as? String)
                }
            } catch _ {
                self.delegate.apiCall(self, finishedWithError: .jsonFailure, andMessage: nil)
            }
        })
        task.resume()
    }
    
    private func bodyFromParameters(parameters:[String:Any]) -> String {
        var bodyData = ""
        for (key, value) in parameters {
            bodyData.append(key+"=\(value)&")
        }
        bodyData.remove(at: bodyData.index(before: bodyData.endIndex))
        return bodyData
    }
}
