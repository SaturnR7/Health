//
//  ViewController.swift
//  HealthKitSample
//
//  Created by Hidemasa Kobayashi on 2021/09/04.
//

import HealthKit
import UIKit

final class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        /// アクセス許可を求めるデータタイプを Set型 で格納します。
        /// 今回は歩数を取得したいので .stepCount を指定します。
        let readDataTypes = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
        /// ユーザーにアクセス許可を求める
        HKHealthStore().requestAuthorization(toShare: nil, read: readDataTypes) { _, _ in }
        self.getSteps()
    }
    
    private func getSteps() {
        /// HealthKit に対して開始日・終了日・データタイプをリクエストして、指定した日付分の歩数を取得します。
        
        /// 今回は、今日を含めた過去8日間の歩数を取得したいため、今日-7日の日付を開始日とする。
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        var sampleArray: [Double] = []
        ///
        let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        
        /// サンプルデータの検索条件を指定する。（サンプルデータのフィルタリング）
        /// 条件は、取得期間（開始日〜終了日）を指定することができる。
        ///
        /// - Parameters:
        ///   - withStart: 今回は、今日を含めた過去８日間の歩数を取得したいため、今日−７日の日付を渡す。
        ///   - end: 今日の日付を渡す。
        ///   - options:取得範囲の指定（？）→ オプションの機能が分かっていません。
        ///             （strictStartDate指定で開始日から狙ったサンプルデータは取得できています）
        /// - Returns: 開始日と終了日が指定された検索情報
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                    end: Date(),
                                                    options: .strictStartDate)
        
        
        /// サンプルデータを取得するためのクエリを生成します。
        ///
        /// - Parameters:
        ///   - quantityType: 取得したいサンプルデータのタイプを指定する。今回は歩数。
        ///   - quantitySamplePredicate: 今回は、今日を含めた過去８日間の歩数を取得したいため、今日−７日の日付を渡す。
        ///   - options: 今日の日付を渡す。
        ///   - anchorDate: 今日の日付を渡す。
        ///   - intervalComponents:取得範囲の指定（？）→ オプションの機能が分かっていません。
        /// - Returns: 開始日と終了日が指定された検索情報
        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                quantitySamplePredicate: predicate,
                                                options: .cumulativeSum,
                                                anchorDate: startDate,
                                                intervalComponents: DateComponents(day: 1))
        
        query.initialResultsHandler = { _, results, _ in
            guard let statsCollection = results else { return }
            statsCollection.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                if let quantity = statistics.sumQuantity() {
                    let stepValue = quantity.doubleValue(for: HKUnit.count())
                    sampleArray.append(floor(stepValue))
                    print("stepArray: ", sampleArray)
                } else {
                    // No Data
                    sampleArray.append(0.0)
                    print("stepArray no data: ", sampleArray)
                }
            }
        }
        HKHealthStore().execute(query)
    }
}
