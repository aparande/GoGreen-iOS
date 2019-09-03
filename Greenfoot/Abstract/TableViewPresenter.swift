//
//  TableViewPresenter.swift
//  Greenfoot
//
//  Created by Anmol Parande on 8/31/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit

protocol TableViewPresenter: UITableViewDelegate, UITableViewDataSource {
    var sections: [TableViewSection] {get set}
}
