local myCar = ac.getCar(0) or error()
local sim = ac.getSim()

local hasPenalty = false
local currentPenaltyTime = 0
local oldLapCuts = 0;
local minorPenalty = true;
ac.onLapCompleted(0, function (carIndex, lapTime, valid, cuts, lapCount)
end)

local safetyMode = false;
local gnServerEvent = ac.OnlineEvent({
  ac.StructItem.key('gnServerEvent'),
  message = ac.StructItem.string(),
  args = ac.StructItem.string(256)
}, function (sender, data)
  local eventMsg, eventArg = data.message, stringify.parse(data.args) or ''
  if eventMsg == 'remove penalty' and currentPenaltyTime > 0 then
    currentPenaltyTime = 0
  elseif eventMsg == 'penalty' and eventArg[1] == myCar.sessionID then
    currentPenaltyTime = currentPenaltyTime + 5
  elseif eventMsg == 'teleport' and eventArg[1] == myCar.sessionID then
    physics.setCarPosition(0, eventArg[2], eventArg[3])
  elseif eventMsg == 'safety on' then
    if safetyMode == false then
      print('safetyMode!!')
      if myCar.gas > .2 then
        physics.forceUserThrottleFor(1, .2)
      end
      -- local passivePush = -50000 * myCar.speedKmh
      -- physics.addForce(0, vec3(0, 0, 0), true, vec3(0, 0, passivePush), true)
    end
    safetyMode = true
  elseif eventMsg == 'safety off' then
    safetyMode = false
  end
end, ac.SharedNamespace.ServerScript)

local gnData = ac.connect({
  ac.StructItem.key("gnData"),
  msg = ac.StructItem.string(),
  arg = ac.StructItem.string(256),
}, true, ac.SharedNamespace.Shared)

ac.onCarCollision(0, function (carIndex)
  if carIndex ~= -1 and myCar.collisionDepth > .01 then
    physics.disableCarCollisions(0)
  end
end)

local mainMenu, shown = true, false
local adminSteamID = '76561199806619573'
function script.update(dt)
  if oldLapCuts < myCar.lapCutsCount then
    currentPenaltyTime = currentPenaltyTime + 5;
  end
  oldLapCuts = myCar.lapCutsCount
  if currentPenaltyTime > 0 then
    ac.setMessage('Penalty', 'slow down for %.1fs or slow down to 35kmh' % currentPenaltyTime, 'illegal', .1)
    if myCar.speedKmh <= 35 then
      currentPenaltyTime = 0
    end
    if myCar.gas == 0 then
      currentPenaltyTime = math.max(currentPenaltyTime - dt, 0)
    end
  end

  if not shown and mainMenu and not sim.isInMainMenu and not ac.isModuleActive(ac.CSPModuleID.RainFX) then
    local msg = 'RainFX is not enabled. (You may be disadvantaged)\n\nRainFX가 활성화되어 있지 않습니다. (불이익이 있을 수 있음)'
    ui.modalPopup('WARNING', msg, 'Confirm', nil, nil, nil, function (okPressed)
    end)
    shown = true
  end
  mainMenu = sim.isInMainMenu

  if safetyMode then
    local distanceToLeader = (ac.getCar.leaderboard(0).position - myCar.position):length()
    distanceToLeader = math.max(0, math.min(distanceToLeader, 1000))
    local passivePush = -500000 * math.max(0, myCar.speedKmh - 100) * sim.dt * (1 - (distanceToLeader / 1000))
    physics.addForce(0, vec3(0, 0, 0), true, vec3(0, 0, passivePush), true)
  end

  if ac.getUserSteamID() ~= adminSteamID then return end
  local currentMsg = gnData.msg
  if currentMsg == '' then
    return
  elseif currentMsg == '1/2 mass' then
    local targetBallast = (myCar.ballast == 0) and math.floor(-myCar.mass / 2) or 0
    physics.setCarBallast(0, targetBallast)
  elseif currentMsg == 'remove penalty' and currentPenaltyTime > 0 then
    currentPenaltyTime = 0
  elseif currentMsg == 'remove penalty for all' then
    gnServerEvent{ message = 'remove penalty' }
  elseif currentMsg == 'teleport' then
    gnServerEvent{ message = 'teleport', args = gnData.arg }
  elseif currentMsg == 'penalty' then
    gnServerEvent{ message = 'penalty', args = gnData.arg }
  elseif currentMsg == 'safety on' then
    gnServerEvent{ message = 'safety on', args = gnData.arg }
  elseif currentMsg == 'safety off' then
    gnServerEvent{ message = 'safety off', args = gnData.arg }
  end

  gnData.msg = ''
end

local safetySize = vec2(240, 80)
local screenSize = const(vec2(sim.windowWidth, sim.windowHeight))
local pos = vec2(screenSize.x, 640) / 2 - safetySize / 2
function script.drawUI(dt)
  if safetyMode then
    ui.transparentWindow('safety', pos, safetySize, function ()
      ui.drawRectFilled(vec2(0), safetySize,
        math.floor(sim.time / 250) % 2 == 0 and rgbm(.15, .15, .15, 1) or rgbm(.7, .7, 0, 1))
      ui.pushStyleVar(ui.StyleVar.ItemSpacing, -2)

      ui.pushAlignment(true)

      ui.pushFont(ui.Font.Title)
      ui.pushAlignment()
      ui.setNextTextBold()
      ui.text('!     SAFETY MOD     !')
      ui.popAlignment()

      ui.pushAlignment()
      ui.text('slow down your car')
      ui.popAlignment()
      ui.popFont()

      ui.popAlignment()
      ui.popStyleVar()
    end)
  end
end
