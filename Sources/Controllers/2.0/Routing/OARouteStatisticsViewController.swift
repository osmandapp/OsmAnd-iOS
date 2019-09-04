//
//  OARouteStatisticsViewController.swift
//  OsmAnd
//
//  Created by Paul on 9/3/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

import UIKit
import Charts

@objc class OARouteStatisticsViewController: UIViewController {

    @IBOutlet weak var chartView: LineChartView!
    // For testing
    override func viewDidLoad() {
        super.viewDidLoad()
        let dollars1 = [20.0, 4.0, 6.0, 3.0, 12.0, 16.0, 4.0, 18.0, 2.0, 4.0, 5.0, 4.0]
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        // 1 - creating an array of data entries
        var yValues : [ChartDataEntry] = [ChartDataEntry]()
        
        for i in 0 ..< months.count {
            yValues.append(ChartDataEntry(x: Double(i + 1), y: dollars1[i]))
        }
        
        let data = LineChartData()
        let ds = LineChartDataSet(entries: yValues, label: "Months")
        
        data.addDataSet(ds)
        chartView.data = data
    }
    
    @objc public func refreshLineChart() {
        
    }

}
