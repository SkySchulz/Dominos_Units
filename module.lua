local bar = _G[...]local mod = bar.master:NewModule('Frame')local enabledFrames = {}local defaults  = {	frames = {		player = true,		target = true,		targettarget = true,		focus = true,		focustarget = true,		playerpet = true,	},	hide = {		PlayerFrame = true,		TargetFrame = true,		FocusFrame = true,	}}local function getSets()	bar.master.db.profile.units = bar.master.db.profile.units or defaults	bar.master.db.profile.units.hide = bar.master.db.profile.units.hide or bar.master.db.profile.units.disable or {		PlayerFrame = true,		TargetFrame = true,		FocusFrame = true,	}	return bar.master.db.profile.unitsendbar.getSets = getSetslocal def = {			scale = 1,			showInOverrideUI = false,			showInPetBattleUI = false,			point = 'Center',			padW = 3,			width = 232,			y = 0,			x = 0,			padH = 3,			height = 100,			focus = {				x = -42,				y = -12,				anchor = 'TopRight',			},			power = {				anchor = 'TopRight',				x = -106,				y = -52,				height = 12,				width = (119/232)*100,			},			health = {				anchor = 'TopRight',				x = -106,				y = -41,				height = 12,				width = (119/232)*100,			},			focus = {				x = -42,				y = -12,				anchor = 'TopRight',			},			name = {				width = 100,				height = 12,				anchor = 'Center',				x = -50,				y = 19,				justifyH = 2,			},			icons = {				width = 45,				height = 45,				style = 'ROUND',				scale = 130,				anchor = 'Right',				angle  = 313,				x = -45,				y = 2,				IsTopToBottom = true,				IsLeftToRight = false,			},			level = {				anchor = 'Center',				x = 63,				y = -16,				justifyH = 2,							},			background = {				anchor = 'TopRight',				x = -106,				y = -22,				width = (119/232)*100,				height = 41,				color = {						r = 0,						g = 0,						b = 0,						a = .5, 				}			},						buffs = {				enable = true,				anchor = 'BottomLeft',				x = 12,				y = 6,				scale = 64,				rows = 1,			},			debuffs = {				enable = true,			},			cast = {					frameLevel = 2,				frameLayer = 4,				scale = 100,				alpha = 100,				width = 117,				y = 17,				x = 7,				anchor = 'Left',				height = 16,				enable = true,				showBG = false,				textheight = 12,			},		}function mod:OnInitialize()	bar.master.db.profile.units = bar.master.db.profile.units or defaults	bar.unitLayouts = nil	bar.unitLayouts = {Default = bar:GetDefaults()}endfunction mod:Load()	wipe(enabledFrames)	for unit, b in pairs(getSets().frames) do		unit = string.lower(unit)		local frame = bar:New(unit)		bar.unitLayouts[unit] = frame.sets		tinsert(enabledFrames, frame)	end		for frameName, b in pairs(getSets().hide) do		if frameName and _G[frameName] then			_G[frameName]:SetParent(MainMenuBarArtFrame)		end	endendfunction mod:Unload()	if enabledFrames then		for i, frame in pairs(enabledFrames) do			bar.master.Frame:ForFrame(frame.id, 'Free')		end	endend