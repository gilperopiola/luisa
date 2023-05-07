local utils = require("utils")

local background = {}

local colors = {
    {1, 0, 0},
    {0, 0, 1},
    {0, 0, 0},
  }
  
  local currentColorIndex = 1
  local nextColorIndex = 2
  local interpolationProgress = 0
  local interpolationSpeed = 0.1 
  
function background.update(rectangles, oscillator, dt)

    -- Interpolate colors
    interpolationProgress = interpolationProgress + interpolationSpeed * dt
    if interpolationProgress >= 1 then
        interpolationProgress = 0
        currentColorIndex = nextColorIndex
        nextColorIndex = currentColorIndex % #colors + 1
    end

    -- Move background rectangles
    for _, rectangle in ipairs(rectangles) do
        rectangle.y = rectangle.y + oscillator / 3 * rectangle.color.a
    end

end

function background.draw()
    local currentColor = colors[currentColorIndex]
    local nextColor = colors[nextColorIndex]
    local r = utils.lerp(currentColor[1], nextColor[1], interpolationProgress)
    local g = utils.lerp(currentColor[2], nextColor[2], interpolationProgress)
    local b = utils.lerp(currentColor[3], nextColor[3], interpolationProgress)
    love.graphics.setBackgroundColor(r, g, b)
end

function background.drawRectangles(rectangles)
    -- Draw the background rectangles
    for _, rectangle in ipairs(rectangles) do
        cc = rectangle.colorComponent
        love.graphics.setColor(cc, cc, cc, rectangle.color.a)
        love.graphics.rectangle("fill", rectangle.x, rectangle.y, rectangle.width, rectangle.height)
    end
end

return background