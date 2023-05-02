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
  hasDoubleJumped = false,
  inverting = false,
  invertingBack = false,

  height = 50
}

local timers = {
  justFirstJumped = 0.0,
  secondJump = 0.0
}

local oscillator = 0
local backgroundOscillation = 25

local shaderCode = [[
    uniform float progress;
    uniform float opacity;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 texcolor = Texel(texture, texture_coords);
        texcolor.rgb = mix(texcolor.rgb, vec3(0.0), progress);
        texcolor.a = texcolor.a * opacity;
        return texcolor * color;
    }
]]
local invertingProgress = 0
local invertingBackProgress = 1
local shader 

function love.load()

    shader = love.graphics.newShader(shaderCode)

    -- Create world
    world = physics.newWorld(0, config.gravity * config.pixelsPerMeter)
    world:setCallbacks(beginContact, endContact) 

    -- Create entities
    backgroundGround = factory.createBackgroundGround({})
    ground = factory.createGround(config)
    box = factory.createBox(config)
end


function love.update(dt)

    -- Update the world with the elapsed time
    world:update(dt)  

    -- Move player
    playerMovement(dt)
    playerActions(dt)

    -- Update timers
    timers.secondJump = timers.secondJump - dt
    timers.justFirstJumped = timers.justFirstJumped - dt

    -- Update inverting
    if states.inverting == true then
      invertingProgress = invertingProgress + 1.5 * dt
      states.height = states.height + 45 * dt
      setBoxHeight(box, states.height) 
      if invertingProgress > 1 then
        invertingProgress = 1
        invertingBackProgress = 1
        states.inverting = false
      end
    end

    -- Update inverting back
    if states.invertingBack == true then
      invertingBackProgress = invertingBackProgress - 1.5 * dt
      states.height = states.height - 45 * dt
      setBoxHeight(box, states.height) 
      if invertingBackProgress < 0 then
        invertingBackProgress = 0
        invertingProgress = 0
        states.invertingBack = false
      end
    end

    -- Update background color
    background.update(dt)

    -- Oscillator
    oscillator = math.sin(love.timer.getTime() * 0.1 * math.pi * 2)

    -- Box trail
    table.insert(box.trail, 1, {x = box.body:getX(), y = box.body:getY(), angle = box.body:getAngle()})
    if #box.trail > box.maxTrailLength then
        table.remove(box.trail)
    end

end

function love.draw()
    background.draw()
 
    -- Move camera
    love.graphics.push()
    setCamera(box.body:getX(), box.body:getY())

    -- Draw the background rectangles
    for _, rectangle in ipairs(backgroundGround.rectangles) do
      love.graphics.setColor(0, 0, 0, rectangle.color.a)
      love.graphics.rectangle("fill", rectangle.x, rectangle.y + oscillator * backgroundOscillation * rectangle.color.a, rectangle.width, rectangle.height)
    end

    -- Draw the ground
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("fill", ground.body:getWorldPoints(ground.shape:getPoints()))

    -- Draw the box
    love.graphics.setShader(shader)
    shader:send("opacity", 1)

    if states.inverting then
      shader:send("progress", invertingProgress)
    end
    if states.invertingBack then
      shader:send("progress", invertingBackProgress)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("fill", box.body:getWorldPoints(box.shape:getPoints()))
    
    -- Draw trail
    for i, pos in ipairs(box.trail) do
      local alpha = (0.7 - i / box.maxTrailLength)
      shader:send("opacity", alpha)
      local corners = getRotatedBoxCorners(pos.x, pos.y, 50, 50, pos.angle)
      love.graphics.polygon("fill", corners)
    end

    love.graphics.setColor(255, 255, 255)

    -- Clean up 
    love.graphics.setShader()
    love.graphics.pop()

    -- Print
    love.graphics.print(oscillator, 0, 0)
end

function setBoxHeight(box, newHeight)
  -- Remove the old fixture
  box.fixture:destroy()

  -- Create a new shape with the new height
  local newShape = physics.newRectangleShape(50, newHeight)

  -- Create a new fixture and attach it to the body
  box.fixture = physics.newFixture(box.body, newShape, 1) -- Density is 1
  box.fixture:setRestitution(box.fixture:getRestitution()) -- Keep the same restitution (bounciness)

  -- Update the box's shape
  box.shape = newShape
end


function playerActions(dt)
  if love.keyboard.isDown("space") and states.inverting == false and states.invertingBack == false then
    if invertingProgress == 0 then 
      states.inverting = true
    else
      states.invertingBack = true
    end
  end

end

function playerMovement(dt)
  
  local forceX, forceY = 0, 0
  
  -- Simple jump
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w")) and states.collidingWithFloor == true then
      timers.secondJump = 0.35
      timers.justFirstJumped = 1.0
      forceY = -config.boxJumpForce
    end

    -- Double jump
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w")) and states.collidingWithFloor == false and states.hasDoubleJumped == false and timers.secondJump <= 0 and timers.justFirstJumped > 0 then
      states.hasDoubleJumped = true
      forceY = -config.boxJumpForce
    end

    -- Move left
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
      forceX = -config.boxMovementForce
      box.body:applyTorque(-config.boxRotationForce)
      if invertingProgress == 1 then
        forceX = -config.boxMovementForce * 2
        box.body:applyTorque(-config.boxRotationForce * 2)
      end
    end

    -- Move right
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
      forceX = config.boxMovementForce
      box.body:applyTorque(config.boxRotationForce)

      -- If black; move more
      if invertingProgress == 1 then
        forceX = config.boxMovementForce * 2
        box.body:applyTorque(config.boxRotationForce * 2)
      end
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

function getRotatedBoxCorners(x, y, width, height, angle)
  local hw, hh = width / 2, height / 2
  local corners = {
      x + hw * math.cos(angle) - hh * math.sin(angle), y + hw * math.sin(angle) + hh * math.cos(angle),
      x - hw * math.cos(angle) - hh * math.sin(angle), y - hw * math.sin(angle) + hh * math.cos(angle),
      x - hw * math.cos(angle) + hh * math.sin(angle), y - hw * math.sin(angle) - hh * math.cos(angle),
      x + hw * math.cos(angle) + hh * math.sin(angle), y + hw * math.sin(angle) - hh * math.cos(angle)
  }
  return corners
end

function love.keypressed(key)
  if key == "f11" then -- You can change "f11" to any key you want to use for toggling fullscreen
      local isFullscreen = love.window.getFullscreen()
      love.window.setFullscreen(not isFullscreen)
  end
end