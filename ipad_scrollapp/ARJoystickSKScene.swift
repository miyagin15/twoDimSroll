//
//  ARJoystickSKScene.swift
//  ARJoystick
//
//  Created by Alex Nagy on 27/07/2018.
//  Copyright © 2018 Alex Nagy. All rights reserved.
//

import SpriteKit

class ARJoystickSKScene: SKScene {
    enum NodesZPosition: CGFloat {
        case joystick
    }

    lazy var analogJoystick: AnalogJoystick = {
        let js = AnalogJoystick(diameter: 150, colors: nil, images: (substrate: #imageLiteral(resourceName: "jSubstrate"), stick: #imageLiteral(resourceName: "jStick")))
        js.position = CGPoint(x: js.radius + 300,
                              y: js.radius + 50)
        js.zPosition = NodesZPosition.joystick.rawValue
        return js
    }()

    override func didMove(to _: SKView) {
        backgroundColor = .clear
        setupNodes()
        setupJoystick()
    }

    func setupNodes() {
        anchorPoint = CGPoint(x: 0.0, y: 0.0)
    }

    func setupJoystick() {
        addChild(analogJoystick)

        analogJoystick.trackingHandler = { [unowned self] data in
            NotificationCenter.default.post(name: joystickNotificationName, object: nil, userInfo: ["data": data])
        }
    }
}
