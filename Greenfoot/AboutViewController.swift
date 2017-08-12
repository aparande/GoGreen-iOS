//
//  CollectionViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 8/11/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit

class AboutViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let reuseIdentifier = "AboutCell"
    private let itemsPerRow: CGFloat = 1
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.backButton.tintColor = UIColor.white
        navigationItem.title = "FAQ"
        navigationItem.titleLabel.textColor = UIColor.white
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
        let heightPerItem = 0.66 * widthPerItem
        
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        //1
        switch kind {
        //2
        case UICollectionElementKindSectionFooter:
            //3
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "AboutFooter", for: indexPath) as! AboutFooter
            footer.licenceButton.addTarget(self, action: #selector(showLicense(_:)), for: .touchUpInside)
            return footer
        default:
            //4
            assert(false, "Unexpected element kind")
        }
    }
    
    func showLicense(_ sender: AnyObject) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "licenseController")
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
        self.cornerRadius = 10
    }
}

class AboutFooter: UICollectionReusableView {
    @IBOutlet weak var licenceButton: UIButton!
}

class LicenseController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var licenseLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backButton.tintColor = UIColor.white
    }
    
    override func viewDidLayoutSubviews() {
        
        let size = CGSize(width: UIScreen.main.bounds.width, height: 2000)
        scrollView.contentSize = size
        
        licenseLabel.frame = CGRect(x: 10, y: 0, width: size.width-20, height: size.height)
        licenseLabel.sizeToFit()
        
        scrollView.layoutIfNeeded()
    }
}
