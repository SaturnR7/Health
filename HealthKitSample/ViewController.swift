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
        /// アクセス許可を求めるデータタイプを Set型 で格納する。
        /// 今回は歩数を取得したいので .stepCount を指定する。
        let readDataTypes = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
        /// ユーザーにアクセス許可を求める。
        HKHealthStore().requestAuthorization(toShare: nil, read: readDataTypes) { _, _ in }
        self.getSteps()
    }
    
    private func getSteps() {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        var sampleArray: [Double] = []
        let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        
        /// サンプルデータの検索条件を指定する。（サンプルデータのフィルタリング）
        /// 条件は、取得期間（開始日〜終了日）を指定することができる。
        ///
        /// - Parameters:
        ///   - withStart: 今回は、今日を含めた過去８日間の歩数を取得したいため、今日−７日の日付を渡す。
        ///   - end: 今日の日付を渡す。
        ///   - options:取得範囲の指定（？）→ オプションの機能が分かっていません。
        ///             （strictStartDate指定で開始日から狙ったサンプルデータは取得できています）
        ///             （こちらも詳しい情報ありましたらコメントいただけると幸いです）
        ///   @see https://developer.apple.com/documentation/healthkit/hkquery/1614771-predicateforsamples/
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                    end: Date(),
                                                    options: .strictStartDate)
        
        /// サンプルデータを取得するためのクエリを生成します。
        ///
        /// - Parameters:
        ///   - quantityType: 取得したいサンプルデータのタイプを指定する。今回は歩数。
        ///   - quantitySamplePredicate: サンプルデータの検索条件。
        ///   - options: サンプルデータの計算方法を指定するオプション。今回は１日の合計歩数がほしいので `cumulativeSum` を指定する。
        ///   - anchorDate: 基準となる日付（時間を数直線とした場合に、アンカー日付は原点で過去・未来両方に伸びる目盛りが作成される。（Documentより））
        ///                 今回の場合、開始日にアンカーを指定してあげれば、指定した機関のサンプルが取得できます。
        ///                 （こちらも詳しい情報ありましたらコメントいただけると幸いです）
        ///   - intervalComponents: サンプルの時間間隔の長さを指定する。今回は日別に歩数を取得したいので、間隔は１日で指定する。
        ///   @see https://developer.apple.com/documentation/healthkit/hkstatisticscollectionquery/1615199-init
        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                quantitySamplePredicate: predicate,
                                                options: .cumulativeSum,
                                                anchorDate: startDate,
                                                intervalComponents: DateComponents(day: 1))
        
        /// クエリの結果（日別の歩数）を配列に格納します
        ///   @see https://developer.apple.com/documentation/healthkit/hkstatisticscollectionquery/1615755-initialresultshandler
        query.initialResultsHandler = { _, results, _ in
            /// `results (HKStatisticsCollection?)` からクエリ結果を取り出す。
            guard let statsCollection = results else { return }
            /// クエリ結果から期間（開始日・終了日）を指定して歩数の統計情報を取り出す。
            statsCollection.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                /// `statistics` から最小単位（今回は１日分の歩数）のサンプルデータが返ってくる。
                /// `sumQuantity` でサンプルデータの合計（１日の合計歩数）を取得する。
                if let quantity = statistics.sumQuantity() {
                    /// サンプルデータは`doubleValue (戻り値はDouble型)`で単位を指定して取得する。
                    /// 単位は歩数の場合`HKUnit.count()`を指定する。他の例では、サンプルデータから速度や距離を取得する場合は、`HKUnit.meter()`や`HKUnit(from: "m/s")`と指定する。
                    /// 取得した歩数を配列に格納する。
                    let stepValue = quantity.doubleValue(for: HKUnit.count())
                    sampleArray.append(floor(stepValue))
                } else {
                    // No Data
                    sampleArray.append(0.0)
                }
            }
        }
        HKHealthStore().execute(query)
    }
}
