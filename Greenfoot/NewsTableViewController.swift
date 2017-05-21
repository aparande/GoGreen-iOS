//
//  NewsTableViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 5/5/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class NewsTableViewController: UITableViewController {
    
    let model = GreenfootModal.sharedInstance

    // MARK: - Table view data source
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "NewsCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "NewsCell")
        tableView.estimatedRowHeight = 120
        
        prepToolbar()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return model.newsFeed.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let cell = UITableViewCell(style: .default, reuseIdentifier: "NewsCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell") as! NewsTableViewCell
    
        // Configure the cell...
        let url = model.newsFeed[indexPath.row]["image"]!
        if let _ = ImageDatabase.images[url]  {
            
        } else {
            downloadImage(url, indexPath: indexPath)
        }
        
        cell.setInfo(model.newsFeed[indexPath.row])

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let url = model.newsFeed[indexPath.row]["link"]!
        
        let webVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewsVC") as! NewsViewController
        webVC.loadUrl(url: url)
        
        navigationController?.pushViewController(webVC, animated: true)
        
    }
    
    func downloadImage(_ url: String, indexPath:IndexPath) {
        if let _ = PendingOperations.imageDownloadsInProgress[indexPath] {
            return
        }
        
        let downloader = ImageDownloader(u: url)
        
        downloader.completionBlock = {
            if downloader.isCancelled {
                return
            }
            DispatchQueue.main.async(execute: {
                PendingOperations.imageDownloadsInProgress.removeValue(forKey: indexPath)
                
                if let _ = self.tableView.cellForRow(at: indexPath) {
                    self.tableView.reloadRows(at: [indexPath], with: .fade)
                }
            })
        }
        
        PendingOperations.imageDownloadsInProgress[indexPath] = downloader
        PendingOperations.imageQueue.addOperation(downloader)
    }
}

class NewsTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var newspaper: UILabel!
    @IBOutlet var loaderIndicator: UIActivityIndicatorView!
    @IBOutlet var articleImageView: UIImageView!
    
    func setInfo(_ info:[String:String]) {
        loaderIndicator.stopAnimating()
        
        titleLabel.text = info["title"]
        
        dateLabel.text = Date.longFormat(date: info["pubDate"]!)
        newspaper.text = info["source"]
        
        let url = info["image"]!
        guard let image = ImageDatabase.images[url] else {
            loaderIndicator.startAnimating()
            return
        }
        
        articleImageView.image = image
    }
}

class NewsViewController: UIViewController {
    var newsUrl: URL!
    @IBOutlet var webView: UIWebView!
    
    func loadUrl(url: String) {
        newsUrl = URL(string: url)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.loadRequest(URLRequest(url: newsUrl))
        
        navigationItem.backButton.tintColor = UIColor.white
    }
}
