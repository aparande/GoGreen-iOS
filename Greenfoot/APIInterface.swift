//
//  APIInterface.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/25/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation

class APIInterface: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    static func connectToServer(atEndpoint endpoint:String, withParameters parameters:[String:Any], completion: @escaping (NSDictionary) -> Void) {
        //let base = URL(string: "http://192.168.1.78:8000")!
        //let base = URL(string: "http://localhost:8000")!
        let base = URL(string: "https://gogreencarbonapp.heroku.com/")!
        let url = URL(string: endpoint, relativeTo: base)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        
        let bodyData = bodyFromParameters(parameters: parameters)
        request.httpBody = bodyData.data(using: String.Encoding.utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) in
            
            if error != nil {
                guard let description = error? .localizedDescription else {
                    completion(["status":"Failed", "message":"Unknown error found"])
                    return
                }
                print(description)
                completion(["status":"Failed", "message":description])
                return
            }
            
            if let HTTPResponse = response as? HTTPURLResponse {
                let statusCode = HTTPResponse.statusCode
                if statusCode != 200 {
                    print("Couldn't connect error because status not 200 its \(statusCode)")
                }
            }
            
            do  {
                let retVal = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                completion(retVal!)
            } catch _ {
                completion(["status":"Failed", "message":"Could not decode JSON"])
            }
        })
        task.resume()
    }

    private static func bodyFromParameters(parameters:[String:Any]) -> String {
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
