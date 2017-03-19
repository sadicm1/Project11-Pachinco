//
//  GameScene.swift
//  Project11
//
//  Created by Mehmet Sadıç on 17/03/2017.
//  Copyright © 2017 Mehmet Sadıç. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
  
  var livesLabel: SKLabelNode!
  var scoreLabel: SKLabelNode!
  var obstacles = [SKNode]()
  
  var score: Int = 0 {
    didSet {
      scoreLabel.text = "Score: \(score)"
      livesLabel.text = "Lives: \(score + 5)"
    }
  }
  
  var editLabel: SKLabelNode!
  
  // Indicates whether we are in edit mode
  var editMode: Bool = false {
    didSet {
      if editMode {
        editLabel.text = "Done"
      } else {
        editLabel.text = "Edit"
      }
    }
  }
  
  let ballNames = ["ballBlue", "ballCyan", "ballGreen", "ballGrey", "ballPurple", "ballYellow", "ballRed"]
  
  // Called when the page is loaded first time
  override func didMove(to view: SKView) {
    
    // Set the livesLabel properties
    livesLabel = SKLabelNode(fontNamed: "chalkduster")
    livesLabel.position = CGPoint(x: 980, y: 650)
    livesLabel.horizontalAlignmentMode = .right
    livesLabel.text = "Lives: 5"
    addChild(livesLabel)
    
    // Set the scoreLabel properties
    scoreLabel = SKLabelNode(fontNamed: "chalkduster")
    scoreLabel.position = CGPoint(x: 980, y: 700)
    scoreLabel.horizontalAlignmentMode = .right
    scoreLabel.text = "Score: 0"
    addChild(scoreLabel)
    
    // Set the editLabel
    editLabel = SKLabelNode(fontNamed: "chalkduster")
    editLabel.position = CGPoint(x: 80, y: 700)
    editLabel.horizontalAlignmentMode = .left
    editLabel.text = "Edit"
    addChild(editLabel)
    
    // Create the background picture
    let background = SKSpriteNode(imageNamed: "background.jpg")
    background.position = CGPoint(x: 512, y: 384)
    background.zPosition = -1
    background.blendMode = .replace
    addChild(background)
    
    // Set the pysical boundry as the frame of screen
    physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    
    // Create 5 bouncers located equally spaced.
    for i in 0..<5 {
      let bouncerPosition = CGPoint(x: i * 256, y: 0)
      makeBouncer(at: bouncerPosition)
    }
    
    for i in 0..<4 {
      let slotPosition = CGPoint(x: 128 + i * 256, y: 0)
      makeSlot(at: slotPosition, isGood: i % 2 == 0)
    }
    
    physicsWorld.contactDelegate = self
  }
  
  // Called when there is a touch
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
    if let touch = touches.first {
      let location = touch.location(in: self)
      let objects = nodes(at: location)
      
      if objects.contains(editLabel) {
        editMode = !editMode
      } else {
        if editMode {
          // create obstacles if we are in edit mode
          
          let randomSize = CGSize(width: RandomInt(min: 32, max: 128), height: 16)
          let box = SKSpriteNode(color: RandomColor(), size: randomSize)
          box.name = "box"
          box.position = location
          box.zRotation = RandomCGFloat(min: 0, max: 3)
          box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
          box.physicsBody!.isDynamic = false
          addChild(box)
          
        } else {
          // create balls if we are not in edit mode
          
          // Balls can be created by tapping above the screen
          guard location.y > 600 else { return }
          
          // Choose the ball colors randomly
          let randomBallNumber = RandomInt(min: 0, max: 6)
          let ball = SKSpriteNode(imageNamed: ballNames[randomBallNumber])
          ball.name = "ball"
          
          // Position of ball is where we tap on the screen
          ball.position = location
          ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2.0)
          
          // Inform us about every collisin
          ball.physicsBody!.contactTestBitMask = ball.physicsBody!.collisionBitMask
          ball.physicsBody!.restitution = 0.4
          
          addChild(ball)
        }
      }
    }
    
  }
  
  func didBegin(_ contact: SKPhysicsContact) {
    if contact.bodyA.node?.name == "ball" {
      makeCollision(ball: contact.bodyA.node!, object: contact.bodyB.node!)
    } else if contact.bodyB.node?.name == "ball" {
      makeCollision(ball: contact.bodyB.node!, object: contact.bodyA.node!)
    }
  }
  
  // Create a bouncer at a given location
  private func makeBouncer(at position: CGPoint) {
    let bouncer = SKSpriteNode(imageNamed: "bouncer.png")
    bouncer.position = position
    bouncer.zPosition = 1
    bouncer.physicsBody = SKPhysicsBody(circleOfRadius: bouncer.size.width / 2.0)
    bouncer.physicsBody?.isDynamic = false
    addChild(bouncer)
  }
  
  // Create a good or bad slotBase and slotGlow at a given location
  private func makeSlot(at position: CGPoint, isGood: Bool) {
    let slotBase, slotGlow: SKSpriteNode
    
    if isGood {
      slotBase = SKSpriteNode(imageNamed: "slotBaseGood.png")
      slotBase.name = "slotBaseGood"
      slotGlow = SKSpriteNode(imageNamed: "slotGlowGood.png")
    } else {
      slotBase = SKSpriteNode(imageNamed: "slotBaseBad.png")
      slotBase.name = "slotBaseBad"
      slotGlow = SKSpriteNode(imageNamed: "slotGlowBad.png")
    }
    
    slotBase.physicsBody = SKPhysicsBody(rectangleOf: slotBase.size)
    slotBase.physicsBody!.isDynamic = false
    slotBase.position = position
    slotGlow.position = position
    
    // Add a continuous spinning action to slotGlow
    let spin = SKAction.rotate(byAngle: CGFloat.pi, duration: 10)
    let spinForever = SKAction.repeatForever(spin)
    slotGlow.run(spinForever)
    
    addChild(slotBase)
    addChild(slotGlow)
  }
  
  private func makeCollision(ball: SKNode, object: SKNode) {
    
    guard let objectName = object.name else { return }
    
    switch objectName {
    case "slotBaseGood":
      destroy(ball: ball)
      score += 1
    case "slotBaseBad":
      destroy(ball: ball)
      score -= 1
    case "box":
      remove(object)
    default:
      return
    }
    
  }
  
  // Destroy the ball
  private func destroy(ball: SKNode) {
    
    // Create a fire effect while ball is destroyed.
    if let emitter = SKEmitterNode(fileNamed: "FireParticles.sks") {
      emitter.position = ball.position
      addChild(emitter)
    }
    
    // Destroy the ball by removing from view
    ball.removeFromParent()
  }
  
  // Remove the box when hit by the ball
  private func remove(_ box: SKNode) {
    let location = box.position
    let obstacles = nodes(at: location)
    if obstacles.contains(box) {
      box.removeFromParent()
    }
  }
  
  
}
