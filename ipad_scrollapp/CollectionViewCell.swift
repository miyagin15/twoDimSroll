//
//  CollectionViewCell.swift
//  ipad_scrollapp
//
//  Created by miyata ginga on 2019/12/02.
//  Copyright © 2019 com.miyagin.ipad_scroll. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    var textLabel: UILabel?
    // var goalView = UIView()

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        // UILabelを生成.
        textLabel = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        textLabel?.text = "nil"
        layer.borderColor = UIColor.red.cgColor
        layer.borderWidth = 1

        textLabel?.font = UIFont.systemFont(ofSize: 36)
        textLabel?.backgroundColor = UIColor.white
        textLabel?.textAlignment = NSTextAlignment.center

        contentView.addSubview(textLabel!)
    }
}
