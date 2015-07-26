local bar = _G[...]local modName = ...--Power Barlocal component = bar:NewComponent('power', 'StatusBar')function component:New(parent)	local name = ('%s_%s_PowerBar'):format(modName, parent.id)	if _G[name] then		return _G[name]	end	local bar = self:Bind(CreateFrame('StatusBar', name, parent.box, 'TextStatusBar'))	bar.owner = parent		bar:SetStatusBarTexture('Interface\\RaidFrame\\Raid-Bar-Hp-Fill', 'BORDER')	bar:SetStatusBarColor(0,1,0,1)	bar:SetBackdrop( {bgFile = 'Interface\\QUESTFRAME\\UI-TextBackground-BackdropBackground'})	bar:EnableMouse(false)	bar:Show()	bar:SetScript('OnEnter', nil)	bar.textHandler = CreateFrame('Frame', nil, bar)	bar.text = bar.text or bar.textHandler:CreateFontString(nil, 'OVERLAY', 'TextStatusBarText')	bar.text:SetTextColor(1.0,1.0,1.0)	bar.text:SetAllPoints(true)	bar.textHandler:SetAllPoints(true)	bar.textHandler:SetFrameLevel(70)	return barendcomponent.defaults = {	scale = 100,	height = 25,	justifyV = 'CENTER',	width = 100,	y = 0,	x = 0,	justifyH = 'CENTER',	drop = true,	anchor = 'Bottom',	enable = true,	percent = true,	alpha = 100,	textureName = 'Raid',	texturePath = 'Interface\\RaidFrame\\Raid-Bar-Hp-Fill',	format = 'percent',	mouseover = 'value',}function component:Layout()	local sets = self.sets	if sets.enable ~= true then		self:Hide()		self.noUpdate = true		return	else		self:Show()		self.noUpdate = nil	end	local sets = self.sets	self:Reposition()	self:Rescale()	local w, h = self:GetParent():GetSize()	local width, height = w*(sets.width/100), h*(sets.height/100)	self:SetSize(width, height)	self.text:SetJustifyH(sets.justifyH) -- Sets horizontal text justification ('LEFT','RIGHT', or 'CENTER')	self.text:SetJustifyV(sets.justifyV) -- Sets vertical   text justification ('TOP','BOTTOM', or 'MIDDLE')	self:SetAlpha(sets.alpha/100)	if sets.drop then		self:SetBackdrop( {bgFile = 'Interface\\QUESTFRAME\\UI-TextBackground-BackdropBackground'})	else		self:SetBackdrop(nil)	end		self:SetStatusBarTexture(self:GetMediaPath('statusbar', self.sets.textureName) or self.sets.texturePath)endlocal function FormatValue(value)	if (value <= 1000) then		return value	elseif (value <= 1000000) then		return ('%.1fk'):format(value / 1000);	elseif (value <= 1000000000) then		return ('%.2fm'):format(value / 1000000);	else		return ('%.2fg'):format(value / 1000000000);	endendlocal function FormatBarValues(value,max,type)	if (type == 'none') then		return ''	elseif (type == 'value') or (max == 0) then		return string.format('%s / %s',AbbreviateLargeNumbers(value),AbbreviateLargeNumbers(max))	elseif (type == 'current') then		return string.format('%s',AbbreviateLargeNumbers(value))	elseif (type == 'full') then		return string.format('%s / %s (%.0f%%)',FormatValue(value),FormatValue(max),value / max * 100)	elseif (type == 'deficit') then		if (value ~= max) then			return string.format('-%s',FormatValue(max - value))		else			return ''		end	elseif (type == 'percent') then		return string.format('%.0f%%',value / max * 100)	endendfunction component:Update()	if self.noUpdate then		return	end	local unit = self.owner.id	local max = UnitPowerMax(unit)	local current = UnitPower(unit)	local dead = UnitIsGhost(unit) or UnitIsDead(unit)	local sets = self.sets	if max == 0 or dead then		self:SetMinMaxValues(0, 1)		self:SetValue(0)		self.text:SetText('')		return	end 	self:SetMinMaxValues(0, max)	if self.sets.mouseover ~= 'none' and (MouseIsOver(self)) then		self.text:SetText(FormatBarValues(current, max, self.sets.mouseover))	else		self.text:SetText(FormatBarValues(current, max, self.sets.format))	end	self:SetValue(current)	local r, g, b	if ( not UnitIsConnected(unit)) then		r, g, b = 0.5, 0.5, 0.5	else		local powerType, powerToken, altR, altG, altB = UnitPowerType(unit)		local info = PowerBarColor[powerToken]		if ( info ) then			r, g, b = info.r, info.g, info.b		else			if ( not altR) then				info = PowerBarColor[powerType] or PowerBarColor['MANA']				r, g, b = info.r, info.g, info.b			else				r, g, b = altR, altG, altB			end		end	end	if dead then		r, g, b = r-.75, g-.75, b-.75	end	self:SetStatusBarColor(r, g, b)			endfunction component:Rescale()	self:SetScale(self.sets.scale/100)endfunction component:Reposition()	self:ClearAllPoints()	local x = self.sets.x/(self.sets.scale/100)	local y = self.sets.y/(self.sets.scale/100)	self:SetPoint(self.sets.anchor, self:GetParent(), x, y)endfunction component:GetMediaPath(kind, fileName)	if bar.lib then		self.sets.texturePath = bar.lib and bar.lib:Fetch(kind, fileName)	end	return (bar.lib and bar.lib:Fetch(kind, fileName))endlocal options = {	{		name = 'Enable',		kind = 'CheckButton',		key = 'enable',	},	{		name = 'Format',		kind = 'Menu',		key = 'format',		table = {			'none',			'value',			'current',			'full',			'deficit',			'percent',		},	},	{		name = 'MouseOver Format',		kind = 'Menu',		key = 'mouseover',		table = {			'none',			'value',			'current',			'full',			'deficit',			'percent',		},	},	{		name = 'Anchor',		kind = 'Menu',		key = 'anchor',		table = {			'TopLeft',			'Top',			'TopRight',			'Right',			'BottomRight',			'Bottom',			'BottomLeft',			'Left',			'Center',		},	},	{		name = 'Percent',		kind = 'CheckButton',		key = 'percent',	},	{		name = 'Backdrop',		kind = 'CheckButton',		key = 'drop',	},	{		name = 'Opacity',		kind = 'Slider',		key = 'alpha',		min = 0,		max = 100,	},	{		name = 'X Offset',		kind = 'Slider',		key = 'x',		min = -400,		max = 400,	},	{		name = 'Y Offset',		kind = 'Slider',		key = 'y',		min = -400,		max = 400,	},	{		name = 'Width',		kind = 'Slider',		key = 'width',		min = 5,		max = 250,	},	{		name = 'Height',		kind = 'Slider',		key = 'height',		min = 5,		max = 250,	},	{		name = 'Scale',		kind = 'Slider',		key = 'scale',		min = 25,		max = 250,	},	{		name = 'Texture',		kind = 'Media',		key = 'textureName',		mediaType = 'StatusBar',		handler = 'power',	},}function component:CreateMenu(menu)	return bar.Menu.NewPanel(menu, 'Power', options)end