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
 
         let speakerBox = SBStage()
         uiNode.addChild(speakerBox)
 
         speakerBox.addSpeaker("Stou")
         speakerBox.addSpeaker("Princess")
 
         speakerBox.setup()
 
         speakerBox.animateIntoView()
 
    - warning: All positioning calculations assume that the parent node (`uiNode` in the example above) is positioned in the center of the scene. Also, it is assumed that scene.size is set.
*/
open class SBStage : SKNode {
    
    /// Config settings for the heights of different elements.
    enum Config : CGFloat {
        case speakerHeight = 193
        case bgHeight = 115
        case bubbleHeight = 135
        case podiumHeight = 40
    }
    
    /// List of speakers (podiums) currently on stage. Exposed publicly so that start and end positions can be read.
    open var speakers = [SBPodium]()
    
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
    
    - note: This is called after adding speakers because it sets the `endPosition` of speakers. Other parts of the code can then access that position and show something near the chatBubble (i.e.: Dialogue).
    */
    open func setup() {
        self.position = CGPoint(x: -1 * self.scene!.size.width / 2, y: -1 * self.scene!.size.height / 2)
        self.buildBottomLetterBox()
        self.buildTopLetterBox()
        self.setPositionsForSpeakers()
    }
    
    /// Add a black bar across the bottom of the stage.
    private func buildBottomLetterBox() {
        let shape = SKShapeNode(rect: CGRect(x: 0, y: 0,
            width: self.scene!.size.width,
            height: Config.bgHeight.rawValue))
        shape.fillColor = SKColor.black
        shape.lineWidth = 0.0
        
        let shapeNode = SKSpriteNode(texture: self.scene!.view!.texture(from: shape))
        shapeNode.position = CGPoint(x:0, y:Config.bgHeight.rawValue * -1 - Config.podiumHeight.rawValue)
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
                height: Config.bgHeight.rawValue + Config.podiumHeight.rawValue))
        shape.fillColor = SKColor.black
        shape.lineWidth = 0.0
        
        let shapeNode = SKSpriteNode(texture: self.scene!.view!.texture(from: shape))
        shapeNode.position = CGPoint(x:0, y:self.scene!.size.height)
        shapeNode.zPosition = 10050
        shapeNode.anchorPoint = CGPoint(x:0, y:0)
        shapeNode.name = "TopLetterBox"
        self.addChild(shapeNode)
    }
    
    // MARK: Managing Speakers
    
    /**
    Add a podium for each new speaker.
    
    - parameter name: The name of the image for the speaker. If the file name is "RyanBubble", just pass is "Ryan" as "Bubble" is appended automatically.
    */
    open func addSpeaker(_ name:String) {
        let speaker = SBPodium(bubbleImage: "\(name)Bubble")
        self.speakers.append(speaker)
        self.addChild(speaker.chatBubble)
    }
    
    open func addSpeakerToConversation(_ name:String, index:Int = 1) {
        let speaker = SBPodium(bubbleImage: "\(name)Bubble")
        self.speakers.insert(speaker, at: index)
        self.addChild(speaker.chatBubble)
        self.adjustPositionsForSpeakers()
        for (existingSpeaker, podium) in self.speakers.enumerated() {
            if(podium.imageName != speaker.imageName) {
                podium.slideChatBubble()
            }
        }
        /// Set the node to the start position
        speaker.chatBubble.position = CGPoint(x: speaker.startPosition!.x, y: Config.speakerHeight.rawValue)
        speaker.animateChatBubbleIn(0, delay:0)
    }
    
    /**
    Remove a speaker from the scene.
     
    - parameter index: The index in the speakers array.
    */
    open func removeSpeaker(_ index:Int) {
        let speaker = self.speakers[index]
        speaker.animateChatBubbleOut(false) {
            self.speakers.remove(at: index)
            self.adjustPositionsForSpeakers()
            for (_, podium) in self.speakers.enumerated() {
                podium.slideChatBubble()
            }
            self.run(SKAction.wait(forDuration: 0.5), completion: {
                speaker.podiumCrop?.removeFromParent()
            }) 
        }
    }
    
    // MARK: Positioning
    
    /// This should be called the first time the stage comes into view. Removing or adding speakers afterwards should call `adjust`.
    private func setPositionsForSpeakers() {
        for (index, speaker) in self.speakers.enumerated() {
            
            /// Find the start and end position
            let coords = self.calculateSpeakerStartAndEndPositions(index)
            speaker.startPosition = coords.startPos
            speaker.endPosition = coords.endPos
            
            /// Set the node to the start position
            speaker.chatBubble.position = CGPoint(x: coords.startPos.x, y: Config.speakerHeight.rawValue)
            
            /// Create the podium that the chat bubble sits on
            speaker.addPodiumBase(self.scene!, index: index, totalPodiums: self.speakers.count)
            
            /// Add the podium base to the scene
            self.addChild(speaker.podiumCrop!)
            
            /// Set sliding window position **after** adding podium base so that relative coordinates works.
            speaker.setSlidingWindowPosition(speaker.startPosition!)
        }
    }
    
    /// Calculate positions when the stage is already in view. For example, removing a podium.
    private func adjustPositionsForSpeakers() {
        for (index, speaker) in self.speakers.enumerated() {
            
            /// Set start to current position and find the end position
            let coords = self.calculateSpeakerStartAndEndPositions(index)
            var startPosition = coords.startPos
            if speaker.onStage == true {
                startPosition = speaker.chatBubble.position
            }
            speaker.startPosition = startPosition
            speaker.endPosition = coords.endPos
            
            /// Remove old podium and create new one based on new dimensions and move it instantly to Y coord.
            speaker.podiumCrop?.removeFromParent()
            speaker.addPodiumBase(self.scene!, index: index, totalPodiums: self.speakers.count)
            speaker.podiumCrop!.position = CGPoint(x:speaker.podiumCrop!.position.x, y:Config.bubbleHeight.rawValue)
            
            /// Add the podium base to the scene
            self.addChild(speaker.podiumCrop!)
            
            /// Set sliding window position **after** adding podium base so that relative coordinates works.
            speaker.setSlidingWindowPosition(speaker.startPosition!)
        }

    }
    
    /**
    Visually, the speakers should animate in near each other, and then spread out. This function will determine the initial position based on the total number of speakers, and also the end position once they are all evenly spread out.
    
    - parameter index: The index of the SBPodium in the self.speakers array.
    
    - returns: Two values. The `startPos` and `endPos` to use when bringing the speaker in.
    */
    private func calculateSpeakerStartAndEndPositions(_ index:Int) -> (startPos:CGPoint, endPos:CGPoint) {
        var startX = self.scene!.size.width / 2
        
        switch self.speakers.count {
        case 2:
            if(index == 0) {
                startX -= 100
            }
            else {
                startX += 100
            }
            break
        case 3:
            if(index == 0) {
                startX -= 200
            }
            else if(index == 1) {
                startX -= 0
            }
            else {
                startX += 200
            }
            break
        default:
            break
        }
        
        let endX = (self.scene!.size.width / CGFloat(self.speakers.count + 1)) * CGFloat(index + 1)
        return (CGPoint(x: startX, y: Config.speakerHeight.rawValue), CGPoint(x: endX, y: Config.speakerHeight.rawValue))
        
    }
    
    // MARK: Displaying the Stage
    
    /// Call this when you're ready for the letterbox and any set speakers to appear into view.
    open func animateIntoView() {
        self.animateBottomLetterBoxIntoView()
        self.animateTopLetterBoxIntoView()
        self.animatePodiumsIntoView()
    }
    
    /// Move bottom box up.
    private func animateBottomLetterBoxIntoView() {
        if let letterBox = self.childNode(withName: "BottomLetterBox") {
            let move = SKAction.moveTo(y: 0, duration: 2)
            move.timingMode = SKActionTimingMode.easeOut
            letterBox.run(move)
        }
    }
    
    /// Move top box down.
    private func animateTopLetterBoxIntoView() {
        if let letterBox = self.childNode(withName: "TopLetterBox") {
            let move = SKAction.moveTo(y: self.scene!.size.height - (Config.bgHeight.rawValue + Config.podiumHeight.rawValue), duration: 2)
            move.timingMode = SKActionTimingMode.easeOut
            letterBox.run(move)
        }
    }
    
    /// Loop through each podium and pan it up. Also, grow chat bubbles and move sliding windows.
    private func animatePodiumsIntoView() {
        let move = SKAction.moveTo(y: Config.bubbleHeight.rawValue, duration: 2)
        move.timingMode = SKActionTimingMode.easeOut
        for (index, podium) in self.speakers.enumerated() {
            podium.podiumCrop?.run(move)
            podium.animateChatBubbleIn(index)
        }
    }
    
    /**
    Hide the letterbox and speakers.
    
    - note: It is up to you to manually remove SBStage from the scene after this.
    */
    open func animateOutOfView() {
        self.animateBottomLetterBoxOutOfView()
        self.animateTopLetterBoxOutOfView()
        self.animatePodiumsOutOfView()
    }
    
    /// Move bottom box down.
    private func animateBottomLetterBoxOutOfView() {
        if let letterBox = self.childNode(withName: "BottomLetterBox") {
            let move = SKAction.moveTo(y: Config.bgHeight.rawValue * -1 - 40, duration: 1)
            move.timingMode = SKActionTimingMode.easeOut
            letterBox.run(move)
        }
    }
    
    /// Move top box up.
    private func animateTopLetterBoxOutOfView() {
        if let letterBox = self.childNode(withName: "TopLetterBox") {
            let move = SKAction.moveTo(y: self.scene!.size.height, duration: 1)
            move.timingMode = SKActionTimingMode.easeOut
            letterBox.run(move)
        }
    }
    
    /// Loop through each podium and pan it up. Also, grow chat bubbles and move sliding windows.
    private func animatePodiumsOutOfView() {
        let move = SKAction.moveTo(y: -1 * Config.bubbleHeight.rawValue, duration: 1)
        move.timingMode = SKActionTimingMode.easeOut
        for (_, podium) in self.speakers.enumerated() {
            podium.podiumCrop?.run(move)
            podium.animateChatBubbleOut() {}
        }
    }
    
}
