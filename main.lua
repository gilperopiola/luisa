local love = require("love")
local physics = love.physics

local background = require("background")
local factory = require("factory")

local config = {
    gravity = 9.81,
    pixelsPerMeter = 64,

    boxMovementForce = 5000,
    boxJumpForce = 89000,
    boxRotationForce = 24000,
    boxBounciness = 0.7,
    floorFriction = 0.6,
}

local states = {
  collidingWithFloor = false,
  hasDoubleJumped = false
}

local timers = {
  justFirstJumped = 0.0,
  secondJump = 0.0
}

function love.load()

    -- Create world
    world = physics.newWorld(0, config.gravity * config.pixelsPerMeter)
    world:setCallbacks(beginContact, endContact) 

    -- Create entities
    ground = factory.createGround(config)
    box = factory.createBox(config)
end


function love.update(dt)

    -- Update the world with the elapsed time
    world:update(dt) 

    -- Move player
    playerMovement(dt)

    -- Update timers
    timers.secondJump = timers.secondJump - dt
    timers.justFirstJumped = timers.justFirstJumped - dt

    -- Update background color
    background.update(dt)
end

function love.draw()
    background.draw()
 
    -- Move camera
    love.graphics.push()
    setCamera(box.body:getX(), box.body:getY())

    -- Draw the ground
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("fill", ground.body:getWorldPoints(ground.shape:getPoints()))

    -- Draw the box
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("fill", box.body:getWorldPoints(box.shape:getPoints()))

    love.graphics.pop()
end


function playerMovement(dt)
  
  local forceX, forceY = 0, 0
  
  -- Simple jump
    if love.keyboard.isDown("up") and states.collidingWithFloor == true then
      timers.secondJump = 0.35
      timers.justFirstJumped = 1.0
      forceY = -config.boxJumpForce
    end

    -- Double jump
    if love.keyboard.isDown("up") and states.collidingWithFloor == false and states.hasDoubleJumped == false and timers.secondJump <= 0 and timers.justFirstJumped > 0 then
      states.hasDoubleJumped = true
      forceY = -config.boxJumpForce
    end

    -- Move left
    if love.keyboard.isDown("left") then
      forceX = -config.boxMovementForce
      box.body:applyTorque(-config.boxRotationForce)
    end

    -- Move right
    if love.keyboard.isDown("right") then
      forceX = config.boxMovementForce
      box.body:applyTorque(config.boxRotationForce)
    end
  
    -- Apply force to the box's body based on arrow key input
    box.body:applyForce(forceX, forceY)

end

-- Utils

function beginContact(fixtureA, fixtureB, contact)
    local isBoxAndGroundCollision =
      (fixtureA == box.fixture and fixtureB == ground.fixture) or
      (fixtureA == ground.fixture and fixtureB == box.fixture)
  
    if isBoxAndGroundCollision then
      states.collidingWithFloor = true
      states.hasDoubleJumped = false
    end
end
  
function endContact(fixtureA, fixtureB, contact)
    local isBoxAndGroundCollision =
      (fixtureA == box.fixture and fixtureB == ground.fixture) or
      (fixtureA == ground.fixture and fixtureB == box.fixture)
  
    if isBoxAndGroundCollision then
      states.collidingWithFloor = false
    end
end

function lerp(a, b, t)
  return a + (b - a) * t
end

function setCamera(x, y)
  local windowWidth, windowHeight = love.graphics.getDimensions()
  local cameraX, cameraY = -x + windowWidth / 2, -y + windowHeight / 2

  -- Apply camera transformation
  love.graphics.translate(cameraX, cameraY)
end
