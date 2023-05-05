local config = require("config")

local player = {}

function player.update(box, state, timers, dt)
    player.move(box, state, timers, dt)
    player.invert(box, state, dt)

    -- Box trail
    table.insert(box.trail, 1, {x = box.body:getX(), y = box.body:getY(), angle = box.body:getAngle()})
    if #box.trail > box.maxTrailLength then
        table.remove(box.trail)
    end
end

function player.invert(box, state, dt)
  if love.keyboard.isDown("space") and state.inverting == false and state.invertingBack == false then
    if state.invertingProgress == 0 then 
      state.inverting = true
    else
      state.invertingBack = true
    end
  end
end

function player.move(box, state, timers, dt)
  
  local forceX, forceY = 0, 0
  
  -- Simple jump
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w")) and state.collidingWithFloor == true then
      timers.secondJump = 0.35
      timers.justFirstJumped = 1.0
      forceY = -config.boxJumpForce
    end

    -- Double jump
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w")) and state.collidingWithFloor == false and state.hasDoubleJumped == false and timers.secondJump <= 0 and timers.justFirstJumped > 0 then
      state.hasDoubleJumped = true
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


return player