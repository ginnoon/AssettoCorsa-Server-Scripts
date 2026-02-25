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
  end

  gnData.msg = ''
end
