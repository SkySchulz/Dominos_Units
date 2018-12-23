local Addon = _G[...]do --simple way to hide UI elements	Addon.HIDER = CreateFrame("Frame")	Addon.HIDER:Hide()enddo --Prevents a frame being made for a unit that can't exist.	local baseUnits = {		'player',		'target',		'playerpet',		'focus',		'arena%d+',		'boss%d+',		'party%d+',		'partypet%d+',		'raid%d+',		'raidpet%d+',		'mouseover',		'nameplate%d+',	}	local maxUnits = {		raid = 40,		raidpet = 40,		arena = 4,		boss = 4,		party = 4,		partypet = 4,	}	local function IsUnitValid(unit, u)		local keep = u or unit		unit = string.lower(u or unit)		local count = 0		if string.match (unit, 'target' , 2) then			_, count = string.gsub(string.sub (unit, 2, string.len(unit)), 'target', '')			if ((unit == 'player') and count > 0) or (count > 5) then				return nil			else				unit = string.gsub (unit, 'target', '', count)			end		end		for i, unitString in pairs(baseUnits) do			if string.match(unit, unitString) then				local base = string.gsub(unit, '%d+', '')				local num = string.gsub(unit, base, '')				local extra = string.gsub(unit, num, '')				if extra == base then					local Max = maxUnits[base]					if (not Max) or (Max and (Max >= tonumber(num))) then 						return string.lower(keep)					end				end			end		end	end	Addon.IsUnitValid = IsUnitValidenddo --slash Commands	local frames = Addon.frames	local commands = Addon.master:GetModule('SlashCommands')	local oldOnCmd = commands.OnCmd		local pauseDelay = CreateFrame("Frame")	function pauseDelay:ResetLock()		if Addon.master.locked == true then		local _time = GetTime()			pauseDelay:SetScript("OnUpdate", function()				local t = (GetTime() - _time)				if t >= .23 then					Addon.master:GetModule('ConfigOverlay'):Hide()					Addon.master.locked = nil					pauseDelay:SetScript("OnUpdate", nil)				end			end)		end	end	Addon.pauseDelay = pauseDelay		local cmds = {		new = function(unit)			unit = string.lower(unit)			if not Addon:IsUnitValid(unit) then				return print('invalid unit! :( ', unit)			end			local UNIT = unit			Addon.frames[UNIT] = Addon.frames[UNIT] or Addon:New(unit)			Addon.frames[UNIT]:Reload()			Addon.frames[UNIT]:Restore()			Addon.frames[UNIT]:Show()			Addon.frames[UNIT]:Layout()			Addon.frames[UNIT]:EnableMouse(true)			if LibStub and LibStub('LibKeyBound-1.0') then				LibStub('LibKeyBound-1.0'):Deactivate()			end			pauseDelay:ResetLock()			Addon.master.db.profile.units.frames[unit] = true		end,		delete = function(unit)			unit = string.lower(unit)			local UNIT = unit			if unit == "vehicle" then				UNIT = string.upper(unit)			end			if frames[UNIT] then				frames[UNIT]:Delete()			end			pauseDelay:ResetLock()		end,		show = function (arg)			if _G[arg] then				Addon.getSets().hide[arg] = nil				_G[arg]:SetParent(_G[arg].par_ent)			end		end,		hide = function (arg)			if _G[arg] and not (Addon.getSets().hide[arg]) then				Addon.getSets().hide[arg] = true				_G[arg].par_ent = _G[arg].par_ent or _G[arg]:GetParent()				_G[arg]:SetParent(Addon.HIDER)				print(arg, "hidden")			end		end,		copy = function(copy)			local enabled = Addon:getSets()			local files = Addon.Profiles.GetCopyProfiles()			local toCopy = files[copy]			if not toCopy then				return			end			enabled.frames = {}			local active = Addon.Profiles:GetActiveProfile()			active.units.frames = {}			for unit, sets in pairs(toCopy) do				active.units.frames[unit] = true				active.frames[unit] = CopyTable(sets)			end						Addon:UnloadAll()			Addon:LoadAll()				if LibStub and LibStub('LibKeyBound-1.0') then					LibStub('LibKeyBound-1.0'):Deactivate()				end				pauseDelay:ResetLock()		end		}	function commands:OnCmd(message)		local arg1, arg2, arg3  = string.split(' ', message)		if arg1:lower() == 'unit' then			if cmds[arg2:lower()] then				cmds[arg2:lower()](arg3)			end			return		end		oldOnCmd(self, message)	endenddo --table manipulation	local function Copy(source, destination, looped, blackList)		destination = destination or {}		if not source then return end		for key, value in pairs(source) do			if (type(value) == 'table') then				destination[key] = Copy(value, destination[key], true, blackList)			else				if (not looped) and (blackList and blackList[key]) then									else					destination[key] = value				end			end		end		return destination	end	Addon.Copy = Copy		local function Blend(source, destination)		destination = destination or {}		if not source then			return destination		end		for key, value in pairs(CopyTable(source)) do			if (type(value) == 'table') then				if type(key) == "number" then					local index = #destination + 1					destination[index] = Blend(value, destination[index])				else					destination[key] = Blend(value, destination[key])				end			else				destination[key] = destination[key] or value			end		end		return destination	end	Addon.Blend = Blend	local function Merge(source, destination, looped, blackList)		destination = destination or {}		if not source then			return destination		end		for key, value in pairs(CopyTable(source)) do			if (type(value) == 'table') then				if type(key) == "number" then					local index = #destination + 1					destination[index] = Merge(value, destination[index], true, blackList)				else					destination[key] = Merge(value, destination[key], true, blackList)				end			else				if (not looped) and (blackList and blackList[key]) then									else					destination[key] = value				end			end		end		return destination	end	Addon.Merge = Merge		local function check(source, target)		--you may now add new defaults at will. ~Goranaws		if not target then 			target = {}		end		if not source then			--return		end		for key, value in pairs(source) do			if type(value) == 'table' then				target[key] = check(value, target[key])			else				if (type(value) == 'boolean') then					if target[key] == nil then						target[key] = value					end				else					--target[key] = target[key] or value				end			end		end		return target	end	Addon.check = checkenddo -- returns a function that generates unique names for frames	-- in the format <AddonName>_<Prefix>[1, 2, ...]	do		local generators = {		}		function Addon:CreateNameGenerator(prefix)			if generators[prefix] then				return generators[prefix]			end			local id = 0			local func =  function()				id = id + 1				return ('%s_%s_%d'):format('DominosUnitsOptions', prefix, id)			end			generators[prefix] = func			return func		end		end	do		local generators = {}		function Addon:CreateWidgetNameGenerator(prefix)		if generators[prefix] then			return generators[prefix]		end		local id = 0		local func =  function()			id = id + 1			return ('%s_%s_%d'):format('DominosUnits', prefix, id)		end		generators[prefix] = func		return func	end	endenddo -- extra textures	local lib = Addon.lib	Addon.statusbarTextures = {		ArcHUD = [[Interface\AddOns\Dominos_Units\textures\ArcHUD.tga]],		ArcHUD2 = [[Interface\AddOns\Dominos_Units\textures\ArcHUD2.tga]],		Bar = [[Interface\AddOns\Dominos_Units\textures\Bar.tga]],		Bar2 = [[Interface\AddOns\Dominos_Units\textures\Bar2.tga]],		BloodGlaives = [[Interface\AddOns\Dominos_Units\textures\BloodGlaives.tga]],		BloodGlaives2 = [[Interface\AddOns\Dominos_Units\textures\BloodGlaives2.tga]],		CleanCurves = [[Interface\AddOns\Dominos_Units\textures\CleanCurves.tga]],		CleanCurves2 = [[Interface\AddOns\Dominos_Units\textures\CleanCurves2.tga]],		CleanCurvesOut = [[Interface\AddOns\Dominos_Units\textures\CleanCurvesOut.tga]],		CleanCurvesOut2 = [[Interface\AddOns\Dominos_Units\textures\CleanCurvesOut2.tga]],		CleanTank = [[Interface\AddOns\Dominos_Units\textures\CleanTank.tga]],		CleanTank2 = [[Interface\AddOns\Dominos_Units\textures\CleanTank2.tga]],		ColorBar = [[Interface\AddOns\Dominos_Units\textures\ColorBar.tga]],		ColorBar2 = [[Interface\AddOns\Dominos_Units\textures\ColorBar2.tga]],		ComboCleanCurves = [[Interface\AddOns\Dominos_Units\textures\ComboCleanCurves.blp]],		DHUD = [[Interface\AddOns\Dominos_Units\textures\DHUD.tga]],		DHUD2 = [[Interface\AddOns\Dominos_Units\textures\DHUD2.tga]],		FangRune = [[Interface\AddOns\Dominos_Units\textures\FangRune.tga]],		FangRune2 = [[Interface\AddOns\Dominos_Units\textures\FangRune2.tga]],		GemTank = [[Interface\AddOns\Dominos_Units\textures\GemTank.tga]],		GlowArc = [[Interface\AddOns\Dominos_Units\textures\GlowArc.tga]],		GlowArc2 = [[Interface\AddOns\Dominos_Units\textures\GlowArc2.tga]],		HiBar = [[Interface\AddOns\Dominos_Units\textures\HiBar.tga]],		HiBar2 = [[Interface\AddOns\Dominos_Units\textures\HiBar2.tga]],		PillTank = [[Interface\AddOns\Dominos_Units\textures\PillTank.tga]],		RivetBar = [[Interface\AddOns\Dominos_Units\textures\RivetBar.tga]],		RivetBar2 = [[Interface\AddOns\Dominos_Units\textures\RivetBar2.tga]],		RoundBar = [[Interface\AddOns\Dominos_Units\textures\RoundBar.tga]],		RoundBar2 = [[Interface\AddOns\Dominos_Units\textures\RoundBar2.tga]],		RuneBar = [[Interface\AddOns\Dominos_Units\textures\RuneBar.tga]],		RuneBar2 = [[Interface\AddOns\Dominos_Units\textures\RuneBar2.tga]],		Druid = [[Interface\addons\Dominos_Units\textures\statusbar\Druid_Horizontal_Fill.tga]],		Darkmoon = [[Interface\addons\Dominos_Units\textures\statusbar\Darkmoon_Horizontal_Fill.tga]],		["Bullet Bar"] = [[Interface\addons\Dominos_Units\textures\statusbar\BulletBar_Horizontal_Fill.tga]],		["Brewing Storm"] = [[Interface\addons\Dominos_Units\textures\statusbar\BrewingStorm_Horizontal_Fill.tga]],		Arsenal = [[Interface\addons\Dominos_Units\textures\statusbar\Arsenal_Horizontal_Fill.tga]],		Amber = [[Interface\addons\Dominos_Units\textures\statusbar\Amber_Horizontal_Fill.tga]],		["Twin Ogron"] = [[Interface\addons\Dominos_Units\textures\statusbar\TwinOgronDistance_Horizontal_Fill.tga]],		Thunderking = [[Interface\addons\Dominos_Units\textures\statusbar\Thunderking_Horizontal_Fill.tga]],		["Stone Guard"] = [[Interface\addons\Dominos_Units\textures\statusbar\StoneGuard_Horizontal_Fill.tga]],		Rhyolith = [[Interface\addons\Dominos_Units\textures\statusbar\Rhyolith_Horizontal_Fill.tga]],		Pride = [[Interface\addons\Dominos_Units\textures\statusbar\Pride_Horizontal_Fill.tga]],		Onyxia = [[Interface\addons\Dominos_Units\textures\statusbar\Onyxia_Horizontal_Fill.tga]],		Lightning = [[Interface\addons\Dominos_Units\textures\statusbar\Lightning_Horizontal_Fill.tga]],		Player = [[Interface\addons\Dominos_Units\textures\statusbar\Generic1Player_Horizontal_Fill.tga]],		["Fuel Guage"] = [[Interface\addons\Dominos_Units\textures\statusbar\FuelGaugeOrange_Horizontal_Fill.tga]],		["Fel Breaker"] = [[Interface\addons\Dominos_Units\textures\statusbar\FelBreakerCaptainShield_Horizontal_Fill.tga]],		["Fel Corruption"] = [[Interface\addons\Dominos_Units\textures\statusbar\FelCorruption_Horizontal_Fill.tga]],	}	for textureName, texturePath in pairs(Addon.statusbarTextures) do		if not lib.MediaTable.statusbar[textureName] then			lib.MediaTable.statusbar[textureName] = texturePath		end	end		local source = [[Interface\addons\Dominos_Units\textures\castBar\]]	local z = [[.blp]]	local castBorders = {		['Skills'] = [[UI-Character-Skills-BarBorder]],		['Skills Highlight'] = [[UI-Character-Skills-BarBorderHighlight]],		['Spec Lock'] = [[spec-lock]],		['StatusBar'] = [[UI-StatusBar-Border]],		['Air'] = [[Air_Horizontal_Frame]],		['Ice'] = [[Ice_Horizontal_Frame]],		['Alliance'] = [[Alliance_Horizontal_Frame]],		['Alliance or'] = [[Alliance50_Horizontal_Frame]],		['Amber'] = [[Amber_Horizontal_Frame]],		['Bamboo'] = [[Bamboo_Horizontal_Frame]],		['Brewing Storm'] = [[BrewingStorm_Horizontal_Frame]],		['Bullet Bar'] = [[BulletBar_Horizontal_Flash]],		['Druid'] = [[Druid_Horizontal_Frame]],		['Fancy Panda'] = [[FancyPanda_Horizontal_Frame]],		['Fire'] = [[Fire_Horizontal_Frame]],		['Fuel Gauge'] = [[FuelGauge_Horizontal_Frame]],		['Party'] = [[Generic1Party_Horizontal_Frame]],		['Player'] = [[Generic1Player_Horizontal_Frame]],		['Target'] = [[Generic1Target_Horizontal_Frame]],		['Horde'] = [[Horde_Horizontal_Frame]],		['Horde 50'] = [[Horde50_Horizontal_Frame]],		['Wow'] = [[WowUI_Horizontal_Frame]],		['Meat'] = [[Meat_Horizontal_Frame]],		['Mechanical'] = [[Mechanical_Horizontal_Frame]],		['Bronze'] = [[MetalBronze_Horizontal_Frame]],		['Eternium'] = [[MetalEternium_Horizontal_Frame]],		['Gold'] = [[MetalGold_Horizontal_Frame]],		['Plain'] = [[MetalPlain_Horizontal_Frame]],		['Rusted'] = [[MetalRusted_Horizontal_Frame]],		['Molten Rock'] = [[MoltenRock_Horizontal_Frame]],		['Onyxia'] = [[Onyxia_Horizontal_Frame]],		['Pride'] = [[Pride_Horizontal_Frame]],		['Rock'] = [[Rock_Horizontal_Frame]],		['Stone Diamond'] = [[StoneDiamond_Horizontal_Frame]],		['Stone Guard Amethyst'] = [[StoneGuardAmethyst_Horizontal_Frame]],		['Stone Tan'] = [[StoneTan_Horizontal_Frame]],		['Thunderking'] = [[Thunderking_Horizontal_Frame]],		['Undead Meat'] = [[UndeadMeat_Horizontal_Frame]],		['WoodBoards'] = [[WoodBoards_Horizontal_Frame]],		['Wood Plank'] = [[WoodPlank_Horizontal_Frame]],		['Wood with Metal'] = [[WoodwithMetal_Horizontal_Frame]],		['Border'] = [[UI-CastingBar-Border]],		['Border Small'] = [[UI-CastingBar-Border-Small]],		["Threat"] =  [[Threat]]	}			Addon.lib.MediaType.CASTBORDER = Addon.lib.MediaType.CASTBORDER or  {}		Addon.lib.MediaTable.castborder =  Addon.lib.MediaTable.castborder or {}	local o = Addon.lib.MediaTable.castborder		for i, b in pairs(castBorders) do		o[i] = source..b..".tga"	endend