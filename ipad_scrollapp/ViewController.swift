//
//  ViewController.swift
//  test2
//
//  Created by ginga-miyata on 2019/08/02.
//  Copyright © 2019 ginga-miyata. All rights reserved.
//

import ARKit
import AudioToolbox
import Foundation
import Network
import SceneKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate {
    var myCollectionView: UICollectionView!

    var changeNum = 0
    var callibrationUseBool = true

    var inputMethodString = "position"

    // 顔を認識できている描画するView
    @IBOutlet var tracking: UIView!

    @IBOutlet var inputClutchView: UIView!

    @IBOutlet var goalLabel: UILabel!
    @IBAction func timeCount(_: Any) {}

    @IBOutlet var timeCount: UISlider!
    @IBOutlet var functionalExpression: UISlider!

    @IBOutlet var sceneView: ARSCNView!
    // スクロール量を調整するSlider
    var ratioChange: Float = 5.0
    @IBAction func ratioChanger(_ sender: UISlider) {
        ratioChange = sender.value * 10
    }

    @IBOutlet var buttonLabel: UIButton!
    @IBAction func changeUseFace(_: Any) {
        changeNum = changeNum + 1
        i = 0
        time = 0
        goalLabel.text = String(goalPositionInt[i])
    }

    // 下を向いている度合いを示す
    @IBOutlet var orietationLabel: UILabel!
    @IBAction func toConfig(_: Any) {
        let secondViewController = storyboard?.instantiateViewController(withIdentifier: "CalibrationViewController") as! CalibrationViewController
        secondViewController.modalPresentationStyle = .fullScreen
        present(secondViewController, animated: true, completion: nil)
    }

    @IBAction func sendFile(_: Any) {
        // createFile(fileArrData: tapData)
        createCSV(fileArrData: nowgoal_Data)
    }

    @IBOutlet var functionalExpressionLabel: UILabel!
    @IBOutlet var callibrationBoolLabel: UIButton!
    @IBAction func callibrationConfigChange(_: Any) {
        if callibrationUseBool == false {
            callibrationUseBool = true
            callibrationBoolLabel.setTitle("キャリブレーション使う", for: .normal)
            return
        } else {
            callibrationUseBool = false
            callibrationBoolLabel.setTitle("キャリブレーション使わない", for: .normal)
            return
        }
    }

    @IBOutlet var inputMethodLabel: UIButton!
    @IBAction func inputMethodChange(_: Any) {
        if inputMethodString == "velocity" {
            inputMethodString = "position"
            inputMethodLabel.setTitle("position", for: .normal)
            return
        } else if inputMethodString == "position" {
            inputMethodString = "velocity"
            inputMethodLabel.setTitle("velocity", for: .normal)
            return
        }
    }

    @IBOutlet var handsSlider: UISlider!
    let userDefaults = UserDefaults.standard
    @IBAction func deleteData(_: Any) {
        nowgoal_Data = []
        i = 0
        time = 0
        goalLabel.text = String(goalPositionInt[i])
        operateView.frame.origin = firstStartPosition
        userDefaults.set(operateView.frame.origin.x, forKey: "nowOperateViewPositionX")
        userDefaults.set(operateView.frame.origin.y, forKey: "nowOperateViewPositionY")
        dataAppendBool = true
        // views削除
        removeAllSubviews(parentView: transparentView)
    }

    func removeAllSubviews(parentView: UIView) {
        let subviews = parentView.subviews
        for subview in subviews {
            subview.removeFromSuperview()
        }
    }

    var firstStartPosition: CGPoint = CGPoint(x: 300, y: 330)

    @IBAction func startButton(_: Any) {
        i = 0
        time = 0
        goalLabel.text = String(goalPositionInt[i])
        operateView.frame.origin = firstStartPosition
        userDefaults.set(operateView.frame.origin.x, forKey: "nowOperateViewPositionX")
        userDefaults.set(operateView.frame.origin.y, forKey: "nowOperateViewPositionY")
        dataAppendBool = true
        removeAllSubviews(parentView: transparentView)
    }

    @IBOutlet var repeatNumberLabel: UILabel!

    @IBOutlet var goalView: UIView!

    @IBOutlet var transparentView: UIView!
    @IBOutlet var targetView: UIView!
    var repeatNumber: Int = 1

    private let cellIdentifier = "cell"
    // Trackingfaceを使うための設定
    private let defaultConfiguration: ARFaceTrackingConfiguration = {
        let configuration = ARFaceTrackingConfiguration()
        return configuration
    }()

    private var tapData: [[Float]] = [[]]
    private var nowgoal_Data: [Float] = []
    let callibrationArr: [String] = ["口左", "口右", "口上", "口下", "頰右", "頰左", "眉上", "眉下", "右笑", "左笑", "上唇", "下唇", "普通"]
    // 初期設定のためのMAXの座標を配列を保存する
    var callibrationPosition: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    // 初期設定のMINの普通の状態を保存する
    var callibrationOrdinalPosition: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var documentInteraction: UIDocumentInteractionController!

    var depthImageView: UIImageView!

    var operateView: UIView!
    var positionXY: [Int: [Double]]!

    let functionalExpressionVerticalSlider = UISlider(frame: CGRect(x: 450, y: 300, width: 350, height: 30))
    let functionalExpressionVerticalLabel = UILabel(frame: CGRect(x: 450, y: 50, width: 350, height: 30))

    var acceptableRange: Double!
    var drawView: DrawView!

    lazy var skView: SKView = {
        let view = SKView()
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        view.isHidden = false
        return view
    }()

    var joystickBackView = UIView(frame: CGRect(x: 800, y: 500, width: 150, height: 150))
    var joystickX: CGFloat = 0.0
    var joystickY: CGFloat = 0.0
    var touched: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        functionalExpressionVerticalSlider.minimumValue = -1
        functionalExpressionVerticalSlider.maximumValue = 1
        functionalExpressionVerticalSlider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        goalView.addSubview(functionalExpressionVerticalSlider)
        goalView.addSubview(functionalExpressionVerticalLabel)

        decideGoalpositionTimeCount(maxTime: dwellTime)
        initialCallibrationSettings()
        drawView = DrawView(frame: goalView.bounds)
        acceptableRange = Double(drawView.radius)

        createTargetView()
        createOperateView()

        sceneView.delegate = self
        //timeInterval秒に一回update関数を動かす
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)

        joystickBackView.backgroundColor = UIColor.white
        view.addSubview(joystickBackView)
        setupSKView()
        setupSKViewScene()
        NotificationCenter.default.addObserver(forName: joystickNotificationName, object: nil, queue: OperationQueue.main) { notification in
            guard let userInfo = notification.userInfo else { return }
            let data = userInfo["data"] as! AnalogJoystickData
            self.touched = true
            print(data.description)
            self.joystickX = data.velocity.x
            self.joystickY = data.velocity.y
        }
    }

    func setupSKView() {
        joystickBackView.addSubview(skView)
        skView.anchor(nil, left: joystickBackView.leftAnchor, bottom: joystickBackView.bottomAnchor, right: joystickBackView.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 360)
    }

    func setupSKViewScene() {
        let scene = ARJoystickSKScene(size: CGSize(width: joystickBackView.bounds.size.width, height: 360))
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
    }

    @objc func update() {
        DispatchQueue.main.async {
            self.tracking.backgroundColor = UIColor.white
        }
    }

    private func createTargetView() {
        // 二次元の目標地点を生成
        goalView.addSubview(drawView)
        positionXY = drawView.getPosition(frame: goalView.bounds)
        for (key, value) in positionXY {
            print("\(key)はx:\(value[0]),y:\(value[1])です")
        }
    }

    private func createOperateView() {
        // 動かすview生成
        operateView = UIView(frame: CGRect(x: goalView.frame.width / 2, y: goalView.frame.height / 2, width: 10, height: 10))
        operateView.backgroundColor = UIColor.red
        goalView.addSubview(operateView)
    }

    private func initialCallibrationSettings() {
        for x in 0 ... 11 {
            if let value = userDefaults.string(forKey: callibrationArr[x]) {
                callibrationPosition[x] = Float(value)!
            } else {
                print("no value", x)
            }
        }
        for x in 0 ... 11 {
            callibrationOrdinalPosition[x] = userDefaults.float(forKey: "普通" + callibrationArr[x])
        }
    }

    private func decideGoalpositionTimeCount(maxTime _: Int) {
        goalLabel.text = String(goalPositionInt[0])
        timeCount.maximumValue = Float(dwellTime)
        timeCount.minimumValue = 0
        timeCount.value = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run(defaultConfiguration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    var LPFRatio: CGFloat = 0.1
    var lastValueR: CGFloat = 0
    var maxValueR: CGFloat = 0
    var lastValueL: CGFloat = 0
    var maxValueL: CGFloat = 0
    var lastValueU: CGFloat = 0
    var maxValueU: CGFloat = 0
    var lastValueD: CGFloat = 0
    var maxValueD: CGFloat = 0
    private func commonScroll(ratio: CGFloat, direction: String) {
        var restrictViewRange: CGFloat = 0
        var directionSign: CGFloat = 1
        var realRatioValue = ratio
        if direction == "right" {
            restrictViewRange = 600
            if operateView.frame.origin.x > restrictViewRange {
                return
            }
        } else if direction == "left" {
            restrictViewRange = 0
            if operateView.frame.origin.x < restrictViewRange {
                return
            }
            directionSign = -1
            realRatioValue = -1 * ratio
        } else if direction == "up" {
            restrictViewRange = 0
            if operateView.frame.origin.y < restrictViewRange {
                return
            }
            directionSign = -1
            realRatioValue = -1 * ratio
        } else if direction == "down" {
            restrictViewRange = 660
            if operateView.frame.origin.y > restrictViewRange {
                return
            }
        }
        var outPutLPF_R = LPFRatio * lastValueR + (1 - LPFRatio) * ratio
        var outPutLPF_L = LPFRatio * lastValueL + (1 - LPFRatio) * ratio
        var outPutLPF_U = LPFRatio * lastValueU + (1 - LPFRatio) * ratio
        var outPutLPF_D = LPFRatio * lastValueD + (1 - LPFRatio) * ratio
        var outPutLPF_LR: CGFloat = 0
        var outPutLPF_UD: CGFloat = 0
        if (direction == "left") || (direction == "right") {
            functionalExpression.value = Float(realRatioValue)
            functionalExpressionLabel.text = "X:" + String(Float(realRatioValue))
            if direction == "left" {
                outPutLPF_L = LPFRatio * lastValueL + (1 - LPFRatio) * ratio
                lastValueL = outPutLPF_L
                outPutLPF_LR = lastValueL
                lastValueR = 0
            } else if direction == "right" {
                outPutLPF_R = LPFRatio * lastValueR + (1 - LPFRatio) * ratio
                lastValueR = outPutLPF_R
                outPutLPF_LR = lastValueR
                lastValueL = 0
            }

        } else if (direction == "up") || (direction == "down") {
            functionalExpressionVerticalSlider.value = Float(-realRatioValue)
            functionalExpressionVerticalLabel.text = "Y:" + String(Float(-realRatioValue))
            if direction == "up" {
                outPutLPF_U = LPFRatio * lastValueU + (1 - LPFRatio) * ratio
                lastValueU = outPutLPF_U
                outPutLPF_UD = lastValueU
                lastValueD = 0
            } else if direction == "down" {
                outPutLPF_D = LPFRatio * lastValueD + (1 - LPFRatio) * ratio
                lastValueD = outPutLPF_D
                outPutLPF_UD = lastValueD
                lastValueU = 0
            }
        }
        if inputMethodString == "velocity" {
            var changedRatio = scrollRatioChange(ratio)
            // mouth only
            if changeNum == 2 || changeNum == 4 {
                if lastValueD > 0.3, lastValueL > 0.3 {
                    changedRatio = scrollRatioChange(ratio * 1.5)
                    print("DL")
                }
                if lastValueD > 0.3, lastValueR > 0.3 {
                    changedRatio = scrollRatioChange(ratio * 1.5)
                    print("DR")
                }
                if lastValueU > 0.3, lastValueR > 0.3 {
                    changedRatio = scrollRatioChange(ratio * 1.5)
                    print("UR")
                }
                if lastValueU > 0.3, lastValueL > 0.3 {
                    changedRatio = scrollRatioChange(ratio * 1.5)
                    print("UL")
                }
            }
        } else if inputMethodString == "position" {
            // 遠くに動かす必要がない位置操作
            if changeNum == 2 {
                if direction == "right" {
                    operateView.frame.origin.x = goalView.frame.width / 2 + CGFloat(ratioChange) * lastValueR * 50
                } else if direction == "left" {
                    operateView.frame.origin.x = goalView.frame.width / 2 - CGFloat(ratioChange) * lastValueL * 50
                } else if direction == "up" {
                    operateView.frame.origin.y = goalView.frame.height / 2 - CGFloat(ratioChange) * lastValueU * 70
                } else if direction == "down" {
                    operateView.frame.origin.y = goalView.frame.height / 2 + CGFloat(ratioChange) * lastValueD * 70
                }
            } else {
                if direction == "right" {
                    operateView.frame.origin.x = goalView.frame.width / 2 + CGFloat(ratioChange) * lastValueR * 50
                } else if direction == "left" {
                    operateView.frame.origin.x = goalView.frame.width / 2 - CGFloat(ratioChange) * lastValueL * 50
                } else if direction == "up" {
                    operateView.frame.origin.y = goalView.frame.height / 2 - CGFloat(ratioChange) * lastValueU * 50
                } else if direction == "down" {
                    operateView.frame.origin.y = goalView.frame.height / 2 + CGFloat(ratioChange) * lastValueD * 50
                }
            }
            return
            // 　一次元の時と同じ位置操作
            if (direction == "left") || (direction == "right") {
                if maxValueR < outPutLPF_LR {
                    maxValueR = outPutLPF_LR
                    let ClutchPosition = userDefaults.float(forKey: "beforeOperateViewPositionX")
                    let tempPosition1 = CGFloat(ClutchPosition)
                    let tempPosition2 = directionSign * 100 * outPutLPF_LR * CGFloat(ratioChange)
                    operateView.frame.origin.x = tempPosition1 + tempPosition2
                    userDefaults.set(operateView.frame.origin.x, forKey: "nowOperateViewPositionX")

                } else if outPutLPF_LR < 0.05 {
                    maxValueR = 0.05
                    let ClutchPosition = userDefaults.float(forKey: "nowOperateViewPositionX")
                    operateView.frame.origin.x = CGFloat(ClutchPosition)
                    userDefaults.set(operateView.frame.origin.x, forKey: "beforeOperateViewPositionX")

                } else if maxValueR - 0.3 > outPutLPF_LR {
                    maxValueR = outPutLPF_LR

                    let ClutchPosition = userDefaults.float(forKey: "nowOperateViewPositionX")
                    operateView.frame.origin.x = CGFloat(ClutchPosition)
                    userDefaults.set(operateView.frame.origin.x, forKey: "beforeOperateViewPositionX")
                }

            } else if (direction == "up") || (direction == "down") {
                if maxValueU < outPutLPF_UD {
                    maxValueU = outPutLPF_UD
                    let ClutchPosition = userDefaults.float(forKey: "beforeOperateViewPositionY")
                    let tempPosition1 = CGFloat(ClutchPosition)
                    let tempPosition2 = directionSign * 100 * outPutLPF_UD * CGFloat(ratioChange)
                    print(ClutchPosition, tempPosition2)
                    operateView.frame.origin.y = tempPosition1 + tempPosition2
                    userDefaults.set(operateView.frame.origin.y, forKey: "nowOperateViewPositionY")
                } else if outPutLPF_UD < 0.05 {
                    maxValueU = 0.05
                    let ClutchPosition = userDefaults.float(forKey: "nowOperateViewPositionY")
                    operateView.frame.origin.y = CGFloat(ClutchPosition)
                    userDefaults.set(operateView.frame.origin.y, forKey: "beforeOperateViewPositionY")
                } else if maxValueU - 0.3 > outPutLPF_UD {
                    maxValueU = outPutLPF_UD
                    let ClutchPosition = userDefaults.float(forKey: "nowOperateViewPositionY")
                    operateView.frame.origin.y = CGFloat(ClutchPosition)
                    userDefaults.set(operateView.frame.origin.y, forKey: "beforeOperateViewPositionY")
                }
            }
        }
    }

    private func rightScrollMainThread(ratio: CGFloat) {
        DispatchQueue.main.async {
            if self.operateView.frame.origin.x > 600 {
                return
            }
            self.commonScroll(ratio: ratio, direction: "right")
        }
    }

    // left scroll
    private func leftScrollMainThread(ratio: CGFloat) {
        DispatchQueue.main.async {
            if self.operateView.frame.origin.x < 0 {
                return
            }
            self.commonScroll(ratio: ratio, direction: "left")
        }
    }

    private func upScrollMainThread(ratio: CGFloat) {
        DispatchQueue.main.async {
            if self.operateView.frame.origin.y < 0 {
                return
            }
            self.commonScroll(ratio: ratio, direction: "up")
        }
    }

    private func downScrollMainThread(ratio: CGFloat) {
        DispatchQueue.main.async {
            if self.operateView.frame.origin.y > 660 {
                return
            }
            self.commonScroll(ratio: ratio, direction: "down")
        }
    }

    private func scrollRatioChange(_ ratioValue: CGFloat) -> CGFloat {
        var changeRatio: CGFloat = 0
//        if ratioValue < 0.25 {
//            changeRatio = ratioValue * 0.2
//        } else if ratioValue > 0.55 {
//            changeRatio = (ratioValue - 0.55) * 1.5 + 0.35
//        } else {
//            changeRatio = ratioValue - 0.25 + 0.05
//        }
        changeRatio = tanh((ratioValue * 3 - 1.5 - 0.8) * 3.14 / 2) * 0.7 + 0.7
        return changeRatio
    }

    // MARK: - ARSCNViewDelegate

    func session(_: ARSession, didFailWithError _: Error) {
        // Present an error message to the user
    }

    func sessionWasInterrupted(_: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }

    func sessionInterruptionEnded(_: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }

    var i: Int = 0
    var time: Int = 0
    //tarcking状態
    let sound: SystemSoundID = 1013
    var distanceAtXYPoint: Float32 = Float32(0)
    var dataAppendBool = true
    let widthIpad: Float = 1194.0
    let heightIpad: Float = 834.0
    var handsSliderValue: Float = 0
    var workTime: Float = 0
    var transTrans = CGAffineTransform() // 移動
    func renderer(_: SCNSceneRenderer, didUpdate _: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return
        }
        // print(faceAnchor.transform.columns.3)
        DispatchQueue.main.async {
            self.inputClutchView.backgroundColor = UIColor.red
            self.tracking.backgroundColor = UIColor.blue
        }
        // 顔のxyz位置
        // print(faceAnchor.transform.columns.3.x, faceAnchor.transform.columns.3.y, faceAnchor.transform.columns.3.z)
        DispatchQueue.main.async {
            if self.nowgoal_Data.count % ProductOfColumnsAndFps == 0 {
                self.orietationLabel.text = String(Float(self.nowgoal_Data.count / ProductOfColumnsAndFps) - self.workTime)
                if (Float(self.nowgoal_Data.count / ProductOfColumnsAndFps) - self.workTime) > Float(Fps) {
                    self.inputClutchView.backgroundColor = UIColor.white
                }
            }
        }
        // 判定処理
        DispatchQueue.main.async {
            // frame.originはviewの左上なことに注意
            let operationViewPositionX = self.operateView.frame.origin.x + self.operateView.frame.width / 2
            let operationViewPositionY = self.operateView.frame.origin.y + self.operateView.frame.height / 2
            let distanceFromCentral = pow(Double(operationViewPositionX) - self.positionXY[goalPositionInt[self.i]]![0], 2) + pow(Double(operationViewPositionY) - self.positionXY[goalPositionInt[self.i]]![1], 2)
            if distanceFromCentral < self.acceptableRange * self.acceptableRange {
                self.time = self.time + 1
                self.timeCount.value = Float(self.time)

                if self.time > dwellTime {
                    AudioServicesPlaySystemSound(self.sound)
                    if self.i < goalPositionInt.count - 1 {
                        self.transparentView.addSubview(self.drawView.clearDraw(number: goalPositionInt[self.i]))
                        self.transparentView.addSubview(self.drawView.nextDraw(number: goalPositionInt[self.i + 1]))
                        self.i = self.i + 1
                        self.timeCount.value = 0
                        self.buttonLabel.backgroundColor = UIColor.blue
                        if self.i == goalPositionInt.count - 1 {
                            self.goalLabel.text = "次:" + String(goalPositionInt[self.i])
                        } else {
                            self.goalLabel.text = "次:" + String(goalPositionInt[self.i]) + "---次の次:" + String(goalPositionInt[self.i + 1])
                        }
                    } else {
                        // self.myCollectionView.contentOffset.x = firstStartPosition
                        self.operateView.frame.origin = CGPoint(x: self.goalView.frame.width / 2, y: self.goalView.frame.height / 2)
                        // 2回目以降
                        if self.repeatNumber != 1 {
                            self.goalLabel.text = "終了!" + String(Float(self.nowgoal_Data.count / ProductOfColumnsAndFps) - self.workTime) + "秒かかった"
                            self.workTime = Float(self.nowgoal_Data.count / ProductOfColumnsAndFps)
                        } else {
                            self.workTime = Float(self.nowgoal_Data.count / ProductOfColumnsAndFps)
                            var ID: Double = log2(Double(self.drawView.halfDistance) / Double(self.drawView.radius) + 1)
                            var TP: Double = ID * 9 / Double(self.workTime - 4)
                            ID = round(ID * 10) / 10
                            TP = round(TP * 10) / 10
                            self.goalLabel.text = "終了." + String(self.workTime) + "s." + "TP:\(TP),ID:\(ID)"
                            print("ID:\(ID),TP:\(TP)")
                        }

                        self.dataAppendBool = false
                        self.repeatNumber = self.repeatNumber + 1
                        self.time = 0
                        // self.userDefaults.set(self.myCollectionView.contentOffset.x, forKey: "nowCollectionViewPosition")
                        // データをパソコンに送る(今の場所と目標地点)
                        DispatchQueue.main.async {
                            self.repeatNumberLabel.text = String(self.repeatNumber) + "回目"
                            // self.NetWork.send(message: [0,0])
                        }
                    }
                }
            } else {
                self.time = 0
            }
        }
        // CSVを作るデータに足していく
        if dataAppendBool == true {
            DispatchQueue.main.async {
                if self.i > 0 {
                    // self.tapData.append([(Float(self.tableViewPosition)),(self.goalPosition[self.i])])
                    self.nowgoal_Data.append(Float(self.positionXY[goalPositionInt[self.i]]![0]))
                    self.nowgoal_Data.append(Float(self.positionXY[goalPositionInt[self.i]]![1]))
                    self.nowgoal_Data.append(Float(self.operateView.frame.origin.x))
                    self.nowgoal_Data.append(Float(self.operateView.frame.origin.y))
                    self.nowgoal_Data.append(Float(self.functionalExpression.value))
                    self.nowgoal_Data.append(Float(self.functionalExpressionVerticalSlider.value))
                }
            }
        }

        let changeAction = changeNum % 5

        switch changeAction {
        case 0:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("mouthRL_browUD", for: .normal)
            }
            var mouthLeft: Float = 0
            var mouthRight: Float = 0
            mouthLeft = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][0], maxFaceAUVertex: callibrationPosition[0], minFaceAUVertex: callibrationOrdinalPosition[0])
            mouthRight = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][0], maxFaceAUVertex: callibrationPosition[1], minFaceAUVertex: callibrationOrdinalPosition[1])
            if mouthLeft > mouthRight {
                leftScrollMainThread(ratio: CGFloat(mouthLeft))

            } else if mouthRight > mouthLeft {
                rightScrollMainThread(ratio: CGFloat(mouthRight))
            }

            var browInnerUp: Float = 0
            var browDownLeft: Float = 0
            browInnerUp = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[762][1], maxFaceAUVertex: callibrationPosition[6], minFaceAUVertex: callibrationOrdinalPosition[6])
            browDownLeft = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[762][1], maxFaceAUVertex: callibrationPosition[7], minFaceAUVertex: callibrationOrdinalPosition[7])
            if browInnerUp > browDownLeft {
                upScrollMainThread(ratio: CGFloat(browInnerUp))
            } else {
                downScrollMainThread(ratio: CGFloat(browDownLeft))
            }

        case 1:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("mouthSmileRL_browUD", for: .normal)
            }
            var cheekR: Float = 0
            var cheekL: Float = 0
            cheekR = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[638][0], maxFaceAUVertex: callibrationPosition[8], minFaceAUVertex: callibrationOrdinalPosition[8])

            cheekL = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[405][0], maxFaceAUVertex: callibrationPosition[9], minFaceAUVertex: callibrationOrdinalPosition[9])
            if cheekL > cheekR {
                leftScrollMainThread(ratio: CGFloat(cheekL))
            } else {
                rightScrollMainThread(ratio: CGFloat(cheekR))
            }
            var browInnerUp: Float = 0
            var browDownLeft: Float = 0

            browInnerUp = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[762][1], maxFaceAUVertex: callibrationPosition[6], minFaceAUVertex: callibrationOrdinalPosition[6])
            browDownLeft = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[762][1], maxFaceAUVertex: callibrationPosition[7], minFaceAUVertex: callibrationOrdinalPosition[7])
            if browInnerUp > browDownLeft {
                upScrollMainThread(ratio: CGFloat(browInnerUp))
            } else {
                downScrollMainThread(ratio: CGFloat(browDownLeft))
            }

        case 2:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("mouthCentral", for: .normal)
            }
            var mouthLeft: Float = 0
            var mouthRight: Float = 0
            mouthLeft = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][0], maxFaceAUVertex: callibrationPosition[0], minFaceAUVertex: callibrationOrdinalPosition[0])
            // print("mouthLeft", mouthLeft)
            mouthRight = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][0], maxFaceAUVertex: callibrationPosition[1], minFaceAUVertex: callibrationOrdinalPosition[1])

            if mouthLeft > mouthRight {
                leftScrollMainThread(ratio: CGFloat(mouthLeft))

            } else if mouthRight > mouthLeft {
                rightScrollMainThread(ratio: CGFloat(mouthRight))
            }
            var mouthUp: Float = 0
            var mouthDown: Float = 0
            if callibrationUseBool == true {
                mouthUp = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][1], maxFaceAUVertex: callibrationPosition[2], minFaceAUVertex: callibrationOrdinalPosition[2])
                mouthDown = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][1], maxFaceAUVertex: callibrationPosition[3], minFaceAUVertex: callibrationOrdinalPosition[3])
            } else {
                mouthUp = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][1], maxFaceAUVertex: -0.03719348, minFaceAUVertex: -0.04107782)
                mouthDown = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][1], maxFaceAUVertex: -0.04889179, minFaceAUVertex: -0.04107782)
            }
//             if mouthUp < 0.1, mouthDown < 0.1 {
//                 return
//             }
            if mouthUp > mouthDown {
                upScrollMainThread(ratio: CGFloat(mouthUp))
            } else {
                downScrollMainThread(ratio: CGFloat(mouthDown))
            }

        case 3:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("mouthPosition", for: .normal)
            }
            var mouthUp: Float = 0
            var mouthDown: Float = 0
            var mouthLeft: Float = 0
            var mouthRight: Float = 0

            mouthUp = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][1], maxFaceAUVertex: callibrationPosition[2], minFaceAUVertex: callibrationOrdinalPosition[2])
            mouthDown = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][1], maxFaceAUVertex: callibrationPosition[3], minFaceAUVertex: callibrationOrdinalPosition[3])
            mouthLeft = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][0], maxFaceAUVertex: callibrationPosition[0], minFaceAUVertex: callibrationOrdinalPosition[0])
            // print("mouthLeft", mouthLeft)
            mouthRight = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][0], maxFaceAUVertex: callibrationPosition[1], minFaceAUVertex: callibrationOrdinalPosition[1])

//             if mouthUp < 0.1, mouthDown < 0.1 {
//                 return
//             }
            var xMove: Float = 0
            var yMove: Float = 0
            if mouthUp > mouthDown {
                upScrollMainThread(ratio: CGFloat(mouthUp))
                yMove = -mouthUp
            } else {
                downScrollMainThread(ratio: CGFloat(mouthDown))
                yMove = mouthDown
            }
            if mouthLeft > mouthRight {
                leftScrollMainThread(ratio: CGFloat(mouthLeft))
                xMove = -mouthLeft
            } else {
                rightScrollMainThread(ratio: CGFloat(mouthRight))
                xMove = mouthRight
            }
//            DispatchQueue.main.async {
//                self.operateView.frame = CGRect(x: self.goalView.frame.width / 2 + CGFloat(xMove) * 250, y: self.goalView.frame.height / 2 + CGFloat(yMove) * 250, width: 10, height: 10)
//            }

        case 4:
//            DispatchQueue.main.async {
//                self.buttonLabel.setTitle("hands", for: .normal)
//                if self.touched == true {
//                    self.operateView.frame.origin.x = 300 + CGFloat(self.joystickX * joystickVelocityMultiplier) * 50
//                    self.operateView.frame.origin.y = 400 - CGFloat(self.joystickY * joystickVelocityMultiplier) * 50
//                }
//                self.touched = false
//            }
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("hands", for: .normal)
                if self.touched == true {
//                    self.operateView.frame.origin.x += CGFloat(self.joystickX * joystickVelocityMultiplier)
//                    self.operateView.frame.origin.y -= CGFloat(self.joystickY * joystickVelocityMultiplier)
                    if CGFloat(self.joystickX) > 0 {
                        self.rightScrollMainThread(ratio: CGFloat(self.joystickX * joystickVelocityMultiplier))
                    } else if CGFloat(self.joystickX) < 0 {
                        self.leftScrollMainThread(ratio: -CGFloat(self.joystickX * joystickVelocityMultiplier))
                    }
                    if CGFloat(self.joystickY) > 0 {
                        self.upScrollMainThread(ratio: CGFloat(self.joystickY * joystickVelocityMultiplier))
                    } else if CGFloat(self.joystickY) < 0 {
                        self.downScrollMainThread(ratio: -CGFloat(self.joystickY * joystickVelocityMultiplier))
                    }
                }
                self.touched = false
            }
        case 5:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("ripRoll", for: .normal)
            }
        default:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("Hands", for: .normal)
                self.handsSliderValue = self.handsSlider.value
            }
            if handsSliderValue > 0 {
                rightScrollMainThread(ratio: CGFloat(handsSliderValue))
            } else {
                leftScrollMainThread(ratio: CGFloat(-handsSliderValue))
            }
        }
    }

    func createCSV(fileArrData: [Float]) {
        let CSVFileData = Utility.createCSVFileData(fileArrData: fileArrData, facailAU: buttonLabel.titleLabel!.text!, direction: "twoDim", inputMethod: inputMethodString)
        let fileName = CSVFileData.fileName
        let fileStrData = CSVFileData.fileData
        // DocumentディレクトリのfileURLを取得
        let documentDirectoryFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!

        // ディレクトリのパスにファイル名をつなげてファイルのフルパスを作る
        let FilePath = documentDirectoryFileURL.appendingPathComponent(fileName)

        print("書き込むファイルのパス: \(FilePath)")

        do {
            try fileStrData.write(to: FilePath, atomically: true, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            print("failed to write: \(error)")
        }

        documentInteraction = UIDocumentInteractionController(url: FilePath)
        documentInteraction.presentOpenInMenu(from: CGRect(x: 10, y: 10, width: 100, height: 50), in: view, animated: true)
        nowgoal_Data = []
        repeatNumber = 1
        repeatNumberLabel.text = String(repeatNumber) + "回目"
    }
}
