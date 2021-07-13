//
//  ViewController.swift
//  ARLearning
//
//  Created by Bogdan Susca on 04.03.2021.
//

import UIKit
import ARKit
import RealityKit
import SceneKit
import AVKit

var imageNames = ["Bio Plamani.png", "Chimie Stari de agregare.png", "Fizica Atomul.png", "Geogra Universul.png", "Istorie Regi.png"]
var referenceImageNames = ["A Bio Image", "A Ch Image", "A Fiz Image", "A Geogra Image", "A Isto Image"]

var videoNames = ["Creier", "Apa", "Atomi", "Calea Lactee", "Cavaleri"]
var referenceVideoNames = ["B Bio Video", "B Ch Video", "B Fiz Video", "B Geogra Video", "B Isto Video"]

var d3Names = ["Inima", "Molecula", "Atom", "Earth", "Sabie"]
var referenceD3Names = ["C Bio 3D", "C Ch 3D", "C Fiz 3D", "C Geogra 3D", "C Isto 3D"]

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var imageView: UIImageView!
    var videoNode: SKVideoNode!
    
    var imageRef: Bool = false
    var d3Ref: Bool = true
    var videoRef: Bool = true
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        let scene = SCNScene(named: "art.scnassets/Scene.scn")!
        
        sceneView.scene = scene
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARImageTrackingConfiguration()
        guard let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
            print("No images available")
            return
        }
        configuration.trackingImages = trackedImages
        configuration.maximumNumberOfTrackedImages = 1
        configuration.isAutoFocusEnabled = true
        
        configuration.isLightEstimationEnabled = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let node = SCNNode()
        
        if let imageAnchor = anchor as? ARImageAnchor {
            
            var displayImageName = ""
            displayImageName = findTrackingImage(anchor: anchor, referenceNameArray: referenceImageNames, overlayNames: imageNames)
            
            // IMAGE RENDERS
            if displayImageName != "" {
                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
                plane.firstMaterial?.diffuse.contents = UIImage(named: displayImageName)
                plane.firstMaterial?.lightingModel = .constant
                let planeNode = SCNNode(geometry: plane)
                planeNode.eulerAngles.x = -.pi / 2
                planeNode.position.y = 0.3
                
                node.addChildNode(planeNode)
            }

            // 3D RENDERS
            if let imageAnchor = anchor as? ARImageAnchor {
                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
                
                plane.firstMaterial?.diffuse.contents = UIColor(white: 0, alpha: 0)
                plane.firstMaterial?.lightingModel = .constant
                
                var displayD3Name = ""
                displayD3Name = findTrackingImage(anchor: anchor, referenceNameArray: referenceD3Names, overlayNames: d3Names)

                if displayD3Name != "" {
                    let planeNode = SCNNode(geometry: plane)
                    planeNode.eulerAngles.x = -.pi / 2
                    print(displayD3Name)
                    let shipScene = SCNScene(named: "art.scnassets/\(displayD3Name).usdz")!
                    let shipNode = shipScene.rootNode.childNodes.first!
                    shipNode.position = SCNVector3Zero
                    shipNode.position.z = 0.15
                    planeNode.addChildNode(shipNode)
                    node.addChildNode(planeNode)
                }
            }
        }
        return node
    }
    
    // VIDEO RENDERS
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard anchor is ARImageAnchor else { return }
        
        guard let referenceImage = ((anchor as? ARImageAnchor)?.referenceImage) else {
            return
        }
        
        if anchor is ARImageAnchor {
            var displayVideoName:String = ""
            displayVideoName = findTrackingImage(anchor: anchor, referenceNameArray: referenceVideoNames, overlayNames: videoNames)
            
            if displayVideoName != "" {
                guard let container = sceneView.scene.rootNode.childNode(withName: "container", recursively: true) else {
                    return }
                container.removeFromParentNode()
                node.addChildNode(container)
                container.isHidden = false
                guard let videoURL = Bundle.main.url(forResource: displayVideoName, withExtension: ".mp4") else {
                    print("Could not find clip named: \(displayVideoName).mp4")
                    return
                }
                                
                var videoPlayer: AVPlayer!
                videoPlayer = AVPlayer(url: videoURL)
                let videoScene = SKScene(size: CGSize(width: 720.0, height: 1280.0))
                videoNode = SKVideoNode(avPlayer: videoPlayer)
                videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
                videoNode.size = videoScene.size
                videoNode.yScale = 1
                videoNode.play()
                videoNode.name = "VideoNode"
                videoNode.zRotation = -3.14
                videoScene.addChild(videoNode)
                print(videoNode as Any)
                guard let video = container.childNode(withName: "video", recursively: true) else { return }
                video.geometry?.firstMaterial?.diffuse.contents = videoScene
                video.geometry?.firstMaterial?.lightingModel = .constant
                video.scale = SCNVector3(x: Float(referenceImage.physicalSize.width), y: Float(referenceImage.physicalSize.height), z: 1.0)
                video.position = node.position
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = (anchor as? ARImageAnchor) else { return }
        var renderIsImage: Bool = false
        var i = 0
        while i < referenceVideoNames.count {
            if referenceVideoNames[i] == imageAnchor.referenceImage.name! {
                renderIsImage = true
            }
            i += 1
        }
        if imageAnchor.isTracked && renderIsImage {
            videoNode?.play()
            
        } else {
            videoNode?.pause()
        }
    }
    
}

func findTrackingImage(anchor: ARAnchor, referenceNameArray: [String], overlayNames: [String]) -> String {
    var displayName = ""
    if let imageAnchor = anchor as? ARImageAnchor {
        var referenceIndex = 0
        while referenceIndex < referenceNameArray.count {
            print(referenceNameArray[referenceIndex])
            print((imageAnchor.referenceImage.name!))
            if referenceNameArray[referenceIndex] == imageAnchor.referenceImage.name! {
                displayName = overlayNames[referenceIndex]
                referenceIndex = referenceNameArray.count
            }
            referenceIndex += 1
        }
    }
    print(displayName)
    return displayName
}
