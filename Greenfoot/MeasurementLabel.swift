//
//  MeasurementLabel.swift
//  Greenfoot
//
//  Created by Anmol Parande on 9/23/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit

class MeasurementLabel: UILabel {
    var prefix: String? {
        didSet {
            guard let pre = prefix, let t = self.text else { return }
            self.text = pre + t
        }
    }
    
    var measurement: Measurement? {
        didSet {
            guard let meas = self.measurement else { self.text = ""; return }
            let (val, unit) = meas.display()
            self.text = String(format: "\(self.prefix ?? "")%.2f ", val) + unit.uppercased()
        }
    }
}
