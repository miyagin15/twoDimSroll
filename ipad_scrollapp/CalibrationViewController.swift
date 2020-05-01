//
//  CalibrationViewController.swift
//  ipad_scrollapp
//
//  Created by miyata ginga on 2019/12/04.
//  Copyright © 2019 com.miyagin.ipad_scroll. All rights reserved.
//

import ARKit
import SceneKit
import UIKit

class CalibrationViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var tracking: UIView!
    @IBOutlet var sceneView: ARSCNView!
    @IBAction func goToVeticalScroll(_: Any) {
        nameCSVtextString = nameCSVField.text!
        userDefaults.set(nameCSVtextString, forKey: "name")
        let verticalViewController = storyboard?.instantiateViewController(withIdentifier: "VerticalViewController") as! VerticalViewController
        verticalViewController.modalPresentationStyle = .fullScreen
        present(verticalViewController, animated: true, completion: nil)
    }

    var nameCSVtextString = ""

    @IBAction func goToHorizonalScroll(_: Any) {
        nameCSVtextString = nameCSVField.text!
        userDefaults.set(nameCSVtextString, forKey: "name")
        let horizonalViewController = storyboard?.instantiateViewController(withIdentifier: "HorizonalViewController") as! ViewController
        horizonalViewController.modalPresentationStyle = .fullScreen
        present(horizonalViewController, animated: true, completion: nil)
    }

    @IBOutlet var nameCSVField: UITextField!
    // ウインクした場所を特定するために定義
    let userDefaults = UserDefaults.standard
    // Trackingfaceを使うための設定
    private let defaultConfiguration: ARFaceTrackingConfiguration = {
        let configuration = ARFaceTrackingConfiguration()
        return configuration
    }()

    // UIButtonを継承した独自クラス
    class callibrationButton: UIButton {
        let x: Int
        init(x: Int, frame: CGRect) {
            self.x = x
            super.init(frame: frame)
        }

        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    let callibrationArr: [String] = ["口左", "口右", "口上", "口下", "頰右", "頰左", "眉上", "眉下", "右笑", "左笑", "上唇", "下唇", "普通"]
    var callibrationPosition: [Float] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.5, 1, 0]

    var mouthDown: Float = 0
    var mouthUp: Float = 0
    var mouthL: Float = 0
    var mouthR: Float = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        nameCSVField.text = userDefaults.string(forKey: "name")
        sceneView.delegate = self
        //timeInterval秒に一回update関数を動かす
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
        createCallibrationButton()
    }

    @objc func update() {
        DispatchQueue.main.async {
            self.tracking.backgroundColor = UIColor.white
        }
    }

    private func createCallibrationButton() {
        for x in 0 ... 12 {
            let buttonXposition = 800
            // 位置を変えながらボタンを作る
            let btn: UIButton = callibrationButton(
                x: x,
                frame: CGRect(x: CGFloat(buttonXposition), y: CGFloat(x) * 90, width: 80, height: 50)
            )
            if x < 6 {
                btn.frame = CGRect(x: CGFloat(buttonXposition), y: CGFloat(x) * 90 + 200, width: 160, height: 50)
            } else {
                btn.frame = CGRect(x: CGFloat(buttonXposition + 180), y: CGFloat(x - 6) * 90 + 200, width: 160, height: 50)
            }
            // sampleというキーを指定して保存していたString型の値を取り出す
            if let value = userDefaults.string(forKey: callibrationArr[x]) {
                btn.setTitle(callibrationArr[x] + ":" + value, for: .normal)
            } else {
                btn.setTitle(callibrationArr[x], for: .normal)
            }
            // ボタンを押したときの動作
            btn.addTarget(self, action: #selector(pushed(mybtn:)), for: .touchUpInside)
            // 見える用に赤くした
            btn.backgroundColor = UIColor.black
            // 画面に追加
            view.addSubview(btn)
        }
    }

    // ボタンが押されたときの動作
    @objc func pushed(mybtn: callibrationButton) {
        // 押されたボタンごとに結果が異なる
        print("button at (\(mybtn.currentTitle!)) is pushed")
        print(mybtn.x)
        print(callibrationPosition[mybtn.x])
        if callibrationArr[mybtn.x] == "普通" {
            for x in 0 ... 11 {
                userDefaults.set(callibrationPosition[x], forKey: "普通" + callibrationArr[x])
                print(callibrationPosition[x], "普通" + callibrationArr[x])
            }
//            userDefaults.set(callibrationPosition[0], forKey: "普通"+callibrationArr[0])
//            userDefaults.set(callibrationPosition[1], forKey: "普通"+callibrationArr[1])
        } else {
            userDefaults.set(callibrationPosition[mybtn.x], forKey: callibrationArr[mybtn.x])
        }
        // UserDefaultsへの値の保存を明示的に行う
        userDefaults.synchronize()
        mybtn.setTitle(String(callibrationPosition[mybtn.x]), for: .normal)
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

    var faceNoseInWorld: SCNVector3 = SCNVector3(0, 0, 0)
    var faceNoseInscreenPos: SCNVector3 = SCNVector3(0, 0, 0)
    var faceLeftCheekInWorld: SCNVector3 = SCNVector3(0, 0, 0)
    var faceLeftCheekInscreenPos: SCNVector3 = SCNVector3(0, 0, 0)
    var faceRightCheekInWorld: SCNVector3 = SCNVector3(0, 0, 0)
    var faceRightCheekInscreenPos: SCNVector3 = SCNVector3(0, 0, 0)
    var distanceAtXYPoint: Float32 = Float32(0)
    var dataAppendBool = true
    let widthIpad: Float = 1194.0
    let heightIpad: Float = 834.0

    let widthRatio: Float = 0.536
    let heightRatio: Float = 0.57554

    func renderer(_: SCNSceneRenderer, didUpdate _: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return
        }

//        let callibrationArr:[String]=["口左","口右","口上","口下","頰右","頰左","眉上","眉下","右笑","左笑","普通","a","b"]
//        let callibrationPosition:[Float]=[0,0,0,0,0,0,0,0,0,0,0,0,0]
        // print(faceAnchor.geometry.vertices[24][1],"24")
        // print(faceAnchor.geometry.vertices[25][1],"25")
        // 口の右側の座標:638,口の左側の座標:405, 中心をみる
        // callibrationPosition[0] = faceAnchor.geometry.vertices[638][0]
        // callibrationPosition[1] = faceAnchor.geometry.vertices[405][0]
        callibrationPosition[0] = faceAnchor.geometry.vertices[24][0]
        callibrationPosition[1] = faceAnchor.geometry.vertices[24][0]
        // 口24を見る。口を上にしたときのy座標と口を下にしたときのy座標:
        callibrationPosition[2] = faceAnchor.geometry.vertices[24][1]
        callibrationPosition[3] = faceAnchor.geometry.vertices[24][1]
        // 口右:638,口左:329のz座標を保存
        callibrationPosition[4] = (faceAnchor.geometry.vertices[697][2] + faceAnchor.geometry.vertices[826][2] + faceAnchor.geometry.vertices[839][2]) / 3
        callibrationPosition[5] = (faceAnchor.geometry.vertices[245][2] + faceAnchor.geometry.vertices[397][2] + faceAnchor.geometry.vertices[172][2]) / 3
        // 眉上:762,眉下のy座標
        callibrationPosition[6] = faceAnchor.geometry.vertices[762][1]
        callibrationPosition[7] = faceAnchor.geometry.vertices[762][1]
        // 半笑い
        callibrationPosition[8] = faceAnchor.geometry.vertices[638][0]
        callibrationPosition[9] = faceAnchor.geometry.vertices[405][0]

//        callibrationPosition[8] = faceAnchor.blendShapes[.mouthSmileLeft] as! Float
//        callibrationPosition[9] = faceAnchor.blendShapes[.mouthSmileRight] as! Float
        // 唇の丸まり具合
//        callibrationPosition[10] = faceAnchor.blendShapes[.mouthRollUpper] as! Float
//        callibrationPosition[11] = faceAnchor.blendShapes[.mouthRollLower] as! Float
        // ＊＊＊＊＊＊＊＊depth 頰＊＊＊＊＊＊＊＊
        // 左447 右600 鼻８
        faceNoseInWorld = SCNVector3(faceAnchor.transform.columns.3.x, faceAnchor.transform.columns.3.y, faceAnchor.transform.columns.3.z)
        faceNoseInscreenPos = sceneView.projectPoint(faceNoseInWorld)

        faceLeftCheekInWorld = SCNVector3(faceAnchor.transform.columns.3.x + faceAnchor.geometry.vertices[449][0], faceAnchor.transform.columns.3.y + faceAnchor.geometry.vertices[449][1], faceAnchor.transform.columns.3.z)
        faceLeftCheekInscreenPos = sceneView.projectPoint(faceLeftCheekInWorld)

        faceRightCheekInWorld = SCNVector3(faceAnchor.transform.columns.3.x + faceAnchor.geometry.vertices[876][0], faceAnchor.transform.columns.3.y + faceAnchor.geometry.vertices[876][1], faceAnchor.transform.columns.3.z)
        faceRightCheekInscreenPos = sceneView.projectPoint(faceRightCheekInWorld)
        // depth を直接取得          print(view.bounds)→1194*834
        if 2 == 1 {
            guard let frame = sceneView.session.currentFrame else { return }
            let depthData = frame.capturedDepthData?.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32)
            let depthDataMap = depthData?.depthDataMap
            if depthDataMap != nil {
                let width = CVPixelBufferGetWidth(depthDataMap!) // 640  ipad2,388 x 1,668
                let height = CVPixelBufferGetHeight(depthDataMap!) // 480
                // let baseAddress = CVPixelBufferGetBaseAddress(depthDataMap!)
                // let floatBuffer = UnsafeMutablePointer<Float32>(baseAddress!)
                CVPixelBufferLockBaseAddress(depthDataMap!, CVPixelBufferLockFlags(rawValue: 0))
                let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthDataMap!), to: UnsafeMutablePointer<Float32>.self)
                // print(floatBuffer)
                // let distanceAtXYPoint = floatBuffer[Int(x * y)]
                let rowDataNose = CVPixelBufferGetBaseAddress(depthDataMap!)! + Int(faceNoseInscreenPos.y * heightRatio) * CVPixelBufferGetBytesPerRow(depthDataMap!)
                let dataNose = UnsafeMutableBufferPointer<Float32>(start: rowDataNose.assumingMemoryBound(to: Float32.self), count: width)
                print("Nose:", dataNose[Int(faceNoseInscreenPos.x * widthRatio)])

                let rowDataCheek = CVPixelBufferGetBaseAddress(depthDataMap!)! + Int(faceLeftCheekInscreenPos.y * heightRatio) * CVPixelBufferGetBytesPerRow(depthDataMap!)
                let dataCheek = UnsafeMutableBufferPointer<Float32>(start: rowDataCheek.assumingMemoryBound(to: Float32.self), count: width)

                // print(dataNose[Int(faceNoseInscreenPos.x / 2)])

                print("Left:", dataCheek[Int(faceLeftCheekInscreenPos.x * widthRatio)])
                print("Right:", dataCheek[Int(faceRightCheekInscreenPos.x * widthRatio)])
                print("Left-Nose:", dataCheek[Int(faceLeftCheekInscreenPos.x * widthRatio)] - dataNose[Int(faceNoseInscreenPos.x * widthRatio)])
                print("Right-Nose:", dataCheek[Int(faceRightCheekInscreenPos.x * widthRatio)] - dataNose[Int(faceNoseInscreenPos.x * widthRatio)])

                // 座標保存用
                callibrationPosition[10] = dataCheek[Int(faceLeftCheekInscreenPos.x * widthRatio)] - dataNose[Int(faceNoseInscreenPos.x * widthRatio)]
                callibrationPosition[11] = dataCheek[Int(faceRightCheekInscreenPos.x * widthRatio)] - dataNose[Int(faceNoseInscreenPos.x * widthRatio)]

                CVPixelBufferUnlockBaseAddress(depthDataMap!, CVPixelBufferLockFlags(rawValue: 0))
            }
        }
        //  認識していたら青色に
        DispatchQueue.main.async {
            // print(self.tableView.contentOffset.y)
            self.tracking.backgroundColor = UIColor.blue
            // sampleというキーを指定して保存していたString型の値を取り出す
        }
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}
