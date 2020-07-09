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
    var radius: CGFloat = 40
    var halfDistance: Double = 200
    var positionXY: [Int: [Double]] = [:]
    let userDefaults = UserDefaults.standard

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        let width = Double(frame.width)
        let height = Double(frame.height)
        radius = CGFloat(userDefaults.float(forKey: "targetSize"))
        halfDistance = Double(userDefaults.float(forKey: "distance"))
        for i in 0 ..< 13 {
            let degree = (Double(i) * 360 / 13)
            let θ = Double.pi / Double(180) * Double(degree)
            let cicleX = width / 2 + halfDistance * cos(θ) // halfDistance=width/3
            let cixleY = height / 2 + halfDistance * sin(θ)
            positionXY.updateValue([cicleX, cixleY], forKey: i)
        }
    }

    func getPosition(frame _: CGRect) -> [Int: [Double]] {
        return positionXY
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func clearDraw(number: Int) -> UIView {
        let circle = UIView()
        circle.frame = CGRect(x: CGFloat(positionXY[number]![0]) - radius, y: CGFloat(positionXY[number]![1]) - radius, width: radius * 2, height: radius * 2)
        circle.backgroundColor = .blue
        circle.alpha = 0.6
        circle.layer.cornerRadius = radius * 2 / 2
        return circle
    }

    func nextDraw(number: Int) -> UIView {
        let circle = UIView()
        circle.frame = CGRect(x: CGFloat(positionXY[number]![0]) - radius, y: CGFloat(positionXY[number]![1]) - radius, width: radius * 2, height: radius * 2)
        circle.backgroundColor = .green
        circle.alpha = 0.6
        circle.layer.cornerRadius = radius * 2 / 2
        return circle
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
            let cicleX = width / 2 + halfDistance * cos(θ)
            let cicleY = height / 2 + halfDistance * sin(θ)
            // 文字を書く
            String(i).draw(at: CGPoint(x: cicleX, y: cicleY), withAttributes: [
                NSAttributedString.Key.foregroundColor: UIColor.blue,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 50),
            ])
            let circle = UIBezierPath(arcCenter: CGPoint(x: cicleX, y: cicleY), radius: radius, startAngle: 0, endAngle: CGFloat(Double.pi) * 2, clockwise: true)
            // 内側の色
            UIColor(red: 1, green: 1, blue: 1, alpha: 0.0).setFill()
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
