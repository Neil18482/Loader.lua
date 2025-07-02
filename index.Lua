loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/NoLag-id/No-Lag-HUB/refs/heads/main/Loader/LoaderV1.lua"))()

--[[ 
    @author depso (depthso)
    @description Grow a Garden stock bot script
    Discord + Facebook Posting
]]

type table = {
	[any]: any
}

_G.Configuration = {
	--// Reporting
	["Enabled"] = true,
	["Webhook"] = "https://discord.com/api/webhooks/1389035637566345418/SJ-vZO6SigPj74kpC1l00vhTCBEWO6pNk3g6ap6lMvWoRfHthFsn41ooOSorYiwOdXrt", -- Replace with your Discord webhook
	["Weather Reporting"] = true,

	--// Facebook Integration
	["Facebook Enabled"] = true,
	["Facebook Page ID"] = "112539638184963", -- Your Facebook Page ID
	["Facebook Access Token"] = "EAAJsbRazAzYBOxYGBmliSZCZAC0c62DVwQ0PTG6jdBSZB0aPPCHXJ9FHxaOaYL6lpgHxKZC7zPRnv4Hgli8mQqZAKTWo7tWJZBWj8OtJ2vrPZC3HqIEEkm84v6QuuvCcI3IYLMNsaBVHV3B20nDMcNTLMZBWBcJpR1Wp6b3zcIbq77D00H8omNMkmxuSGL4XxxlXStpiF9iZBaykKRwLMtZBmpCaMZD", -- Long-lived Page Access Token

	--// User
	["Anti-AFK"] = true,
	["Auto-Reconnect"] = true,
	["Rendering Enabled"] = false,

	--// Embeds
	["AlertLayouts"] = {
		["Weather"] = {
			EmbedColor = Color3.fromRGB(42, 109, 255),
		},
		["SeedsAndGears"] = {
			EmbedColor = Color3.fromRGB(56, 238, 23),
			Layout = {
				["ROOT/SeedStock/Stocks"] = "SEEDS STOCK",
				["ROOT/GearStock/Stocks"] = "GEAR STOCK"
			}
		},
		["EventShop"] = {
			EmbedColor = Color3.fromRGB(212, 42, 255),
			Layout = {
				["ROOT/EventShopStock/Stocks"] = "EVENT STOCK"
			}
		},
		["Eggs"] = {
			EmbedColor = Color3.fromRGB(251, 255, 14),
			Layout = {
				["ROOT/PetEggStock/Stocks"] = "EGG STOCK"
			}
		},
		["CosmeticStock"] = {
			EmbedColor = Color3.fromRGB(255, 106, 42),
			Layout = {
				["ROOT/CosmeticStock/ItemStocks"] = "COSMETIC ITEMS STOCK"
			}
		}
	}
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = cloneref(game:GetService("VirtualUser"))
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")

--// Remotes
local DataStream = ReplicatedStorage.GameEvents.DataStream
local WeatherEventStarted = ReplicatedStorage.GameEvents.WeatherEventStarted

local LocalPlayer = Players.LocalPlayer

--// Facebook Posting
local function FacebookPost(Message: string)
	local FacebookEnabled = _G.Configuration["Facebook Enabled"]
	local PageID = _G.Configuration["Facebook Page ID"]
	local AccessToken = _G.Configuration["Facebook Access Token"]

	if not FacebookEnabled or PageID == "" or AccessToken == "" then return end

	local FacebookURL = `https://graph.facebook.com/{PageID}/feed`

	local EncodedMessage = HttpService:UrlEncode(Message)
	local EncodedToken = HttpService:UrlEncode(AccessToken)
	local PostBody = `message={EncodedMessage}&access_token={EncodedToken}`

	local RequestData = {
		Url = FacebookURL,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/x-www-form-urlencoded"
		},
		Body = PostBody
	}

	task.spawn(function()
		local success, err = pcall(function()
			request(RequestData)
		end)
		if not success then
			warn("Facebook post failed:", err)
		end
	end)
end

--// Utilities
local function GetConfigValue(Key: string)
	return _G.Configuration[Key]
end

RunService:Set3dRenderingEnabled(GetConfigValue("Rendering Enabled"))
if _G.StockBot then return end
_G.StockBot = true

local function ConvertColor3(Color: Color3): number
	local Hex = Color:ToHex()
	return tonumber(Hex, 16)
end

local function GetDataPacket(Data, Target: string)
	for _, Packet in Data do
		if Packet[1] == Target then
			return Packet[2]
		end
	end
	return
end

local function GetLayout(Type: string)
	return GetConfigValue("AlertLayouts")[Type]
end

local function WebhookSend(Type: string, Fields: table)
	if not GetConfigValue("Enabled") then return end
	local Layout = GetLayout(Type)
	local Color = ConvertColor3(Layout.EmbedColor)

	local TimeStamp = DateTime.now():ToIsoDate()
	local Body = {
		embeds = {{
			color = Color,
			fields = Fields,
			footer = { text = "Created by Laire Neil Villena" },
			timestamp = TimeStamp
		}}
	}

	local RequestData = {
		Url = GetConfigValue("Webhook"),
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode(Body)
	}

	task.spawn(request, RequestData)
end

local function MakeStockString(Stock: table): string
	local String = ""
	for Name, Data in Stock do 
		local Amount = Data.Stock
		local EggName = Data.EggName 
		Name = EggName or Name
		String ..= `{Name} **x{Amount}**\n`
	end
	return String
end

local function ProcessPacket(Data, Type: string, Layout)
	local Fields = {}
	local FieldsLayout = Layout.Layout
	if not FieldsLayout then return end

	for Packet, Title in FieldsLayout do 
		local Stock = GetDataPacket(Data, Packet)
		if not Stock then return end

		local Field = {
			name = Title,
			value = MakeStockString(Stock),
			inline = true
		}
		table.insert(Fields, Field)
	end

	WebhookSend(Type, Fields)

	-- Facebook post for SeedsAndGears
	if Type == "SeedsAndGears" then
		local CombinedStock = ""
		for _, field in Fields do
			CombinedStock ..= `📦 {field.name}\n{field.value}\n\n`
		end

		local FacebookMessage = table.concat({
			"🛒 **Grow a Garden Item Stock Update**",
			"",
			CombinedStock,
			"🌱 Hurry before it runs out!",
			"🎮 Game: Grow a Garden"
		}, "\n")

		FacebookPost(FacebookMessage)
	end
end

--// Weather Event
WeatherEventStarted.OnClientEvent:Connect(function(Event: string, Length: number)
	if not GetConfigValue("Weather Reporting") then return end

	local ServerTime = math.round(workspace:GetServerTimeNow())
	local EndUnix = ServerTime + Length

	local FacebookMessage = table.concat({
		"🌤️ **Weather Event Detected!**",
		"",
		`🌪️ Type: {Event}`,
		`⏱️ Duration: {Length} seconds`,
		"",
		"🎮 Game: Grow a Garden",
		"📌 Stock will auto-update here. Stay tuned!"
	}, "\n")

	FacebookPost(FacebookMessage)

	WebhookSend("Weather", {{
		name = "WEATHER",
		value = `{Event}\nEnds:<t:{EndUnix}:R>`,
		inline = true
	}})
end)

--// Stock Data Stream
DataStream.OnClientEvent:Connect(function(Type: string, Profile: string, Data: table)
	if Type ~= "UpdateData" then return end
	if not Profile:find(LocalPlayer.Name) then return end

	local Layouts = GetConfigValue("AlertLayouts")
	for Name, Layout in Layouts do
		ProcessPacket(Data, Name, Layout)
	end
end)

--// Anti idle
LocalPlayer.Idled:Connect(function()
	if not GetConfigValue("Anti-AFK") then return end
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

--// Auto reconnect
GuiService.ErrorMessageChanged:Connect(function()
	if not GetConfigValue("Auto-Reconnect") then return end

	local IsSingle = #Players:GetPlayers() <= 1
	local PlaceId = game.PlaceId
	local JobId = game.JobId

	queue_on_teleport("https://rawscripts.net/raw/Grow-a-Garden-Grow-a-Garden-Stock-bot-41500")

	if IsSingle then
		TeleportService:Teleport(PlaceId, LocalPlayer)
	else
		TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
	end
end)
