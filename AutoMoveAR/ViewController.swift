//
//  ViewController.swift
//  AutoMoveAR
//
//  Created by y-taka on 2021/02/26.
//

import UIKit
import RealityKit
import ARKit

//進行方向の管理用enum　上下左右のUIButtonと連動している
enum Direction: String {
    case none = "none"
    case up = "up"
    case left = "left"
    case right = "right"
    case down = "down"
}

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    @IBOutlet weak var directionLabel: UILabel!
    
    //駒の格納用AnchorEntity
    var knightAnchorEntity: AnchorEntity!
    
    //進行方向の指示用変数　デフォルトでは動かないように.noneで設定
    var direction:Direction = .none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView.session.delegate = self
        
        //.collisionを設定することで後述するraycastによる移動が有効となる
        //.occlusionの設定を外しても問題ない　よりリアルに駒の動きをみたい場合には入れておく
        arView.environment.sceneUnderstanding.options.insert([.occlusion, .collision])
        //メッシュ表示用設定
        arView.debugOptions.insert(.showSceneUnderstanding)
        
        //Experience.rcprojectからナイトの駒を読み込む
        //移動させるためにAnchorEntityを作成し、そちらに格納する
        //この時点でarViewに追加してもいいが、AR空間の読み込みが遅いと駒が表示されない場合があるので、今回は追加ボタンで操作する
        let knight = try! Experience.loadKnight()
        knightAnchorEntity = AnchorEntity()
        knightAnchorEntity.addChild(knight)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //AR空間の詳細設定　上述の.showSceneUnderstandingとこちらの.meshでメッシュが表示されるようになる
        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .mesh
        arView.session.run(configuration)
    }
    
    //読み込んだ駒の設置用メソッド
    @IBAction func add(_ sender: Any) {
        guard let knight = knightAnchorEntity else { return }
        
        if let raycast = arView.raycast(from: arView.center, allowing: .estimatedPlane, alignment: .any).first {
            let transform = Transform(matrix: raycast.worldTransform)
            knight.transform = transform
        }
        arView.scene.anchors.append(knight)
    }
    
    //進行方向の操作用メソッド
    @IBAction func walk(_ sender: UIButton) {
        if let identifier = sender.restorationIdentifier {
            directionLabel.text = identifier
            direction = Direction(rawValue: identifier)!
        }
    }
    
    //ARSessionのデリゲートメソッド
    //フレームが更新されるたびに呼ばれるため、他のメソッドよりも駒をリアルタイムに動かしやすい
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if direction == .none { return }
        guard let knight = knightAnchorEntity else { return }
        
        //初期値の設定　下のswitch分で中身を変更する
        var directionPoint: SIMD3<Float> = SIMD3<Float>(x: 0, y: 0, z: 0)
        //raycastの照射位置と照射方向を決めるための値の設定　0.005は0.5cmと同じ
        let threshold:Float = 0.05
        
        //進行方向を決定するためのswitch構文
        switch direction {
        case .up:
            directionPoint = SIMD3<Float>(x: 0, y: -threshold, z: -threshold)
        case .left:
            directionPoint = SIMD3<Float>(x: -threshold, y: -threshold, z: 0)
        case .right:
            directionPoint = SIMD3<Float>(x: threshold, y: -threshold, z: 0)
        case .down:
            directionPoint = SIMD3<Float>(x: 0, y: -threshold, z: threshold)
        default:
            break
        }
        
        //上で作成した照射位置と照射方向は、あくまでも駒の持つ座標を基準にしている
        //raycastする場合にはこれをworldの座標に変換する必要がある
        let from = knight.convert(position: SIMD3<Float>(x: 0, y: threshold, z: 0), to: nil)
        let direction = knight.convert(direction: directionPoint, to: nil)
        
        //raycastの実行と結果の判定　viewDidLoad()で.collisionを設定していると、HasSceneUnderstandingの部分で判定が行われる
        //raycastの第2引数がdirectionの場合、raycastがヒットしても突き抜けていくので、一番最初にヒットしたものだけ抽出する
        let collisionResults = arView.scene.raycast(origin: from, direction: normalize(direction))
        if let result = collisionResults.compactMap({ $0.entity as? HasSceneUnderstanding != nil ? $0 : nil}).first {
            let transform = Transform(matrix: float4x4(result.position, normal: result.normal))
            knight.move(to: transform, relativeTo: nil, duration: 0.5)
        }
    }
}

//Extensions from Creating a Game with SceneUnderstanding(Apple Sample)
extension float4x4 {
    public init(_ position: SIMD3<Float>, normal: SIMD3<Float>) {
        // build a transform from the position and normal (up vector, perpendicular to surface)
        let absX = abs(normal.x)
        let absY = abs(normal.y)
        let abzZ = abs(normal.z)
        let yAxis = normalize(normal)
        // find a vector sufficiently different from yAxis
        var notYAxis = yAxis
        if absX <= absY, absX <= abzZ {
            // y of yAxis is smallest component
            notYAxis.x = 1
        } else if absY <= absX, absY <= abzZ {
            // y of yAxis is smallest component
            notYAxis.y = 1
        } else if abzZ <= absX, abzZ <= absY {
            // z of yAxis is smallest component
            notYAxis.z = 1
        } else {
            fatalError("couldn't find perpendicular axis")
        }
        let xAxis = normalize(cross(notYAxis, yAxis))
        let zAxis = cross(xAxis, yAxis)

        self = float4x4(SIMD4<Float>(xAxis, w: 0.0),
                        SIMD4<Float>(yAxis, w: 0.0),
                        SIMD4<Float>(zAxis, w: 0.0),
                        SIMD4<Float>(position, w: 1.0))
    }
}

extension SIMD4 where Scalar == Float {
    init(_ xyz: SIMD3<Float>, w: Float) {
        self.init(xyz.x, xyz.y, xyz.z, w)
    }

    var xyz: SIMD3<Float> {
        get { return SIMD3<Float>(x: x, y: y, z: z) }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
}
