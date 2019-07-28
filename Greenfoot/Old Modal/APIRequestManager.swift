//
//  APIInterface.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/25/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
// Im typing a silly thing here to see if commit revert wont screw things up

import Foundation

enum APIError {
    case connectionFailure
    case serverFailure
    case jsonFailure
    case unknown
    case special
}

enum APINotifications:String {
    case stateRank = "fetchedStateRank"
    case cityRank = "fetchedCityRank"
    case carDataCompiled = "compiledCarData"
}

enum APIRequestType: String {
    case get = "GET"
    case log = "LOG"
    case delete = "DELETE"
    case consensus = "CONSENSUS"
    case login = "LOGIN"
    case signup = "SIGNUP"
    case account = "ACCOUNT"
}

class APIRequestManager: NSObject, URLSessionDelegate {
    static let sharedInstance = APIRequestManager()
    private var runningRequests:[String: APICall] = [:]
    private var queuedRequests:[String: APICall] = [:]
    
    func queueAPICall(identifiedBy uId:String, atEndpoint endpoint:String, withParameters parameters:[String:Any], andSuccessFunction success:((NSDictionary) -> Void)?, andFailureFunction failure:((NSDictionary) -> Void)?) {
        //let base = URL(string: "http://192.168.1.94:8000/api/")!
        //let base = URL(string: "http://localhost:8000/api/")!
        let base = URL(string: "https://gogreencarbonapp.herokuapp.com/api/")!
        
        let call = APICall(self, atEndpoint: endpoint, onURL:base, withParameters: parameters, identifiedBy:uId, andSuccessFunction: success, andFailureFunction: failure)
        
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
        
        if let success = call.successFunction {
            success(data)
        }
        
        manageQueue(forId: call.uniqId)
    }
    
    func apiCall(_ call: APICall, finishedWithError error: APIError, andMessage message: String?) {
        switch error {
        case .connectionFailure:
            print(call.uniqId + " finished with connection error. Message: \(String(describing: message))")
        case .jsonFailure:
            print(call.uniqId + " finished with JSON Decode error")
        case .serverFailure:
            print (call.uniqId + " finished with server failure. Message: \(String(describing: message))")
        case .special:
            print (call.uniqId + " finished with special error. Message: \(String(describing: message))")
        case .unknown:
            print (call.uniqId + " finished with unknown error.")
        }
        
        if let failure = call.failureFunction {
            failure(["Error":error, "Message": message ?? "No Message"])
        }
        
        manageQueue(forId: call.uniqId)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    func requestExists(_ id:String) -> Bool {
        if let _ = runningRequests[id] {
            return true
        }
        
        if let _ = queuedRequests[id] {
            return true
        }
        
        return false
    }
}
