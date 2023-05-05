local timers = {
  justFirstJumped = 0.0,
  secondJump = 0.0
}

function timers.update(dt)
  timers.secondJump = timers.secondJump - dt
  timers.justFirstJumped = timers.justFirstJumped - dt
end

return timers