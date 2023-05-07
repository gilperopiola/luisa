local love = require("love")
local physics = love.physics

local utils = {}

function utils.lerp(a, b, t)
  return a + (b - a) * t
end

function utils.setCamera(x, y)
  local windowWidth, windowHeight = love.graphics.getDimensions()
  local cameraX, cameraY = -x + windowWidth / 2, -y + windowHeight / 2

  -- Apply camera transformation
  love.graphics.translate(cameraX, cameraY)
end

function utils.getRotatedBoxCorners(x, y, width, height, angle)
  local hw, hh = width / 2, height / 2
  local corners = {
      x + hw * math.cos(angle) - hh * math.sin(angle), y + hw * math.sin(angle) + hh * math.cos(angle),
      x - hw * math.cos(angle) - hh * math.sin(angle), y - hw * math.sin(angle) + hh * math.cos(angle),
      x - hw * math.cos(angle) + hh * math.sin(angle), y - hw * math.sin(angle) - hh * math.cos(angle),
      x + hw * math.cos(angle) + hh * math.sin(angle), y + hw * math.sin(angle) - hh * math.cos(angle)
  }
  return corners
end

function utils.setBoxHeight(box, state, newHeight)
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

function utils.setBoxWidth(box, state, newWidth)
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


return utils