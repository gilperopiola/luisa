local state = require("state")

local collision = {}

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

return collision