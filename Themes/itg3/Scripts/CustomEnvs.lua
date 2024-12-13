function OptionHitSounds()
	local Values = {}
	for i = 1,11 do Values[i] = ((i-1)*0.1) end

	local Names = {"SILENT"}
	for i = 2,11 do Names[i] = string.format("%d",(Values[i]*100)).."%" end

	local t = {
		Name = "HitSoundsOptions",
		LayoutType = "ShowAllInRow",
		SelectType = "SelectOne",
		OneChoiceForAllPlayers = false,
		ExportOnChange = false,
		Choices = Names,

		LoadSelections = function(self, list, pn)
			local type = GAMESTATE:GetEnv("P"..tostring(pn+1).."HitSounds") 
			if not type then list[9] = true return end

			for i=1,11 do
				if tonumber(type) == Values[i] then list[i] = true return end
			end
		end,
		
		SaveSelections = function(self, list, pn)
			for i=1,11 do
				if list[i] then
					GAMESTATE:SetEnv("P"..tostring(pn+1).."HitSounds",Values[i]) 
					return
				end
			end
		end
		
	}
	setmetatable(t, t)
	return t
end

function GetOptionHitSounds(pn)
	local p = tostring(pn+1)
	if GAMESTATE:PlayerUsingBothSides() then
		if GAMESTATE:IsPlayerEnabled(0) then
			p = "1"
		else
			p = "2"
		end
	end

	local type = GAMESTATE:GetEnv("P"..p.."HitSounds")
	if type ~= nil then
	return tonumber(type) else
	return tonumber(0.8)
	end
end