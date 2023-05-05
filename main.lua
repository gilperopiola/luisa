local love = require("love")
local physics = love.physics

local config = require("config")
local state = require("state")
local timers = require("timers")

local player = require("player")
local background = require("background")
local factory = require("factory")

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
local shader 

function love.load()

    shader = love.graphics.newShader(shaderCode)

    -- Create world
    world = physics.newWorld(0, config.gravity * config.pixelsPerMeter)
    world:setCallbacks(beginContact, endContact) 

    -- Create entities
    backgroundGround = factory.createBackgroundGround({})
    grounds = factory.createGround(config)
    box = factory.createBox(config)
end


function love.update(dt)

    -- Update the world with the elapsed time
    world:update(dt)  

    -- Move player
    player.update(box, state, timers, dt)

    -- Update timers
    timers.update(dt)

    -- Invert black / white
    playerInvert(dt)

    -- Update background color
    background.update(dt)

    -- Oscillator
    oscillator = math.sin(love.timer.getTime() * 0.1 * math.pi * 2)

    -- Move background rectangles
    for _, rectangle in ipairs(backgroundGround.rectangles) do
      rectangle.y = rectangle.y + oscillator / 3 * rectangle.color.a
    end

end

function love.draw()
    background.draw()
 
    -- Move camera
    love.graphics.push()
    setCamera(box.body:getX(), box.body:getY())

    -- Draw the background rectangles
    for _, rectangle in ipairs(backgroundGround.rectangles) do
      cc = rectangle.colorComponent
      love.graphics.setColor(cc, cc, cc, rectangle.color.a)
      love.graphics.rectangle("fill", rectangle.x, rectangle.y, rectangle.width, rectangle.height)
    end

    -- Draw the ground
    for _, ground in ipairs(grounds.grounds) do
      love.graphics.setColor(1, 1, 1)
      love.graphics.polygon("fill", ground.body:getWorldPoints(ground.shape:getPoints()))
    end

    -- Set everything to draw the box
    love.graphics.setShader(shader)
    shader:send("opacity", 1)

    if state.inverting then
      shader:send("progress", state.invertingProgress)
    end
    if state.invertingBack then
      shader:send("progress", state.invertingBackProgress)
    end
    
    -- Draw box
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.polygon("fill", box.body:getWorldPoints(box.shape:getPoints()))

    -- Draw trail
    for i, pos in ipairs(box.trail) do
      local alpha = (0.45 - i / box.maxTrailLength)
      shader:send("opacity", alpha)
      local corners = getRotatedBoxCorners(pos.x, pos.y, state.width, state.height, pos.angle)
      love.graphics.polygon("fill", corners)
    end

    
    -- Clean up 
    love.graphics.setColor(255, 255, 255)
    love.graphics.setShader()
    love.graphics.pop()

    -- Print
    love.graphics.print(oscillator, 0, 0)
end

function setBoxHeight(box, newHeight)
  -- Remove the old fixture
  box.fixture:destroy()

  -- Create a new shape with the new height
  local newShape = physics.newRectangleShape(state.width, newHeight)

  -- Create a new fixture and attach it to the body
  box.fixture = physics.newFixture(box.body, newShape, 1) -- Density is 1
  box.fixture:setRestitution(box.fixture:getRestitution()) -- Keep the same restitution (bounciness)

  -- Update the box's shape
  box.shape = newShape
end

function setBoxWidth(box, newWidth)
  -- Remove the old fixture
  box.fixture:destroy()

  -- Create a new shape with the new height
  local newShape = physics.newRectangleShape(newWidth, state.height)

  -- Create a new fixture and attach it to the body
  box.fixture = physics.newFixture(box.body, newShape, 1) -- Density is 1
  box.fixture:setRestitution(box.fixture:getRestitution()) -- Keep the same restitution (bounciness)

  -- Update the box's shape
  box.shape = newShape
end



function playerInvert(dt)
    -- Update inverting
    if state.inverting == true then
      state.invertingProgress = state.invertingProgress + 1.5 * dt
      state.height = state.height + 45 * dt
      setBoxHeight(box, state.height) 
      state.width = state.width - 30 * dt
      setBoxWidth(box, state.width) 
      if state.invertingProgress > 1 then
        state.invertingProgress = 1
        state.invertingBackProgress = 1
        state.inverting = false
      end
    end

    -- Update inverting back
    if state.invertingBack == true then
      state.invertingBackProgress = state.invertingBackProgress - 1.5 * dt
      state.height = state.height - 45 * dt
      setBoxHeight(box, state.height) 
      state.width = state.width + 30 * dt
      setBoxWidth(box, state.width) 
      if state.invertingBackProgress < 0 then
        state.invertingBackProgress = 0
        state.invertingProgress = 0
        state.invertingBack = false
      end
    end
end

-- Utils

function beginContact(fixtureA, fixtureB, contact)
  
  local isBoxAndGroundCollision = false
  for _, ground in ipairs(grounds.grounds) do
    if (fixtureA == box.fixture and fixtureB == ground.fixture) or (fixtureA == ground.fixture and fixtureB == box.fixture) then
      isBoxAndGroundCollision = true
    end
  end

  if isBoxAndGroundCollision then
    state.collidingWithFloor = true
    state.hasDoubleJumped = false
  end
end
  
function endContact(fixtureA, fixtureB, contact)

  local isBoxAndGroundCollision = false
  for _, ground in ipairs(grounds.grounds) do
    if (fixtureA == box.fixture and fixtureB == ground.fixture) or (fixtureA == ground.fixture and fixtureB == box.fixture) then
      isBoxAndGroundCollision = true
    end
  end
  
  if isBoxAndGroundCollision then
    state.collidingWithFloor = false
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