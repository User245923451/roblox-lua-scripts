local TeleportService = game:GetService("TeleportService") -- Doğrudan Roblox servisinden al
local Players = (syn and syn.get_service) and syn.get_service("Players") or game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer
local placeId = game.PlaceId -- Bulunduğun oyunun PlaceId'sini otomatik alır

-- Dosya işlemleri için yardımcı fonksiyonlar
local function saveJobIds(jobIds)
    if writefile then
        pcall(function()
            writefile("TeleportJobIds.json", HttpService:JSONEncode(jobIds))
        end)
    end
end

local function loadJobIds()
    if readfile then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile("TeleportJobIds.json"))
        end)
        if success then
            return result or {}
        end
    end
    return {}
end

-- GUI oluşturma (Ana Pencere)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportGUI"
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Position = UDim2.new(0, 0, 0, 5)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Teleport Arayüzü"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 20
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Parent = MainFrame

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -30, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "X"
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Parent = MainFrame

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 25, 0, 25)
MinimizeButton.Position = UDim2.new(1, -60, 0, 5)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Text = "-"
MinimizeButton.TextSize = 16
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.Parent = MainFrame

local JobIdBox = Instance.new("TextBox")
JobIdBox.Size = UDim2.new(0.9, 0, 0, 30)
JobIdBox.Position = UDim2.new(0.05, 0, 0, 40)
JobIdBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
JobIdBox.TextColor3 = Color3.fromRGB(0, 0, 0)
JobIdBox.TextSize = 16
JobIdBox.Font = Enum.Font.SourceSans
JobIdBox.PlaceholderText = "JobId'yi buraya girin (UUID formatı)"
JobIdBox.Parent = MainFrame

local CopyServerJobIdButton = Instance.new("TextButton")
CopyServerJobIdButton.Size = UDim2.new(0.9, 0, 0, 30)
CopyServerJobIdButton.Position = UDim2.new(0.05, 0, 0, 80)
CopyServerJobIdButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
CopyServerJobIdButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyServerJobIdButton.Text = "Mevcut Sunucunun JobId'sini Kopyala"
CopyServerJobIdButton.TextSize = 16
CopyServerJobIdButton.Font = Enum.Font.SourceSansBold
CopyServerJobIdButton.Parent = MainFrame

local ListButton = Instance.new("TextButton")
ListButton.Size = UDim2.new(0.9, 0, 0, 30)
ListButton.Position = UDim2.new(0.05, 0, 0, 120)
ListButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
ListButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ListButton.Text = "Kaydedilen JobId Listesini Aç"
ListButton.TextSize = 16
ListButton.Font = Enum.Font.SourceSansBold
ListButton.Parent = MainFrame

local TeleportButton = Instance.new("TextButton")
TeleportButton.Size = UDim2.new(0.9, 0, 0, 30)
TeleportButton.Position = UDim2.new(0.05, 0, 0, 160)
TeleportButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
TeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportButton.Text = "Işınlan"
TeleportButton.TextSize = 16
TeleportButton.Font = Enum.Font.SourceSansBold
TeleportButton.Parent = MainFrame

local CountdownLabel = Instance.new("TextLabel")
CountdownLabel.Size = UDim2.new(0.9, 0, 0, 30)
CountdownLabel.Position = UDim2.new(0.5, -180, 0, 200)
CountdownLabel.BackgroundTransparency = 1
CountdownLabel.Text = ""
CountdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
CountdownLabel.TextSize = 16
CountdownLabel.Font = Enum.Font.SourceSans
CountdownLabel.Parent = MainFrame

local CancelButton = Instance.new("TextButton")
CancelButton.Size = UDim2.new(0.9, 0, 0, 30)
CancelButton.Position = UDim2.new(0.05, 0, 0, 240)
CancelButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CancelButton.Text = "İptal"
CancelButton.TextSize = 16
CancelButton.Font = Enum.Font.SourceSansBold
CancelButton.Visible = false
CancelButton.Parent = MainFrame

-- Liste Penceresi
local ListFrame = Instance.new("Frame")
ListFrame.Size = UDim2.new(0, 400, 0, 350)
ListFrame.Position = UDim2.new(0.5, -200, 0.5, -175)
ListFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ListFrame.BorderSizePixel = 2
ListFrame.Active = true
ListFrame.Draggable = true
ListFrame.Visible = false
ListFrame.Parent = ScreenGui

local ListTitleLabel = Instance.new("TextLabel")
ListTitleLabel.Size = UDim2.new(1, 0, 0, 30)
ListTitleLabel.Position = UDim2.new(0, 0, 0, 5)
ListTitleLabel.BackgroundTransparency = 1
ListTitleLabel.Text = "Kaydedilen JobId'ler"
ListTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ListTitleLabel.TextSize = 20
ListTitleLabel.Font = Enum.Font.SourceSansBold
ListTitleLabel.Parent = ListFrame

local ListCloseButton = Instance.new("TextButton")
ListCloseButton.Size = UDim2.new(0, 25, 0, 25)
ListCloseButton.Position = UDim2.new(1, -30, 0, 5)
ListCloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ListCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ListCloseButton.Text = "X"
ListCloseButton.TextSize = 16
ListCloseButton.Font = Enum.Font.SourceSansBold
ListCloseButton.Parent = ListFrame

local ListJobIdBox = Instance.new("TextBox")
ListJobIdBox.Size = UDim2.new(0.9, 0, 0, 30)
ListJobIdBox.Position = UDim2.new(0.05, 0, 0, 40)
ListJobIdBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ListJobIdBox.TextColor3 = Color3.fromRGB(0, 0, 0)
ListJobIdBox.TextSize = 16
ListJobIdBox.Font = Enum.Font.SourceSans
ListJobIdBox.PlaceholderText = "Kaydedilecek JobId'yi buraya girin"
ListJobIdBox.Parent = ListFrame

local NameBox = Instance.new("TextBox")
NameBox.Size = UDim2.new(0.9, 0, 0, 30)
NameBox.Position = UDim2.new(0.05, 0, 0, 80)
NameBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
NameBox.TextColor3 = Color3.fromRGB(0, 0, 0)
NameBox.TextSize = 16
NameBox.Font = Enum.Font.SourceSans
NameBox.PlaceholderText = "JobId için isim girin"
NameBox.Parent = ListFrame

local SaveJobIdButton = Instance.new("TextButton")
SaveJobIdButton.Size = UDim2.new(0.9, 0, 0, 30)
SaveJobIdButton.Position = UDim2.new(0.05, 0, 0, 120)
SaveJobIdButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
SaveJobIdButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveJobIdButton.Text = "JobId'yi Kaydet"
SaveJobIdButton.TextSize = 16
SaveJobIdButton.Font = Enum.Font.SourceSansBold
SaveJobIdButton.Parent = ListFrame

local SavedJobIdsFrame = Instance.new("ScrollingFrame")
SavedJobIdsFrame.Size = UDim2.new(0.9, 0, 0, 170)
SavedJobIdsFrame.Position = UDim2.new(0.05, 0, 0, 160)
SavedJobIdsFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
SavedJobIdsFrame.BorderSizePixel = 1
SavedJobIdsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
SavedJobIdsFrame.ScrollBarThickness = 5
SavedJobIdsFrame.Parent = ListFrame

-- Kaydedilmiş JobId'ler
local jobIds = loadJobIds()

-- JobId'nin geçerli bir UUID formatında olduğunu kontrol et
local function isValidUUID(str)
    if type(str) ~= "string" then
        return false
    end
    return str:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

-- Bildirim gösterme fonksiyonu
local function showNotification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

-- Kaydedilmiş JobId'leri gösteren fonksiyon
local function updateSavedJobIdsList()
    -- Önce mevcut listeyi temizle
    for _, child in ipairs(SavedJobIdsFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- Yeni listeyi oluştur
    local yOffset = 5
    for i, data in ipairs(jobIds) do
        local JobIdFrame = Instance.new("Frame")
        JobIdFrame.Size = UDim2.new(1, -10, 0, 30)
        JobIdFrame.Position = UDim2.new(0, 5, 0, yOffset)
        JobIdFrame.BackgroundTransparency = 1
        JobIdFrame.Parent = SavedJobIdsFrame

        local JobIdLabel = Instance.new("TextLabel")
        JobIdLabel.Size = UDim2.new(0.5, 0, 1, 0)
        JobIdLabel.BackgroundTransparency = 1
        JobIdLabel.Text = data.name -- Sadece isim göster
        JobIdLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        JobIdLabel.TextSize = 14
        JobIdLabel.Font = Enum.Font.SourceSans
        JobIdLabel.TextXAlignment = Enum.TextXAlignment.Left
        JobIdLabel.Parent = JobIdFrame

        local CopyButton = Instance.new("TextButton")
        CopyButton.Size = UDim2.new(0.15, 0, 1, 0)
        CopyButton.Position = UDim2.new(0.5, 0, 0, 0)
        CopyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        CopyButton.Text = "Kopyala"
        CopyButton.TextSize = 14
        CopyButton.Font = Enum.Font.SourceSans
        CopyButton.Parent = JobIdFrame

        local TeleportSavedButton = Instance.new("TextButton")
        TeleportSavedButton.Size = UDim2.new(0.15, 0, 1, 0)
        TeleportSavedButton.Position = UDim2.new(0.65, 0, 0, 0)
        TeleportSavedButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        TeleportSavedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        TeleportSavedButton.Text = "Işınlan"
        TeleportSavedButton.TextSize = 14
        TeleportSavedButton.Font = Enum.Font.SourceSans
        TeleportSavedButton.Parent = JobIdFrame

        local DeleteButton = Instance.new("TextButton")
        DeleteButton.Size = UDim2.new(0.15, 0, 1, 0)
        DeleteButton.Position = UDim2.new(0.8, 0, 0, 0)
        DeleteButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        DeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        DeleteButton.Text = "Sil"
        DeleteButton.TextSize = 14
        DeleteButton.Font = Enum.Font.SourceSans
        DeleteButton.Parent = JobIdFrame

        CopyButton.MouseButton1Click:Connect(function()
            if setclipboard then
                pcall(function()
                    setclipboard(data.jobId)
                    showNotification("Bilgi", "JobId kopyalandı: " .. data.jobId)
                end)
            else
                showNotification("Hata", "Kopyalama desteklenmiyor!")
            end
        end)

        TeleportSavedButton.MouseButton1Click:Connect(function()
            local jobId = data.jobId
            print("Liste Işınlan butonuna basıldı, jobId: " .. tostring(jobId))
            print("Kullanılan placeId: " .. tostring(placeId))
            showNotification("Bilgi", "Işınlanma başlatılıyor: " .. data.name)
            attemptTeleport(jobId)
        end)

        DeleteButton.MouseButton1Click:Connect(function()
            table.remove(jobIds, i)
            saveJobIds(jobIds)
            updateSavedJobIdsList()
            showNotification("Bilgi", "JobId silindi: " .. data.name)
        end)

        yOffset = yOffset + 35
    end
    SavedJobIdsFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Geri sayım ve ışınlanma fonksiyonu
local countdownConnection = nil
local function attemptTeleport(jobId)
    print("attemptTeleport çağrıldı, jobId: " .. tostring(jobId))
    if not isValidUUID(jobId) then
        warn("Hata: JobId geçerli bir UUID değil")
        showNotification("Hata", "JobId geçerli bir UUID değil")
        return
    end

    print("Teleport denemesi öncesi: placeId = " .. tostring(placeId) .. ", jobId = " .. tostring(jobId))
    if not TeleportService or type(TeleportService.TeleportToPlaceInstance) ~= "function" then
        warn("TeleportService veya TeleportToPlaceInstance tanımsız! Executor uyumluluğunu kontrol et.")
        showNotification("Hata", "TeleportService çalışmıyor, executor uyumluluğunu kontrol et!")
        return
    end

    showNotification("Bilgi", "Geri sayım başladı: 10 saniye")

    local countdown = 10
    TeleportButton.Visible = false
    CancelButton.Visible = true
    CountdownLabel.Text = "Işınlanma için geri sayım: " .. countdown .. " saniye"

    countdownConnection = RunService.Heartbeat:Connect(function(deltaTime)
        countdown = countdown - deltaTime
        CountdownLabel.Text = "Işınlanma için geri sayım: " .. math.max(0, math.floor(countdown)) .. " saniye"
        
        if countdown <= 0 then
            countdownConnection:Disconnect()
            countdownConnection = nil
            TeleportButton.Visible = true
            CancelButton.Visible = false
            CountdownLabel.Text = ""

            local success, errorMessage = pcall(function()
                print("Teleport denemesi: placeId = " .. tostring(placeId) .. ", jobId = " .. tostring(jobId))
                TeleportService:TeleportToPlaceInstance(placeId, jobId, localPlayer)
            end)

            if success then
                print("Teleport başarılı: " .. jobId)
                showNotification("Bilgi", "Teleport başarılı: " .. jobId)
            else
                warn("Teleport başarısız: " .. tostring(errorMessage))
                showNotification("Hata", "Teleport başarısız: " .. tostring(errorMessage))
            end
        end
    end)
end

-- Buton tıklama olayları
CopyServerJobIdButton.MouseButton1Click:Connect(function()
    local currentJobId = game.JobId
    if currentJobId and currentJobId ~= "" then
        if setclipboard then
            pcall(function()
                setclipboard(currentJobId)
                JobIdBox.Text = currentJobId
                showNotification("Bilgi", "Mevcut sunucunun JobId'si kopyalandı: " .. currentJobId)
            end)
        else
            showNotification("Hata", "Kopyalama desteklenmiyor!")
        end
    else
        showNotification("Hata", "Mevcut sunucunun JobId'si alınamadı!")
    end
end)

SaveJobIdButton.MouseButton1Click:Connect(function()
    local jobId = ListJobIdBox.Text
    local name = NameBox.Text
    if not isValidUUID(jobId) then
        showNotification("Hata", "Geçerli bir JobId girin!")
        return
    end
    if name == "" then
        name = "JobId " .. #jobIds + 1
    end
    table.insert(jobIds, {name = name, jobId = jobId})
    saveJobIds(jobIds)
    updateSavedJobIdsList()
    showNotification("Bilgi", "JobId kaydedildi: " .. name)
    ListJobIdBox.Text = ""
    NameBox.Text = ""
end)

TeleportButton.MouseButton1Click:Connect(function()
    local jobId = JobIdBox.Text
    print("Ana Işınlan butonuna basıldı, jobId: " .. tostring(jobId))
    showNotification("Bilgi", "Işınlanma başlatılıyor (Ana arayüz)")
    attemptTeleport(jobId)
end)

CancelButton.MouseButton1Click:Connect(function()
    if countdownConnection then
        countdownConnection:Disconnect()
        countdownConnection = nil
        TeleportButton.Visible = true
        CancelButton.Visible = false
        CountdownLabel.Text = ""
        showNotification("Bilgi", "Işınlanma iptal edildi")
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    showNotification("Bilgi", "Teleport GUI kapatıldı")
end)

ListCloseButton.MouseButton1Click:Connect(function()
    ListFrame.Visible = false
    showNotification("Bilgi", "JobId Listesi kapatıldı")
end)

MinimizeButton.MouseButton1Click:Connect(function()
    if MainFrame.Size == UDim2.new(0, 400, 0, 30) then
        MainFrame.Size = UDim2.new(0, 400, 0, 300)
        JobIdBox.Visible = true
        CopyServerJobIdButton.Visible = true
        ListButton.Visible = true
        TeleportButton.Visible = true
        CountdownLabel.Visible = true
        CancelButton.Visible = countdownConnection ~= nil
        MinimizeButton.Text = "-"
        showNotification("Bilgi", "GUI açıldı")
    else
        MainFrame.Size = UDim2.new(0, 400, 0, 30)
        JobIdBox.Visible = false
        CopyServerJobIdButton.Visible = false
        ListButton.Visible = false
        TeleportButton.Visible = false
        CountdownLabel.Visible = false
        CancelButton.Visible = false
        MinimizeButton.Text = "+"
        showNotification("Bilgi", "GUI minimize edildi")
    end
end)

ListButton.MouseButton1Click:Connect(function()
    ListFrame.Visible = true
    updateSavedJobIdsList()
    showNotification("Bilgi", "JobId Listesi açıldı")
end)

-- Teleport işleminin sonucunu dinleme
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    warn("Işınlanma başarısız: " .. tostring(teleportResult) .. " - " .. tostring(errorMessage))
    showNotification("Hata", "Işınlanma başarısız: " .. tostring(teleportResult) .. " - " .. tostring(errorMessage))
    print("TeleportInitFailed: " .. tostring(errorMessage))
end)

-- Başlangıçta kaydedilmiş JobId'leri yükle
updateSavedJobIdsList()
showNotification("Bilgi", "Teleport GUI yüklendi!")
