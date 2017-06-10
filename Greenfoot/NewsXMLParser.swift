//
//  NewsXMLParser.swift
//  Greenfoot
//
//  Created by Anmol Parande on 5/3/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation

protocol NewsParserDelegate {
    func parsingWasFinished(parser: NewsXMLParser)
}

class NewsXMLParser: NSObject, XMLParserDelegate {
    var urls:[String : URL] = [:]
    var arrParsedData = [Dictionary<String, String>]()
    var currentDataDictionary = Dictionary<String, String>()
    var currentElement = ""
    var foundCharacters = ""
    var delegate: NewsParserDelegate?
    
    var parserPairs:[XMLParser:String] = [:]
    
    func startParsingWithContentsOfUrl(rssUrls: [String:URL]) {
        for (source, url) in rssUrls {
            let parser = XMLParser(contentsOf: url)
            if let _ = parser {
                parser!.delegate = self
                parserPairs[parser!] = source
                parser!.parse()
            }
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName:String, namespaceURI:String?, qualifiedName qName:String?, attributes attributeDict:[String : String]) {
        currentElement = elementName
        
        if currentElement == "media:content" {
            currentDataDictionary["image"] = attributeDict["url"]!
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string:String) {
        if (currentElement == "title" && string != "Climate change | The Guardian" && string != "NYT > Environment" && string != "Global Climate Change - Vital Signs of the Planet - News RSS Feed" || currentElement == "link" || currentElement == "pubDate") {
            foundCharacters += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "item" && currentDataDictionary.keys.count != 0{
            currentDataDictionary["source"] = parserPairs[parser]
            arrParsedData.append(currentDataDictionary)
            currentDataDictionary = [:]
            return
        }
        
        foundCharacters = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if !foundCharacters.isEmpty {
            currentDataDictionary[currentElement] = foundCharacters
            foundCharacters = ""
            
            if currentDataDictionary.keys.contains("image") {
                currentDataDictionary["source"] = parserPairs[parser]
                arrParsedData.append(currentDataDictionary)
                currentDataDictionary = [:]
            }
            
            
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        delegate?.parsingWasFinished(parser: self)
        arrParsedData = []
    }
}
