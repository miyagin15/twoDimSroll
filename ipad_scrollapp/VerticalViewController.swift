//
//  ViewController.swift
//  test2
//
//  Created by ginga-miyata on 2019/08/02.
//  Copyright © 2019 ginga-miyata. All rights reserved.
//

import ARKit
import Network
import SceneKit
import UIKit

class VerticalViewController: UIViewController, ARSCNViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    var myCollectionView: UICollectionView!

    var changeNum = 0
    var callibrationUseBool = true

    var inputMethodString = "velocity"

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
                //        } else if inputMethodString == "position" {
                //            inputMethodString = "p_mouse"
                //            inputMethodLabel.setTitle("p_mouse", for: .normal)
                //            return
        } else if inputMethodString == "position" {
            inputMethodString = "velocity"
            inputMethodLabel.setTitle("velocity", for: .normal)
            return
        }
    }

    // 値を端末に保存するために宣言
    let userDefaults = UserDefaults.standard

    @IBAction func deleteButton(_: Any) {
        nowgoal_Data = []
        i = 0
        time = 0
        goalLabel.text = String(goalPositionInt[i])
        myCollectionView.contentOffset.y = firstStartPosition
        userDefaults.set(myCollectionView.contentOffset.y, forKey: "nowCollectionViewPosition")
        dataAppendBool = true
    }

    @IBAction func startButton(_: Any) {
        // nowgoal_Data = []
        i = 0
        time = 0
        goalLabel.text = String(goalPositionInt[i])
        myCollectionView.contentOffset.y = firstStartPosition
        userDefaults.set(myCollectionView.contentOffset.y, forKey: "nowCollectionViewPosition")
        dataAppendBool = true
    }

    @IBOutlet var handsSlider: UISlider!
    @IBOutlet var repeatNumberLabel: UILabel!
    var repeatNumber: Int = 1

    private let cellIdentifier = "cell"
    // Trackingfaceを使うための設定
    private let defaultConfiguration: ARFaceTrackingConfiguration = {
        let configuration = ARFaceTrackingConfiguration()
        return configuration
    }()

    // var NetWork = NetWorkViewController()
    // ゴールの目標セルを決める
    // var goalPositionInt: [Int] = [15, 14, 13, 12, 11, 10, 20, 16, 17, 18, 19]
    // ゴールの目標位置を決める.数だけは合わせる必要がある
    var goalPosition: [Float] = [0, 0, 13, 12, 11, 10, 20, 16, 17, 18, 19]
    private var tapData: [[Float]] = [[]]
    private var nowgoal_Data: [Float] = []
    let callibrationArr: [String] = ["口左", "口右", "口上", "口下", "頰右", "頰左", "眉上", "眉下", "右笑", "左笑", "上唇", "下唇", "普通"]
    // 初期設定のためのMAXの座標を配列を保存する
    var callibrationPosition: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    // 初期設定のMINの普通の状態を保存する
    var callibrationOrdinalPosition: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var documentInteraction: UIDocumentInteractionController!

    override func viewDidLoad() {
        super.viewDidLoad()
        functionalExpression.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        handsSlider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)

        // goalPositionInt = Utility.goalPositionInt
        createScrollVIew()
        decideGoalpositionTimeCount()
        createGoalView()
        initialCallibrationSettings()
        sceneView.delegate = self
        myCollectionView.contentOffset.y = firstStartPosition
        userDefaults.set(myCollectionView.contentOffset.y, forKey: "nowCollectionViewPosition")

        //timeInterval秒に一回update関数を動かす
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
    }

    @objc func update() {
        DispatchQueue.main.async {
            self.tracking.backgroundColor = UIColor.white
        }
    }

    // Cellの総数を返す
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return 100
    }

    // Cellに値を設定する
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: CollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath) as! CollectionViewCell
        cell.textLabel?.text = indexPath.row.description
        return cell
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

    // scrolViewを作成する
    private func createScrollVIew() {
        myCollectionView = Utility.createScrollView(directionString: "vertical")
        myCollectionView.delegate = self
        myCollectionView.dataSource = self
        view.addSubview(myCollectionView)
    }

    private func decideGoalpositionTimeCount() {
        goalLabel.text = String(goalPositionInt[0])
        for i in 0 ..< goalPositionInt.count {
            goalPosition[i] = Float(goalPositionInt[i] * 100 - 200)
        }
        timeCount.maximumValue = 60
        timeCount.minimumValue = 0
        timeCount.value = 0
    }

    private func createGoalView() {
        view.addSubview(Utility.createGoalView(directionString: "vertical")
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        sceneView.session.run(defaultConfiguration)
        // NetWork.startConnection(to: "a")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sceneView.session.pause()
        // NetWork.stopConnection()
    }

    var lastValueU: CGFloat = 0
    // LPFの比率
    var LPFRatio: CGFloat = 0.5
    var maxValueUP: CGFloat = 0
    // up scroll
    private func scrollUpInMainThread(ratio: CGFloat) {
        DispatchQueue.main.async {
            if self.myCollectionView.contentOffset.y > 6000 {
                return
            }
            self.functionalExpression.value = -Float(ratio)
            self.functionalExpressionLabel.text = String(-Float(ratio))
            let outPutLPF = self.LPFRatio * self.lastValueU + (1 - self.LPFRatio) * ratio
            self.lastValueU = outPutLPF

            if self.inputMethodString == "velocity" {
                let changedRatio = self.scrollRatioChange(ratio)
                self.myCollectionView.contentOffset = CGPoint(x: 0, y: self.myCollectionView.contentOffset.y + 10 * changedRatio * CGFloat(self.ratioChange))
            } else if self.inputMethodString == "position" {
                if self.maxValueUP < outPutLPF {
                    self.maxValueUP = outPutLPF
                    let ClutchPostition = self.userDefaults.float(forKey: "beforeCollectionViewPosition")
                    self.myCollectionView.contentOffset = CGPoint(x: 0, y: CGFloat(ClutchPostition) + 100 * outPutLPF * CGFloat(self.ratioChange))
                    self.userDefaults.set(self.myCollectionView.contentOffset.y, forKey: "nowCollectionViewPosition")
                } else if outPutLPF < 0.05 {
                    self.maxValueUP = 0.05
                    let ClutchPosition = self.userDefaults.float(forKey: "nowCollectionViewPosition")
                    self.myCollectionView.contentOffset = CGPoint(x: 0, y: CGFloat(ClutchPosition))
                    self.userDefaults.set(self.myCollectionView.contentOffset.y, forKey: "beforeCollectionViewPosition")
                } else if self.maxValueUP - 0.3 > outPutLPF {
                    self.maxValueUP = self.maxValueUP - 0.3
                    let ClutchPosition = self.userDefaults.float(forKey: "nowCollectionViewPosition")
                    self.myCollectionView.contentOffset = CGPoint(x: 0, y: CGFloat(ClutchPosition))
                    self.userDefaults.set(self.myCollectionView.contentOffset.y, forKey: "beforeCollectionViewPosition")
                }
            }

//                if self.ratioLookDown > 0.65 {
//                    self.userDefaults.set(self.myCollectionView.contentOffset.y, forKey: "nowCollectionViewPosition")
//                } else {
//                    let ClutchPosition = self.userDefaults.float(forKey: "nowCollectionViewPosition")
//                    self.myCollectionView.contentOffset = CGPoint(x: 0, y: CGFloat(ClutchPosition) + 100 * outPutLPF * CGFloat(self.ratioChange))
//                }
//            }
            // self.tableView.contentOffset = CGPoint(x: 0, y: self.tableView.contentOffset.y + 10*ratio*CGFloat(self.ratioChange))
        }
    }

    var lastValueD: CGFloat = 0
    var maxValueDown: CGFloat = 0
    // down scroll
    private func scrollDownInMainThread(ratio: CGFloat) {
        DispatchQueue.main.async {
            if self.myCollectionView.contentOffset.y < 0 {
                return
            }
            self.functionalExpression.value = Float(ratio)
            self.functionalExpressionLabel.text = String(Float(ratio))
            let outPutLPF = self.LPFRatio * self.lastValueD + (1 - self.LPFRatio) * ratio
            self.lastValueD = outPutLPF
            if self.inputMethodString == "velocity" {
                let changedRatio = self.scrollRatioChange(ratio)
                self.myCollectionView.contentOffset = CGPoint(x: 0, y: self.myCollectionView.contentOffset.y - 10 * changedRatio * CGFloat(self.ratioChange))
            } else if self.inputMethodString == "position" {
                if self.maxValueDown < outPutLPF {
                    self.maxValueDown = outPutLPF
                    let ClutchPostition = self.userDefaults.float(forKey: "beforeCollectionViewPosition")
                    self.myCollectionView.contentOffset = CGPoint(x: 0, y: CGFloat(ClutchPostition) - 100 * outPutLPF * CGFloat(self.ratioChange))
                    self.userDefaults.set(self.myCollectionView.contentOffset.y, forKey: "nowCollectionViewPosition")
                } else if outPutLPF < 0.05 {
                    self.maxValueDown = 0.05
                    let ClutchPosition = self.userDefaults.float(forKey: "nowCollectionViewPosition")
                    self.myCollectionView.contentOffset = CGPoint(x: 0, y: CGFloat(ClutchPosition))
                    self.userDefaults.set(self.myCollectionView.contentOffset.y, forKey: "beforeCollectionViewPosition")
                } else if self.maxValueDown - 0.3 > outPutLPF {
                    self.maxValueDown = self.maxValueDown - 0.3
                    let ClutchPosition = self.userDefaults.float(forKey: "nowCollectionViewPosition")
                    self.myCollectionView.contentOffset = CGPoint(x: 0, y: CGFloat(ClutchPosition))
                    self.userDefaults.set(self.myCollectionView.contentOffset.y, forKey: "beforeCollectionViewPosition")
                }
            }
//                if self.ratioLookDown > 0.65 {
//                    self.userDefaults.set(self.myCollectionView.contentOffset.y, forKey: "nowCollectionViewPosition")
//                } else {
//                    let ClutchPosition = self.userDefaults.float(forKey: "nowCollectionViewPosition")
//                    self.myCollectionView.contentOffset = CGPoint(x: 0, y: CGFloat(ClutchPosition) - 100 * outPutLPF * CGFloat(self.ratioChange))
//                }
//            }
            // self.tableView.contentOffset = CGPoint(x: 0, y: self.tableView.contentOffset.y - 10*ratio*CGFloat(self.ratioChange))
        }
    }

    private func scrollRatioChange(_ ratioValue: CGFloat) -> CGFloat {
        var changeRatio: CGFloat = 0
        // y = 1.5x^2
        // changeRatio = 1.5 * ratioValue * ratioValue

        //        if ratioValue < 0.25 {
        //            changeRatio = ratioValue * 0.2
        //        } else if ratioValue > 0.55 {
        //            changeRatio = (ratioValue - 0.55) * 1.5 + 0.35
        //        } else {
        //            changeRatio = ratioValue - 0.25 + 0.05
        //        }
        changeRatio = tanh((ratioValue * 3 - 1.5 - 0.8) * 3.14 / 2) * 0.7 + 0.7
        // changeRatio = ratioValue

        //        if ratioValue < 0.55 {
        //            changeRatio = 0.10
        //        } else if ratioValue > 0.55 {
        //            changeRatio = 1
        //        }

        // print(changeRatio, "changeRatio")
        //        if ratioValue < 0.25 {
        //            changeRatio = ratioValue * 0.2
        //        } else if ratioValue > 0.55 {
        //            changeRatio = ratioValue * 1.5
        //        } else {
        //            changeRatio = ratioValue
        //        }
        return changeRatio
    }

    // right scroll
    private func rightScrollMainThread(ratio: CGFloat) {
        DispatchQueue.main.async {
            if self.myCollectionView.contentOffset.x > 8000 {
                return
            }
            self.functionalExpression.value = Float(ratio)
            self.functionalExpressionLabel.text = String(Float(ratio))
            if ratio < 0.25 {
                let ratio = ratio * 0.3
                self.myCollectionView.contentOffset = CGPoint(x: self.myCollectionView.contentOffset.x + 10 * ratio * CGFloat(self.ratioChange), y: 0)
            } else if ratio > 0.55 {
                let ratio = ratio * 1.5
                self.myCollectionView.contentOffset = CGPoint(x: self.myCollectionView.contentOffset.x + 10 * ratio * CGFloat(self.ratioChange), y: 0)
            } else {
                self.myCollectionView.contentOffset = CGPoint(x: self.myCollectionView.contentOffset.x + 10 * ratio * CGFloat(self.ratioChange), y: 0)
            }
            // self.tableView.contentOffset = CGPoint(x: 0, y: self.tableView.contentOffset.y + 10*ratio*CGFloat(self.ratioChange))
        }
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
    var tableViewPosition: CGFloat = 0
    var myCollectionViewPosition: CGFloat = 0
    var before_cheek_right: Float = 0
    var after_cheek_right: Float = 0
    var before_cheek_left: Float = 0
    var after_cheek_left: Float = 0
    let sound: SystemSoundID = 1013
    var ratioLookDown: Float = 0

    var handsSliderValue: Float = 0
    var workTime: Float = 0

    var dataAppendBool = true
    // let firstConfig:[Float] = userDefaults.array(forKey: "firstConfig") as! [Float]

    func renderer(_: SCNSceneRenderer, didUpdate _: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return
        }
        //  認識していたら青色に
        DispatchQueue.main.async {
            // print(self.tableView.contentOffset.y)
            self.inputClutchView.backgroundColor = UIColor.red
            self.tracking.backgroundColor = UIColor.blue
        }
//        // 下を向いている時の処理
//        ratioLookDown = faceAnchor.transform.columns.1.z
//        DispatchQueue.main.async {
//            self.orietationLabel.text = String(self.ratioLookDown)
//        }

//        if ratioLookDown > 0.65 {
//            //  認識していたら青色に
//            DispatchQueue.main.async {
//                // print(self.tableView.contentOffset.y)
//                self.inputClutchView.backgroundColor = UIColor.white
//            }
//            print("うなづき")
//        }
        //  認識していたら青色に
        DispatchQueue.main.async {
            if self.nowgoal_Data.count % 120 == 0 {
                self.orietationLabel.text = String(Float(self.nowgoal_Data.count / 120) - self.workTime)
                //                self.userDefaults.set(self.myCollectionView.contentOffset.x, forKey: "nowCollectionViewPosition")
                // print(self.tableView.contentOffset.y)
                if (Float(self.nowgoal_Data.count / 120) - self.workTime) > 60 {
                    self.inputClutchView.backgroundColor = UIColor.white
                }
            }
        }

        let goal = goalPosition[self.i]
//        DispatchQueue.main.async {
//            self.tableViewPosition = self.tableView.contentOffset.y
//            //目標との距離が近くなったら
//            if( (Float(self.tableViewPosition) - goal) < 50 && (Float(self.tableViewPosition) - goal) > -50){
//                print("クリア")
//                self.time=self.time+1
//                self.timeCount.value=Float(self.time)
//                if(self.time>50){
//                    print("クリア2")
//                    if(self.i < self.goalPositionInt.count-1){
//                        self.i=self.i+1
//                        self.timeCount.value = 0
//                        self.buttonLabel.backgroundColor  = UIColor.blue
//                        self.goalLabel.text = "次:"+String(self.goalPositionInt[self.i]) + "---次の次:"+String(self.goalPositionInt[self.i+1])
//                    }else{
//                        self.tableView.contentOffset.y = 0
//                        self.goalLabel.text = "終了"
//                        //データをパソコンに送る(今の場所と目標地点)
//                        DispatchQueue.main.async {
//                            //self.NetWork.send(message: [0,0])
//                        }
//                    }
//                }
//            }else{
//                self.time=0
//            }
//        }
        DispatchQueue.main.async {
            self.myCollectionViewPosition = self.myCollectionView.contentOffset.y
            // 目標との距離が近くなったら
            if goal - 50 < Float(self.myCollectionViewPosition), Float(self.myCollectionViewPosition) < goal {
                // if((Float(self.myCollectionViewPosition)) - Float(100 * self.i) < -200.0 && (Float(self.myCollectionViewPosition)) - Float(100 * self.i) > -250.0){
                // if( (Float(self.myCollectionViewPosition) - goal) < 50 && (Float(self.myCollectionViewPosition) - goal) > -50){
                print("クリア")
                self.time = self.time + 1
                self.timeCount.value = Float(self.time)
                if self.time > 60 {
                    print("クリア2")
                    AudioServicesPlaySystemSound(self.sound)
                    if self.i < goalPositionInt.count - 1 {
                        self.i = self.i + 1
                        self.timeCount.value = 0
                        self.buttonLabel.backgroundColor = UIColor.blue
                        if self.i == goalPositionInt.count - 1 {
                            self.goalLabel.text = "次:" + String(goalPositionInt[self.i])
                        } else {
                            self.goalLabel.text = "次:" + String(goalPositionInt[self.i]) + "---次の次:" + String(goalPositionInt[self.i + 1])
                        }
                    } else {
                        self.myCollectionView.contentOffset.y = firstStartPosition
                        if self.repeatNumber != 1 {
                            self.goalLabel.text = "終了!" + String(Float(self.nowgoal_Data.count / 120) - self.workTime) + "秒かかった"
                            self.workTime = Float(self.nowgoal_Data.count / 120)
                        } else {
                            self.workTime = Float(self.nowgoal_Data.count / 120)
                            self.goalLabel.text = "終了." + String(self.workTime) + "sかかった"
                        }
                        self.dataAppendBool = false
                        self.repeatNumber = self.repeatNumber + 1
                        self.time = 0
                        self.userDefaults.set(self.myCollectionView.contentOffset.y, forKey: "nowCollectionViewPosition")
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
        //  認識していたら青色に
        DispatchQueue.main.async {
            // print(self.tableView.contentOffset.y)
            self.tracking.backgroundColor = UIColor.blue
        }

        // CSVを作るデータに足していく縦スクロール
//        DispatchQueue.main.async {
//            if((Float(self.tableViewPosition) > 5)){
//                //self.tapData.append([(Float(self.tableViewPosition)),(self.goalPosition[self.i])])
//                self.nowgoal_Data.append(Float(self.tableViewPosition))
//                self.nowgoal_Data.append(Float(self.goalPosition[self.i]))
//            }
//            if(Float(self.tableViewPosition) < -160){
//                self.goalLabel.text = "5.0"
//                self.nowgoal_Data = []
//                //self.tapData = []
//
//            }
//            //print(Float(self.tableViewPosition))
//            //データをパソコンに送る(今の場所と目標地点)
//            //self.NetWork.send(message: [Float(self.tableViewPosition),self.goalPosition[self.i]])
//        }
        // CSVを作るデータに足していく
        if dataAppendBool == true {
            DispatchQueue.main.async {
                if self.i > 0 {
                    // self.tapData.append([(Float(self.tableViewPosition)),(self.goalPosition[self.i])])
                    self.nowgoal_Data.append(Float(self.myCollectionViewPosition + 25))
                    self.nowgoal_Data.append(Float(self.goalPosition[self.i]))
                }
                // print(Float(self.tableViewPosition))
                // データをパソコンに送る(今の場所と目標地点)
                // self.NetWork.send(message: [Float(self.tableViewPosition),self.goalPosition[self.i]])
            }
        }

        let changeAction = changeNum % 7

        switch changeAction {
        case 0:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("MouthRL", for: .normal)
            }
            let mouthLeftBS = faceAnchor.blendShapes[.mouthLeft] as! Float
            let mouthRightBS = faceAnchor.blendShapes[.mouthRight] as! Float
            var mouthLeft: Float = 0
            var mouthRight: Float = 0
            if callibrationUseBool == true {
                mouthLeft = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][0], maxFaceAUVertex: callibrationPosition[0], minFaceAUVertex: callibrationOrdinalPosition[0])
                // print("mouthLeft", mouthLeft)
                mouthRight = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][0], maxFaceAUVertex: callibrationPosition[1], minFaceAUVertex: callibrationOrdinalPosition[1])
                // print("mouthRight", mouthRight)

//                if mouthLeft < 0.1, mouthRight < 0.1 {
//                    return
//                }

                // print(mouthLeftBS, mouthRightBS)
                // mouthRightが逆を表す
            } else {
//                if let mouthLeft = faceAnchor.blendShapes[.mouthLeft] as? Float {
//                    if mouthLeft > 0.02 {
//                        // self.scrollDownInMainThread(ratio: CGFloat(mouthLeft))
//                        rightScrollMainThread(ratio: CGFloat(mouthLeft))
//                    }
//                }
//                if let mouthRight = faceAnchor.blendShapes[.mouthRight] as? Float {
//                    if mouthRight > 0.02 {
//                        // self.scrollUpInMainThread(ratio: CGFloat(mouthRight))
//                        leftScrollMainThread(ratio: CGFloat(mouthRight))
//                    }
//                }
                mouthLeft = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[638][0], maxFaceAUVertex: 0.008952, minFaceAUVertex: 0.021727568)
                // print("mouthLeft", mouthLeft)
                mouthRight = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[405][0], maxFaceAUVertex: -0.004787985, minFaceAUVertex: -0.0196867)
                // print("mouthRight", mouthRight)
//                if mouthLeft < 0.1, mouthRight < 0.1 {
//                    return
//                }
//                // print(mouthLeftBS, mouthRightBS)
//                if mouthLeft > mouthRight, mouthRightBS > 0.01 {
//                    scrollUpInMainThread(ratio: CGFloat(mouthLeft))
//
//                } else if mouthRight > mouthLeft, mouthLeftBS > 0.01 {
//                    scrollDownInMainThread(ratio: CGFloat(mouthRight))
            }
            if mouthLeft > mouthRight {
                scrollUpInMainThread(ratio: CGFloat(mouthLeft))

            } else if mouthRight > mouthLeft {
                scrollDownInMainThread(ratio: CGFloat(mouthRight))
            }

        case 1:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("mouthHalfSmile", for: .normal)
            }
            let cheekSquintLeft = faceAnchor.blendShapes[.mouthSmileLeft] as! Float
            let cheekSquintRight = faceAnchor.blendShapes[.mouthSmileRight] as! Float
            var cheekR: Float = 0
            var cheekL: Float = 0
            if callibrationUseBool == true {
                cheekR = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[638][0], maxFaceAUVertex: callibrationPosition[8], minFaceAUVertex: callibrationOrdinalPosition[8])

                cheekL = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[405][0], maxFaceAUVertex: callibrationPosition[9], minFaceAUVertex: callibrationOrdinalPosition[9])
            } else {
                cheekR = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[638][0], maxFaceAUVertex: callibrationPosition[8], minFaceAUVertex: callibrationOrdinalPosition[8])

                cheekL = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[405][0], maxFaceAUVertex: callibrationPosition[9], minFaceAUVertex: callibrationOrdinalPosition[9])
            }
            if cheekL > cheekR {
                scrollUpInMainThread(ratio: CGFloat(cheekL))
            } else {
                scrollDownInMainThread(ratio: CGFloat(cheekR))
            }

            // 頰を動かす。口角のz座標
//            before_cheek_right = after_cheek_right
//            before_cheek_left = after_cheek_left
//            after_cheek_right = faceAnchor.geometry.vertices[636][2]+faceAnchor.geometry.vertices[678][2]+faceAnchor.geometry.vertices[635][2]
//
//
//            after_cheek_left = faceAnchor.geometry.vertices[405][2]+faceAnchor.geometry.vertices[243][2]+faceAnchor.geometry.vertices[245][2]
//            print(after_cheek_right)
//            print(after_cheek_left)

            /*
             print((after_cheek_right-before_cheek_right)/before_cheek_right)
             print(after_cheek_right)
             print(before_cheek_right)
             */
            // print(abs((after_cheek_right-before_cheek_right) / before_cheek_right ))

//            if abs((after_cheek_right-before_cheek_right) / before_cheek_right )>0.003{
//                print("右の頬move")
//                self.scrollDownInMainThread(ratio: CGFloat(0.8))
//            }
//
//            if abs(after_cheek_left)>0.052{
//                print("左の頬move")
//                self.scrollDownInMainThread(ratio: CGFloat(0.8))
//            }

            // 動かす部分
//            if abs(after_cheek_right)>0.152{
//                print("右の頬move")
//                self.scrollDownInMainThread(ratio: CGFloat(0.8))
//            }
//            if abs(after_cheek_left)>0.152{
//                print("左の頬move")
//                self.scrollUpInMainThread(ratio: CGFloat(0.8))
//            }
//

//            if let cheek_right = faceAnchor.geometry.vertices[187] as? simd_float3{
//                print(cheek_right)
//            }
//            if let cheek_leght = faceAnchor.geometry.vertices[676] as? simd_float3{
//                print(cheek_leght)
//            }
        //        case (1):
        //            buttonLabel.setTitle("Eye", for: .normal)
        //            if let mouthLeft = faceAnchor.blendShapes[.eyeLookDownLeft] as? Float {
        //                if mouthLeft < 0.2 {
        //                    self.scrollDownInMainThread(ratio: CGFloat(1/(mouthLeft+0.1)/20))
        //                }
        //            }
        case 2:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("Brow", for: .normal)
            }
            var browInnerUp: Float = 0
            var browDownLeft: Float = 0
            if callibrationUseBool == true {
                browInnerUp = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[762][1], maxFaceAUVertex: callibrationPosition[6], minFaceAUVertex: callibrationOrdinalPosition[6])
                browDownLeft = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[762][1], maxFaceAUVertex: callibrationPosition[7], minFaceAUVertex: callibrationOrdinalPosition[7])

//                if browInnerUp < 0.1, browDownLeft < 0.1 {
//                    return
//                }
            } else {
                browInnerUp = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[762][1], maxFaceAUVertex: 0.053307146, minFaceAUVertex: 0.04667869)
                // print("mouthLeft", mouthLeft)
                browDownLeft = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[762][1], maxFaceAUVertex: 0.043554213, minFaceAUVertex: 0.04667869)
//                if browInnerUp < 0.1, browDownLeft < 0.1 {
//                    return
//                }
//                // print(mouthLeftBS, mouthRightBS)
//                if browInnerUp > browDownLeft {
//                    scrollDownInMainThread(ratio: CGFloat(browInnerUp))
//
//                } else if browDownLeft > browInnerUp {
//                    scrollUpInMainThread(ratio: CGFloat(browDownLeft))
//                }

//                if let browInnerUp = faceAnchor.blendShapes[.browInnerUp] as? Float {
//                    if browInnerUp > 0.5 {
//                        leftScrollMainThread(ratio: CGFloat(browInnerUp - 0.4) * 1.5)
//                    }
//                }
//
//                if let browDownLeft = faceAnchor.blendShapes[.browDownLeft] as? Float {
//                    if browDownLeft > 0.2 {
//                        rightScrollMainThread(ratio: CGFloat(browDownLeft))
//                    }
//                }
            }
            if browInnerUp > browDownLeft {
                scrollDownInMainThread(ratio: CGFloat(browInnerUp))

            } else if browDownLeft > browInnerUp {
                scrollUpInMainThread(ratio: CGFloat(browDownLeft))
            }
        case 3:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("mouthUpDown", for: .normal)
            }
            // let callibrationArr:[String]=["口左","口右","口上","口下","頰右","頰左","眉上","眉下","右笑","左笑","普通","a","b"]
            var mouthUp: Float = 0
            var mouthDown: Float = 0
            if callibrationUseBool == true {
                mouthUp = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][1], maxFaceAUVertex: callibrationPosition[2], minFaceAUVertex: callibrationOrdinalPosition[2])

                mouthDown = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][1], maxFaceAUVertex: callibrationPosition[3], minFaceAUVertex: callibrationOrdinalPosition[3])

//                if mouthUp < 0.1, mouthDown < 0.1 {
//                    return
//                }
            } else {
                mouthUp = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][1], maxFaceAUVertex: -0.03719348, minFaceAUVertex: -0.04107782)

                mouthDown = Utility.faceAURangeChange(faceAUVertex: faceAnchor.geometry.vertices[24][1], maxFaceAUVertex: -0.04889179, minFaceAUVertex: -0.04107782)

//                if mouthUp < 0.1, mouthDown < 0.1 {
//                    return
//                }
//                if mouthUp > mouthDown {
//                    scrollDownInMainThread(ratio: CGFloat(mouthUp))
//                } else {
//                    scrollUpInMainThread(ratio: CGFloat(mouthDown))
//                }
            }
            if mouthUp > mouthDown {
                scrollDownInMainThread(ratio: CGFloat(mouthUp))
            } else {
                scrollUpInMainThread(ratio: CGFloat(mouthDown))
            }

        case 4:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("cheekPuff", for: .normal)
            }
            let cheekR = Utility.faceAURangeChange(faceAUVertex: (faceAnchor.geometry.vertices[697][2] + faceAnchor.geometry.vertices[826][2] + faceAnchor.geometry.vertices[839][2]) / 3, maxFaceAUVertex: callibrationPosition[4], minFaceAUVertex: callibrationOrdinalPosition[4])
            // print("cheekR", cheekR)
            let cheekL = Utility.faceAURangeChange(faceAUVertex: (faceAnchor.geometry.vertices[245][2] + faceAnchor.geometry.vertices[397][2] + faceAnchor.geometry.vertices[172][2]) / 3, maxFaceAUVertex: callibrationPosition[5], minFaceAUVertex: callibrationOrdinalPosition[5])
            // print("cheekL", cheekL)

//            if cheekR < 0.1, cheekL < 0.1 {
//                return
//            }
            if cheekL > cheekR, faceAnchor.geometry.vertices[24][0] > 0 {
                scrollUpInMainThread(ratio: CGFloat(cheekL))
            } else if cheekR > cheekL, faceAnchor.geometry.vertices[24][0] < 0 {
                scrollDownInMainThread(ratio: CGFloat(cheekR))
            }
//            if cheekL > cheekR {
//                scrollUpInMainThread(ratio: CGFloat(cheekL))
//            } else {
//                scrollDownInMainThread(ratio: CGFloat(cheekR))
//            }

        case 5:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("ripRoll", for: .normal)
            }
            let mouthRollUpper = faceAnchor.blendShapes[.mouthRollUpper] as! Float
            let mouthRollLower = faceAnchor.blendShapes[.mouthRollLower] as! Float
            print("mouthRollUP:", mouthRollUpper, "mouthRollLower", mouthRollLower)
            return
            if callibrationUseBool == true {
                let mouthRollUp = Utility.faceAURangeChange(faceAUVertex: mouthRollUpper, maxFaceAUVertex: callibrationPosition[10], minFaceAUVertex: callibrationOrdinalPosition[10])
                print("mouthRollUp", mouthRollUp)
                let mouthRollDown = Utility.faceAURangeChange(faceAUVertex: mouthRollLower, maxFaceAUVertex: callibrationPosition[11], minFaceAUVertex: callibrationOrdinalPosition[11])
                print("mouthRollDown", mouthRollDown)

                if mouthRollUp < 0.1, mouthRollDown < 0.1 {
                    return
                }
                if mouthRollDown > mouthRollUp {
                    scrollUpInMainThread(ratio: CGFloat(mouthRollDown))
                } else {
                    scrollDownInMainThread(ratio: CGFloat(mouthRollUp))
                }
            } else {
                if mouthRollUpper < 0.1, mouthRollLower < 0.1 {
                    return
                }
                if mouthRollUpper > mouthRollLower {
                    scrollDownInMainThread(ratio: CGFloat(mouthRollUpper))
                } else {
                    scrollUpInMainThread(ratio: CGFloat(mouthRollLower))
                }
            }
        default:
            DispatchQueue.main.async {
                self.buttonLabel.setTitle("Hands", for: .normal)
                self.handsSliderValue = self.handsSlider.value
            }
            if handsSliderValue > 0 {
                scrollDownInMainThread(ratio: CGFloat(handsSliderValue))
            } else {
                scrollUpInMainThread(ratio: CGFloat(-handsSliderValue))
            }
        }
    }

    func createFile(fileArrData: [[Float]]) {
        var fileStrData: String = ""
        let fileName = buttonLabel.titleLabel!.text! + ".csv"

        // StringのCSV用データを準備
        for singleArray in fileArrData {
            for singleString in singleArray {
                let singleString = String(singleString)
                fileStrData += "\"" + singleString + "\""
                if Float(singleString) != singleArray[singleArray.count - 1] {
                    fileStrData += ","
                }
            }
            fileStrData += "\n"
        }
        print(fileStrData)

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

        documentInteraction = UIDocumentInteractionController()
        documentInteraction.url = FilePath

        if !(documentInteraction?.presentOpenInMenu(from: view.frame, in: view, animated: true))! {
            // 送信できるアプリが見つからなかった時の処理
            let alert = UIAlertController(title: "送信失敗", message: "ファイルを送れるアプリが見つかりません", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        tapData = [[]]
    }

    func createCSV(fileArrData: [Float]) {
        let CSVFileData = Utility.createCSVFileData(fileArrData: fileArrData, facailAU: buttonLabel.titleLabel!.text!, direction: "vertical", inputMethod: inputMethodString)
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
