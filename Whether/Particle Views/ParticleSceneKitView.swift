//
//  ParticleSceneKitView.swift
//  ParticleSystemTest
//
//  Created by Ben Davis on 10/31/24.
//

import UIKit
import QuartzCore
import SceneKit
import SwiftUI

struct ParticleSceneKitView: UIViewControllerRepresentable {
//    @Environment(\.verticalSizeClass) var verticalSizeClass

    typealias WeatherEffect = ParticleSettings.WeatherEffect
    typealias WeatherEffectDirection = ParticleSettings.WeatherEffectDirection
    typealias WeatherEffectAmount = ParticleSettings.WeatherEffectAmount

    typealias UIViewControllerType = ParticleSceneKitViewController

//    func makeCoordinator() -> Coordinator {
//      Coordinator(self)
//    }
    let backgroundColor: UIColor
    let images: [UIImage]
    let subsystemImage: UIImage
    let effect: WeatherEffect
    var direction: WeatherEffectDirection
    let amount: WeatherEffectAmount

    var scale: CGFloat = 0.25

    let tintColor: UIColor?

    @Binding var yOffset: Double
    let verticalSizeClass: UserInterfaceSizeClass?
    let subsystemSize: CGFloat
    init(settings: ParticleSettings,
         backgroundColor: UIColor,
         yOffset: Binding<Double>,
         verticalSizeClass: UserInterfaceSizeClass?) {
        let effect = settings.effect
        self.backgroundColor = backgroundColor
        self.effect = effect
        self.direction = settings.direction
        self.amount = settings.amount
        _yOffset = yOffset
        self.verticalSizeClass = verticalSizeClass
        self.images = settings.images()
        self.subsystemImage = settings.subsystemImage()
        switch effect {
        case .snow:
            self.subsystemSize = 0.10
            self.scale = verticalSizeClass == .regular ? 0.01 : 0.10
            self.tintColor = .white

        case .rain(let mist):
            if mist {
                self.scale = verticalSizeClass == .regular ? 0.75 : 1.0
                self.tintColor = .white
                self.subsystemSize = 1
            } else {
                self.scale = verticalSizeClass == .regular ? 0.15 : 0.65
                self.tintColor = UIColor(named: "RainColor")
                self.subsystemSize = verticalSizeClass == .regular ? 1 : 1.4
            }

        }
    }

    func makeUIViewController(context: Context) -> ParticleSceneKitViewController {
        let list = ParticleSceneKitViewController(effect: self.effect,
                                                  backgroundColor: self.backgroundColor,
                                                  images: self.images,
                                                  tintColor: self.tintColor,
                                                  size: self.scale,
                                                  subsystemSize: self.subsystemSize,
                                                  amount: self.amount)
        list.subsystemImage = self.subsystemImage
        return list
    }

    func updateUIViewController(_ uiViewController: ParticleSceneKitViewController, context: Context) {
        uiViewController.yOffset = self.yOffset
        uiViewController.subsystemImage = self.subsystemImage
        switch self.effect {
        case .snow:
            uiViewController.size = self.verticalSizeClass == .regular ? 0.01 : 0.10
            uiViewController.subsystemSize = 0.10

        case .rain(let mist):
            if mist {
                uiViewController.size = self.verticalSizeClass == .regular ? 0.75 : 1.0
            } else {
                uiViewController.size = self.verticalSizeClass == .regular ? 0.15 : 0.65
                uiViewController.subsystemSize = self.verticalSizeClass == .regular ? 1 : 1.4

            }
        }
    }

//    class Coordinator: ParticleViewControllerDelegate {
//        var parent: ParticleSceneKitView
//        
//        init(_ parent: ParticleSceneKitView) {
//            self.parent = parent
//        }
//    }

}

struct ParticleSettings {

    var direction: WeatherEffectDirection
    var amount: WeatherEffectAmount
    var effect: WeatherEffect

    func subsystemImage() -> UIImage {
        switch effect {
        case .snow:
            return UIImage(named: ["snowflake1", "snowflake2", "snowflake3"].randomElement()!)!
        case .rain(let mist):
            if !mist {
                return UIImage(named: "Raindrop4")!
            }
            return UIImage(named: "Mist")!
        }
    }

    /** Returns the right image based on `effect` and `amount`.
     */
    func images() -> [UIImage] {
        var images: [UIImage] = []
        switch effect {
        case .snow:
            let fileNames = ["snowflake1", "snowflake2", "snowflake3"]
            images = [UIImage(named: fileNames.randomElement()!)!]
        case .rain(let mist):
            if mist {
                images = [UIImage(named: "Mist")!]
            } else {
                images = [UIImage(named: "Raindrop2")!]
            }

        }
        return images
    }

    static func new(rain: CurrentWeather.Rain?,
                    snow: CurrentWeather.Snow?,
                    wind: CurrentWeather.Wind?,
                    conditions: CurrentWeather.WeatherConditions?) -> ParticleSettings? {

        if let snow {
            let effect = WeatherEffect.snow
            let amount = WeatherEffectAmount.amountForSnow(snow)
            var direction: WeatherEffectDirection?

            if let wind {
                direction = WeatherEffectDirection.directionForWindSpeed(wind.speedCategory)
            } else {
                direction = .straightDown
            }
            return ParticleSettings(direction: direction!, amount: amount, effect: effect)
        }
        if let rain {
            let effect = WeatherEffect.rain(mist: false)
            let amount = WeatherEffectAmount.amountForRain(rain)
            var direction: WeatherEffectDirection?

            if let wind {
                direction = WeatherEffectDirection.directionForWindSpeed(wind.speedCategory)
            } else {
                direction = .straightDown
            }
            return ParticleSettings(direction: direction!, amount: amount, effect: effect)
        } else if let conditions, conditions.atmosphereConditions == .mist {
            let effect = WeatherEffect.rain(mist: true)
            let amount = WeatherEffectAmount.regular
            var direction: WeatherEffectDirection?

            if let wind {
                direction = WeatherEffectDirection.directionForWindSpeed(wind.speedCategory)
            } else {
                direction = WeatherEffectDirection.straightDown
            }
            return ParticleSettings(direction: direction!, amount: amount, effect: effect)

        }
        return nil
    }

    enum WeatherEffectDirection {
        case angleRightHard
        case angleRight
        case straightDown
        case angleLeft
        case angleLeftHard
        case leftToRight

        static func directionForWindSpeed(_ windSpeed: CurrentWeather.Wind.WindSpeedCategory?) -> WeatherEffectDirection {
            if windSpeed == .fast || windSpeed == .extreme {
                return .angleRight
            }
            return .straightDown
        }
    }

    enum WeatherEffectAmount {
        case light
        case regular
        case heavy

        static func amountForRain(_ rain: CurrentWeather.Rain) -> WeatherEffectAmount {
            guard let density = rain.rainDensity else { return WeatherEffectAmount.light }

            switch density {
            case .light:
                return WeatherEffectAmount.light
            case .medium:
                return WeatherEffectAmount.regular
            case .heavy, .extreme:
                return WeatherEffectAmount.heavy
            }
        }

        static func amountForSnow(_ snow: CurrentWeather.Snow) -> WeatherEffectAmount {
            guard let density = snow.snowDensity else { return WeatherEffectAmount.light }

            switch density {
            case .light:
                return WeatherEffectAmount.light
            case .medium:
                return WeatherEffectAmount.regular
            case .heavy, .extreme:
                return WeatherEffectAmount.heavy
            }
        }

    }

    enum WeatherEffect: Equatable {
        case snow
        case rain(mist: Bool)

        public static func == (lhs: WeatherEffect, rhs: WeatherEffect) -> Bool {
            if case .rain(let lhsMist) = lhs, case .rain(let rhsMist) = rhs {
                return lhsMist == rhsMist
            } else if case .snow = lhs, case .snow = rhs {
                return true
            }
            return false

        }
    }
}

struct Collision: OptionSet {
    let rawValue: Int
    static let splashEffect = Collision(rawValue: 1 << 0)
}

class ParticleSceneKitViewController: UIViewController {

    typealias WeatherEffect = ParticleSettings.WeatherEffect
    typealias WeatherEffectDirection = ParticleSettings.WeatherEffectDirection
    typealias WeatherEffectAmount = ParticleSettings.WeatherEffectAmount

    private var scnView: SCNView!
    private var scnScene: SCNScene!
    private var cameraNode: SCNNode!
    private var particleSystem: SCNParticleSystem?
    // Represents the first UI element -- the particles from `particleSystem` collide with `plane1`, begining the secondary particle effect.
    private var plane1: SCNNode!

    var effect: WeatherEffect
    var images: [UIImage]
    var subsystemImage: UIImage?
    var size: CGFloat
    var sizeVariation: CGFloat
    var subsystemSize: CGFloat
    var direction: WeatherEffectDirection = .straightDown
    var amount: WeatherEffectAmount
    var tintColor: UIColor?
    var sceneBackgroundColor: UIColor

    private var planePositionOrigin: Float = 3.05

    var yOffset: CGFloat = 0.0 {
        didSet {
            if UITraitCollection.current.verticalSizeClass == .regular {
                self.plane1.position.y = (Float(self.yOffset) * 0.012) + self.planePositionOrigin
            } else {
                self.plane1.position.y = (Float(self.yOffset) * 0.0253) + self.planePositionOrigin
            }
        }
    }

//    weak var delegate: ParticleViewControllerDelegate?

    init(effect: WeatherEffect,
         backgroundColor: UIColor,
         images: [UIImage],
         tintColor: UIColor?,
         size: CGFloat = 1.0,
         sizeVariation: CGFloat = 0.25,
         subsystemSize: CGFloat,
         direction: WeatherEffectDirection = .straightDown,
         amount: WeatherEffectAmount) {
        self.sceneBackgroundColor = backgroundColor
        self.effect = effect
        self.tintColor = tintColor
        self.images = images
        self.subsystemSize = subsystemSize
        self.size = size
        self.sizeVariation = sizeVariation
        self.direction = direction
        self.amount = amount

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupScene()
        setupPlane()

        setupCamera()
        createAngledEffect(self.effect,
                           size: self.size,
                           sizeVariation: self.sizeVariation,
                           direction: self.direction,
                           amount: self.amount)

    }

    func setupPlane() {
        let sizeClass = UITraitCollection.current.verticalSizeClass
        let boxHeight = sizeClass == .regular ? 1.94 : 3.84
        self.planePositionOrigin = sizeClass == .regular ? 3.05 : 2.48

        let geometry = SCNBox(width: 42, height: boxHeight, length: 1, chamferRadius: 0)
        plane1 = SCNNode(geometry: geometry)
        plane1.position = SCNVector3(x: 0, y: self.planePositionOrigin, z: 0)
        plane1.physicsBody = .static()
        plane1.physicsBody?.categoryBitMask = Collision.splashEffect.rawValue

        let clearMaterial = SCNMaterial()
        clearMaterial.diffuse.contents = UIColor.clear
        geometry.materials = [clearMaterial]
        scnScene.rootNode.addChildNode(plane1)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        let maxDimension = max(size.width, size.height)
        var emitterWidth: CGFloat = 10
        var boxHeight: CGFloat = 1.74

        if maxDimension == size.height {

            self.planePositionOrigin = 3.05
            self.particleSystem?.speedFactor = 1.2
        } else if maxDimension == size.width {

            self.planePositionOrigin = 2.48
            emitterWidth = 18
            boxHeight = 3.84
            self.particleSystem?.speedFactor = 1.4
        }

        if let box = plane1.geometry as? SCNBox {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.2
            box.height = boxHeight
            SCNTransaction.commit()
        }

        coordinator.animate { [weak self] _ in
            guard let `self` = self else { return }
            self.scnView.setNeedsLayout()
            self.particleSystem?.emitterShape = SCNBox(width: emitterWidth,
                                                       height: 0.1,
                                                       length: 0.1,
                                                       chamferRadius: 0)
            self.particleSystem?.particleSize = self.size
            self.particleSystem?.systemSpawnedOnCollision?.particleSize = self.subsystemSize
        }
    }

    private func createAngledEffect(_ effect: WeatherEffect,
                                    size: CGFloat,
                                    sizeVariation: CGFloat,
                                    direction: WeatherEffectDirection,
                                    amount: WeatherEffectAmount) {
        precondition(self.images.isEmpty == false,
                     "ParticleSceneKitViewController.images is empty! Cannot create particle effect.")
        var birthRate: CGFloat = 30.0
        switch amount {
        case .light, .regular:
            birthRate = 30.0
        case .heavy:
            birthRate = 60.0
        }
        for image in self.images {
            weatherEffect(effect: effect,
                          image: image,
                          birthRate: birthRate,
                          direction: direction)
        }
    }

    func setupView() {
        self.view.backgroundColor = self.sceneBackgroundColor
        let view = SCNView(frame: self.view.bounds)
        self.scnView = view
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(view)
        //        scnView.delegate = self
        scnView.showsStatistics = false
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true
    }

    func setupScene() {
        scnScene = SCNScene()
        scnScene.background.contents = self.sceneBackgroundColor
        scnView.scene = scnScene
    }

    func setupCamera() {
        // Create camera node
         cameraNode = SCNNode()
         let camera = SCNCamera()
         // Set up orthographic camera
         camera.usesOrthographicProjection = true
         camera.orthographicScale = 5  // Adjust this to control visible area
         cameraNode.camera = camera
        cameraNode.focusBehavior = .none
         // Position camera to look straight ahead
         cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
         // Add camera to scene
        scnScene.rootNode.addChildNode(cameraNode)
    }

    /** Uses the `WeatherEffect` enum and `WeatherEffectDirection` enum to build a tuple containing the acceleration speed and emitter position for the Scene Kit Particle Effect.  We move the emitter position based on direction so that even if the effect slants to the right or left we still have the majority of the view window being filled by the effect.
     
        - parameter effect: The effect (rain, snow, or mist) that should be shown.
        - parameter direction: How slanted the effect should be when crossing the screen.
     */
    private func particleAngle(effect: WeatherEffect,
                               direction: WeatherEffectDirection) -> CGFloat {
        switch direction {
        case .angleRight:
            return 15
        case .angleRightHard:
            return 30
        case .angleLeft:
            return -15
        case .angleLeftHard:
            return -30
        default:
            return 0
        }
    }

    /** Uses the `WeatherEffect` enum and `WeatherEffectDirection` enum to build a tuple containing the acceleration speed and emitter position for the Scene Kit Particle Effect.  We move the emitter position based on direction so that even if the effect slants to the right or left we still have the majority of the view window being filled by the effect.
     
        - parameter effect: The effect (rain, snow, or mist) that should be shown.
        - parameter direction: How slanted the effect should be when crossing the screen.
     */
    private func accelerationAndEmitterPosition(effect: WeatherEffect,
                                                direction: WeatherEffectDirection) -> (SCNVector3, SCNMatrix4) {
        var emitterPosition: SCNMatrix4!
        var acceleration: SCNVector3!
        switch direction {
        case .straightDown:
            if case .rain(let useMist) = effect {
                acceleration = useMist ? SCNVector3(0.0, -0.5, 0) : SCNVector3(0.0, -2, 0)
            } else {
                acceleration = SCNVector3(0.0, -2, 0)
            }
            emitterPosition = SCNMatrix4MakeTranslation(0, 7, 0)
        case .angleRight:
            acceleration = SCNVector3(0.25, -2, 0)
            emitterPosition = SCNMatrix4MakeTranslation(-1, 7, 0)
        case .angleRightHard:
            acceleration = SCNVector3(0.5, -2, 0)
            emitterPosition = SCNMatrix4MakeTranslation(-2.5, 7, 0)
        case .angleLeft:
            acceleration = SCNVector3(-0.25, -2, 0)
            emitterPosition = SCNMatrix4MakeTranslation(1, 7, 0)
        case .angleLeftHard:
            acceleration = SCNVector3(-0.5, -2, 0)
            emitterPosition = SCNMatrix4MakeTranslation(2.5, 7, 0)
        case .leftToRight:
            acceleration = SCNVector3(0.50, 0, 0)
            emitterPosition = SCNMatrix4MakeTranslation(-8, 4, 0)
        }
        return (acceleration, emitterPosition)
    }

    private func weatherEffect(effect: WeatherEffect,
                               image: UIImage,
                               birthRate: CGFloat,
                               direction: WeatherEffectDirection,
                               velocity: CGFloat = 1) {
        if self.particleSystem == nil {
            self.particleSystem = SCNParticleSystem()
        }
        guard let particleSystem else { return }
        // Emission properties
        particleSystem.birthRate = birthRate
        particleSystem.birthLocation = .volume
        particleSystem.isLocal = false  // Emit in world space
        // Create wide, thin emitter shape to cover screen width
        let orientation = UITraitCollection.current.verticalSizeClass

        let emitterWidth: CGFloat = orientation == .regular ? 10 : 18
        particleSystem.emitterShape = SCNBox(width: emitterWidth,
                                           height: 0.1,
                                           length: 0.1,
                                           chamferRadius: 0)
        // Particle properties
        particleSystem.particleVelocity = velocity
        particleSystem.particleImage = image
        particleSystem.particleSize = self.size
        particleSystem.particleSizeVariation = self.sizeVariation
        particleSystem.particleLifeSpanVariation = 2

        let color = self.tintColor ?? UIColor.white

        particleSystem.particleColor = color
        switch effect {
        case .rain(let mist):
            if !mist {
                particleSystem.particleLifeSpan = 7
                particleSystem.stretchFactor = -0.25
                particleSystem.warmupDuration = 2.0
            } else {
                particleSystem.particleLifeSpan = 12
                particleSystem.stretchFactor = 0
                particleSystem.speedFactor = 0.4
                // Need a faster warmup so mist appears quickly
                // mist is slower than other effects, so faster
                // warmup ensures the `mist` appears quickly.
                particleSystem.warmupDuration = 13.0
            }
        default:
            particleSystem.warmupDuration = 2.0
            particleSystem.spreadingAngle = 35
            particleSystem.particleLifeSpan = 7
            particleSystem.stretchFactor = 0
        }

        particleSystem.particleAngle = self.particleAngle(effect: effect, direction: direction)
        // Gravity effect
        let (acceleration, emitterPosition) = accelerationAndEmitterPosition(effect: effect, direction: direction)
        particleSystem.acceleration = acceleration
        // Continuous emission
        particleSystem.loops = true
        // Rendering properties
        particleSystem.blendMode = .alpha
        particleSystem.isLightingEnabled = false
        particleSystem.orientationMode = .billboardScreenAligned
        particleSystem.colliderNodes = [plane1]
        particleSystem.systemSpawnedOnCollision = self.splashEffect(image: self.subsystemImage ?? image,
                                                                    size: self.subsystemSize,
                                                                    color: color,
                                                                    birthRate: 4)
        particleSystem.particleDiesOnCollision = true

        // Add particle system to scene
        scnScene.addParticleSystem(particleSystem, transform: emitterPosition)

    }
    func splashEffect(image: UIImage,
                      size: CGFloat = 0.08,
                      color: UIColor,
                      birthRate: CGFloat = 2) -> SCNParticleSystem {
        let particleSystem = SCNParticleSystem()

        // Emission properties
        particleSystem.birthRate = birthRate
        particleSystem.idleDuration = 4
        particleSystem.idleDurationVariation = 0.5
        particleSystem.warmupDuration = 2
        particleSystem.birthLocation = .vertex
        particleSystem.isLocal = false  // Emit in world space

        particleSystem.emitterShape = SCNBox(width: 42, height: 1.84, length: 1, chamferRadius: 0)

        // Particle properties
        particleSystem.particleLifeSpan = 8
        particleSystem.particleLifeSpanVariation = 1
        particleSystem.particleVelocity = 0

        particleSystem.particleDiesOnCollision = false
        particleSystem.emittingDirection = SCNVector3(0, -2, 0)
        // Initial spread
        particleSystem.spreadingAngle = 0
        particleSystem.stretchFactor = 0
        particleSystem.particleAngle = 0

        particleSystem.isAffectedByGravity = true
        particleSystem.particleMass = 3.0
        particleSystem.dampingFactor = 0.90
        particleSystem.particleImage = image
        particleSystem.particleColor = color
        particleSystem.particleSize = size

        // Rendering properties
        particleSystem.blendMode = .alpha
        particleSystem.isLightingEnabled = false
        particleSystem.orientationMode = .billboardViewAligned
        particleSystem.loops = false
        return particleSystem

    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
}
