local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ibanDataStore = DataStoreService:GetDataStore("PlayerIbansV2") 
local IbanManager = {}

local playerIbansCache = {} 

function IbanManager:LoadIban(player)
	if not player then return nil end
	local userId = player.UserId
	local userIdStr = tostring(userId)

	if playerIbansCache[userId] then
		return playerIbansCache[userId]
	end

	local success, storedIban = pcall(function()
		return ibanDataStore:GetAsync(userIdStr)
	end)

	if success then
		if storedIban then
			playerIbansCache[userId] = storedIban
			print("IbanManager: " .. player.Name .. " için IBAN DataStore'dan yüklendi: " .. storedIban)
			return storedIban
		else
			local newIban = string.format("TR%05d", math.random(0, 99999)) 
			local setSuccess, setErr = pcall(function()
				ibanDataStore:SetAsync(userIdStr, newIban)
			end)
			if setSuccess then
				playerIbansCache[userId] = newIban
				print("IbanManager: " .. player.Name .. " için yeni IBAN oluşturuldu ve kaydedildi: " .. newIban)
				return newIban
			else
				warn("IbanManager: Yeni IBAN (" .. newIban .. ") DataStore'a kaydedilemedi! Oyuncu: " .. player.Name .. " Hata: " .. setErr)
				return nil 
			end
		end
	else
		warn("IbanManager: IBAN DataStore'dan okunamadı! Oyuncu: " .. player.Name .. " Hata: " .. storedIban)
		return nil
	end
end

function IbanManager:GetIban(player)
	if not player then return nil end
	return playerIbansCache[player.UserId]
end

function IbanManager:GetUserIdByIban(targetIban)
	if not targetIban or targetIban == "" then return nil end
	for userId, iban in pairs(playerIbansCache) do
		if iban == targetIban then
			return userId
		end
	end
	print("IbanManager: IBAN ("..targetIban..") önbellekte bulunamadı.")
	return nil
end

function IbanManager:RemoveIbanFromCache(player)
	if player and playerIbansCache[player.UserId] then
		playerIbansCache[player.UserId] = nil
		print("IbanManager: " .. player.Name .. " IBAN'ı önbellekten kaldırıldı.")
	end
end

function IbanManager:SaveIbanOnExit(player)
	if player and playerIbansCache[player.UserId] then
		local userIdStr = tostring(player.UserId)
		local ibanToSave = playerIbansCache[player.UserId]
		local success, err = pcall(function()
			ibanDataStore:SetAsync(userIdStr, ibanToSave)
		end)
		if not success then
			warn("IbanManager: " .. player.Name .. " ayrılırken IBAN ("..ibanToSave..") kaydedilemedi: " .. err)
		else
			print("IbanManager: " .. player.Name .. " ayrılırken IBAN ("..ibanToSave..") DataStore'a kaydedildi.")
		end
	end
end

return IbanManager
