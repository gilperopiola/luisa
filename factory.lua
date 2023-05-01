local factory = {}

local love = require("love")
local physics = love.physics

function factory.createBox(config)
    box = {}
    box.body = physics.newBody(world, love.graphics.getWidth() / 2, 100, "dynamic")
    box.shape = physics.newRectangleShape(50, 50)
    box.fixture = physics.newFixture(box.body, box.shape, 1) -- Density is 1
    box.fixture:setRestitution(config.boxBounciness) -- Set restitution (bounciness) for box
    box.body:setLinearDamping(5)
    box.body:setAngularDamping(5) 
    return box
end

function factory.createGround(config)
    ground = {}
    ground.body = physics.newBody(world, love.graphics.getWidth() / 2, love.graphics.getHeight() - 50)
    ground.shape = physics.newRectangleShape(love.graphics.getWidth(), 70)
    ground.fixture = physics.newFixture(ground.body, ground.shape)
    ground.fixture:setFriction(config.floorFriction) -- Set friction for ground
    return ground
end


return factory