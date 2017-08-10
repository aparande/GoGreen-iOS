//
//  APIInterface.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/25/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation

enum APIError {
    case connectionFailure
    case serverFailure
    case jsonFailure
    case unknown
    case special
}

class APIInterface: NSObject, URLSessionDelegate {
    static let sharedInstance = APIInterface()
    
    private var runningRequests:[String: APICall] = [:]
    private var queuedRequests:[String: APICall] = [:]
    
    func queueAPICall(identifiedBy uId:String, atEndpoint endpoint:String, withParameters parameters:[String:Any], andSuccessFunction function:((NSDictionary) -> Void)?) {
        let base = URL(string: "http://192.168.1.78:8000")!
        //let base = URL(string: "http://localhost:8000")!
        //let base = URL(string: "https://gogreencarbonapp.herokuapp.com/")!
        
        let call = APICall(self, atEndpoint: endpoint, onURL:base, withParameters: parameters, identifiedBy:uId, andSuccessFunction: function)
        
        if let _ = runningRequests[uId] {
            //If there is a running request with the same id, queue this request. If a request with the id is in the queue, overwrite it
            if let _ = queuedRequests[uId] {
                print("Overwrote queue for " + uId)
            } else {
                print("Added \(uId) to the queue")
            }
            queuedRequests[uId] = call
        } else {
            runningRequests[uId] = call
            call.run()
        }
    }
    
    private func manageQueue(forId id:String) {
        //Run any queued request with the same id or pop the old one off the dictionary
        if let request = queuedRequests.removeValue(forKey: id) {
            print("Running queued request: "+id)
            runningRequests[id] = request
            request.run()
        } else {
            runningRequests.removeValue(forKey: id)
        }
    }
    
    func apiCall(_ call:APICall, sucessfullyReturnedData data:NSDictionary) {
        print(call.uniqId + " finished successfully")
        
        manageQueue(forId: call.uniqId)
        
        if let success = call.successFunction {
            success(data)
        }
    }
    
    func apiCall(_ call: APICall, finishedWithError error: APIError, andMessage message: String?) {
        switch error {
        case .connectionFailure:
            print(call.uniqId + " finished with connection error. Message: " + message!)
        case .jsonFailure:
            print(call.uniqId + " finished with JSON Decode error")
        case .serverFailure:
            print (call.uniqId + " finished with server failure. Message: " + message!)
        case .special:
            print (call.uniqId + " finished with special error. Message: " + message!)
        case .unknown:
            print (call.uniqId + " finished with unknown error.")
        }
        
        manageQueue(forId: call.uniqId)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

class APICall {
    //Parameter variables
    let uniqId: String
    let successFunction: ((NSDictionary) -> Void)?
    private let endpoint: String
    private let base: URL
    private let parameters: [String:Any]
    private let delegate: APIInterface
    
    //Computed variables
    private var request:URLRequest
    
    init(_ delegate:APIInterface, atEndpoint endpoint:String, onURL base:URL, withParameters parameters:[String:Any], andSuccessFunction function: ((NSDictionary) -> Void)?) {
        self.delegate = delegate
        self.endpoint = endpoint
        self.base = base
        self.parameters = parameters
        self.successFunction = function
        
        let url = URL(string: endpoint, relativeTo: base)!
        request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        uniqId = UUID().uuidString
        
        let bodyData = bodyFromParameters(parameters: parameters)
        request.httpBody = bodyData.data(using: String.Encoding.utf8)
    }
    
    init(_ delegate:APIInterface, atEndpoint endpoint:String, onURL base:URL, withParameters parameters:[String:Any], identifiedBy uID:String, andSuccessFunction function:((NSDictionary) -> Void)?) {
        self.delegate = delegate
        self.endpoint = endpoint
        self.base = base
        self.parameters = parameters
        self.successFunction = function
        
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
                
                if retVal!["status"]! as! String == "Success" {
                    self.delegate.apiCall(self, sucessfullyReturnedData: retVal!)
                } else {
                    self.delegate.apiCall(self, finishedWithError: .serverFailure, andMessage: retVal!["message"] as? String)
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

enum APINotifications:String {
    case stateRank = "fetchedStateRank"
    case cityRank = "fetchedCityRank"
}

enum APIRequestType: String {
    case add = "ADD"
    case get = "GET"
    case update = "UPDATE"
    case delete = "DELETE"
}
