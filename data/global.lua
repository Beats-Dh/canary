math.randomseed(os.time())
dofile('data/lib/lib.lua')

NOT_MOVEABLE_ACTION = 100
PARTY_PROTECTION = 1 -- Set to 0 to disable.
ADVANCED_SECURE_MODE = 1 -- Set to 0 to disable.

NORTH = DIRECTION_NORTH
EAST = DIRECTION_EAST
SOUTH = DIRECTION_SOUTH
WEST = DIRECTION_WEST
SOUTHWEST = DIRECTION_SOUTHWEST
SOUTHEAST = DIRECTION_SOUTHEAST
NORTHWEST = DIRECTION_NORTHWEST
NORTHEAST = DIRECTION_NORTHEAST

STORAGEVALUE_PROMOTION = 30018

SERVER_NAME = configManager.getString(configKeys.SERVER_NAME)

-- Bestiary charm
GLOBAL_CHARM_GUT = 0
GLOBAL_CHARM_SCAVENGE = 0

--WEATHER
weatherConfig = {
    groundEffect = CONST_ME_LOSEENERGY,
	fallEffect = CONST_ANI_SMALLICE,
    thunderEffect = configManager.getBoolean(configKeys.WEATHER_THUNDER),
    minDMG = 1,
    maxDMG = 5
}

-- Event Schedule
SCHEDULE_LOOT_RATE = 100
SCHEDULE_EXP_RATE = 100
SCHEDULE_SKILL_RATE = 100

-- MARRY
PROPOSED_STATUS = 1
MARRIED_STATUS = 2
PROPACCEPT_STATUS = 3
LOOK_MARRIAGE_DESCR = TRUE
ITEM_WEDDING_RING = 2121
ITEM_ENGRAVED_WEDDING_RING = 10502

-- Scarlett Etzel
SCARLETT_MAY_TRANSFORM = 0
SCARLETT_MAY_DIE = 0

ropeSpots = {386, 421, 7762, 12202, 12936, 14238, 17238, 21501, 21965, 21966, 21967, 21968, 23363, 24358}
specialRopeSpots = {12935}

-- Impact Analyser
-- Every 2 seconds
updateInterval = 2
-- Healing
-- Global table to insert data
healingImpact = {}
-- Damage
-- Global table to insert data
damageImpact = {}

-- New prey => preyTimeLeft
nextPreyTime = {}

do -- Event Schedule rates
	local lootRate = Game.getEventSLoot()
	if lootRate ~= 100 then
		SCHEDULE_LOOT_RATE = lootRate
	end

	local expRate = Game.getEventSExp()
	if expRate ~= 100 then
		SCHEDULE_EXP_RATE = expRate
	end

	local skillRate = Game.getEventSSkill()
	if skillRate ~= 100 then
		SCHEDULE_SKILL_RATE = skillRate
	end
end

table.contains = function(array, value)
	for _, targetColumn in pairs(array) do
		if targetColumn == value then
			return true
		end
	end
	return false
end

string.split = function(str, sep)
	local res = {}
	for v in str:gmatch("([^" .. sep .. "]+)") do
		res[#res + 1] = v
	end
	return res
end

string.splitTrimmed = function(str, sep)
	local res = {}
	for v in str:gmatch("([^" .. sep .. "]+)") do
		res[#res + 1] = v:trim()
	end
	return res
end

string.trim = function(str)
	return str:match'^()%s*$' and '' or str:match'^%s*(.*%S)'
end

-- Stamina
if nextUseStaminaTime == nil then
	nextUseStaminaTime = {}
end

if nextUseStaminaPrey == nil then
	nextUseStaminaPrey = {}
end

if nextUseXpStamina == nil then
	nextUseXpStamina = {}
end

if lastItemImbuing == nil then
	lastItemImbuing = {}
end

if nextDelayPreyReroll == nil then
	nextDelayPreyReroll = {}
end

-- Delay potion
if not playerDelayPotion then
	playerDelayPotion = {}
end

-- this is a fix for lua52 or higher which has the function renamed to table.unpack, while luajit still uses unpack
if unpack == nil then
	unpack = table.unpack
end

-- Increase Stamina when Attacking Trainer
staminaBonus = {
	target = 'Training Machine',
	period = configManager.getNumber(configKeys.STAMINA_TRAINER_DELAY) * 60 * 1000, -- time on miliseconds trainers
	bonus = configManager.getNumber(configKeys.STAMINA_TRAINER_GAIN), -- gain stamina trainers
	eventsTrainer = {}, -- stamina in trainers
	eventsPz = {} -- stamina in Pz
}

function addStamina(id, ...)
	-- Creature:onTargetCombat
	if id then
		local player = Player(id)
		if configManager.getBoolean(configKeys.STAMINA_TRAINER) then
			if not player then
				staminaBonus.eventsTrainer[id] = nil
			else
				local target = player:getTarget()
				if not target or target:getName() ~= staminaBonus.target then
					staminaBonus.eventsTrainer[id] = nil
				else
					player:setStamina(player:getStamina() + staminaBonus.bonus)
					player:sendTextMessage(MESSAGE_STATUS_SMALL,
																string.format("%i of stamina has been refilled.",
																configManager.getNumber(configKeys.STAMINA_TRAINER_GAIN)))
					staminaBonus.eventsTrainer[id] = addEvent(addStamina, staminaBonus.period, id)
				end
			end
		end
		return not configManager.getBoolean(configKeys.STAMINA_TRAINER)
	end

	-- Player:onChangeZone
	local id, delay = ...

	if id and delay then
		if not staminaBonus.eventsPz[id] then return false end
		stopEvent(staminaBonus.eventsPz[id])

		local player = Player(id)
		if not player then
			staminaBonus.eventsPz[id] = nil
			return false
		end

		local actualStamina = player:getStamina()

		if actualStamina > 2400 and actualStamina < 2520 then
			delay = configManager.getNumber(configKeys.STAMINA_GREEN_DELAY) * 60 * 1000 -- Stamina Green 12 min.
		elseif actualStamina == 2520 then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "You are no longer refilling stamina, because your stamina is already full.")
			staminaBonus.eventsPz[id] = nil
			return false
		end

		player:setStamina(player:getStamina() + configManager.getNumber(configKeys.STAMINA_PZ_GAIN))
		player:sendTextMessage(MESSAGE_STATUS_SMALL,
																string.format("%i of stamina has been refilled.",
																configManager.getNumber(configKeys.STAMINA_PZ_GAIN)))
																staminaBonus.eventsPz[id] = addEvent(addStamina, delay, nil, id, delay)
		return true
	end
	return false
end
