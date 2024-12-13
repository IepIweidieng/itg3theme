--[[
OpenITG resolution switcher, version 1.1
Licensed under Creative Commons Attribution-Share Alike 3.0 Unported
(http://creativecommons.org/licenses/by-sa/3.0/)

These probably won't work unless they're used on the same screen. You've been warned.

Written by Mark Cannon ("Vyhd") for OpenITG (http://www.boxorroxors.net/)
All I ask is that you keep this notice intact and don't redistribute in bytecode.
--]]

-- used in a few places, so we keep it here.
-- checks to see if two floats are equal, within error
local function fequ( f1, f2, error )
	if not f1 or not f2 then return nil end
	local error = error or 0.01
	local absolute_diff = math.abs(f1 - f2)
	return absolute_diff < error
end

-- Ratio is pre-declared in order to avoid drifting due to
-- saving badly-rounded floats over time. Possibly paranoia,
-- but this will save us some headaches regardless.
local Resolutions =
{
	["9:16"] =
	{
		Ratio = 0.5625,
		Res = { "480x848", "480x854", "540x960", "576x1024", "600x1024", "720x1280", "768x1360", "768x1366", "900x1600", "1000x1776", "1080x1920", "1152x2048", "1440x2560" },
	},

	["10:16"] =
	{
		Ratio = 0.625,
		Res = { "480x720", "480x768", "600x1000", "640x1024", "720x1152", "800x1280", "900x1440", "1024x1600", "1050x1680", "1200x1920", "1280x2048", "1440x2304", "1600x2560" },
	},

	["3:4"] =
	{
		Ratio = 0.75,
		Res = { "384x512", "480x640", "600x800", "720x960", "768x1024", "864x1152", "960x1280", "1050x1400", "1080x1440", "1200x1600", "1344x1792", "1392x1856", "1440x1920", "1536x2048", "1728x2304", "1920x2560" },
	},

	["1:1"] =
	{
		Ratio = 1,
		Res = { "1024x1024", "1080x1080", "1280x1280", "1600x1600", "1920x1920", "2048x2048", "2560x2560" },
	},

	["5:4"] =
	{
		Ratio = 1.25,
		Res = { "600x480", "1280x1024", "1800x1440", "2560x2048" },
	},

	["5:3"] =
	{
		Ratio = 1.666666,
		Res = { "800x480", "1280x768" },
	},

	["4:3"] =
	{
		Ratio = 1.333333,
		Res = { "512x384", "640x480", "800x600", "960x720", "1024x768", "1152x864", "1280x960", "1400x1050", "1440x1080", "1600x1200", "1792x1344", "1856x1392", "1920x1440", "2048x1536", "2304x1728", "2560x1920" },
	},

	["3:2"] =
	{
		Ratio = 1.5,
		Res = { "960x640", "1920x1280", "2560x1700" },
	},

	["16:10"] =
	{
		Ratio = 1.6,
		Res = { "720x480", "768x480", "1000x600", "1024x640", "1152x720", "1280x800", "1440x900", "1600x1024", "1680x1050", "1920x1200", "2048x1280", "2304x1440", "2560x1600" },
	},

	["16:9"] =
	{
		Ratio = 1.777777,
		Res = { "848x480", "854x480", "960x540", "1024x576", "1024x600", "1280x720", "1360x768", "1366x768", "1600x900", "1776x1000", "1920x1080", "2048x1152", "2560x1440" },
	},

	["8:3"] =
	{
		Ratio = 2.666666,
		Res = { "640x240" },
	},
}

local Resolutions_lookup = {}
for k,v in pairs(Resolutions) do table.insert(Resolutions_lookup, k) end
table.sort(Resolutions_lookup, function(lhs, rhs) return Resolutions[lhs].Ratio < Resolutions[rhs].Ratio end)

-- Width, then height. "640x480" -> 640, 480
local function SplitResolution( res )
	-- part before "x" is the width in pixels, part after is height in pixels
	local delim_pos = string.find( res, "x" )
	local width = tonumber( string.sub(res,1,delim_pos-1) )
	local height = tonumber( string.sub(res,delim_pos+1) )
	return width, height
end

-- returns the float value associated with the given ratio
local function RatioToFloat( ratio )
	return tonumber(Resolutions[ratio].Ratio)
end

-- returns the table key that best matches the given ratio
local function FloatToRatio( float )
	for key,tbl in pairs(Resolutions) do
		if fequ( tbl.Ratio, float ) then return key end
	end

	return nil
end

-- holds the aspect ratio that the system will have once everything's set
local temp_ratio = FloatToRatio( PREFSMAN:GetPreference("DisplayAspectRatio") )
local temp_float = RatioToFloat( temp_ratio )

-- This function only sets a temporary ratio for the other table to pick up on
function LuaSetAspectRatio()	
	-- build from all the key values of Resolutions
	local Names = Resolutions_lookup
	
	local function Load(self, list, pn)
		local default = 1
		for i=1,table.getn(Names) do
			if fequ(temp_float, RatioToFloat(Names[i])) then list[i] = true return end
			if Names[i] == "4:3" then default = i end
		end
	
		list[default] = true;	-- default to 4:3
	end

	local function Save(self, list, pn)
		for i=1,table.getn(Names) do
			if list[i] then
				if not fequ(ratio,temp_float) then
					temp_ratio = Names[i]
					temp_float = RatioToFloat( temp_ratio )
					MESSAGEMAN:Broadcast( "AspectRatioChanged" )
					return
				end
			end
		end
	end

	local Params =
	{
		Name = "AspectRatio",
		LayoutType = "ShowAllInRow",
		ExportOnChange = true,
	}

	return CreateOptionRow( Params, Names, Load, Save )
end

function LuaSetResolution( index )
	local ratio = Resolutions_lookup[index]

	-- Fill in with the values names of the appropriate Resolutions table
	local Names = {}
	if ratio then
		for i=1,table.getn(Resolutions[ratio].Res) do table.insert(Names, "  "..Resolutions[ratio].Res[i].."  ") end
	else
		Names = { "" }
	end

	local curwidth = PREFSMAN:GetPreference( "DisplayWidth" )
	local curheight = PREFSMAN:GetPreference( "DisplayHeight" )

	local function Load(self, list, pn)
		if not ratio then return end

		for i=1,table.getn(Names) do
			local width, height = SplitResolution( string.gsub(Names[i], " ", "") )

			-- just find the closest match here...
			if width == curwidth or height == curheight then list[i] = true return end
		end

		-- fallback value: smallest one
		list[1] = true
	end

	local function Save(self, list, pn)
		for i=1,table.getn(Names) do
			if list[i] then
				-- make sure we're the right one being selected
				if ratio ~= temp_ratio then return end

				local width, height = SplitResolution( string.gsub(Names[i], " ", "") )

				-- set the new preferences
				PREFSMAN:SetPreference( "DisplayWidth", width )
				PREFSMAN:SetPreference( "DisplayHeight", height )
				PREFSMAN:SetPreference( "DisplayAspectRatio", Resolutions[ratio].Ratio )
				Debug( "New resolution: " .. width .. "x" .. height .. ", ratio " .. Resolutions[ratio].Ratio )

				GAMESTATE:DelayedGameCommand( "reloadtheme" )
			end
		end
	end

	local Params =
	{
		Name = "DisplayResolution",
		LayoutType = "ShowOneInRow",
		SelectType = ratio and "SelectOne" or "SelectMultiple",

		-- disable this line if it isn't used for the current ratio
		EnabledForPlayers = ratio and fequ(RatioToFloat(ratio),temp_float) and {PLAYER_1,PLAYER_2} or {},
		ReloadRowMessages = { "AspectRatioChanged" },
	};

	return CreateOptionRow( Params, Names, Load, Save )
end
