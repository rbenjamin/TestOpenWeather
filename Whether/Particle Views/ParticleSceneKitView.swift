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

    typealias WeatherEffect = ParticleSettings.WeatherEffect
    typealias WeatherEffectDirection = ParticleSettings.WeatherEffectDirection
    typealias WeatherEffectAmount = ParticleSettings.WeatherEffectAmount

    typealias UIViewControllerType = ParticleSceneKitViewController

    let backgroundColor: UIColor
    let images: [UIImage]
    let effect: WeatherEffect
    var direction: WeatherEffectDirection
    let amount: WeatherEffectAmount

    var scale: CGFloat = 0.25

    let tintColor: UIColor?

    init(settings: ParticleSettings, backgroundColor: UIColor) {
        let effect = settings.effect
        self.backgroundColor = backgroundColor
        self.effect = effect
        self.direction = settings.direction
        self.amount = settings.amount

        switch effect {
        case .snow:
            self.scale = 0.15
            self.images = [UIImage(named: "snowflake1")!, UIImage(named: "snowflake2")!, UIImage(named: "snowflake3")!]
            self.tintColor = .white

        case .rain(let mist):
            if mist {
                self.images = [UIImage(named: "Mist")!]
                self.scale = 0.75
                self.tintColor = .white
            } else {
                self.images = [UIImage(named: "Raindrop")!, UIImage(named: "Raindrop2")!]
                self.scale = 0.15
                self.tintColor = UIColor(named: "RainColor")
            }

        }
    }

    func makeUIViewController(context: Context) -> ParticleSceneKitViewController {
        let list = ParticleSceneKitViewController(effect: self.effect,
                                                  backgroundColor: self.backgroundColor,
                                                  images: self.images,
                                                  tintColor: self.tintColor,
                                                  size: self.scale,
                                                  amount: self.amount)
          return list
    }

    func updateUIViewController(_ uiViewController: ParticleSceneKitViewController, context: Context) {

    }

}

struct ParticleSettings {

    var direction: WeatherEffectDirection
    var amount: WeatherEffectAmount
    var effect: WeatherEffect

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

class ParticleSceneKitViewController: UIViewController {

    typealias WeatherEffect = ParticleSettings.WeatherEffect
    typealias WeatherEffectDirection = ParticleSettings.WeatherEffectDirection
    typealias WeatherEffectAmount = ParticleSettings.WeatherEffectAmount

    private var scnView: SCNView!
    private var scnScene: SCNScene!
    private var cameraNode: SCNNode!
    private var planeNode: SCNNode!
    private var particleSystem: SCNParticleSystem?

    var effect: WeatherEffect
    var images: [UIImage]
    var size: CGFloat
    var sizeVariation: CGFloat
    var direction: WeatherEffectDirection = .straightDown
    var amount: WeatherEffectAmount
    var tintColor: UIColor?
    var sceneBackgroundColor: UIColor

    init(effect: WeatherEffect,
         backgroundColor: UIColor,
         images: [UIImage],
         tintColor: UIColor?,
         size: CGFloat = 1.0,
         sizeVariation: CGFloat = 0.25,
         direction: WeatherEffectDirection = .straightDown,
         amount: WeatherEffectAmount) {
        self.sceneBackgroundColor = backgroundColor
        self.effect = effect
        self.tintColor = tintColor
        self.images = images
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
        setupCamera()
        createAngledEffect(self.effect,
                           size: self.size,
                           sizeVariation: self.sizeVariation,
                           direction: self.direction,
                           amount: self.amount)
    }

    private func createAngledEffect(_ effect: WeatherEffect,
                                    size: CGFloat,
                                    sizeVariation: CGFloat,
                                    direction: WeatherEffectDirection,
                                    amount: WeatherEffectAmount) {
        precondition(self.images.isEmpty == false, "ParticleSceneKitViewController.images is empty! Cannot create particle effect.")
        switch amount {
        case .light:
            weatherEffect(effect: effect,
                          image: images[0],
                          birthRate: 30,
                          direction: direction)
        case .regular:
            let subset = images.prefix(2)
            for idx in 0 ..< subset.count {
                weatherEffect(effect: effect,
                              image: images[idx],
                              birthRate: 30.0,
                              direction: direction)
            }
        case .heavy:
            for image in images {
                weatherEffect(effect: effect,
                              image: image,
                              birthRate: 60.0,
                              direction: direction)
            }
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
         // Position camera to look straight ahead
         cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
         // Add camera to scene
        scnScene.rootNode.addChildNode(cameraNode)
    }

    private func particleAngle(effect: WeatherEffect,
                               direction: WeatherEffectDirection) -> CGFloat {
        switch effect {
        case .rain:
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
        default:
            if case WeatherEffectDirection.leftToRight = direction {
                return 30
            }
            return 68.7
        }
    }

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
        let emitterWidth: CGFloat = 10  // Adjust based on your needs
        particleSystem.emitterShape = SCNBox(width: emitterWidth,
                                           height: 0.1,
                                           length: 0.1,
                                           chamferRadius: 0)
        // Particle properties
        particleSystem.particleVelocity = velocity
        particleSystem.isLightingEnabled = true
        particleSystem.particleImage = image
        particleSystem.particleSize = self.size
        particleSystem.particleSizeVariation = self.sizeVariation
        particleSystem.particleLifeSpanVariation = 2

        particleSystem.particleColor = self.tintColor ?? UIColor.white
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
        // Add particle system to scene
        scnScene.addParticleSystem(particleSystem, transform: emitterPosition)

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
