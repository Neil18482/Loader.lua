loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/NoLag-id/No-Lag-HUB/refs/heads/main/Loader/LoaderV1.lua"))()

--[[ 
	@author Laire Neil
	@description Grow a Garden stock bot script
	Discord + Make.com Posting (FB Page, Group, Messenger)
]]

type table = {
	[any]: any
}

_G.Configuration = {
	--// Reporting
	["Enabled"] = true,
	["Webhook"] = "https://discord.com/api/webhooks/1389872635713945610/NPjEQKE8aK0iXMioXOlvKDllGEXoGyqWFWCiCUWvbJ9ODgooIJDpDZbmi4tflnlrRCs-", -- Replace
	["Weather Reporting"] = true,

	--// User Settings
	["Anti-AFK"] = true,
	["Auto-Reconnect"] = true,
	["Rendering Enabled"] = false,

	--// Embed Layouts
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

--// Make.com Integration
local function SendToMakeCom(payload: table)
	local MakeWebhook = "https://hook.eu2.make.com/69qy7aj17oh5lhyn3lv7gunwy1ys1l59" -- Replace this
	local body = HttpService:JSONEncode(payload)

	local success, err = pcall(function()
		request({
			Url = MakeWebhook,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = body
		})
	end)

	if not success then
		warn("Make.com Webhook failed:", err)
	end
end

--// Util
local function GetConfigValue(Key: string)
	return _G.Configuration[Key]
end

local function ConvertColor3(Color: Color3): number
	return tonumber(Color:ToHex(), 16)
end

local function GetDataPacket(Data, Target: string)
	for _, Packet in Data do
		if Packet[1] == Target then
			return Packet[2]
		end
	end
end

local function GetLayout(Type: string)
	return GetConfigValue("AlertLayouts")[Type]
end

local EmojiMap = {
	["Carrot"] = "🥕",
	["Strawberry"] = "🍓",
	["Blueberry"] = "🫐",
	["Tomato"] = "🍅",
	["Cauliflower"] = "🥦", -- closest emoji
	["Watermelon"] = "🍉",
	["Rafflesia"] = "🌸",
	["Green"] = "🟢",
	["Apple"] = "🍎",
	["Avocado"] = "🥑",
	["Banana"] = "🍌",
	["Pineapple"] = "🍍",
	["Kiwi"] = "🥝",
	["Bell Pepper"] = "🫑",
	["Prickly Pear"] = "🌵",
	["Loquat"] = "🍑", -- closest emoji
	["Feijoa"] = "🍈",
	["Pitcher"] = "🪣",
	["Plant"] = "🪴",
	["Sugar Apple"] = "🍏"
	-- Gear Shop Items
	["Watering Can"] = "💧",
	["Trowel"] = "🧱",
	["Recall Wrench"] = "🔧",
	["Basic Sprinkler"] = "⚙️",
	["Advanced Sprinkler"] = "🔩",
	["Godly Sprinkler"] = "🌟",
	["Magnifying Glass"] = "🔍",
	["Tanning Mirror"] = "🪞",
	["Master Sprinkler"] = "🏆",
	["Cleaning Spray"] = "🧼",
	["Favorite Tool"] = "❤️",
	["Harvest Tool"] = "🌾",
	["Friendship Pot"] = "🪴",
}

local function MakeStockString(Stock: table): string
	local result = ""
	for Name, Data in Stock do 
		local Amount = Data.Stock
		local DisplayName = Data.EggName or Name

		local Emoji = EmojiMap[DisplayName] or "📦"
		result ..= `{Emoji} {DisplayName}: **x{Amount}**\n`
	end
	return result
end


--// Discord Send
local function WebhookSend(Type: string, Fields: table)
	if not GetConfigValue("Enabled") then return end
	local Layout = GetLayout(Type)
	local Color = ConvertColor3(Layout.EmbedColor)

	local Body = {
		embeds = {{
			color = Color,
			fields = Fields,
			footer = { text = "Created by Laire Neil Villena" },
			timestamp = DateTime.now():ToIsoDate()
		}}
	}

	task.spawn(function()
		request({
			Url = GetConfigValue("Webhook"),
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(Body)
		})
	end)
end

--// Process Inventory Data
local function ProcessPacket(Data, Type: string, Layout)
	local Fields = {}
	local FieldsLayout = Layout.Layout
	if not FieldsLayout then return end

	for Path, Label in FieldsLayout do 
		local Stock = GetDataPacket(Data, Path)
		if not Stock then return end

		table.insert(Fields, {
			name = Label,
			value = MakeStockString(Stock),
			inline = true
		})
	end

	-- Send to Discord
	WebhookSend(Type, Fields)

	-- Send to Make.com (Facebook / Messenger)
	if Type == "SeedsAndGears" then
		local combinedMessage = table.concat({
			"==============================",
			"🌟 **GROW A GARDEN - STOCK ALERT** 🌟",
			"==============================",
			"",
			"🛒 *New Items Just Restocked!*",
			"",
		}, "\n")

		for _, field in Fields do
			combinedMessage ..= `\n📌 *{field.name}*\n{field.value}`
		end

		combinedMessage ..= table.concat({
			"",
			"==============================",
			"🌱 Grab them while supplies last!",
			"🎮 Play now: https://www.roblox.com/games/126884695634066",
			"",
			"#GrowAGarden #RobloxFarming #StockAlert"
		}, "\n")

		-- 🔁 Send to Make.com webhook
		SendToMakeCom({
			source = "Grow A Garden Bot",
			type = "stock",
			message = combinedMessage
		})
	end
end


local WeatherEmojiMap = {
	["Wet"] = "💧",
	["Windstruc"] = "🌬️",
	["Moonlit"] = "🌙",
	["Chilled"] = "🧊",
	["Choc"] = "🍫",
	["Bloodil"] = "🩸",
	["Twisted"] = "🌀",
	["Drenched"] = "🌊",
	["Frozen"] = "❄️",
	["Aurora"] = "🌈",
	["Shocked"] = "⚡",
	["Celestial"] = "✨"
}
--// Weather Event Reporting
WeatherEventStarted.OnClientEvent:Connect(function(Event: string, Duration: number)
	if not GetConfigValue("Weather Reporting") then return end

	local EndTime = math.round(workspace:GetServerTimeNow()) + Duration
	local Emoji = WeatherEmojiMap[Event] or "🌫️" -- fallback if unknown

	local weatherMessage = table.concat({
		"🌦️ **Weather Event Detected!**",
		`{Emoji} Type: {Event}`,
		`⏱️ Duration: {Duration} seconds`,
		"🎮 Game: Grow a Garden"
	}, "\n")

	SendToMakeCom({
		source = "Grow A Garden Bot",
		type = "weather",
		message = weatherMessage,
		event = Event,
		duration = Duration,
		unix_ends = EndTime
	})

	WebhookSend("Weather", {{
		name = "WEATHER",
		value = `{Emoji} {Event}\nEnds: <t:{EndTime}:R>`,
		inline = true
	}})
end)


--// Receive Stock Updates
DataStream.OnClientEvent:Connect(function(Type: string, Profile: string, Data: table)
	if Type ~= "UpdateData" then return end
	if not Profile:find(LocalPlayer.Name) then return end

	for Name, Layout in GetConfigValue("AlertLayouts") do
		ProcessPacket(Data, Name, Layout)
	end
end)

--// Anti-AFK
LocalPlayer.Idled:Connect(function()
	if not GetConfigValue("Anti-AFK") then return end
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

--// Auto-Reconnect
GuiService.ErrorMessageChanged:Connect(function()
	if not GetConfigValue("Auto-Reconnect") then return end

	local isSolo = #Players:GetPlayers() <= 1
	local placeId = game.PlaceId
	local jobId = game.JobId

	queue_on_teleport("https://rawscripts.net/raw/Grow-a-Garden-Grow-a-Garden-Stock-bot-41500")

	if isSolo then
		TeleportService:Teleport(placeId, LocalPlayer)
	else
		TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
	end
end)

--// Enable Rendering Option
RunService:Set3dRenderingEnabled(GetConfigValue("Rendering Enabled"))
