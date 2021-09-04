//
//  ViewController.swift
//  HealthKitSample
//
//  Created by Hidemasa Kobayashi on 2021/09/04.
//

import HealthKit
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.getSteps()
    }
    
    private func getSteps() {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        var stepArray: [Double] = []
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                    end: Date(),
                                                    options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(quantityType: stepsQuantityType,
                                                quantitySamplePredicate: predicate,
                                                options: .cumulativeSum,
                                                anchorDate: startDate,
                                                intervalComponents: DateComponents(day: 1))
        
        query.initialResultsHandler = { _, results, _ in
            guard let statsCollection = results else { return }
            statsCollection.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                if let quantity = statistics.sumQuantity() {
                    let stepValue = quantity.doubleValue(for: HKUnit.count())
                    stepArray.append(floor(stepValue))
                    print("stepArray: ", stepArray)
                } else {
                    // No Data
                    stepArray.append(0.0)
                    print("stepArray no data: ", stepArray)
                }
            }
        }
        HKHealthStore().execute(query)
    }
}
