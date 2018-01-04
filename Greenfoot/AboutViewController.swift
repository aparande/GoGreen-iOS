//
//  CollectionViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 8/11/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class AboutViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let reuseIdentifier = "AboutCell"
    private let itemsPerRow: CGFloat = 1
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        prepNavigationBar(titled: "FAQ")
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 3
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AboutCell
        
        // Configure the cell
        cell.titleLabel.text = titleForPath(indexPath)
        cell.detailLabel.text = descriptionForPath(indexPath)
        
        /*let finalFrame = cell.frame
        
        cell.frame = CGRect(x:cell.frame.origin.x - view.bounds.width-100, y:cell.frame.origin.y, width: cell.frame.width, height: cell.frame.height)
        
        UIView.animate(withDuration: 0.5, delay: 0.5*Double(indexPath.row), options: .curveEaseOut, animations: {
            cell.frame = finalFrame
        }, completion: nil) */
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow+1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        let modifier:CGFloat = (UIDevice.current.userInterfaceIdiom == .phone) ? 0.66 : 0.5
        let heightPerItem = modifier * widthPerItem
        
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    /*
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        //1
        switch kind {
        //2
        case UICollectionElementKindSectionFooter:
            //3
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "AboutFooter", for: indexPath) as! AboutFooter
            footer.licenceButton.addTarget(self, action: #selector(showLicense(_:)), for: .touchUpInside)
            footer.privacyButton.addTarget(self, action: #selector(showPrivacy(_:)), for: .touchUpInside)
            return footer
        default:
            //4
            assert(false, "Unexpected element kind")
        }
        return UICollectionReusableView()
    } */
    
    @objc func showLicense(_ sender: AnyObject) {
        let contentHeight:CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 1000 : 2000
        let vc = FileScrollViewController(fileName: "license", contentHeight: contentHeight)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func showPrivacy(_ sender: AnyObject) {
        let contentHeight:CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 2500 : 4000
        let vc = FileScrollViewController(fileName: "privacy", contentHeight: contentHeight)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func titleForPath(_ path:IndexPath) -> String {
        switch path.row {
        case 0:
            return "GoGreen"
        case 1:
            return "What are Energy Points"
        case 2:
            return "What are attributes"
        default:
            return "GoGreen"
        }
    }
    
    private func descriptionForPath(_ path:IndexPath) -> String {
        switch path.row {
        case 0:
            return "Welcome to GoGreen! We hope that in the process of using GoGreen, you not only learn more about your own carbon footprint, but you actively strive to reduce it. Make sure you follow us on social media so more people can begin taking better care of our planet."
        case 1:
            return "Energy Points are a measure of how you compare with the average national consumption. For each data point you enter, the application will award you energy points based on how you compared with the national average. Above-average consumption will receive negative energy points, and below-average consumption will receive positive energy points. These energy points accumulate over time."
        case 2:
            return "Attributes are various actions you can take to reduce your carbon footprint such as installing solar panels and taking shorter showers. How energy points are awarded differs per attribute. Tapping on any attribute will tell you how you can gain energy points from it."
        default:
            return "NA"
        }
    }
}

class AboutCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = Colors.green
        self.layer.cornerRadius = 10
    }
}

class AboutFooter: UICollectionReusableView {
    @IBOutlet weak var licenceButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
}

class FileScrollViewController: UIViewController {
    var scrollHeight:CGFloat
    var file: String
    
    var scrollingLabel: UILabel!
    var scrollView: UIScrollView!
    var contentView: UIView!
    
    init(fileName: String, contentHeight: CGFloat) {
        self.file = fileName
        self.scrollHeight = contentHeight
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        scrollView = UIScrollView(frame: UIScreen.main.bounds)
        
        let size = CGSize(width: UIScreen.main.bounds.width, height: scrollHeight)
        scrollView.contentSize = size
        
        let frame = CGRect(x: 10, y: 0, width: size.width-20, height: size.height)
        
        contentView = UIView(frame: frame)
        scrollingLabel = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width:size.width-20, height:size.height)))
        
        contentView.addSubview(scrollingLabel)
        scrollView.addSubview(contentView)
       
        self.view = scrollView
    }
    
    override func viewDidLoad() {
        navigationItem.backButton.tintColor = UIColor.white
        
        if let filepath = Bundle.main.path(forResource: file, ofType: "txt") {
            do {
                let contents = try String(contentsOfFile: filepath)
                scrollingLabel.text = contents
                scrollingLabel.numberOfLines = 0
                scrollingLabel.textColor = UIColor.black
                
                scrollingLabel.sizeToFit()
            } catch {
                // contents could not be loaded
                print("Couldn't load file")
            }
        } else {
            // example.txt not found!
            print("File not found")
        }
    }
}
