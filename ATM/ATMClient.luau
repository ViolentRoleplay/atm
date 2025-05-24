local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ATMEvent = ReplicatedStorage:WaitForChild("ATMEvent")

local screenGui = script.Parent
local atmFrame = screenGui:FindFirstChild("AtmFrame")
local cardInsertionFrame -- Yeni kart takma arayüzü için değişken
local amountInputFrame -- Miktar girişi için yeni frame
local currentTransactionType = nil -- "withdraw" veya "deposit"
local isUiOverallVisibleState = false -- Tracks if any ATM UI is globally visible for this client

if atmFrame then
	atmFrame:Destroy() -- Önceki arayüzü temizle
end

local function checkAndNotifyServerUiStatus()
	local anyUiVisible = (cardInsertionFrame and cardInsertionFrame.Visible) or
	                     (atmFrame and atmFrame.Visible) or
	                     (amountInputFrame and amountInputFrame.Visible)

	if isUiOverallVisibleState == anyUiVisible then return end -- No change in overall state
	isUiOverallVisibleState = anyUiVisible
	ATMEvent:FireServer("atm_set_busy_status", isUiOverallVisibleState)
	-- print("Client UI Busy Status Sent to Server:", isUiOverallVisibleState) -- Debug
end


-- Miktar Giriş Arayüzü Oluşturma
local function createAmountInputUI()
	if amountInputFrame and amountInputFrame.Parent then
		amountInputFrame:Destroy()
	end

	amountInputFrame = Instance.new("Frame", screenGui)
	amountInputFrame.Name = "AmountInputFrame"
	amountInputFrame.Size = UDim2.new(0.4, 0, 0.35, 0) -- Boyutunu ayarlayalım
	amountInputFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	amountInputFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	amountInputFrame.BackgroundColor3 = Color3.fromRGB(60, 70, 80) -- Biraz farklı bir renk
	amountInputFrame.BorderSizePixel = 0
	amountInputFrame.Visible = false
	local amountCorner = Instance.new("UICorner", amountInputFrame)
	amountCorner.CornerRadius = UDim.new(0, 10)

	local amountTitle = Instance.new("TextLabel", amountInputFrame)
	amountTitle.Name = "AmountTitle"
	amountTitle.Size = UDim2.new(1, 0, 0.2, 0)
	amountTitle.Position = UDim2.new(0.5, 0, 0.1, 0)
	amountTitle.AnchorPoint = Vector2.new(0.5, 0)
	amountTitle.Font = Enum.Font.GothamSemibold
	amountTitle.Text = "Miktar Giriniz" -- Bu dinamik olarak değişecek
	amountTitle.TextColor3 = Color3.fromRGB(220, 220, 230)
	amountTitle.TextSize = 20
	amountTitle.BackgroundTransparency = 1

	local amountTextBox = Instance.new("TextBox", amountInputFrame)
	amountTextBox.Name = "AmountTextBox"
	amountTextBox.Size = UDim2.new(0.8, 0, 0.2, 0)
	amountTextBox.Position = UDim2.new(0.5, 0, 0.4, 0)
	amountTextBox.AnchorPoint = Vector2.new(0.5, 0)
	amountTextBox.Font = Enum.Font.Gotham
	amountTextBox.PlaceholderText = "0.00"
	amountTextBox.Text = ""
	amountTextBox.TextColor3 = Color3.fromRGB(50,50,50)
	amountTextBox.BackgroundColor3 = Color3.fromRGB(230,230,230)
	amountTextBox.TextSize = 18
	amountTextBox.ClearTextOnFocus = false
	local tbCorner = Instance.new("UICorner", amountTextBox)
	tbCorner.CornerRadius = UDim.new(0, 6)

	local confirmButton = Instance.new("TextButton", amountInputFrame)
	confirmButton.Name = "ConfirmAmountButton"
	confirmButton.Size = UDim2.new(0.4, 0, 0.2, 0)
	confirmButton.Position = UDim2.new(0.28, 0, 0.75, 0) -- Sol tarafa
	confirmButton.AnchorPoint = Vector2.new(0.5, 0.5)
	confirmButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Yeşil
	confirmButton.Font = Enum.Font.GothamSemibold
	confirmButton.Text = "Onayla"
	confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmButton.TextSize = 16
	local cfmBtnCorner = Instance.new("UICorner", confirmButton)
	cfmBtnCorner.CornerRadius = UDim.new(0, 8)

	local cancelAmountButton = Instance.new("TextButton", amountInputFrame)
	cancelAmountButton.Name = "CancelAmountButton"
	cancelAmountButton.Size = UDim2.new(0.4, 0, 0.2, 0)
	cancelAmountButton.Position = UDim2.new(0.72, 0, 0.75, 0) -- Sağ tarafa
	cancelAmountButton.AnchorPoint = Vector2.new(0.5, 0.5)
	cancelAmountButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Kırmızı
	cancelAmountButton.Font = Enum.Font.GothamSemibold
	cancelAmountButton.Text = "İptal"
	cancelAmountButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelAmountButton.TextSize = 16
	local cnlBtnCorner = Instance.new("UICorner", cancelAmountButton)
	cnlBtnCorner.CornerRadius = UDim.new(0, 8)

	confirmButton.MouseButton1Click:Connect(function()
		local amount = tonumber(amountTextBox.Text)
		if amount and amount > 0 and currentTransactionType then
			amountInputFrame.Visible = false
			checkAndNotifyServerUiStatus() -- UI visibility changed
			amountTextBox.Text = "" -- TextBox'ı temizle
			
			local processingFeedback = Instance.new("TextLabel", screenGui)
			processingFeedback.Name = "ProcessingFeedbackLabel"
			processingFeedback.Size = UDim2.new(0.3,0,0.1,0)
			processingFeedback.Position = UDim2.new(0.5,0,0.5,0)
			processingFeedback.AnchorPoint = Vector2.new(0.5,0.5)
			processingFeedback.Font = Enum.Font.Gotham
			processingFeedback.Text = "İşleminiz yapılıyor..."
			processingFeedback.TextSize = 18
			processingFeedback.TextColor3 = Color3.fromRGB(220,220,220)
			processingFeedback.BackgroundTransparency = 0.3
			processingFeedback.BackgroundColor3 = Color3.fromRGB(40,40,40)
			local procCorner = Instance.new("UICorner", processingFeedback)
			procCorner.CornerRadius = UDim.new(0,6)
			processingFeedback.Visible = true

			ATMEvent:FireServer(currentTransactionType, amount)
			
			-- Geri bildirim geldikten sonra bu label kaldırılacak (feedback event'inde)
			-- Şimdilik, belirli bir süre sonra kaldıralım veya feedback'e bırakalım.
			-- task.delay(2, function() if processingFeedback and processingFeedback.Parent then processingFeedback:Destroy() end end)
		else
			amountTextBox.Text = ""
			amountTextBox.PlaceholderText = "Geçerli miktar girin!"
			task.wait(1.5)
			amountTextBox.PlaceholderText = "0.00"
		end
	end)

	cancelAmountButton.MouseButton1Click:Connect(function()
		amountInputFrame.Visible = false
		checkAndNotifyServerUiStatus() -- UI visibility changed
		amountTextBox.Text = ""
		if atmFrame then 
			atmFrame.Visible = true 
			checkAndNotifyServerUiStatus() -- UI visibility changed
		end 
		currentTransactionType = nil
	end)
end
createAmountInputUI() -- Miktar giriş UI'ını oluştur ama gizli tut

-- Kart Takma Arayüzü Oluşturma
local function createCardInsertionUI()
	if cardInsertionFrame and cardInsertionFrame.Parent then
		cardInsertionFrame:Destroy()
	end

	cardInsertionFrame = Instance.new("Frame", screenGui)
	cardInsertionFrame.Name = "CardInsertionFrame"
	cardInsertionFrame.Size = UDim2.new(0.3, 0, 0.25, 0)
	cardInsertionFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	cardInsertionFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	cardInsertionFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	cardInsertionFrame.BorderSizePixel = 0
	cardInsertionFrame.Visible = false
	local cardCorner = Instance.new("UICorner", cardInsertionFrame)
	cardCorner.CornerRadius = UDim.new(0, 10)

	local cardTitle = Instance.new("TextLabel", cardInsertionFrame)
	cardTitle.Name = "CardTitle"
	cardTitle.Size = UDim2.new(1, 0, 0.2, 0)
	cardTitle.Position = UDim2.new(0.5, 0, 0.1, 0)
	cardTitle.AnchorPoint = Vector2.new(0.5, 0)
	cardTitle.Font = Enum.Font.GothamSemibold
	cardTitle.Text = "VIO BANK"
	cardTitle.TextColor3 = Color3.fromRGB(200, 200, 220)
	cardTitle.TextSize = 20
	cardTitle.BackgroundTransparency = 1

	local instructionLabel = Instance.new("TextLabel", cardInsertionFrame)
	instructionLabel.Name = "InstructionLabel"
	instructionLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
	instructionLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
	instructionLabel.AnchorPoint = Vector2.new(0.5, 0)
	instructionLabel.Font = Enum.Font.Gotham
	instructionLabel.Text = "Lütfen kartınızı ATM'ye takınız."
	instructionLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	instructionLabel.TextSize = 16
	instructionLabel.TextWrapped = true
	instructionLabel.BackgroundTransparency = 1

	local insertCardButton = Instance.new("TextButton", cardInsertionFrame)
	insertCardButton.Name = "InsertCardButton"
	insertCardButton.Size = UDim2.new(0.6, 0, 0.2, 0)
	insertCardButton.Position = UDim2.new(0.5, 0, 0.75, 0)
	insertCardButton.AnchorPoint = Vector2.new(0.5, 0.5)
	insertCardButton.BackgroundColor3 = Color3.fromRGB(102, 187, 106) -- Yeşil
	insertCardButton.Font = Enum.Font.GothamSemibold
	insertCardButton.Text = "Kartı Tak"
	insertCardButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	insertCardButton.TextSize = 16
	local insButtonCorner = Instance.new("UICorner", insertCardButton)
	insButtonCorner.CornerRadius = UDim.new(0, 8)

	insertCardButton.MouseButton1Click:Connect(function()
		cardInsertionFrame.Visible = false
		checkAndNotifyServerUiStatus() -- UI visibility changed
		-- Kullanıcıya geri bildirim
		local tempFeedback = Instance.new("TextLabel", screenGui)
		tempFeedback.Name = "TempFeedbackLabel"
		tempFeedback.Size = UDim2.new(0.2,0,0.05,0)
		tempFeedback.Position = UDim2.new(0.5,0,0.4,0)
		tempFeedback.AnchorPoint = Vector2.new(0.5,0.5)
		tempFeedback.Font = Enum.Font.Gotham
		tempFeedback.Text = "Kart okunuyor..."
		tempFeedback.TextSize = 18
		tempFeedback.TextColor3 = Color3.fromRGB(220,220,220)
		tempFeedback.BackgroundTransparency = 0.5
		tempFeedback.BackgroundColor3 = Color3.fromRGB(40,40,40)
		local tempCorner = Instance.new("UICorner", tempFeedback)
		tempCorner.CornerRadius = UDim.new(0,6)
		tempFeedback.Visible = true
		
		task.delay(1.5, function() -- Kart okuma simülasyonu
			if tempFeedback and tempFeedback.Parent then
				tempFeedback:Destroy()
			end
			-- Gecikme tamamlandıktan SONRA sunucuya onay gönder
			ATMEvent:FireServer("card_inserted_ack") 
		end)
	end)
end
createCardInsertionUI() -- Script başladığında UI'ı oluştur ama gizli tut

-- Yeni ATM Arayüzü Oluşturma
atmFrame = Instance.new("Frame", screenGui)
atmFrame.Name = "AtmFrame"
atmFrame.Size = UDim2.new(0.6, 0, 0.75, 0) -- Boyutu biraz daha geniş ve yüksek yapalım
atmFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
atmFrame.AnchorPoint = Vector2.new(0.5, 0.5)
atmFrame.BackgroundColor3 = Color3.fromRGB(102, 187, 106) -- Garanti yeşili (yaklaşık)
atmFrame.BorderSizePixel = 0
atmFrame.Visible = false

local corner = Instance.new("UICorner", atmFrame)
corner.CornerRadius = UDim.new(0, 12)

-- Üst Kısım (Logo, Slogan, İptal Butonu)
local headerFrame = Instance.new("Frame", atmFrame)
headerFrame.Name = "HeaderFrame"
headerFrame.Size = UDim2.new(1, 0, 0.12, 0)
headerFrame.BackgroundColor3 = Color3.fromRGB(85, 166, 90) -- Biraz daha koyu yeşil
headerFrame.BorderSizePixel = 0

local logoLabel = Instance.new("TextLabel", headerFrame)
logoLabel.Name = "LogoLabel"
logoLabel.Size = UDim2.new(0.2, 0, 0.8, 0)
logoLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
logoLabel.AnchorPoint = Vector2.new(0, 0.5)
logoLabel.Font = Enum.Font.GothamSemibold -- Veya benzeri
logoLabel.Text = "Garanti" -- Logo yerine metin
logoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
logoLabel.TextSize = 24
logoLabel.BackgroundTransparency = 1
logoLabel.TextXAlignment = Enum.TextXAlignment.Left

local sloganLabel = Instance.new("TextLabel", headerFrame)
sloganLabel.Name = "SloganLabel"
sloganLabel.Size = UDim2.new(0.5, 0, 0.8, 0)
sloganLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
sloganLabel.AnchorPoint = Vector2.new(0.5, 0.5)
sloganLabel.Font = Enum.Font.Gotham -- Veya benzeri
sloganLabel.Text = "Lütfen seçiminizi yapın"
sloganLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
sloganLabel.TextSize = 18
sloganLabel.BackgroundTransparency = 1

local iptalButton = Instance.new("TextButton", headerFrame)
iptalButton.Name = "IptalButton"
iptalButton.Size = UDim2.new(0.15, 0, 0.6, 0)
iptalButton.Position = UDim2.new(0.95, 0, 0.5, 0)
iptalButton.AnchorPoint = Vector2.new(1, 0.5)
iptalButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Kırmızımsı
iptalButton.Font = Enum.Font.GothamSemibold
iptalButton.Text = "İPTAL"
iptalButton.TextColor3 = Color3.fromRGB(255, 255, 255)
iptalButton.TextSize = 16
local iptalCorner = Instance.new("UICorner", iptalButton)
iptalCorner.CornerRadius = UDim.new(0, 6)

-- İçerik Alanı
local contentFrame = Instance.new("Frame", atmFrame)
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 0.88, 0) -- Kalan alanı kapla
contentFrame.Position = UDim2.new(0, 0, 0.12, 0) -- Header'ın altına
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0

-- Sol Panel (Hesap Bilgileri)
local leftPanel = Instance.new("Frame", contentFrame)
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0.45, -10, 1, -20) -- Genişlik ve padding
leftPanel.Position = UDim2.new(0, 10, 0, 10) -- Sol üst ve padding
leftPanel.BackgroundTransparency = 1

local accountInfoFrame = Instance.new("Frame", leftPanel)
accountInfoFrame.Name = "AccountInfoFrame"
accountInfoFrame.Size = UDim2.new(1, 0, 0.8, 0) -- Yükseklik
accountInfoFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240) -- Açık gri
accountInfoFrame.BorderSizePixel = 1
accountInfoFrame.BorderColor3 = Color3.fromRGB(220,220,220)
local accInfoCorner = Instance.new("UICorner", accountInfoFrame)
accInfoCorner.CornerRadius = UDim.new(0, 8)
-- TODO: Dashed border için özel bir çözüm gerekebilir (örn: ImageLabel ile)

local accountInfoLayout = Instance.new("UIListLayout", accountInfoFrame)
accountInfoLayout.Padding = UDim.new(0, 5)
accountInfoLayout.SortOrder = Enum.SortOrder.LayoutOrder
accountInfoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local accountNameLabel = Instance.new("TextLabel", accountInfoFrame)
accountNameLabel.Name = "AccountNameLabel"
accountNameLabel.Size = UDim2.new(0.9, 0, 0, 25)
accountNameLabel.Font = Enum.Font.GothamBold
accountNameLabel.Text = "XXXX-XXXXXXX İSİM SOYİSİM" -- Sunucudan alınacak
accountNameLabel.TextColor3 = Color3.fromRGB(50,50,50)
accountNameLabel.TextSize = 16
accountNameLabel.BackgroundTransparency = 1
accountNameLabel.LayoutOrder = 1
accountNameLabel.TextXAlignment = Enum.TextXAlignment.Left
accountNameLabel.ClipsDescendants = true

local ibanLabel = Instance.new("TextLabel", accountInfoFrame)
ibanLabel.Name = "IbanLabel"
ibanLabel.Size = UDim2.new(0.9, 0, 0, 20)
ibanLabel.Font = Enum.Font.Gotham
ibanLabel.Text = "TRXX XXXX XXXX XXXX XXXX XXXX XX" -- Sunucudan alınacak
ibanLabel.TextColor3 = Color3.fromRGB(100,100,100)
ibanLabel.TextSize = 12
ibanLabel.BackgroundTransparency = 1
ibanLabel.LayoutOrder = 2
ibanLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Kullanılabilir Bakiye (Önemli)
local balanceFrame = Instance.new("Frame", accountInfoFrame)
balanceFrame.Name = "BalanceFrame"
balanceFrame.Size = UDim2.new(0.9,0,0,35)
balanceFrame.BackgroundTransparency = 1
balanceFrame.LayoutOrder = 3

local balanceTitleLabel = Instance.new("TextLabel", balanceFrame)
balanceTitleLabel.Name = "BalanceTitleLabel"
balanceTitleLabel.Size = UDim2.new(0.5,0,1,0)
balanceTitleLabel.Position = UDim2.new(0,0,0,0)
balanceTitleLabel.Font = Enum.Font.GothamMedium
balanceTitleLabel.Text = "Kullanılabilir Bakiye"
balanceTitleLabel.TextColor3 = Color3.fromRGB(80,80,80)
balanceTitleLabel.TextSize = 14
balanceTitleLabel.BackgroundTransparency = 1
balanceTitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local balanceValueLabel = Instance.new("TextLabel", balanceFrame) -- Bu bizim eski balanceLabel'ımız olacak
balanceValueLabel.Name = "BalanceValueLabel"
balanceValueLabel.Size = UDim2.new(0.45,0,0.8,0)
balanceValueLabel.Position = UDim2.new(1,0,0.5,0)
balanceValueLabel.AnchorPoint = Vector2.new(1,0.5)
balanceValueLabel.BackgroundColor3 = Color3.fromRGB(255, 226, 107) -- Sarı
balanceValueLabel.Font = Enum.Font.GothamBold
balanceValueLabel.Text = "0,00 TL"
balanceValueLabel.TextColor3 = Color3.fromRGB(50,50,50)
balanceValueLabel.TextSize = 14
local balValCorner = Instance.new("UICorner", balanceValueLabel)
balValCorner.CornerRadius = UDim.new(0,4)



-- İşlem Geçmişi Alanı
local transactionHistoryFrame = Instance.new("ScrollingFrame", accountInfoFrame)
transactionHistoryFrame.Name = "TransactionHistoryFrame"
transactionHistoryFrame.Size = UDim2.new(0.9, 0, 0.5, 0) -- Boyutunu ayarla, kalan alanı kaplayabilir
transactionHistoryFrame.Position = UDim2.new(0.5, 0, 0, 0) -- accountInfoLayout yönetecek
transactionHistoryFrame.AnchorPoint = Vector2.new(0.5, 0)
transactionHistoryFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
transactionHistoryFrame.BorderSizePixel = 1
transactionHistoryFrame.BorderColor3 = Color3.fromRGB(210,210,210)
transactionHistoryFrame.CanvasSize = UDim2.new(0,0,0,0) -- İçeriğe göre otomatik
transactionHistoryFrame.ScrollBarThickness = 6
transactionHistoryFrame.LayoutOrder = 4

local historyLayout = Instance.new("UIListLayout", transactionHistoryFrame)
historyLayout.Padding = UDim.new(0, 3)
historyLayout.SortOrder = Enum.SortOrder.LayoutOrder
historyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local noHistoryLabel = Instance.new("TextLabel", transactionHistoryFrame)
noHistoryLabel.Name = "NoHistoryLabel"
noHistoryLabel.Size = UDim2.new(1, -10, 0, 30)
noHistoryLabel.Text = "İşlem geçmişi bulunmamaktadır."
noHistoryLabel.Font = Enum.Font.Gotham
noHistoryLabel.TextSize = 12
noHistoryLabel.TextColor3 = Color3.fromRGB(120,120,120)
noHistoryLabel.BackgroundTransparency = 1
noHistoryLabel.TextWrapped = true
noHistoryLabel.LayoutOrder = 1

-- accountInfoFrame boyutunu ve digerHesaplarButton konumunu ayarla
accountInfoFrame.Size = UDim2.new(1, 0, 0.8, 0) -- Yüksekliği sabit tutabilir veya dinamik yapabiliriz. Şimdilik sabit.
-- DigerHesaplarButton'un LayoutOrder'ını güncellemek gerekebilir veya pozisyonunu.
-- UIListLayout içinde olduğu için LayoutOrder ile yönetilmesi daha iyi.
-- accountInfoLayout.Padding'i kontrol et, elemanlar arası boşluk için.

local digerHesaplarButton = Instance.new("TextButton", leftPanel)
digerHesaplarButton.Name = "DigerHesaplarButton"
digerHesaplarButton.Size = UDim2.new(1, 0, 0.15, 0)
digerHesaplarButton.Position = UDim2.new(0, 0, 1, 0) -- Sol panelin altına
digerHesaplarButton.AnchorPoint = Vector2.new(0, 1)
digerHesaplarButton.BackgroundColor3 = Color3.fromRGB(220,220,220)
digerHesaplarButton.Font = Enum.Font.GothamMedium
digerHesaplarButton.Text = "<  Diğer Hesaplar"
digerHesaplarButton.TextColor3 = Color3.fromRGB(80,80,80)
digerHesaplarButton.TextSize = 16
local digerCorner = Instance.new("UICorner", digerHesaplarButton)
digerCorner.CornerRadius = UDim.new(0, 6)

-- Sağ Panel (İşlem Butonları)
local rightPanel = Instance.new("Frame", contentFrame)
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(0.5, -10, 1, -20) -- Genişlik ve padding
rightPanel.Position = UDim2.new(1, -10, 0, 10) -- Sağ üst ve padding
rightPanel.AnchorPoint = Vector2.new(1,0)
rightPanel.BackgroundTransparency = 1

local actionButtonLayout = Instance.new("UIListLayout", rightPanel)
actionButtonLayout.Padding = UDim.new(0, 15)
actionButtonLayout.FillDirection = Enum.FillDirection.Vertical
actionButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionButtonLayout.VerticalAlignment = Enum.VerticalAlignment.Center

-- Transfer Menüsü Frame'i (contentFrame içinde, leftPanel ve rightPanel'e kardeş)
local transferMenuFrame = Instance.new("Frame", contentFrame)
transferMenuFrame.Name = "TransferMenuFrame"
transferMenuFrame.Size = UDim2.new(1, -20, 1, -20) -- contentFrame'i padding ile kapla
transferMenuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
transferMenuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
transferMenuFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245) -- Ana ATM'den biraz farklı
transferMenuFrame.BorderSizePixel = 0
transferMenuFrame.Visible = false
local tmCorner = Instance.new("UICorner", transferMenuFrame)
tmCorner.CornerRadius = UDim.new(0,8)

local tmContainerPadding = Instance.new("UIPadding", transferMenuFrame)
tmContainerPadding.PaddingTop = UDim.new(0, 20) -- Apply 20px padding at the top of the frame.
tmContainerPadding.PaddingLeft = UDim.new(0, 10) 
tmContainerPadding.PaddingRight = UDim.new(0, 10)
tmContainerPadding.PaddingBottom = UDim.new(0, 10)


local tmLayout = Instance.new("UIListLayout", transferMenuFrame)
tmLayout.Padding = UDim.new(0,10) -- This is for spacing BETWEEN items
tmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tmLayout.SortOrder = Enum.SortOrder.LayoutOrder

local tmTitle = Instance.new("TextLabel", transferMenuFrame)
tmTitle.Name = "TransferMenuTitle"
tmTitle.Size = UDim2.new(0.9,0,0,30)
tmTitle.Text = "Para Transferi"
tmTitle.Font = Enum.Font.GothamBold
tmTitle.TextSize = 20
tmTitle.TextColor3 = Color3.fromRGB(60,60,60)
tmTitle.BackgroundTransparency = 1
tmTitle.LayoutOrder = 1

-- Alıcı IBAN Girişi
local ibanInputLabel = Instance.new("TextLabel", transferMenuFrame)
ibanInputLabel.Name = "IbanInputLabel"
ibanInputLabel.Size = UDim2.new(0.8,0,0,20)
ibanInputLabel.Text = "Alıcı IBAN:"
ibanInputLabel.Font = Enum.Font.GothamMedium
ibanInputLabel.TextSize = 14
ibanInputLabel.TextColor3 = Color3.fromRGB(80,80,80)
ibanInputLabel.BackgroundTransparency = 1
ibanInputLabel.TextXAlignment = Enum.TextXAlignment.Left
ibanInputLabel.LayoutOrder = 2

local ibanTextBox = Instance.new("TextBox", transferMenuFrame)
ibanTextBox.Name = "IbanTextBox"
ibanTextBox.Size = UDim2.new(0.8,0,0,35)
ibanTextBox.PlaceholderText = "TRXXXXX"
ibanTextBox.Font = Enum.Font.Gotham
ibanTextBox.TextSize = 14
ibanTextBox.BackgroundColor3 = Color3.fromRGB(255,255,255)
ibanTextBox.LayoutOrder = 3
local ibanTbCorner = Instance.new("UICorner", ibanTextBox)
ibanTbCorner.CornerRadius = UDim.new(0,6)

-- Alıcı Kullanıcı Adı Girişi
local usernameInputLabel = Instance.new("TextLabel", transferMenuFrame)
usernameInputLabel.Name = "UsernameInputLabel"
usernameInputLabel.Size = UDim2.new(0.8,0,0,20)
usernameInputLabel.Text = "Alıcı Kullanıcı Adı:"
usernameInputLabel.Font = Enum.Font.GothamMedium
usernameInputLabel.TextSize = 14
usernameInputLabel.TextColor3 = Color3.fromRGB(80,80,80)
usernameInputLabel.BackgroundTransparency = 1
usernameInputLabel.TextXAlignment = Enum.TextXAlignment.Left
usernameInputLabel.LayoutOrder = 4

local usernameTextBox = Instance.new("TextBox", transferMenuFrame)
usernameTextBox.Name = "UsernameTextBox"
usernameTextBox.Size = UDim2.new(0.8,0,0,35)
usernameTextBox.PlaceholderText = "KullanıcıAdı"
usernameTextBox.Font = Enum.Font.Gotham
usernameTextBox.TextSize = 14
usernameTextBox.BackgroundColor3 = Color3.fromRGB(255,255,255)
usernameTextBox.LayoutOrder = 5
local userTbCorner = Instance.new("UICorner", usernameTextBox)
userTbCorner.CornerRadius = UDim.new(0,6)

-- Miktar Girişi
local amountTransferLabel = Instance.new("TextLabel", transferMenuFrame)
amountTransferLabel.Name = "AmountTransferLabel"
amountTransferLabel.Size = UDim2.new(0.8,0,0,20)
amountTransferLabel.Text = "Gönderilecek Miktar:"
amountTransferLabel.Font = Enum.Font.GothamMedium
amountTransferLabel.TextSize = 14
amountTransferLabel.TextColor3 = Color3.fromRGB(80,80,80)
amountTransferLabel.BackgroundTransparency = 1
amountTransferLabel.TextXAlignment = Enum.TextXAlignment.Left
amountTransferLabel.LayoutOrder = 6

local amountTransferTextBox = Instance.new("TextBox", transferMenuFrame)
amountTransferTextBox.Name = "AmountTransferTextBox"
amountTransferTextBox.Size = UDim2.new(0.8,0,0,35)
amountTransferTextBox.PlaceholderText = "0.00"
amountTransferTextBox.Font = Enum.Font.Gotham
amountTransferTextBox.TextSize = 14
amountTransferTextBox.BackgroundColor3 = Color3.fromRGB(255,255,255)
amountTransferTextBox.LayoutOrder = 7
local amountTTbCorner = Instance.new("UICorner", amountTransferTextBox)
amountTTbCorner.CornerRadius = UDim.new(0,6)

-- Gönder Butonları
local sendByIbanButton = Instance.new("TextButton", transferMenuFrame)
sendByIbanButton.Name = "SendByIbanButton"
sendByIbanButton.Size = UDim2.new(0.8,0,0,40)
sendByIbanButton.Text = "IBAN ile Gönder"
sendByIbanButton.Font = Enum.Font.GothamSemibold
sendByIbanButton.TextSize = 16
sendByIbanButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
sendByIbanButton.TextColor3 = Color3.fromRGB(255,255,255)
sendByIbanButton.LayoutOrder = 8
local sendIbanCorner = Instance.new("UICorner", sendByIbanButton)
sendIbanCorner.CornerRadius = UDim.new(0,8)

local sendByUsernameButton = Instance.new("TextButton", transferMenuFrame)
sendByUsernameButton.Name = "SendByUsernameButton"
sendByUsernameButton.Size = UDim2.new(0.8,0,0,40)
sendByUsernameButton.Text = "Kullanıcı Adı ile Gönder"
sendByUsernameButton.Font = Enum.Font.GothamSemibold
sendByUsernameButton.TextSize = 16
sendByUsernameButton.BackgroundColor3 = Color3.fromRGB(60, 150, 220)
sendByUsernameButton.TextColor3 = Color3.fromRGB(255,255,255)
sendByUsernameButton.LayoutOrder = 9
local sendUserCorner = Instance.new("UICorner", sendByUsernameButton)
sendUserCorner.CornerRadius = UDim.new(0,8)

-- Geri Butonu
local backButtonTransferMenu = Instance.new("TextButton", transferMenuFrame)
backButtonTransferMenu.Name = "BackButtonTransferMenu"
backButtonTransferMenu.Size = UDim2.new(0.5,0,0,40)
backButtonTransferMenu.Text = "Geri"
backButtonTransferMenu.Font = Enum.Font.GothamSemibold
backButtonTransferMenu.TextSize = 16
backButtonTransferMenu.BackgroundColor3 = Color3.fromRGB(200,200,200)
backButtonTransferMenu.TextColor3 = Color3.fromRGB(50,50,50)
backButtonTransferMenu.LayoutOrder = 10
local backBtnCorner = Instance.new("UICorner", backButtonTransferMenu)
backBtnCorner.CornerRadius = UDim.new(0,8)


-- Türkçe karakterleri ASCII'ye çeviren yardımcı fonksiyon (BURAYA TAŞINDI)
local function createAsciiKey(name)
	local key = name:gsub(" ", "") -- Boşlukları kaldır
	key = key:gsub("Ç", "C"):gsub("ç", "c")
	key = key:gsub("Ğ", "G"):gsub("ğ", "g")
	key = key:gsub("İ", "I"):gsub("ı", "i")
	key = key:gsub("Ö", "O"):gsub("ö", "o")
	key = key:gsub("Ş", "S"):gsub("ş", "s")
	key = key:gsub("Ü", "U"):gsub("ü", "u")
	return key .. "Button"
end

local actionButtonDisplayNames = {"Para Çekme", "Para Yatırma", "Hesap Hareketleri", "Tüm İşlemler"} -- Görünen isimler
local actionButtons = {}

for i, displayName in ipairs(actionButtonDisplayNames) do
	local actionButton = Instance.new("TextButton", rightPanel)
	local asciiKeyName = createAsciiKey(displayName) -- ASCII anahtar oluştur

	actionButton.Name = asciiKeyName -- Butonun Name özelliğini de ASCII yapalım
	actionButton.Size = UDim2.new(0.9, 0, 0, 60) -- Yükseklik
	actionButton.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
	actionButton.Font = Enum.Font.GothamMedium
	actionButton.Text = displayName .. "  >" -- Görünen metin Türkçe karakterli kalacak
	actionButton.TextColor3 = Color3.fromRGB(80,80,80)
	actionButton.TextSize = 18
	local btnCorner = Instance.new("UICorner", actionButton)
	btnCorner.CornerRadius = UDim.new(0, 8)
	actionButtons[asciiKeyName] = actionButton -- Tabloya ASCII anahtar ile ekle
end

-- İşlem Geçmişini Görüntüleme Fonksiyonu
local function displayTransactionHistory(history)
	for _, child in ipairs(transactionHistoryFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name == "HistoryEntryFrame" then -- Now removing frames
			child:Destroy()
		elseif child:IsA("TextLabel") and child.Name == "NoHistoryLabel" then
			-- Keep NoHistoryLabel, will be handled below
		end
	end

	if #history == 0 then
		noHistoryLabel.Visible = true
		transactionHistoryFrame.CanvasSize = UDim2.new(0,0,0,0) -- Reset canvas size
		return
	end

	noHistoryLabel.Visible = false
	local canvasHeight = 0
	local entryFrameHeight = 55 -- Fixed height for each entry frame

	for i, entry in ipairs(history) do
		local entryFrame = Instance.new("Frame", transactionHistoryFrame)
		entryFrame.Name = "HistoryEntryFrame"
		entryFrame.Size = UDim2.new(1, -6, 0, entryFrameHeight) -- Slightly less than full width for padding, fixed height
		entryFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245) -- Light background for each entry
		entryFrame.BorderSizePixel = 0
		entryFrame.LayoutOrder = i
		local entryCorner = Instance.new("UICorner", entryFrame)
		entryCorner.CornerRadius = UDim.new(0, 4)

		-- Date Label (Top-Left)
		local dateLabel = Instance.new("TextLabel", entryFrame)
		dateLabel.Name = "DateLabel"
		dateLabel.Size = UDim2.new(0.9, 0, 0, 15)
		dateLabel.Position = UDim2.new(0, 8, 0, 3)
		dateLabel.Font = Enum.Font.Gotham
		dateLabel.TextSize = 10
		dateLabel.TextColor3 = Color3.fromRGB(120, 120, 120) -- Grey
		dateLabel.Text = entry.date or "Tarih Yok"
		dateLabel.BackgroundTransparency = 1
		dateLabel.TextXAlignment = Enum.TextXAlignment.Left

		-- Description Label (Below Date, Main Info)
		local descriptionLabel = Instance.new("TextLabel", entryFrame)
		descriptionLabel.Name = "DescriptionLabel"
		descriptionLabel.Size = UDim2.new(0.65, -8, 0, 20) -- Width for description
		descriptionLabel.Position = UDim2.new(0, 8, 0, 20)
		descriptionLabel.Font = Enum.Font.GothamMedium -- Slightly bolder
		descriptionLabel.TextSize = 13
		descriptionLabel.TextColor3 = Color3.fromRGB(50, 50, 50) -- Darker grey
		descriptionLabel.Text = entry.description or "Açıklama Yok"
		descriptionLabel.BackgroundTransparency = 1
		descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
		descriptionLabel.ClipsDescendants = true


		-- Amount Label (Top-Right)
		local amountColor = Color3.fromRGB(70,70,70)
		local amountString
		if entry.amount < 0 then
			amountColor = Color3.fromRGB(200, 60, 60) -- Darker Red
			amountString = string.format("%.2f TL", entry.amount)
		elseif entry.amount > 0 then
			amountColor = Color3.fromRGB(60, 160, 60) -- Darker Green
			amountString = "+" .. string.format("%.2f TL", entry.amount)
		else
			amountString = string.format("%.2f TL", entry.amount)
		end

		local amountLabel = Instance.new("TextLabel", entryFrame)
		amountLabel.Name = "AmountLabel"
		amountLabel.Size = UDim2.new(0.35, -8, 0, 20)
		amountLabel.Position = UDim2.new(1, -8, 0, 5) -- Top-right
		amountLabel.AnchorPoint = Vector2.new(1, 0)
		amountLabel.Font = Enum.Font.GothamBold
		amountLabel.TextSize = 14
		amountLabel.TextColor3 = amountColor
		amountLabel.Text = amountString
		amountLabel.BackgroundTransparency = 1
		amountLabel.TextXAlignment = Enum.TextXAlignment.Right
		
		-- Balance After Label (Below Amount, if available)
		if entry.balanceAfter then
			local balanceAfterLabel = Instance.new("TextLabel", entryFrame)
			balanceAfterLabel.Name = "BalanceAfterLabel"
			balanceAfterLabel.Size = UDim2.new(0.35, -8, 0, 15)
			balanceAfterLabel.Position = UDim2.new(1, -8, 0, 28) -- Below amountLabel
			balanceAfterLabel.AnchorPoint = Vector2.new(1, 0)
			balanceAfterLabel.Font = Enum.Font.Gotham
			balanceAfterLabel.TextSize = 11
			balanceAfterLabel.TextColor3 = Color3.fromRGB(100, 100, 100) -- Grey
			balanceAfterLabel.Text = string.format("Bakiye: %.2f TL", entry.balanceAfter):gsub("%.",",")
			balanceAfterLabel.BackgroundTransparency = 1
			balanceAfterLabel.TextXAlignment = Enum.TextXAlignment.Right
		end
		
		canvasHeight = canvasHeight + entryFrameHeight + historyLayout.Padding.Offset
	end
	transactionHistoryFrame.CanvasSize = UDim2.new(0,0,0, canvasHeight - historyLayout.Padding.Offset) -- Remove last padding
end


-- Fonksiyonlar ve Olay Bağlantıları
local function showAtmUI(show)
	if cardInsertionFrame and cardInsertionFrame.Visible then 
		atmFrame.Visible = false
		-- checkAndNotifyServerUiStatus() -- Not here, atmFrame visibility didn't change yet
		return
	end
	if amountInputFrame and amountInputFrame.Visible then 
		atmFrame.Visible = false
		-- checkAndNotifyServerUiStatus() -- Not here
		return
	end

	local visibilityActuallyChanged = atmFrame.Visible ~= show
	atmFrame.Visible = show

	if visibilityActuallyChanged then
		checkAndNotifyServerUiStatus() -- UI visibility changed
	end

	if show then
		-- Ana ATM arayüzü gösterildiğinde, transfer menüsünü gizle, ana panelleri göster
		if transferMenuFrame then transferMenuFrame.Visible = false end
		if leftPanel then leftPanel.Visible = true end
		if rightPanel then rightPanel.Visible = true end
		sloganLabel.Text = "Lütfen seçiminizi yapın"
	end
end

iptalButton.MouseButton1Click:Connect(function()
	showAtmUI(false) -- This will call checkAndNotifyServerUiStatus if visibility changes
	-- Eğer miktar giriş ekranı açıksa onu da kapat
	if amountInputFrame and amountInputFrame.Visible then
		amountInputFrame.Visible = false
		amountInputFrame.AmountTextBox.Text = ""
		checkAndNotifyServerUiStatus() -- UI visibility changed
	end
	currentTransactionType = nil
end)

-- Para Çekme/Yatırma butonları için geçici olaylar (sonraki adımda miktar ekranı eklenecek)
-- ASCII anahtarları kullanarak butonlara erişim
if actionButtons.ParaCekmeButton then
	actionButtons.ParaCekmeButton.MouseButton1Click:Connect(function()
		if atmFrame then 
			atmFrame.Visible = false 
			checkAndNotifyServerUiStatus() -- UI visibility changed
		end
		if amountInputFrame then
			amountInputFrame.AmountTitle.Text = "Çekilecek Tutar"
			amountInputFrame.Visible = true
			checkAndNotifyServerUiStatus() -- UI visibility changed
			currentTransactionType = "withdraw"
			amountInputFrame.AmountTextBox:CaptureFocus()
		else
			warn("AmountInputFrame bulunamadı!")
		end
	end)
else
	warn("ParaCekmeButton actionButtons tablosunda bulunamadı!")
end

if actionButtons.ParaYatirmaButton then
	actionButtons.ParaYatirmaButton.MouseButton1Click:Connect(function()
		if atmFrame then 
			atmFrame.Visible = false 
			checkAndNotifyServerUiStatus() -- UI visibility changed
		end
		if amountInputFrame then
			amountInputFrame.AmountTitle.Text = "Yatırılacak Tutar"
			amountInputFrame.Visible = true
			checkAndNotifyServerUiStatus() -- UI visibility changed
			currentTransactionType = "deposit"
			amountInputFrame.AmountTextBox:CaptureFocus()
		else
			warn("AmountInputFrame bulunamadı!")
		end
	end)
else
	warn("ParaYatirmaButton actionButtons tablosunda bulunamadı!")
end

if actionButtons.HesapHareketleriButton then
	actionButtons.HesapHareketleriButton.MouseButton1Click:Connect(function()
		if leftPanel then leftPanel.Visible = false end
		if rightPanel then rightPanel.Visible = false end
		if transferMenuFrame then 
			transferMenuFrame.Visible = true 
			sloganLabel.Text = "Para Transferi"
			-- Gerekirse sunucudan güncel işlem geçmişi veya transfer için gerekli bilgiler istenebilir.
			-- ATMEvent:FireServer("getTransferDetails") 
		end
		checkAndNotifyServerUiStatus() -- Genel UI durumu değişmiş olabilir (ana ATM frame hala görünür)
	end)
else
	warn("HesapHareketleriButton actionButtons tablosunda bulunamadı!")
end

-- Transfer Menüsü Geri Butonu
backButtonTransferMenu.MouseButton1Click:Connect(function()
	if transferMenuFrame then transferMenuFrame.Visible = false end
	if leftPanel then leftPanel.Visible = true end
	if rightPanel then rightPanel.Visible = true end
	sloganLabel.Text = "Lütfen seçiminizi yapın"
	checkAndNotifyServerUiStatus()
end)

-- Transfer Gönderme Butonları (Şimdilik sadece geri bildirim)
sendByIbanButton.MouseButton1Click:Connect(function()
	local targetIban = ibanTextBox.Text
	local amount = tonumber(amountTransferTextBox.Text)
	if targetIban ~= "" and amount and amount > 0 then
		ATMEvent:FireServer("transferToIban", targetIban, amount)
		-- Geri bildirim için UI eklenebilir
	else
		-- Hatalı giriş uyarısı
		print("ATMClient: IBAN ile transfer için geçersiz giriş.")
	end
	-- Clear textboxes after the attempt, regardless of client-side validation success
	ibanTextBox.Text = ""
	usernameTextBox.Text = "" -- Also clear username if IBAN send is attempted
	amountTransferTextBox.Text = ""
end)

sendByUsernameButton.MouseButton1Click:Connect(function()
	local targetUsername = usernameTextBox.Text
	local amount = tonumber(amountTransferTextBox.Text)
	if targetUsername ~= "" and amount and amount > 0 then
		ATMEvent:FireServer("transferToUsername", targetUsername, amount)
		-- Geri bildirim için UI eklenebilir
	else
		-- Hatalı giriş uyarısı
		print("ATMClient: Kullanıcı adı ile transfer için geçersiz giriş.")
	end
	-- Clear textboxes after the attempt, regardless of client-side validation success
	ibanTextBox.Text = "" -- Also clear IBAN if username send is attempted
	usernameTextBox.Text = ""
	amountTransferTextBox.Text = ""
end)


ATMEvent.OnClientEvent:Connect(function(data)
	if not data or not data.action then return end

	if data.action == "requestCardInsertion" then
		if atmFrame then 
			atmFrame.Visible = false 
			checkAndNotifyServerUiStatus() -- UI visibility changed
		end 
		if cardInsertionFrame then
			cardInsertionFrame.Visible = true
			checkAndNotifyServerUiStatus() -- UI visibility changed
		else
			createCardInsertionUI() 
			cardInsertionFrame.Visible = true
			checkAndNotifyServerUiStatus() -- UI visibility changed
		end
	elseif data.action == "showAtmUIDetails" then -- NEW HANDLER
		if cardInsertionFrame then 
			cardInsertionFrame.Visible = false 
			checkAndNotifyServerUiStatus() 
		end 
		if amountInputFrame then 
			amountInputFrame.Visible = false 
			checkAndNotifyServerUiStatus() 
		end 
		
		local processingFeedback = screenGui:FindFirstChild("ProcessingFeedbackLabel")
		if processingFeedback then processingFeedback:Destroy() end
		
		if data.balance then
			balanceValueLabel.Text = string.format("%.2f TL", data.balance):gsub("%.",",")
		end
		if data.iban then
			ibanLabel.Text = data.iban
		end
		if data.history then -- İşlem geçmişini göster
			displayTransactionHistory(data.history)
		end
		accountNameLabel.Text = LocalPlayer.DisplayName -- Set player name
		
		showAtmUI(true) -- Now make the main frame visible
	elseif data.action == "balanceUpdate" then
		if data.balance then
			balanceValueLabel.Text = string.format("%.2f TL", data.balance):gsub("%.",",")
		end
		if data.iban then -- Also update IBAN if provided with balance
			ibanLabel.Text = data.iban
		end
		if data.history then -- İşlem geçmişini göster
			displayTransactionHistory(data.history)
		end
		-- Bakiye güncellendiğinde, eğer açıksa ana ATM arayüzünü göster
		local processingFeedback = screenGui:FindFirstChild("ProcessingFeedbackLabel")
		if processingFeedback then processingFeedback:Destroy() end
		
		if not (atmFrame and atmFrame.Visible) and not (cardInsertionFrame and cardInsertionFrame.Visible) and not (amountInputFrame and amountInputFrame.Visible) then
			showAtmUI(true)
		end
	elseif data.action == "feedback" then
		local processingFeedback = screenGui:FindFirstChild("ProcessingFeedbackLabel")
		if processingFeedback then processingFeedback:Destroy() end
		
		print("ATM Geri Bildirim: " .. (data.message or "Bir hata oluştu.") .. " Başarı: " .. tostring(data.success))
		
		-- Geri bildirim mesajını göstermek için geçici bir label oluşturabiliriz.
		local feedbackLabel = Instance.new("TextLabel", screenGui)
		feedbackLabel.Name = "TempFeedbackMessage"
		feedbackLabel.Size = UDim2.new(0.4, 0, 0.1, 0)
		feedbackLabel.Position = UDim2.new(0.5, 0, 0.15, 0) -- Ekranın biraz üstünde
		feedbackLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		feedbackLabel.Font = Enum.Font.Gotham
		feedbackLabel.Text = data.message or "İşlem sonucu."
		feedbackLabel.TextSize = 16
		feedbackLabel.TextColor3 = data.success and Color3.fromRGB(100, 220, 100) or Color3.fromRGB(220, 100, 100)
		feedbackLabel.BackgroundTransparency = 0.2
		feedbackLabel.BackgroundColor3 = Color3.fromRGB(50,50,60)
		local fbCorner = Instance.new("UICorner", feedbackLabel)
		fbCorner.CornerRadius = UDim.new(0,6)
		feedbackLabel.Visible = true
		
		task.delay(3.5, function()
			if feedbackLabel and feedbackLabel.Parent then
				feedbackLabel:Destroy()
			end
		end)

		-- İşlemden sonra ana ATM arayüzünü göster
		if not (atmFrame and atmFrame.Visible) and not (cardInsertionFrame and cardInsertionFrame.Visible) and not (amountInputFrame and amountInputFrame.Visible) then
			showAtmUI(true) -- This will call checkAndNotifyServerUiStatus if visibility changes
		end
		currentTransactionType = nil
		checkAndNotifyServerUiStatus() -- Ensure status is correct after feedback handling
	end
end)

print("ATMClient.luau (Garanti Temalı) çalıştı.")
showAtmUI(false) -- This will call checkAndNotifyServerUiStatus if visibility changes
checkAndNotifyServerUiStatus() -- Initial check
