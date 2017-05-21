//
//  NewsXMLParser.swift
//  Greenfoot
//
//  Created by Anmol Parande on 5/3/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation

protocol NewsParserDelegate {
    func parsingWasFinished(feed: String, parser: NewsXMLParser)
}

class NewsXMLParser: NSObject, XMLParserDelegate {
    var arrParsedData = [Dictionary<String, String>]()
    var currentDataDictionary = Dictionary<String, String>()
    var currentElement = ""
    var foundCharacters = ""
    var delegate: NewsParserDelegate?
    
    var currentFeed:String = ""
    
    func startParsingWithContentsOfUrl(feed:String, rssUrl: URL) {
        currentFeed = feed
        let parser = XMLParser(contentsOf: rssUrl)!
        parser.delegate = self
        parser.parse()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName:String, namespaceURI:String?, qualifiedName qName:String?, attributes attributeDict:[String : String]) {
        currentElement = elementName
        
        if currentElement == "media:content" {
            currentDataDictionary["image"] = attributeDict["url"]!
        }
    }
    func parser(_ parser: XMLParser, foundCharacters string:String) {
        if (currentElement == "title" && string != "Climate change | The Guardian" && string != "NYT > Environment") || currentElement == "link" || currentElement == "pubDate" {
            foundCharacters += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        foundCharacters = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if !foundCharacters.isEmpty {
            if currentDataDictionary.keys.count != 4 {
                currentDataDictionary[currentElement] = foundCharacters
                foundCharacters = ""
            } else {
                currentDataDictionary["source"] = currentFeed
                arrParsedData.append(currentDataDictionary)
                currentDataDictionary = [:]
                
                currentDataDictionary[currentElement] = foundCharacters
                foundCharacters = ""
            }
            
            if currentDataDictionary.keys.contains("image") {
                currentDataDictionary["source"] = currentFeed
                arrParsedData.append(currentDataDictionary)
                currentDataDictionary = [:]
            }
            
            
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        delegate?.parsingWasFinished(feed: currentFeed, parser: self)
    }
}
