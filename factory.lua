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
    box.trail = {}
    box.maxTrailLength = 20
    return box
end

local groundsJSON = {
    {x = 400, y = 550, width = 800, height = 70},
    {x = 400, y = 780, width = 800, height = 70},
    {x = 400, y = 1010, width = 800, height = 40},
    {x = 400, y = 1240, width = 800, height = 20},
    {x = 400, y = 1470, width = 800, height = 10},

    {x = 775, y = 500, width = 50, height = 50},
    {x = 25, y = 850, width = 50, height = 350}
}

function factory.createGround(config)
    local grounds = {}
    grounds.grounds = {}

    for _, groundJSON in ipairs(groundsJSON) do
        ground = {}
        ground.body = physics.newBody(world, groundJSON.x, groundJSON.y)
        ground.shape = physics.newRectangleShape(groundJSON.width, groundJSON.height)
        ground.fixture = physics.newFixture(ground.body, ground.shape)
        ground.fixture:setFriction(config.floorFriction) 
        table.insert(grounds.grounds, ground)
    end

    return grounds
end

function factory.createBackgroundGround(config)
    local backgroundGround = {}
    backgroundGround.rectangles = {}

    -- Configuration for the number of rectangles and their size range
    local numRectangles = config.numRectangles or 300
    local minWidth = config.minWidth or 30
    local maxWidth = config.maxWidth or 600
    local minHeight = config.minHeight or 30
    local maxHeight = config.maxHeight or 80

    -- Time to flip color
    local flipColorMinSeconds = 0.15
    local flipColorMaxSeconds = 6.15
    local flipColorTimer = flipColorMinSeconds + (flipColorMaxSeconds - flipColorMinSeconds) * math.random()

    -- Create the random rectangles
    for i = 1, numRectangles do
        local rectangle = {
            x = math.random(-love.graphics.getWidth() * 3, love.graphics.getWidth() * 3),
            y = math.random(-love.graphics.getHeight() * 3, love.graphics.getHeight() * 3),
            width = math.random(minWidth, maxWidth),
            height = math.random(minHeight, maxHeight),
            color = {
                r = 255,
                g = 255,
                b = 255,
                a = math.random(1, 5) / 10,
            },
            flipColorTimer = flipColorTimer,
            colorComponent = 0,
            state = "idle",
            trail = {}
        }
        table.insert(backgroundGround.rectangles, rectangle)
    end

    return backgroundGround

end

return factory