//
//  DescriptionCollectionViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 5/21/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit

class DescriptionCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var data:GreenData!
    
    let sectionInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
    let itemsPerRow: CGFloat = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
        navigationItem.backButton.tintColor = UIColor.white
    }
    
    func setData(data:GreenData) {
        self.data = data
    }
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return data.attributes.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DescriptionCell", for: indexPath) as! DescriptionCell
    
        // Configure the cell
        cell.backgroundColor = Colors.green
        cell.titleLabel.text = data.attributes[indexPath.row]
        cell.moreInfoLabel.text = data.descriptions[indexPath.row]
        
        let finalFrame = cell.frame
        
        cell.frame = CGRect(x:cell.frame.origin.x - view.bounds.width-100, y:cell.frame.origin.y, width: cell.frame.width, height: cell.frame.height)
        
        UIView.animate(withDuration: 0.5, delay: 0.5*Double(indexPath.row), options: .curveEaseOut, animations: {
            cell.frame = finalFrame
        }, completion: nil)
    
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow+1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        let heightPerItem = 0.5 * widthPerItem
        
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

class DescriptionCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var moreInfoLabel: UILabel!
    var frontFacing = true
}
