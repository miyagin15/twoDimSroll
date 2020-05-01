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

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_: CGRect) {
        // ここにUIBezierPathを記述する
        // 円
        let width = Double(UIScreen.main.bounds.size.width)
        let height = Double(UIScreen.main.bounds.size.height)
        for i in 0 ..< 12 {
            let degree = (Double(i) * 30.0)
            let θ = Double.pi / Double(180) * Double(degree)
            let circle = UIBezierPath(arcCenter: CGPoint(x: width / 2 + width / 3 * cos(θ), y: height / 2 + width / 3 * sin(θ)), radius: 30, startAngle: 0, endAngle: CGFloat(Double.pi) * 2, clockwise: true)
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
