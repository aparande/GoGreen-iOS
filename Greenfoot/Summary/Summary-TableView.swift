//
//  Summary-TableView.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/30/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit

extension SummaryViewController: TableViewPresenter {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let _ = sections[indexPath.section] as? DataLogTableViewSection else { return }
        
        let source = self.aggregator.sources[indexPath.row]
        if source.points.count == 0 {
            self.presentBulletin(forSource: source)
        } else {
            self.performSegue(withIdentifier: "toGraphView", sender: self.aggregator.sources[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sections[section].header
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return sections[section].footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return sections[section].footerHeight
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sections[section].headerHeight
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rowCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return sections[indexPath.section].rowHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellType = sections[indexPath.section].cellType
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CellType.reuseIdentifier) as! CustomCell
        cell.loadData(sections[indexPath.section].data[indexPath.row])
        return cell as! UITableViewCell
    }
    
    func setupTableContainer() {
        tableContainerView.backgroundColor = UIColor.clear
        tableContainerView.layer.shadowColor = UIColor.darkGray.cgColor
        tableContainerView.layer.shadowOffset = CGSize(width: 0, height: -1.0)
        tableContainerView.layer.shadowOpacity = 1.0
        tableContainerView.layer.shadowRadius = 10
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.estimatedSectionHeaderHeight = 40
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.white
        tableView.layer.cornerRadius = 20
        tableView.layer.masksToBounds = true
        tableView.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
    }
    
    func setupTableViewSections() {
        sections = []
        
        if aggregator.points.count != 0 {
            sections.append(BarGraphTableViewSection(titled: "Monthly Emissions", points: aggregator.points, unit: aggregator.unit))
        }
        
        sections.append(DataLogTableViewSection(titled: "View Data", sources: aggregator.sources))
    }
}
