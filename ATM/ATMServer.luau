local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local ATMEvent = ReplicatedStorage:FindFirstChild("ATMEvent")
if not ATMEvent then
	ATMEvent = Instance.new("RemoteEvent")
	ATMEvent.Name = "ATMEvent"
	ATMEvent.Parent = ReplicatedStorage
	print("ATMServer: ATMEvent oluşturuldu.")
end

-- DataStore'lar
local balanceDataStore = DataStoreService:GetDataStore("PlayerBalancesV2")
local ibanDataStore = DataStoreService:GetDataStore("PlayerIbansV2")
local transactionHistoryDataStore = DataStoreService:GetDataStore("PlayerTransactionHistoryV2")

local balances = {} -- Oyuncu bakiyelerini saklamak için (önbellek)
local ATM_Machine_Part = workspace:WaitForChild("ATM_Machine_Part", 60) -- ATM makine parçası
local playersCurrentlyUsingAtm = {} -- Oyuncuların ATM kullanım durumunu saklamak için
local playerIbans = {} -- Oyuncuların IBAN'larını saklamak için (önbellek)
local playerTransactionHistories = {} -- Oyuncuların işlem geçmişlerini saklamak için (önbellek)

local function getBalance(player)
	return balances[player.UserId] or 0
end

local function setBalance(player, newBalance)
	balances[player.UserId] = newBalance
	local success, err = pcall(function()
		balanceDataStore:SetAsync(tostring(player.UserId), newBalance)
	end)
	if not success then
		warn("ATMServer: Bakiye DataStore'a kaydedilemedi! Oyuncu: " .. player.Name .. " Hata: " .. err)
	end
end

local function addTransactionToHistory(playerId, type, amount, description)
	if not playerTransactionHistories[playerId] then
		playerTransactionHistories[playerId] = {}
	end
	local entry = {
		type = type,
		amount = amount,
		description = description,
		date = os.date("%Y-%m-%d %H:%M:%S")
	}
	table.insert(playerTransactionHistories[playerId], 1, entry)
	while #playerTransactionHistories[playerId] > 20 do
		table.remove(playerTransactionHistories[playerId])
	end
	
	local success, err = pcall(function()
		transactionHistoryDataStore:SetAsync(tostring(playerId), playerTransactionHistories[playerId])
	end)
	if not success then
		warn("ATMServer: İşlem geçmişi DataStore'a kaydedilemedi! Oyuncu ID: " .. playerId .. " Hata: " .. err)
	end
end


local function generateAndStoreIban(player)
	if playerIbans[player.UserId] then
		return playerIbans[player.UserId]
	end
	
	local newIban
	local success, storedIban = pcall(function()
		return ibanDataStore:GetAsync(tostring(player.UserId))
	end)

	if success and storedIban then
		newIban = storedIban
	else
		if not success then warn("ATMServer: IBAN DataStore'dan okunamadı! Oyuncu: " .. player.Name .. " Hata: " .. storedIban) end
		newIban = string.format("TR%05d", math.random(0,99999)) -- TODO: IBAN çakışma kontrolü eklenebilir
		local setSuccess, setErr = pcall(function()
			ibanDataStore:SetAsync(tostring(player.UserId), newIban)
		end)
		if not setSuccess then
			warn("ATMServer: Yeni IBAN DataStore'a kaydedilemedi! Oyuncu: " .. player.Name .. " Hata: " .. setErr)
		end
	end
	playerIbans[player.UserId] = newIban
	print("ATMServer: " .. player.Name .. " için IBAN: " .. newIban .. (success and storedIban and " (DataStore'dan yüklendi)" or " (Yeni oluşturuldu/kaydedildi)"))
	return newIban
end

local function sendFeedback(player, message, success)
	ATMEvent:FireClient(player, {action = "feedback", message = message, success = success})
end

ATMEvent.OnServerEvent:Connect(function(player, eventName, ...)
	local args = {...}

	if eventName == "withdraw" then
		local amount = args[1]
		if type(amount) ~= "number" or amount <= 0 then
			sendFeedback(player, "Geçersiz miktar.", false)
			return
		end
		local currentBalance = getBalance(player)
		if currentBalance >= amount then
			setBalance(player, currentBalance - amount) -- setBalance artık DataStore'a da yazıyor
			addTransactionToHistory(player.UserId, "withdraw", amount, "ATM Para Çekme") -- Bu da DataStore'a yazıyor
			sendFeedback(player, string.format("%.2f TL çekildi. Yeni bakiye: %.2f TL", amount, getBalance(player)), true)
			ATMEvent:FireClient(player, {
				action = "balanceUpdate", 
				balance = getBalance(player),
				iban = playerIbans[player.UserId],
				history = playerTransactionHistories[player.UserId]
			})
		else
			sendFeedback(player, "Yetersiz bakiye.", false)
		end
	elseif eventName == "deposit" then
		local amount = args[1]
		if type(amount) ~= "number" or amount <= 0 then
			sendFeedback(player, "Geçersiz miktar.", false)
			return
		end
		local currentBalance = getBalance(player)
		setBalance(player, currentBalance + amount) -- setBalance artık DataStore'a da yazıyor
		addTransactionToHistory(player.UserId, "deposit", amount, "ATM Para Yatırma") -- Bu da DataStore'a yazıyor
		sendFeedback(player, string.format("%.2f TL yatırıldı. Yeni bakiye: %.2f TL", amount, getBalance(player)), true)
		ATMEvent:FireClient(player, {
			action = "balanceUpdate", 
			balance = getBalance(player),
			iban = playerIbans[player.UserId],
			history = playerTransactionHistories[player.UserId]
		})
	elseif eventName == "getBalance" then
		local currentBalance = getBalance(player) -- Önbellekten okur
		local currentPlayerIban = playerIbans[player.UserId] -- Önbellekten okur (PlayerAdded'da yüklenmiş olmalı)
		local currentHistory = playerTransactionHistories[player.UserId] -- Önbellekten okur
		
		ATMEvent:FireClient(player, {
			action = "balanceUpdate", 
			balance = currentBalance,
			iban = currentPlayerIban,
			history = currentHistory
		})
	elseif eventName == "card_inserted_ack" then
		print(player.Name .. " kartını taktı, ATM arayüzü ve bilgiler gönderiliyor.")
		local currentBalance = getBalance(player)
		local currentPlayerIban = playerIbans[player.UserId] 
		local currentHistory = playerTransactionHistories[player.UserId]
		
		ATMEvent:FireClient(player, {
			action = "showAtmUIDetails", 
			balance = currentBalance, 
			iban = currentPlayerIban,
			history = currentHistory
		})
	elseif eventName == "atm_set_busy_status" then 
		local isBusy = args[1]
		playersCurrentlyUsingAtm[player.UserId] = isBusy
		print("ATMServer: " .. player.Name .. " ATM kullanım durumu: " .. (isBusy and "Meşgul" or "Müsait"))
	elseif eventName == "transferToIban" then
		local targetIban = args[1]
		local amount = args[2]
		-- TODO: IBAN'a göre oyuncu bulma, bakiye kontrolü, transfer işlemi, DataStore güncellemesi
		print(string.format("ATMServer: %s, %s IBAN'ına %.2f TL transfer etmeye çalışıyor.", player.Name, targetIban, amount))
		sendFeedback(player, "IBAN ile transfer özelliği yapım aşamasındadır.", false)
		-- Başarılı olursa geçmişe ekle ve bakiye güncellemesi gönder
	elseif eventName == "transferToUsername" then
		local targetUsername = args[1]
		local amount = args[2]
		-- TODO: Kullanıcı adına göre oyuncu bulma (offline dahil), bakiye kontrolü, transfer, DataStore
		print(string.format("ATMServer: %s, %s kullanıcısına %.2f TL transfer etmeye çalışıyor.", player.Name, targetUsername, amount))
		sendFeedback(player, "Kullanıcı adına transfer özelliği yapım aşamasındadır.", false)
		-- Başarılı olursa geçmişe ekle ve bakiye güncellemesi gönder
	else
		warn("Bilinmeyen ATM olayı: " .. eventName)
	end
end)

Players.PlayerAdded:Connect(function(player)
	local userIdStr = tostring(player.UserId)

	-- Bakiye yükle
	local balanceSuccess, balanceResult = pcall(function()
		return balanceDataStore:GetAsync(userIdStr)
	end)
	if balanceSuccess then
		if balanceResult ~= nil then
			balances[player.UserId] = balanceResult
			print("ATMServer: " .. player.Name .. " katıldı, DataStore'dan bakiye yüklendi: " .. balanceResult)
		else
			balances[player.UserId] = 1000 -- Varsayılan başlangıç bakiyesi
			print("ATMServer: " .. player.Name .. " katıldı, DataStore'da bakiye yok, başlangıç bakiyesi ayarlandı: 1000")
			pcall(function() balanceDataStore:SetAsync(userIdStr, balances[player.UserId]) end) -- Yeni bakiyeyi kaydet
		end
	else
		warn("ATMServer: " .. player.Name .. " için bakiye DataStore'dan okunamadı! Hata: " .. balanceResult .. ". Varsayılan bakiye (1000) kullanılıyor.")
		balances[player.UserId] = 1000 
	end

	-- IBAN yükle veya oluştur
	generateAndStoreIban(player) -- Bu fonksiyon zaten DataStore'u kontrol ediyor ve gerekirse oluşturup kaydediyor.

	-- İşlem geçmişi yükle
	local historySuccess, historyResult = pcall(function()
		return transactionHistoryDataStore:GetAsync(userIdStr)
	end)
	if historySuccess then
		if historyResult then
			playerTransactionHistories[player.UserId] = historyResult
			print("ATMServer: " .. player.Name .. " için işlem geçmişi DataStore'dan yüklendi.")
		else
			playerTransactionHistories[player.UserId] = {}
			addTransactionToHistory(player.UserId, "system", balances[player.UserId], "Hesap Oluşturuldu") -- Bu DataStore'a da yazar
			print("ATMServer: " .. player.Name .. " için DataStore'da işlem geçmişi yok, yeni oluşturuldu.")
		end
	else
		warn("ATMServer: " .. player.Name .. " için işlem geçmişi DataStore'dan okunamadı! Hata: " .. historyResult .. ". Boş geçmiş kullanılıyor.")
		playerTransactionHistories[player.UserId] = {}
		addTransactionToHistory(player.UserId, "system", balances[player.UserId], "Hesap Oluşturuldu")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local userIdStr = tostring(player.UserId)
	-- Oyuncu ayrılırken verileri DataStore'a kaydet (setBalance, addTransactionToHistory, generateAndStoreIban zaten anlık kaydediyor)
	-- Ancak yine de son bir kontrol ve kaydetme yapmak iyi bir pratik olabilir, özellikle önbellek ve DataStore arasında tutarsızlık riski varsa.
	-- Mevcut yapıda anlık kayıt olduğu için burası büyük ölçüde yedekleme/garanti amaçlıdır.
	
	if balances[player.UserId] ~= nil then
		local success, err = pcall(function()
			balanceDataStore:SetAsync(userIdStr, balances[player.UserId])
		end)
		if not success then warn("ATMServer: " .. player.Name .. " ayrılırken bakiye kaydedilemedi: " .. err) end
	end

	if playerIbans[player.UserId] ~= nil then
		local success, err = pcall(function()
			ibanDataStore:SetAsync(userIdStr, playerIbans[player.UserId])
		end)
		if not success then warn("ATMServer: " .. player.Name .. " ayrılırken IBAN kaydedilemedi: " .. err) end
	end

	if playerTransactionHistories[player.UserId] ~= nil then
		local success, err = pcall(function()
			transactionHistoryDataStore:SetAsync(userIdStr, playerTransactionHistories[player.UserId])
		end)
		if not success then warn("ATMServer: " .. player.Name .. " ayrılırken işlem geçmişi kaydedilemedi: " .. err) end
	end

	-- Önbellekten temizle
	balances[player.UserId] = nil
	playerIbans[player.UserId] = nil
	playerTransactionHistories[player.UserId] = nil
	playersCurrentlyUsingAtm[player.UserId] = nil 
	print("ATMServer: " .. player.Name .. " ayrıldı, veriler DataStore'a kaydedildi ve önbellek temizlendi.")
end)

if ATM_Machine_Part then
	local proximityPrompt = ATM_Machine_Part:FindFirstChildOfClass("ProximityPrompt")
	if not proximityPrompt then
		print("ATMServer: ATM_Machine_Part içinde ProximityPrompt bulunamadı, yeni bir tane oluşturuluyor.")
		proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.ActionText = "ATM Kullan"
		proximityPrompt.ObjectText = "Vio Bank ATM"
		proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
		proximityPrompt.RequiresLineOfSight = false
		proximityPrompt.MaxActivationDistance = 10
		proximityPrompt.Parent = ATM_Machine_Part
	end

	proximityPrompt.Triggered:Connect(function(player)
		if playersCurrentlyUsingAtm[player.UserId] then
			print("ATMServer: " .. player.Name .. " zaten bir ATM kullanıyor, yeni etkileşim engellendi.")
			-- İsteğe bağlı: Oyuncuya zaten meşgul olduğuna dair bir geri bildirim gönderilebilir.
			ATMEvent:FireClient(player, {action = "feedback", message = "Zaten bir ATM işlemi yapıyorsunuz.", success = false})
			return
		end

		if not balances[player.UserId] then
			balances[player.UserId] = 1000 -- Varsayılan başlangıç bakiyesi
		end
		print(player.Name .. " ATM'yi kullanmaya çalışıyor (kart takma adımı): " .. ATM_Machine_Part.Name)
		ATMEvent:FireClient(player, {action = "requestCardInsertion"})
	end)
else
	warn("ATM_Machine_Part bulunamadı! ATM işlevselliği çalışmayacak.")
end

print("ATMServer.luau çalıştı.")
