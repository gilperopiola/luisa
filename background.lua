local background = {}

local colors = {
    {1, 0, 0},
    {0, 1, 0},
    {0, 0, 1},
    {1, 1, 0}
  }
  
  local currentColorIndex = 1
  local nextColorIndex = 2
  local interpolationProgress = 0
  local interpolationSpeed = 0.1 
  
function background.update(dt)

    -- Interpolate colors
    interpolationProgress = interpolationProgress + interpolationSpeed * dt
    if interpolationProgress >= 1 then
        interpolationProgress = 0
        currentColorIndex = nextColorIndex
        nextColorIndex = currentColorIndex % #colors + 1
    end

end

function background.draw()
    local currentColor = colors[currentColorIndex]
    local nextColor = colors[nextColorIndex]
    local r = lerp(currentColor[1], nextColor[1], interpolationProgress)
    local g = lerp(currentColor[2], nextColor[2], interpolationProgress)
    local b = lerp(currentColor[3], nextColor[3], interpolationProgress)
    love.graphics.setBackgroundColor(r, g, b)
end

return background