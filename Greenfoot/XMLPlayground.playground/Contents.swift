//: Playground - noun: a place where people can play

import Foundation

protocol NewsParserDelegate {
    func parsingWasFinished()
}

class NewsXMLParser: NSObject, XMLParserDelegate {
    var arrParsedData = [Dictionary<String, String>]()
    var currentDataDictionary = Dictionary<String, String>()
    var currentElement = ""
    var foundCharacters = ""
    var delegate: NewsParserDelegate?
    
    func startParsingWithContentsOfUrl(rssUrl: URL) {
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
            currentDataDictionary[currentElement] = foundCharacters
            foundCharacters = ""
            
            if currentDataDictionary.keys.contains("image") {
                arrParsedData.append(currentDataDictionary)
                currentDataDictionary = [:]
            }
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        delegate?.parsingWasFinished()
    }
}

class MyClass: NewsParserDelegate {
    var parser: NewsXMLParser!
    
    init() {
        parser = NewsXMLParser()
        parser.delegate = self
        
        //parser.startParsingWithContentsOfUrl(rssUrl: URL(string: "http://rss.nytimes.com/services/xml/rss/nyt/Environment.xml")!)
        parser.startParsingWithContentsOfUrl(rssUrl: URL(string: "https://www.theguardian.com/environment/climate-change/rss")!)
    }
    
    func parsingWasFinished() {
        print(parser.arrParsedData[0])
    }
}

let obj = MyClass()
