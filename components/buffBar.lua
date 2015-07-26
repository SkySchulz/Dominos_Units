local bar = _G[...]local modName = ...--Buff Barlocal component = bar:NewComponent('buffs', 'Frame')function component:New(parent)	local name = ('%s_%s_BuffBar'):format(modName, parent.id)	if _G[name] then		return _G[name]	end	local bar = self:Bind(CreateFrame('Frame', name, parent.box))	bar.owner = parent	bar.drop = bar.drop or CreateFrame('Frame', nil, bar)--	bar.drop:SetFrameLevel(bar:GetFrameLevel()-1)	bar.drop:SetAllPoints(bar)	bar.filter = 'HELPFUL'	bar.kind = 'buff'	return barendcomponent.defaults = {	columns = 6,	scale = 76,	rows = 3,	alpha = 100,	y = 89,	x = 0,	isLeftToRight = true,	spacing = 0,	anchor = 'Bottom',	enable = false,	showBG = false,	isTopToBottom = false,	color = {		a = 1,		r = 0,		g = 0,		b = 0,	},	sort = 'Duration',}function component:Load()	self:SetAttribute('unit', self.owner.id)	self:SetAttribute('filter', self.filter)	self:EnableMouse(false)	self.noMouse = true	self.id = self.owner.id	self.icons = self.icons or {}	self.total = self.total or 0endfunction component:Layout()	local sets = self.sets	if sets.enable ~=true then		self:Hide()		self.noUpdate = true		return	else		self:Show()		self.noUpdate = nil	end	self:ClearAllPoints()	local x = sets.x/(sets.scale/100)	local y = sets.y/(sets.scale/100)	self:SetPoint(sets.anchor, self:GetParent(), x, y)	if sets.scale < 25 then		sets.scale = sets.scale *100	end	self:SetScale(sets.scale/100)	self:SetAlpha(sets.alpha/100)	for i = 1, sets.rows * sets.columns do		self:GetOrCreateIcon(i)	end			local w, h = self.icons[1]:GetSize()	w, h =  w + sets.spacing,  h + sets.spacing			local newWidth =  w * sets.columns - sets.spacing	local newHeight = h * sets.rows    - sets.spacing	self:SetSize(newWidth, newHeight)	local cols, rows = sets.columns, sets.rows	local isLeftToRight = sets.isLeftToRight	local isTopToBottom = sets.isTopToBottom			for i, icon in pairs(self.icons) do		local col, row = (cols-1) - (i-1) % cols, rows - ceil(i / cols)		if isLeftToRight then			col = (i-1) % cols		end		if isTopToBottom then			row = ceil(i / cols) - 1		end		icon:ClearAllPoints()		icon:SetPoint('TOPLEFT', w*col, -(h*row))		icon:Show()	end	if sets.showBG then		self.drop:SetBackdrop(self.bg)		self.drop:SetBackdropColor(self.sets.color.r, self.sets.color.g, self.sets.color.b, self.sets.color.a)	else		self.drop:SetBackdrop(nil)	endendfunction component:Update(elapsed)	if self.sets.enable ~= true then		return	end	self:GetAuras()	self:DisplayOrder()	self:UpdateTooltip()endfunction component:GetAuras()	local numDisplayed = self.sets.columns * self.sets.rows	self.auras = self.auras or {}	wipe(self.auras)	local i = 1	while i do		local name, _, icon, count, debuffType, remaining, expiration = UnitAura(self.id, i, self.filter)		if name then			tinsert(self.auras, {name, icon, count, expiration, remaining, i,})			i = i + 1		else			i = nil		end	endendfunction component:DisplayOrder()	for i, icon in pairs(self.icons) do --clear any unused icons.		if i > #self.auras then			self:ClearIcon(icon)		end	end	if self.sets.sort == 'Duration' then		table.sort(self.auras,	function(a, b)			local A, B = a[5], b[5]			if A == 0 then--durations of 0 are considered 'infinite' for sorting purposes				A = 1000000000000000000000000			end			if B == 0 then				B = 1000000000000000000000000			end			return A < B		end)	elseif self.sets.sort == 'Alphabetical' then		table.sort(self.auras,	function(a, b)			return a[1] < b[1]		end)	end	if self.sets.reverse then		local reversedTable = {}		local itemCount = #self.auras		for k, v in ipairs(self.auras) do			reversedTable[itemCount + 1 - k] = v		end		self.auras = reversedTable	end	local numDisplayed = self.sets.columns * self.sets.rows	for i, info in pairs(self.auras) do --update displayable auras		if i <= (numDisplayed) then			self:SetIcon(i, unpack(info))		end	endendfunction component:UpdateTooltip()	local hasMouse	for i, b in pairs(self.icons) do		if self.auras[i] then			if MouseIsOver(b) then				hasMouse = true				GameTooltip:SetOwner(self)				GameTooltip:SetUnitAura(self.id, self.auras[i][6], self.filter)				GameTooltip:ClearAllPoints()				GameTooltip:SetPoint('BottomRight', b, 'TopLeft')				break			end		end	end	if hasMouse ~= true then		if GameTooltip:GetOwner() == self then			GameTooltip:Hide()		end	endendfunction component:GetOrCreateIcon(i)	local t = self.icons[i] or self:CreateTexture(self:GetName()..self.kind..i, 'ARTWORK')	if not self.icons[i] then		self.icons[i] = t		t:SetSize(32, 32)		t.cooldown = CreateFrame('Cooldown', t:GetName()..'Cooldown', self, 'CooldownFrameTemplate')		t.cooldown:SetAllPoints(t)		t.count = self:CreateFontString(t:GetName()..'Count', 'OVERLAY', 'GameFontNormal')		t.count:SetPoint('BottomRight', t)		t.isShown = nil		t.index = i	end	return tendfunction component:ClearIcons()endfunction component:SetIcon(i, name, image, count, expiration, remaining)	local icon = self:GetOrCreateIcon(i)	if icon.lastImage ~= image then --only make a change, if there is a change.		icon.lastImage = image		icon:SetTexture(image)		icon:SetTexCoord(.1,.9,.1,.9)	end	if (icon.lastExpiration ~= expiration) then		icon.lastExpiration = expiration		CooldownFrame_SetTimer(icon.cooldown, expiration - remaining, remaining, 1)	end	if icon.lastCount ~= count then		icon.lastCount = count		if count == 0 then			count = ''		end		icon.count:SetText(count)	end	icon.empty = nilendfunction component:ClearIcon(icon)	if not icon.empty then --don't clear if it's already clear.		icon.empty = true		icon.lastImage = nil		icon:SetTexture('')		icon.lastCount = nil		icon.count:SetText('')		icon.lastExpiration = nil		icon.cooldown:Hide()	endendcomponent.bg = {	bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',	insets = {left = 0, right = 0, top = 0, bottom = 0},	tile = false,}local anchors = {	'TopLeft',	'Top',	'TopRight',	'Right',	'BottomRight',	'Bottom',	'BottomLeft',	'Left',	'Center',}local layers = {	'BACKGROUND',	'LOW',	'MEDIUM',	'HIGH',	'DIALOG',	'FULLSCREEN',	'FULLSCREEN_DIALOG',	'TOOLTIP',}local options = {	{		name = 'Anchor',		kind = 'Menu',		key = 'anchor',		table = anchors,	},	{		name = 'Enable',		kind = 'CheckButton',		key = 'enable',	},	{		name = 'Sort',		kind = 'Menu',		key = 'sort',		table = {			'Duration',			'Alphabetical',			'Normal',		},	},	{		name = 'Reverse',		kind = 'CheckButton',		key = 'reverse',	},	{		name = 'isTopToBottom',		kind = 'CheckButton',		key = 'isTopToBottom',	},	{		name = 'isLeftToRight',		kind = 'CheckButton',		key = 'isLeftToRight',	},	{		name = 'Backdrop',		kind = 'CheckButton',		key = 'showBG',	},	{		name = 'Backdrop Color',		kind = 'ColorPicker',		key = 'color',	},	{		name = 'X Offset',		kind = 'Slider',		key = 'x',		min = -450,		max = 450,	},	{		name = 'Y Offset',		kind = 'Slider',		key = 'y',		min = -450,		max = 450,	},	{		name = 'Columns',		kind = 'Slider',		key = 'columns',		min = 1,		max = 10,	},	{		name = 'Rows',		kind = 'Slider',		key = 'rows',		min = 1,		max = 10,	},	{		name = 'Spacing',		kind = 'Slider',		key = 'spacing',		min = -13,		max = 30,	},	{		name = 'Scale',		kind = 'Slider',		key = 'scale',		min = 25,		max = 250,	},	{		name = 'Opacity',		kind = 'Slider',		key = 'alpha',		min = 0,		max = 100,	},	}function component:CreateMenu(menu)	return bar.Menu.NewPanel(menu, 'Buffs', options)end