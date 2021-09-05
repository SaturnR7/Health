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
        
        /// アクセスしたいデータ項目のタイプを `Set型` で格納する。
        /// 今回は歩数を取得したいので `.stepCount` を指定する。
        /// また、兵器歩行速度なら `.walkingSpeed`、歩行距離なら `.distanceWalkingRunning`など、許可を得たい項目を配列で指定する。
        let readDataTypes = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
        /// ユーザーにアクセス許可を求める。
        HKHealthStore().requestAuthorization(toShare: nil, read: readDataTypes) { _, _ in }
        
        self.getSteps()
    }
    
    private func getSteps() {
        
        var sampleArray: [Double] = []
        
        /// ７日前の日付を取得し、`startOfDay`で日の始まりを取得する。
        let sevenDaysAgo = Calendar.current.date(byAdding: DateComponents(day: -7), to: Date())!
        let startDate = Calendar.current.startOfDay(for: sevenDaysAgo)

        /// サンプルデータの検索条件を指定する。（サンプルデータのフィルタリング）
        /// 条件は、取得したいサンプルデータの期間（開始日〜終了日）を指定する。
        ///
        /// - Parameters:
        ///   - withStart: サンプルデータの取得開始日を指定する。
        ///   - end: サンプルデータの終了日を指定する。
        ///   - options:取得範囲の指定（？）→ オプションの機能が分かっていません。
        ///             （strictStartDate指定で開始日から狙ったサンプルデータは取得できています）
        ///             （こちらも詳しい情報ありましたらコメントいただけると幸いです）
        ///   @see https://developer.apple.com/documentation/healthkit/hkquery/1614771-predicateforsamples/
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                    end: Date(),
                                                    options: .strictStartDate)
        
        /// サンプルデータを取得するためのクエリを生成する。
        ///
        /// - Parameters:
        ///   - quantityType: サンプルデータのタイプを指定する。（今回は歩数。）
        ///   - quantitySamplePredicate: サンプルデータの検索条件。（取得したいデータの期間）
        ///   - options: サンプルデータの計算方法を指定する。今回は１日の合計歩数がほしいので `cumulativeSum` を指定する。
        ///   - anchorDate: 基準となる日付（時間を数直線とした場合に、アンカー日付は原点で過去・未来両方に伸びる目盛りが作成される。（Documentより））
        ///                 今回の場合、開始日にアンカーを指定してあげれば、指定した機関のサンプルが取得できます。
        ///                 （こちらも詳しい情報ありましたらコメントいただけると幸いです）
        ///   - intervalComponents: サンプルの時間間隔の長さを指定する。今回は日別に歩数を取得したいので、間隔は１日で指定する。
        ///   @see https://developer.apple.com/documentation/healthkit/hkstatisticscollectionquery/1615199-init
        let query = HKStatisticsCollectionQuery(quantityType: HKObjectType.quantityType(forIdentifier: .stepCount)!,
                                                quantitySamplePredicate: predicate,
                                                options: .cumulativeSum,
                                                anchorDate: startDate,
                                                intervalComponents: DateComponents(day: 1))
        
        /// クエリ結果を配列に格納します
        ///   @see https://developer.apple.com/documentation/healthkit/hkstatisticscollectionquery/1615755-initialresultshandler
        query.initialResultsHandler = { _, results, _ in
            /// `results (HKStatisticsCollection?)` からクエリ結果を取り出す。
            guard let statsCollection = results else { return }
            /// クエリ結果から期間（開始日・終了日）を指定して歩数の統計情報を取り出す。
            statsCollection.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                /// `statistics` から最小単位（今回は１日分の歩数）のサンプルデータが返ってくる。
                /// `sumQuantity` でサンプルデータの合計（１日の合計歩数）を取得する。
                if let quantity = statistics.sumQuantity() {
                    /// サンプルデータは`doubleValue (戻り値はDouble型)`で取り出し、単位を指定して取得する。
                    /// 単位：歩数の場合`HKUnit.count()`と指定する。（歩行速度の場合：`HKUnit.meter()`、歩行距離の場合：`HKUnit(from: "m/s")`といった単位を指定する。）
                    let stepValue = quantity.doubleValue(for: HKUnit.count())
                    /// 取得した歩数を配列に格納する。
                    sampleArray.append(floor(stepValue))
                    print("sampleArray", sampleArray)
                } else {
                    // No Data
                    sampleArray.append(0.0)
                    print("sampleArray", sampleArray)
                }
            }
        }
        HKHealthStore().execute(query)
    }
}
