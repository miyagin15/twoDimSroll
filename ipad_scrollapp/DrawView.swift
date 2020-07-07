//
//  DrawView.swift
//  two_dim_move
//
//  Created by miyata ginga on 2019/09/27.
//  Copyright © 2019 com.miyata.UDP. All rights reserved.
//

import Darwin
import UIKit

class DrawView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }

    func getPosition(frame: CGRect) -> [Int: [Double]] {
        var positionXY: [Int: [Double]] = [:]
        let width = Double(frame.width)
        let height = Double(frame.height)
        for i in 0 ..< 13 {
            let degree = (Double(i) * 360 / 13)
            let θ = Double.pi / Double(180) * Double(degree)
            let cicleX = width / 2 + width / 3 * cos(θ)
            let cixleY = height / 2 + width / 3 * sin(θ)
            positionXY.updateValue([cicleX, cixleY], forKey: i)
        }
        print(positionXY)
        return positionXY
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_: CGRect) {
        // ここにUIBezierPathを記述する
        // 円
//        let width = Double(UIScreen.main.bounds.size.width / 2
//      let height = Double(UIScreen.main.bounds.size.height / 2)
        let width = Double(frame.width) // width: 619.0
        let height = Double(frame.height) // height: 695.0
        for i in 0 ..< 13 {
            let degree = (Double(i) * 360 / 13)
            let θ = Double.pi / Double(180) * Double(degree)
            let cicleX = width / 2 + width / 3 * cos(θ)
            let cixleY = height / 2 + width / 3 * sin(θ)
            // 文字を書く
            String(i).draw(at: CGPoint(x: cicleX, y: cixleY), withAttributes: [
                NSAttributedString.Key.foregroundColor: UIColor.blue,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 50),
            ])
            let circle = UIBezierPath(arcCenter: CGPoint(x: cicleX, y: cixleY), radius: 30, startAngle: 0, endAngle: CGFloat(Double.pi) * 2, clockwise: true)
            // 内側の色
            UIColor(red: 0, green: 0, blue: 1, alpha: 0.3).setFill()
            // 内側を塗りつぶす
            circle.fill()
            // 線の色
            UIColor(red: 0, green: 0, blue: 1, alpha: 1.0).setStroke()
            // 線の太さ
            circle.lineWidth = 2.0
            // 線を塗りつぶす
            circle.stroke()
        }
    }
}
