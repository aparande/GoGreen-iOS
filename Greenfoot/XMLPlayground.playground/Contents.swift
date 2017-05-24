//: Playground - noun: a place where people can play

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
        if (currentElement == "title" && string != "Climate change | The Guardian" && string != "NYT > Environment" && string != "Global Climate Change - Vital Signs of the Planet - News RSS Feed" || currentElement == "link" || currentElement == "pubDate") {
            foundCharacters += string
        }
    }
     //This could be made more efficient
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
       
        if elementName == "item" && currentDataDictionary.keys.count != 0{
            currentDataDictionary["source"] = currentFeed
            arrParsedData.append(currentDataDictionary)
            currentDataDictionary = [:]
            return
        }
        
        foundCharacters = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if !foundCharacters.isEmpty {
            if currentDataDictionary.keys.count != 4 {
                currentDataDictionary[currentElement] = foundCharacters
                foundCharacters = ""
            } else {
                print("hi")
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

class MyClass: NewsParserDelegate {
    var parser: NewsXMLParser!
    
    init() {
        parser = NewsXMLParser()
        parser.delegate = self

        //parser.startParsingWithContentsOfUrl(feed: "NASA", rssUrl: URL(string: "https://climate.nasa.gov/news/rss.xml")!)
        //parser.startParsingWithContentsOfUrl(feed: "NASA", rssUrl: URL(string: "http://rss.nytimes.com/services/xml/rss/nyt/Environment.xml")!)
        parser.startParsingWithContentsOfUrl(feed: "NASA", rssUrl: URL(string: "https://www.theguardian.com/environment/climate-change/rss")!)
        
    }
    
    func parsingWasFinished(feed: String, parser: NewsXMLParser) {
        for data in parser.arrParsedData {
            print(data)
        }
    }
}

let obj = MyClass()
