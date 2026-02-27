local myCar = ac.getCar(0) or error()
local sim = ac.getSim()

local hasPenalty = false
local currentPenaltySlowdownTime = 0
ac.onMessage(function (title, description, type, time)
  if type == 'illegal' and title:startsWith('PENALTY, SLOW DOWN') then
    hasPenalty = true
    currentPenaltySlowdownTime = tonumber(title:split(' ')[5]) or 0
  end
end)

local safetyMode = false;
local gnServerEvent = ac.OnlineEvent({
  ac.StructItem.key('gnServerEvent'),
  message = ac.StructItem.string(),
  args = ac.StructItem.string(256)
}, function (sender, data)
  local eventMsg, eventArg = data.message, stringify.parse(data.args) or ''
  if eventMsg == 'remove penalty' and currentPenaltySlowdownTime > 0 then
    physics.setCarPenalty(ac.PenaltyType.SlowDown, -currentPenaltySlowdownTime - 1)
  elseif eventMsg == 'penalty' and eventArg[1] == myCar.sessionID then
    physics.setCarPenalty(ac.PenaltyType.SlowDown, 5)
  elseif eventMsg == 'teleport' and eventArg[1] == myCar.sessionID then
    physics.setCarPosition(0, eventArg[2], eventArg[3])
  elseif eventMsg == 'safety on' then
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

local adminSteamID = '76561199806619573'
function script.update(dt)
  if sim.raceFlagType ~= ac.FlagType.ReturnToPits then
    hasPenalty = false
    currentPenaltySlowdownTime = 0
  end
  if ac.getUserSteamID() ~= adminSteamID then return end
  local currentMsg = gnData.msg
  if currentMsg == '' then
    return
  elseif currentMsg == '1/2 mass' then
    local targetBallast = (myCar.ballast == 0) and math.floor(-myCar.mass / 2) or 0
    physics.setCarBallast(0, targetBallast)
  elseif currentMsg == 'remove penalty' and currentPenaltySlowdownTime > 0 then
    physics.setCarPenalty(ac.PenaltyType.SlowDown, -currentPenaltySlowdownTime - 1)
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
