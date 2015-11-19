//
//  SBPodium.swift
//  SpeakerBox
//
//  Created by Ryan Campbell on 11/19/15.
//  Copyright © 2015 Phalanx Studios. All rights reserved.
//

import SpriteKit

internal class SBPodium {
    
    var chatBubble : SKSpriteNode
    
    var endPosition : CGPoint?
    
    var startPosition : CGPoint?
    
    var podiumCrop : SKCropNode?
    
    var slidingWindow : SKSpriteNode?
    
    internal init(bubbleImage:String) {
        self.chatBubble = SKSpriteNode(imageNamed: bubbleImage)
        self.chatBubble.setScale(0)
        self.chatBubble.zPosition = 10050
    }
    
    internal func addPodiumBase(scene:SKScene, index:Int, totalPodiums:Int) {
        let placement = self.calculatePodiumPosition(scene.size.width, index: index, totalPodiums: CGFloat(totalPodiums))
        self.podiumCrop = SKCropNode()
        self.slidingWindow = SKSpriteNode(imageNamed: "bubble_base")
        
        let shape = SKShapeNode(rect: CGRect(x: 0, y: 0, width: placement.width, height: SBStage.Config.PodiumHeight.rawValue + 4))
        shape.fillColor = SKColor.redColor()
        shape.lineWidth = 0
        let shapeTexture = scene.view!.textureFromNode(shape)
        let mask = SKSpriteNode(texture: shapeTexture)
        
        self.podiumCrop?.addChild(self.slidingWindow!)
        self.podiumCrop?.maskNode = mask
        self.podiumCrop?.zPosition = 10000
        self.podiumCrop?.position = placement.startPos
    }
    
    
    private func calculatePodiumPosition(sceneWidth:CGFloat, index:Int, totalPodiums:CGFloat) -> (startPos:CGPoint, width:CGFloat) {
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
        return (CGPoint(x:cropposX, y: -1 * SBStage.Config.PodiumHeight.rawValue), cropwidth)
    }
    
    internal func setSlidingWindowPosition(point:CGPoint) {
        var innerPos = self.chatBubble.parent!.convertPoint(self.startPosition!, toNode: self.podiumCrop!)
        innerPos.y = 0
        self.slidingWindow?.position = innerPos
    }
    
    // MARK: Animations
        
    internal func animateChatBubbleIn(index:Int) {
        
        let move1 = SKAction.scaleTo(1, duration: 1)
        move1.timingMode = SKActionTimingMode.EaseOut
        
        let move2 = SKAction.moveTo(self.endPosition!, duration: 0.5)
        move2.timingMode = SKActionTimingMode.EaseOut
        
        let delay1 = SKAction.waitForDuration(NSTimeInterval(1 + (0.3 * CGFloat(index))))
        
        let delay2 = SKAction.waitForDuration(NSTimeInterval(0.6 - (0.3 * CGFloat(index))))
        
        self.chatBubble.runAction(SKAction.sequence([
            delay1,
            move1,
            delay2,
            move2
        ]))

        self.animateSlidingWindow(delay1, delay2: delay2)
    }
    
    private func animateSlidingWindow(delay1:SKAction, delay2:SKAction) {
        var pos = self.chatBubble.parent!.convertPoint(self.endPosition!, toNode: self.podiumCrop!)
        pos.y = 0
        print(self.endPosition)
        print(pos)
        let move = SKAction.moveTo(pos, duration: 0.5)
        let cropdelay = SKAction.waitForDuration(1)
        move.timingMode = SKActionTimingMode.EaseOut
        self.slidingWindow?.runAction(SKAction.sequence([delay1, cropdelay, delay2, move]))
    }
    
}
