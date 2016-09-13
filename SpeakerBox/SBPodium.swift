//
//  SBPodium.swift
//  SpeakerBox
//
//  Created by Ryan Campbell on 11/19/15.
//  Copyright © 2015 Phalanx Studios. All rights reserved.
//

import SpriteKit

/**
    This class represents a podium for each speaker. Podiums sit on top of the bottom letterbox. If there is one speaker, there would be one podium with a cropnode spanning the entire width. Two speakers would have two podiums, each being half the scene width. Each podium has a few elements:
 
    - The chat bubble representing who is speaking.
    - The podiumCrop which is a black bar (mask) representing the width of the podium.
    - The slidingWindow which is the pedestal the chatBubble sits in. By being in a crop, we can move it back and forth with the chatBubble.
*/
open class SBPodium {
    
    /// The node representing the image of the speaker.
    internal var chatBubble : SKSpriteNode
    
    /// The desired end position of the chatBubble
    open var endPosition : CGPoint?
    
    /// Desired start position of the chat bubble
    open var startPosition : CGPoint?
    
    /// A crop node placed on top of the bottom letterbox
    internal var podiumCrop : SKCropNode?
    
    /// The viewable portion o the podiumCrop which contains the base that chatBubble sits in.
    internal var slidingWindow : SKSpriteNode?
    
    // Mark: Initializing a SBPodium
    
    /// Base construction with a chat bubble.
    internal init(bubbleImage:String) {
        self.chatBubble = SKSpriteNode(imageNamed: bubbleImage)
        self.chatBubble.setScale(0)
        self.chatBubble.zPosition = 10050
    }
    
    /** 
    Constructs the podium base. This is the most complicated part, so let's run through an example using 2 speakers. The crop node for each speaker would be half of the screen width. Meanwhile, the slidingWindow is the width of the entire screen. But because the window sits in a crop node, the only portion visible will be half of the screen. With that in mind, you can imagine sliding the window back and forth which would move the podium (indentation) that the chatBubble sits on.
    */
    internal func addPodiumBase(_ scene:SKScene, index:Int, totalPodiums:Int) {
        
        /// Create our podium and sliding window.
        let placement = self.calculatePodiumPosition(scene.size.width, index: index, totalPodiums: CGFloat(totalPodiums))
        self.podiumCrop = SKCropNode()
        self.slidingWindow = SKSpriteNode(imageNamed: "bubble_base")
        
        /// Make an empty black square represent the viewable area of the crop node.
        let shape = SKShapeNode(rect: CGRect(x: 0, y: 0, width: placement.width, height: SBStage.Config.podiumHeight.rawValue + 4))
        shape.fillColor = SKColor.red
        shape.lineWidth = 0
        let shapeTexture = scene.view!.texture(from: shape)
        let mask = SKSpriteNode(texture: shapeTexture)
        
        /// Add the sliding window to the podium, which will be masked by the empty black square in the last step.
        self.podiumCrop?.addChild(self.slidingWindow!)
        self.podiumCrop?.maskNode = mask
        self.podiumCrop?.zPosition = 10000
        self.podiumCrop?.position = placement.startPos
    }
    
    // MARK: Positioning
    
    /// Honestly, I have no idea how this function works. Essentially, it is trying to figure out the ideal width of the crop node, and the position it should start at. Would have to log with test data to figure out why it works.
    fileprivate func calculatePodiumPosition(_ sceneWidth:CGFloat, index:Int, totalPodiums:CGFloat) -> (startPos:CGPoint, width:CGFloat) {
        var cropwidth = sceneWidth / totalPodiums
        var cropposX = (sceneWidth / CGFloat(totalPodiums + 1)) * CGFloat(index + 1)
        if index == 1 && totalPodiums == 3 {
            cropwidth = 133
        }
        if index == 0 && totalPodiums == 3 {
            cropwidth = sceneWidth / 2 - 67
            cropposX -= 33
        }
        if index == 2 && totalPodiums == 3 {
            cropwidth = sceneWidth / 2 - 67
            cropposX += 33
        }
        if(totalPodiums == 2) {
            cropposX = (cropwidth * CGFloat(index)) + (cropwidth / 2)
        }
        return (CGPoint(x:cropposX, y: -1 * SBStage.Config.podiumHeight.rawValue), cropwidth)
    }
    
    /// Since the sliding window sits inside of the podiumCrop, this is just a convenience function to change its position.
    internal func setSlidingWindowPosition(_ point:CGPoint) {
        var innerPos = self.chatBubble.parent!.convert(self.startPosition!, to: self.podiumCrop!)
        innerPos.y = 0
        self.slidingWindow?.position = innerPos
    }
    
    // MARK: Animations
    
    /// Bring chat bubles in, wait until they are all in, then slide out together.
    internal func animateChatBubbleIn(_ index:Int) {
        
        let move1 = SKAction.scale(to: 1, duration: 1)
        move1.timingMode = SKActionTimingMode.easeOut
        
        let move2 = SKAction.move(to: self.endPosition!, duration: 0.5)
        move2.timingMode = SKActionTimingMode.easeOut
        
        let delay1 = SKAction.wait(forDuration: TimeInterval(1 + (0.3 * CGFloat(index))))
        
        let delay2 = SKAction.wait(forDuration: TimeInterval(0.6 - (0.3 * CGFloat(index))))
        
        self.chatBubble.run(SKAction.sequence([
            delay1,
            move1,
            delay2,
            move2
        ]))

        self.animateSlidingWindow(delay1, delay2: delay2)
    }
    
    /// Slide chat buble if it has already been brought onto stage.
    internal func slideChatBubble() {
        let move = SKAction.move(to: self.endPosition!, duration: 0.5)
        move.timingMode = SKActionTimingMode.easeOut
        self.chatBubble.run(move)
        
        /// Move sliding window with it, this time with no delay since it isn't the first time thestage is loaded.
        self.animateSlidingWindow(SKAction.wait(forDuration: 0), delay2: SKAction.wait(forDuration: 0), cropDuration: 0)
    }
    
    /// Once chat bubbles have finished first half of animation, slide the window to mirror the chat bubble identically.
    fileprivate func animateSlidingWindow(_ delay1:SKAction, delay2:SKAction, cropDuration:Double = 1) {
        var pos = self.chatBubble.parent!.convert(self.endPosition!, to: self.podiumCrop!)
        pos.y = 0
        let move = SKAction.move(to: pos, duration: 0.5)
        let cropdelay = SKAction.wait(forDuration: cropDuration)
        move.timingMode = SKActionTimingMode.easeOut
        self.slidingWindow?.run(SKAction.sequence([delay1, cropdelay, delay2, move]))
    }
    
    /// Shrink the buble until it disappears.
    /// withMove is used because the letterbox remains if removeSpeaker is called, but not if the scene ends.
    internal func animateChatBubbleOut(_ withMove:Bool = true, callback:@escaping ()->()) {
        let move = SKAction.moveTo(y: 0, duration: 1)
        move.timingMode = SKActionTimingMode.easeOut
        let scale = SKAction.scale(to: 0, duration: 1)
        scale.timingMode = SKActionTimingMode.easeOut
        
        if(withMove) {
            self.chatBubble.run(SKAction.group([move,scale]), completion: {
                self.chatBubble.removeFromParent()
                callback()
            }) 
        }
        else {
            self.chatBubble.run(scale, completion: {
                self.chatBubble.removeFromParent()
                callback()
            }) 
        }
    }
    
}
