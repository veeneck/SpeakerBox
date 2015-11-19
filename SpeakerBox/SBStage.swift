//
//  SBStage.swift
//  SpeakerBox
//
//  Created by Ryan Campbell on 11/19/15.
//  Copyright © 2015 Phalanx Studios. All rights reserved.
//

import SpriteKit

/**
    Create a stage that shows in letterbox format, and allows up to 3 speakers. Handles construction, animation, speaker bubbles, and tear down.
*/
public class SBStage : SKNode {
    
    /// Config settings for the heights of different elements.
    enum Config : CGFloat {
        case SpeakerHeight = 193
        case BGHeight = 115
        case BubbleHeight = 135
        case PodiumHeight = 40
    }
    
    var speakers = [SBPodium]()
    
    // MARK: Initializing a SBStage
    
    /// Creates an empty SKNode that can be added to the scene before stage construction starts.
    public override init() {
        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setting the stage and speakers
    
    /**
    Create the intiial components of the stage like letterbox bars.
    
    - precondition: The SBStage must be added to the scene before calling this function.
    */
    public func setup() {
        self.buildBottomLetterBox()
        self.buildTopLetterBox()
    }
    
    /// Add a black bar across the bottom of the stage.
    private func buildBottomLetterBox() {
        let shape = SKShapeNode(rect: CGRect(x: 0, y: 0,
            width: self.scene!.size.width,
            height: Config.BGHeight.rawValue))
        shape.fillColor = SKColor.blackColor()
        shape.lineWidth = 0.0
        
        let shapeNode = SKSpriteNode(texture: self.scene!.view!.textureFromNode(shape))
        shapeNode.position = CGPoint(x:0, y:Config.BGHeight.rawValue * -1 - Config.PodiumHeight.rawValue)
        shapeNode.zPosition = 10050
        shapeNode.anchorPoint = CGPoint(x:0, y:0)
        shapeNode.name = "BottomLetterBox"
        self.addChild(shapeNode)
    }
    
    /// Add a black bar across the top of the stage.
    private func buildTopLetterBox() {
        let shape = SKShapeNode(
            rect: CGRect(x: 0, y: 0,
                width: self.scene!.size.width,
                height: Config.BGHeight.rawValue + Config.PodiumHeight.rawValue))
        shape.fillColor = SKColor.blackColor()
        shape.lineWidth = 0.0
        
        let shapeNode = SKSpriteNode(texture: self.scene!.view!.textureFromNode(shape))
        shapeNode.position = CGPoint(x:0, y:self.scene!.size.height)
        shapeNode.zPosition = 10050
        shapeNode.anchorPoint = CGPoint(x:0, y:0)
        shapeNode.name = "TopLetterBox"
        self.addChild(shapeNode)
    }
    
    // MARK: Adding speakers
    
    /**
    Add a podium for each new speaker.
    
    - parameter name: The name of the image for the speaker. If the file name is "RyanBubble", just pass is "Ryan" as "Bubble" is appended automatically.
    */
    public func addSpeaker(name:String) {
        let speaker = SBPodium(bubbleImage: "\(name)Bubble")
        self.speakers.append(speaker)
    }
    
    // MARK: Bringing the stage into view
    
    /// Call this when you're ready for the letterbox and any set speakers to appear into view.
    public func animateIntoView() {
        self.animateBottomLetterBoxIntoView()
        self.animateTopLetterBoxIntoView()
    }
    
    /// Move bottom box up.
    private func animateBottomLetterBoxIntoView() {
        if let letterBox = self.childNodeWithName("BottomLetterBox") {
            let move = SKAction.moveToY(0, duration: 2)
            move.timingMode = SKActionTimingMode.EaseOut
            letterBox.runAction(move)
        }
    }
    
    /// Move top box down.
    private func animateTopLetterBoxIntoView() {
        if let letterBox = self.childNodeWithName("TopLetterBox") {
            let move = SKAction.moveToY(self.scene!.size.height - (Config.BGHeight.rawValue + Config.PodiumHeight.rawValue), duration: 2)
            move.timingMode = SKActionTimingMode.EaseOut
            letterBox.runAction(move)
        }
    }
    
}