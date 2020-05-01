//
//  Utility.swift
//  ipad_scrollapp
//
//  Created by miyata ginga on 2020/01/06.
//  Copyright © 2020 com.miyagin.ipad_scroll. All rights reserved.
//

import Foundation
import UIKit
// let goalPositionInt: [Int] = [9, 11, 8, 12, 7, 13, 40, 13]
let goalPositionInt: [Int] = [9, 10, 8, 11, 7, 12, 30, 12, 9]
let firstStartPosition: CGFloat = 800
let thresholdPositionInput: CGFloat = 0.05
class Utility {
    static let callibrationArr: [String] = ["口左", "口右", "口上", "口下", "頰右", "頰左", "眉上", "眉下", "右笑", "左笑", "上唇", "下唇", "普通"]
    // 初期設定のMINの普通の状態を保存する
    static var callibrationOrdinalPosition: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    // y = x/(max-min)+min/(min-max)
    class func faceAURangeChange(faceAUVertex: Float, maxFaceAUVertex: Float, minFaceAUVertex: Float) -> Float {
        let faceAUChangeValue = faceAUVertex / (maxFaceAUVertex - minFaceAUVertex) + minFaceAUVertex / (minFaceAUVertex - maxFaceAUVertex)
        return faceAUChangeValue
    }

    class func createScrollView(directionString: String) -> UICollectionView {
        var myCollectionView: UICollectionView!
        // CollectionViewのレイアウトを生成.
        let layout = UICollectionViewFlowLayout()
        if directionString == "horizonal" {
            // Cell一つ一つの大きさ.
            layout.itemSize = CGSize(width: 100, height: 600)
            layout.minimumLineSpacing = 0.1
            // Cellのマージン.
            // layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
            layout.scrollDirection = .horizontal

            // layout.scrollDirection = .vertical

            // セクション毎のヘッダーサイズ.
            // layout.headerReferenceSize = CGSize(width:10,height:30)
            // CollectionViewを生成.
            // myCollectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
            myCollectionView = UICollectionView(frame: CGRect(x: 0, y: 150, width: 600, height: 600),
                                                collectionViewLayout: layout)
            myCollectionView.backgroundColor = UIColor.white
            // Cellに使われるクラスを登録.
            myCollectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
            myCollectionView.contentSize = CGSize(width: 1800, height: 600)
        } else if directionString == "vertical" {
            // Cell一つ一つの大きさ.
            layout.itemSize = CGSize(width: 600, height: 100)
            layout.minimumLineSpacing = 0.1
            // Cellのマージン.
            // layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
            // layout.scrollDirection = .horizontal

            layout.scrollDirection = .vertical

            // セクション毎のヘッダーサイズ.
            // layout.headerReferenceSize = CGSize(width:10,height:30)
            // CollectionViewを生成.
            // myCollectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
            myCollectionView = UICollectionView(frame: CGRect(x: 0, y: 150, width: 600, height: 600),
                                                collectionViewLayout: layout)
            myCollectionView.backgroundColor = UIColor.white
            // Cellに使われるクラスを登録.
            myCollectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
            myCollectionView.contentSize = CGSize(width: 600, height: 1800)
        }
        return myCollectionView
    }

    class func createGoalView(directionString: String) -> UIView {
        let goalView = UIView()
        if directionString == "horizonal" {
            goalView.frame = CGRect(x: 200, y: 150, width: 150, height: 700)
        } else if directionString == "vertical" {
            goalView.frame = CGRect(x: 0, y: 350, width: 600, height: 150)
        }
        goalView.backgroundColor = UIColor(red: 0, green: 0.3, blue: 0.8, alpha: 0.5)
        return goalView
    }

    class func createCSVFileData(fileArrData: [Float], facailAU: String, direction: String, inputMethod: String) -> (fileName: String, fileData: String) {
        var fileStrData: String = ""
        // ウインクした場所を特定するために定義
        let userDefaults = UserDefaults.standard
        let name: String = userDefaults.string(forKey: "name") ?? "noName"
        let fileName1 = name + "_" + facailAU + "_"
        let fileName = fileName1 + direction + "_" + inputMethod + ".csv"

        // StringのCSV用データを準備
        // print(fileArrData)
        if fileArrData.count == 0 {
            return ("0", "0")
        }
        // キャリブレーション座標のラベル追加
        for x in 0 ... 11 {
            if x != 11 {
                fileStrData += String(callibrationArr[x]) + ","
            } else {
                fileStrData += String(callibrationArr[x]) + "\n"
            }
        }
        // キャリブレーションMAX座標の値
        for x in 0 ... 11 {
            if x != 11 {
                if let value = userDefaults.string(forKey: callibrationArr[x]) {
                    fileStrData += String(value) + ","
                } else {
                    print("no value", x)
                }
            } else {
                if let value = userDefaults.string(forKey: callibrationArr[x]) {
                    fileStrData += String(value) + "\n"
                } else {
                    print("no value", x)
                }
            }
        }
        // 普通の時のラベル
        for x in 0 ... 11 {
            if x != 11 {
                fileStrData += String("普通" + callibrationArr[x]) + ","
            } else {
                fileStrData += String("普通" + callibrationArr[x]) + "\n"
            }
        }
        // 普通の時の座標
        for x in 0 ... 11 {
            callibrationOrdinalPosition[x] = userDefaults.float(forKey: "普通" + callibrationArr[x])
            if x != 11 {
                fileStrData += String(callibrationOrdinalPosition[x]) + ","
            } else {
                fileStrData += String(callibrationOrdinalPosition[x]) + "\n"
            }
        }

        fileStrData += "position,goalPosition\n"
        for i in 1 ... fileArrData.count {
            if i % 2 != 0 {
                fileStrData += String(fileArrData[i - 1]) + ","
            }
            if i % 2 == 0 {
                fileStrData += String(fileArrData[i - 1]) + "\n"
            }
        }
        // print(fileStrData)
        return (fileName, fileStrData)
    }
}
