//
//  ImageDownloadOperations.swift
//  Greenfoot
//
//  Created by Anmol Parande on 5/6/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit

enum ImageState {
    //Contains the three possible states an image can be in
    case new, downloaded, failed
}

class PendingOperations {
    //Stores the current operations for post images
    static var imageDownloadsInProgress = [IndexPath: Operation]()
    
    //Stores the Post image queue
    static var imageQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Image Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
}

class ImageDownloader: Operation {
    //Defines the operation to download a post picture
    
    let url:URL
    
    //Constructs the downloader and initailizes its instance variable
    init(u: String) {
        url = URL(string:u)!
    }
    //Run when the operation is called to download the image
    override func main() {
        if self.isCancelled {
            return
        }
        //Get the data from the url
        let imageData = try? Data(contentsOf: url)
        
        
        if self.isCancelled {
            return
        }
        
        //Construct the image from the data
        if (imageData?.count)! > 0 {
            let image = UIImage(data:imageData!)
            ImageDatabase.images[url.absoluteString] = image
        } else {
            //Have some kind of error handling
            ImageDatabase.images[url.absoluteString] = UIImage(named: "Emblem")!
            print("Download failed")
        }
    }
}

class ImageDatabase {
    //Stores the downloaded images
    static var images = [String : UIImage]()
}
