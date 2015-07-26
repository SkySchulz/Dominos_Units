local bar = _G[...]local modName = ...--Status Icon Barlocal component = bar:NewComponent('icons', 'Frame')function component:New(parent)	local name = ('%s_%s_IconBar'):format(modName, parent.id)	if _G[name] then		return _G[name]	end	local frame = self:Bind(CreateFrame('Frame', name, parent.box))	frame:SetFrameLevel(200)	frame.owner = parent	return frameendcomponent.defaults = {	columns = 8,	scale = 81,	alpha = 100,	y = 72,	x =3,	isLeftToRight = true,	spacing = 0,	anchor = 'Bottom',	enable = true,	isTopToBottom = false,	angle = 0,	width = 100,	height = 100,	style = 'Bar',	compress = 0,	frameLayer = 2,}function component:Load()	self:SetAttribute('unit', self.owner.id)	self.id = self.owner.id	self:EnableMouse(false)	self.icons = self.icons or {}	self.total = self.total or 0	self.noMouse = trueendlocal layers = {	'BACKGROUND',	'LOW',	'MEDIUM',	'HIGH',	'DIALOG',	'FULLSCREEN',	'FULLSCREEN_DIALOG',	'TOOLTIP',}function component:Layout()	local sets = self.sets	if sets.enable ~=true then		self:Hide()		self.noUpdate = true		return	else		self:Show()		self.noUpdate = nil	end	self:ClearAllPoints()	local x = sets.x/(sets.scale/100)	local y = sets.y/(sets.scale/100)	self:SetPoint(sets.anchor, self:GetParent(), x, y)	if sets.scale < 25 then		sets.scale = sets.scale *100	end	self:SetScale(sets.scale/100)	self:SetAlpha(sets.alpha/100)			for i = 1, #self.Cons do		self:getIcon(i)	end			local w, h = self.icons[1]:GetSize()	w, h =  w + sets.spacing,  h + sets.spacing			local rows = ceil(9 / sets.columns)			local newWidth =  w * sets.columns - sets.spacing	local newHeight = h * rows    - sets.spacing				if sets.style == 'Bar' then		self:SetSize(newWidth, newHeight)		local cols, rows = sets.columns, rows		local isLeftToRight = sets.isLeftToRight		local isTopToBottom = sets.isTopToBottom				for i, icon in pairs(self.icons) do			local col, row = (cols-1) - (i-1) % cols, rows - ceil(i / cols)			if isLeftToRight then	col = (i-1) % cols			end			if isTopToBottom then	row = ceil(i / cols) - 1			end			icon:ClearAllPoints()			icon:SetPoint('TOPLEFT', w*col, -(h*row))			icon:Show()		end	else--round???		self:SetSize(sets.width, sets.height)			for i, icon in pairs(self.icons) do			self:updatePosition(i, icon)		end	end		local lay = layers[sets.frameLayer]	self:SetFrameStrata(lay)		self:Update()			endfunction component:Update()	if self.noUpdate then		return	end	local sets = self.sets	local max = #self.Cons	self.total = 0	self.store = self.store or {}	wipe(self.store)	for i = 1, max do		local name, texture, coords = self.Cons[i](self)		if name then			self.total = self.total + 1			if count == 0 then	count = ''			end			self:storeIcon(name, texture, coords)		else			--break		end			end	for i = 1, self.total do		local store = self.store[i]		if sets.reverse then			store = self.store[(self.total + 1 ) - i]		end		self:updateIcon(i, unpack(store))	end	for i = self.total+1, #self.icons do		if i > #self.store then			self:resetIcon(i)		end	end	self:updateTooltip()			endcomponent.Shapes = {	['ROUND'] = {true, true, true, true},	['SQUARE'] = {false, false, false, false},	['CORNER-TOPLEFT'] = {false, false, false, true},	['CORNER-TOPRIGHT'] = {false, false, true, false},	['CORNER-BOTTOMLEFT'] = {false, true, false, false},	['CORNER-BOTTOMRIGHT'] = {true, false, false, false},	['SIDE-LEFT'] = {false, true, false, true},	['SIDE-RIGHT'] = {true, false, true, false},	['SIDE-TOP'] = {false, false, true, true},	['SIDE-BOTTOM'] = {true, true, false, false},	['TRICORNER-TOPLEFT'] = {false, true, true, true},	['TRICORNER-TOPRIGHT'] = {true, false, true, true},	['TRICORNER-BOTTOMLEFT'] = {true, true, false, true},	['TRICORNER-BOTTOMRIGHT'] = {true, true, true, false},			}			function component:updatePosition(i, button)				local base = (360/9) - (((360/9)) * (self.sets.compress/100))				local angle = math.rad(self.sets.angle + ((base) *i)- (base))	local x, y, q = math.cos(angle), math.sin(angle), 1	if x < 0 then q = q + 1 end	if y > 0 then q = q + 2 end	local quadTable = self.Shapes[self.sets.style]		local w = self.sets.width/2	local h = self.sets.height/2	if quadTable[q] then		x, y = x*w, y*h	else		x = x*w		y = y*h	end	button:ClearAllPoints()	if self.sets.isLeftToRight then		x = -x	end	if self.sets.isTopToBottom then		y = -y	end	button:SetPoint('CENTER', self, 'CENTER', x, y)end			function component:HasMouse()	local index	if self.lastMouse and MouseIsOver(self:getIcon(self.lastMouse)) then		return true, self.lastMouse	else		for i = 1, self.total do			local icon = self:getIcon(i)			if MouseIsOver(icon) and self.isShown then	self.hasMouse = i	return true, i			end		end	endend			function component:updateTooltip()	local hasMouse, index =  self:HasMouse()	if hasMouse then		if (index ~= self.lastMouse) and self:getIcon(index).isShown then			GameTooltip:SetOwner(self)			GameTooltip:SetText(self.id, self:GetIndex(index))			GameTooltip:ClearAllPoints()			GameTooltip:SetPoint('BottomRight', self:getIcon(index), 'TopLeft')			self.lastMouse = index		end	else		if GameTooltip:GetOwner() == self then			self.hasMouse = nil			self.lastMouse = nil			GameTooltip:Hide()			return		end	endend			function component:GetIndex(i)	local rev = i	if self.sets.reverse then		rev = (self.total + 1 ) - i	end	return rev, i end			function component:updateIcon(i, name, texture, coords)	local icon = self:getIcon(i)	--if icon.lastIcon ~= texture then --only make a change, if there is a change.		icon.lastIcon = texture		icon:SetTexture(texture)		icon:SetTexCoord(unpack(coords))	--end	if not icon.isShown then		icon.isShown = true	endend			function component:resetIcon(i)	local icon = self:getIcon(i)	if icon.isShown then		icon.lastIcon = nil		icon:SetTexture('')		icon.isShown = nil		if MouseIsOver(icon) then			self.hasMouse = nil			self.lastMouse = nil		end	endend			function component:storeIcon(...)	tinsert(self.store, {...})end			function component:getIcon( i)	local t = self.icons[i] or self:CreateTexture(self:GetName()..'Icon'..i, 'ARTWORK')	if not self.icons[i] then		self.icons[i] = t		t:SetSize(20, 20)		t.isShown = nil		t.index = i	end	return tend			component.Cons = {		function(self)			local index = GetRaidTargetIndex(self.id);			if ( index ) then				index = index - 1;				local left, right, top, bottom;				local coordIncrement = RAID_TARGET_ICON_DIMENSION / RAID_TARGET_TEXTURE_DIMENSION;				left = mod(index , RAID_TARGET_TEXTURE_COLUMNS) * coordIncrement;				right = left + coordIncrement;				top = floor(index / RAID_TARGET_TEXTURE_ROWS) * coordIncrement;				bottom = top + coordIncrement;				return 'Raid Target', 'Interface\\TargetingFrame\\UI-RaidTargetingIcons', {left, right, top, bottom}			end		end,		function(self)			if ( (self.id == 'player') and IsResting() ) then				return 'Resting', 'Interface\\CharacterFrame\\UI-StateIcon', {.05, .45, .07, 0.46}			end			 		end,		function(self)			local factionGroup = UnitFactionGroup(self.id);			if ( UnitIsPVPFreeForAll(self.id) ) then				return 'PvP: FFA', 'Interface\\TargetingFrame\\UI-PVP-FFA', {.1, .5, 0, .6}			elseif ( factionGroup and factionGroup ~= 'Neutral' and UnitIsPVP(self.id) ) then				return 'PvP', 'Interface\\TargetingFrame\\UI-PVP-'..factionGroup, {.025, .6, .025, .6}			end			 		end,		function(self)			if ( UnitIsGroupLeader(self.id) ) then				if ( HasLFGRestrictions() ) then		return 'Guide', 'Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES', {0, 0.296875, 0.015625, 0.3125}				else		return 'Leader', 'Interface\\GroupFrame\\UI-Group-LeaderIcon', {0, 1, 0, 1}				end			end 		end, 		function(self)			local lootMethod			local lootMaster			lootMethod, lootMaster = GetLootMethod()			if ( lootMaster == 0 and IsInGroup() ) then				return 'Loot Master', 'Interface\\GroupFrame\\UI-Group-MasterLooter', {0, 1, 0, 1}			end 		end,		function(self)			local role = UnitGroupRolesAssigned(self.id)			if ( role == 'TANK' or role == 'HEALER' or role == 'DAMAGER') then				return 'Role: '..role, 'Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES', {GetTexCoordsForRoleSmallCircle(role)}			end	 	end,		function(self)			if (UnitAffectingCombat(self.id)) then				return 'In Combat', 'Interface\\CharacterFrame\\UI-StateIcon', {.5, 1, 0, 0.5}			end			 		end,		function(self)			local targetLevel = UnitLevel(self.id)			if (not  UnitIsCorpse(self.id)) and (not ( targetLevel > 0 )) and (not ( UnitIsWildBattlePet(self.id) and UnitIsBattlePetCompanion(self.id)))  then				return 'High Level', 'Interface\\TargetingFrame\\UI-TargetingFrame-Skull', {0, 1, 0, 1}			end 		end,		function(self)			if (UnitIsQuestBoss(self.id)) then				return 'Quest', 'Interface\\TargetingFrame\\PortraitQuestBadge', {0, 1, 0, 1}			end 		end,		function(self)			if ( UnitIsWildBattlePet(self.id) or UnitIsBattlePetCompanion(self.id) ) then				local petType = UnitBattlePetType(self.id)				return 'Battle Pet', 'Interface\\TargetingFrame\\PetBadge-'..PET_TYPE_SUFFIX[petType], {0, 1, 0, 1}			end 		end,			}local anchors = {	'TopLeft',	'Top',	'TopRight',	'Right',	'BottomRight',	'Bottom',	'BottomLeft',	'Left',	'Center',}local options = {	{		name = 'Anchor',		kind = 'Menu',		key = 'anchor',		table = anchors,	},	{		name = 'Style',		kind = 'Menu',		key = 'style',		table = {			'ROUND',			'SQUARE',			--'CORNER-TOPLEFT',			--'CORNER-TOPRIGHT',			--'CORNER-BOTTOMLEFT',			--'CORNER-BOTTOMRIGHT',			--'SIDE-LEFT',			--'SIDE-RIGHT',			--'SIDE-TOP',			--'SIDE-BOTTOM',			--'TRICORNER-TOPLEFT',			--'TRICORNER-TOPRIGHT',			--'TRICORNER-BOTTOMLEFT',			--'TRICORNER-BOTTOMRIGHT',			'Bar',		},	},	{		name = 'Enable',		kind = 'CheckButton',		key = 'enable',	},	{		name = 'Reverse',		kind = 'CheckButton',		key = 'reverse',	},	{		name = 'isTopToBottom',		kind = 'CheckButton',		key = 'isTopToBottom',	},	{		name = 'isLeftToRight',		kind = 'CheckButton',		key = 'isLeftToRight',	},	{		name = 'Frame Layer',		kind = 'Slider',		key = 'frameLayer',		min = 1,		max = 8,	},	{		name = 'X Offset',		kind = 'Slider',		key = 'x',		min = -400,		max = 400,	},	{		name = 'Y Offset',		kind = 'Slider',		key = 'y',		min = -400,		max = 400,	},	{		name = 'Columns',		kind = 'Slider',		key = 'columns',		min = 1,		max = 10,	},	{		name = 'Spacing',		kind = 'Slider',		key = 'spacing',		min = -13,		max = 30,	},	{		name = 'Scale',		kind = 'Slider',		key = 'scale',		min = 25,		max = 250,	},	{		name = 'Opacity',		kind = 'Slider',		key = 'alpha',		min = 0,		max = 100,	},	{		name = 'Angle',		kind = 'Slider',		key = 'angle',		min = 0,		max = 360,	},	{		name = 'Height',		kind = 'Slider',		key = 'height',		min = 10,		max = 400,	},		{		name = 'Width',		kind = 'Slider',		key = 'width',		min = 10,		max = 400,	},	{		name = 'Compression',		kind = 'Slider',		key = 'compress',		min = -13,		max = 100,		step = .25,	},	}function component:CreateMenu(menu)	return bar.Menu.NewPanel(menu, 'Icons', options)end