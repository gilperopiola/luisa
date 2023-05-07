local love = require("love")
local physics = love.physics

local config = require("config")
local state = require("state")
local timers = require("timers")
local collision = require("collision")
local utils = require("utils")

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

local mouseX, mouseY = 0, 0

function love.load()

    -- 800x600 starting resolution

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
    world:update(dt)  
    player.update(box, state, timers, dt)
    timers.update(dt)
    background.update(backgroundGround.rectangles, oscillator, dt)
    oscillator = math.sin(love.timer.getTime() * 0.1 * math.pi * 2)
end

function love.draw()

    background.draw()
 
    -- Move camera
    love.graphics.push()
    utils.setCamera(box.body:getX(), box.body:getY())

    background.drawRectangles(backgroundGround.rectangles)
    drawGround()
    player.draw(box, state, shader)
    
    -- Clean up 
    love.graphics.setColor(255, 255, 255)
    love.graphics.setShader()
    love.graphics.pop()

    love.graphics.print(mouseX .. "/" .. mouseY)
end

function drawGround()
    for _, ground in ipairs(grounds.grounds) do
      love.graphics.setColor(1, 1, 1)
      love.graphics.polygon("fill", ground.body:getWorldPoints(ground.shape:getPoints()))
    end
end

function love.keypressed(key)
  if key == "f11" then -- You can change "f11" to any key you want to use for toggling fullscreen
      local isFullscreen = love.window.getFullscreen()
      love.window.setFullscreen(not isFullscreen)
  end
end

function love.mousepressed(x, y, button)
  if button == 1 then  -- check if left mouse button was pressed
    mouseX, mouseY = x, y  -- save the mouse coordinates
  end
end
