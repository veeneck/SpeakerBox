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
    
    internal init(bubbleImage:String) {
        self.chatBubble = SKSpriteNode(imageNamed: bubbleImage)
        self.chatBubble.setScale(0)
        self.chatBubble.zPosition = 10050
    }
    
}
