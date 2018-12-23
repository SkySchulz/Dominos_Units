local Addon = _G[...]local StatusBar = Addon.StatusBar local castingBar = {}do	function castingBar:LoadColors()		self.startCastColor = CreateColor(1.0, 0.7, 0.0)		self.startChannelColor = CreateColor(0.0, 1.0, 0.0);		self.finishedCastColor = CreateColor(0.0, 1.0, 0.0);		self.nonInterruptibleColor = CreateColor(0.7, 0.7, 0.7);		self.failedCastColor = CreateColor(1.0, 0.0, 0.0);		self.finishedColorSameAsStart = true		self.flashColorSameAsStart = true	end	function castingBar:GetEffectiveStartColor(isChannel, notInterruptible)		if self.nonInterruptibleColor and notInterruptible then			return self.nonInterruptibleColor;		end			return isChannel and self.startChannelColor or self.startCastColor;	end	-- Fades additional widgets along with the cast bar, in case these widgets are not parented or use ignoreParentAlpha	function castingBar:AddWidgetForFade(widget)		self.additionalFadeWidgets = self.additionalFadeWidgets or {};		self.additionalFadeWidgets[widget] = true;	end	function castingBar:ApplyAlpha(alpha)		self:SetAlpha(alpha);		if self.additionalFadeWidgets then			for widget in pairs(self.additionalFadeWidgets) do				widget:SetAlpha(alpha);			end		end	end	function castingBar:ApplyShown(hide)		if hide == true then			self:Hide();			if self.additionalFadeWidgets then				for widget in pairs(self.additionalFadeWidgets) do					widget:Hide();				end			end				--self:Reset(true)		else			self:Show();			if self.additionalFadeWidgets then				for widget in pairs(self.additionalFadeWidgets) do					widget:Show();				end			end		end	end	function castingBar:GetCastingInfo(unit)		local castType, func		if UnitCastingInfo(unit) then			castType, func = 'cast', UnitCastingInfo		elseif UnitChannelInfo(unit) then			castType, func = 'channel', UnitChannelInfo		end		if castType and func then			return castType, func(unit)		end	end	function castingBar:FinishSpell()		if not self.finishedColorSameAsStart then			self:SetStatusBarColor(self.finishedCastColor:GetRGB());		end		if ( self.Spark ) then			self.Spark:Hide();		end	--	if ( self.Flash ) then	--		self.Flash:SetAlpha(0.0);	--		self.Flash:Show();	--	end		self.flash = true;		self.fadeOut = true;		self.casting = nil;		self.channeling = nil;	end	function castingBar:GetMaxValue()	--	local castType, name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = self:GetCastingInfo(self.id)		if (UnitCastingInfo(self.id))  then				local _, _, _, startTime, endTime = UnitCastingInfo(self.id);				if ( startTime ) then					self.value = (GetTime() - (startTime / 1000));				end			self.maxValue = (endTime - startTime) / 1000;			self:SetMinMaxValues(0, self.maxValue);		elseif (UnitChannelInfo(self.id)) then				local _, _, _, startTime, endTime = UnitChannelInfo(self.id);				if ( endTime ) then					self.value = ((endTime / 1000) - GetTime());				end			self.maxValue = (endTime - startTime) / 1000;			self:SetMinMaxValues(0, self.maxValue);		else			self.value = 0			self.maxValue = 0		end	end	function castingBar:TriggerEvent(event, ...)		local arg1 = ...;		local unit = self.id;		if ( event == "PLAYER_ENTERING_WORLD" ) then			local nameChannel = UnitChannelInfo(unit);			local nameSpell = UnitCastingInfo(unit);			if ( nameChannel ) then				event = "UNIT_SPELLCAST_CHANNEL_START";				arg1 = unit;			elseif ( nameSpell ) then				event = "UNIT_SPELLCAST_START";				arg1 = unit;			else				self:FinishSpell();			end		end				if ( event == "UNIT_SPELLCAST_START" ) then			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit);			if ( not name or (not self.showTradeSkills and isTradeSkill)) then				self:ApplyShown(true)				return;			end			local startColor = self:GetEffectiveStartColor(self, false, notInterruptible);			self:SetStatusBarColor(startColor:GetRGB());	--		if self.flashColorSameAsStart then			--	self.Flash:SetVertexColor(startColor:GetRGB());	--		else			--	self.Flash:SetVertexColor(1, 1, 1);	--		end						if ( self.Spark ) then				self.Spark:Show();			end						self.value = (GetTime() - (startTime / 1000));			self.maxValue = (endTime - startTime) / 1000;			self:SetMinMaxValues(0, self.maxValue);			self:SetValue(self.value);			if ( self.text ) then				self.text:SetText(text);			end			self:ApplyAlpha(1.0);			self.holdTime = 0;			self.casting = true;			self.castID = castID;			self.channeling = nil;			self.fadeOut = nil;			if ( self.showCastbar ) then				self:ApplyShown()			end		elseif ( event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP") then			if ( not self:IsVisible() ) then				self:ApplyShown(true)			end			if ( (self.casting and event == "UNIT_SPELLCAST_STOP" and select(4, ...) == self.castID) or				 (self.channeling and event == "UNIT_SPELLCAST_CHANNEL_STOP") ) then				if ( self.Spark ) then					self.Spark:Hide();				end	--			if ( self.Flash ) then	--				self.Flash:SetAlpha(0.0);	--				self.Flash:Show();	--			end				self:SetValue(self.maxValue);				if ( event == "UNIT_SPELLCAST_STOP" ) then					self.casting = nil;					if not self.finishedColorSameAsStart then						self:SetStatusBarColor(self.finishedCastColor:GetRGB());					end				else					self.channeling = nil;				end				self.flash = true;				self.fadeOut = true;				self.holdTime = 0;			end		elseif ( event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" ) then			if ( self:IsShown() and				 (self.casting and select(4, ...) == self.castID) and not self.fadeOut ) then				self:SetValue(self.maxValue);				self:SetStatusBarColor(self.failedCastColor:GetRGB());				if ( self.Spark ) then					self.Spark:Hide();				end				if ( self.text ) then					if ( event == "UNIT_SPELLCAST_FAILED" ) then						self.text:SetText(FAILED);					else						self.text:SetText(INTERRUPTED);					end				end				self.casting = nil;				self.channeling = nil;				self.fadeOut = true;				self.holdTime = GetTime() + CASTING_BAR_HOLD_TIME;			end		elseif ( event == "UNIT_SPELLCAST_DELAYED" ) then			if ( self:IsShown() ) then				local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit);				if ( not name or (not self.showTradeSkills and isTradeSkill)) then					-- if there is no name, there is no bar					self:ApplyShown(true)					return;				end				self.value = (GetTime() - (startTime / 1000));				self.maxValue = (endTime - startTime) / 1000;				self:SetMinMaxValues(0, self.maxValue);				if ( not self.casting ) then					self:SetStatusBarColor(self:GetEffectiveStartColor(self, false, notInterruptible):GetRGB());					if ( self.Spark ) then						self.Spark:Show();					end	--				if ( self.Flash ) then	--					self.Flash:SetAlpha(0.0);	--					self.Flash:Hide();	--				end					self.casting = true;					self.channeling = nil;					self.flash = nil;					self.fadeOut = nil;				end			end		elseif ( event == "UNIT_SPELLCAST_CHANNEL_START" ) then			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit);			if ( not name or (not self.showTradeSkills and isTradeSkill)) then				-- if there is no name, there is no bar				self:ApplyShown(true)				return;			end			local startColor = self:GetEffectiveStartColor(self, true, notInterruptible);	--		if self.flashColorSameAsStart then	--			self.Flash:SetVertexColor(startColor:GetRGB());	--		else	--			self.Flash:SetVertexColor(1, 1, 1);	--		end			self:SetStatusBarColor(startColor:GetRGB());			self.value = (endTime / 1000) - GetTime();			self.maxValue = (endTime - startTime) / 1000;			self:SetMinMaxValues(0, self.maxValue);			self:SetValue(self.value);			if ( self.text ) then				self.text:SetText(text);			end			if ( self.Spark ) then				self.Spark:Hide();			end			self:ApplyAlpha(1.0);			self.holdTime = 0;			self.casting = nil;			self.channeling = true;			self.fadeOut = nil;			if ( self.showCastbar ) then				self:ApplyShown()							end		elseif ( event == "UNIT_SPELLCAST_CHANNEL_UPDATE" ) then			if ( self:IsShown() ) then				local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(unit);				if ( not name or (not self.showTradeSkills and isTradeSkill)) then					-- if there is no name, there is no bar					self:ApplyShown(true)					return;				end				self.value = ((endTime / 1000) - GetTime());				self.maxValue = (endTime - startTime) / 1000;				self:SetMinMaxValues(0, self.maxValue);				self:SetValue(self.value);			end		elseif ( event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" ) then			self:UpdateInterruptibleState(self, event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE");		end	end	function castingBar:UpdateInterruptibleState(notInterruptible)		if ( self.casting or self.channeling ) then			local startColor = self:GetEffectiveStartColor(self, self.channeling, notInterruptible);			self:SetStatusBarColor(startColor:GetRGB());	--		if self.flashColorSameAsStart then	--			self.Flash:SetVertexColor(startColor:GetRGB());	--		end		end	end	function castingBar:UpdateCurrentCast(elapsed)		local currentGUID = UnitGUID(self.id)		local CurrentTime = GetTime()		print(currentGUID)				if not currentGUID then --no target, hide the bar			return self:Reset()		elseif self.previousGUID ~= currentGUID then --target has changed, force an update of cast info			self.castType = nil			self.spellID = nil			self.startTime = nil			self.endTime = nil			self.spellname = nil			self.seconds = ''			self.stop = true		end				local castType, name, nameSubtext, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = self:GetCastingInfo(currentGUID)		if (castType == 'cast') and startTime then			self.value = CurrentTime - (startTime / 1000)		elseif (castType == 'channel') and endTime then			self.value = (endTime / 1000) - CurrentTime		else			self.value = 0		end						local isCasting		if (castType == "cast") or (castType == "channel") then --a spell is being cast			self.showCastbar = true 			self.castType = castType			self.spellID = select( 7, GetSpellInfo(name))			self.startTime = startTime			self.endTime = endTime			self.castID = castID or 0			self.stop = nil			isCasting = true			if self.spellname ~= name then --a new spell has just started				if castType == 'cast' then					self:TriggerEvent('UNIT_SPELLCAST_START', name, nil, nil, castID)				elseif castType == 'channel' then					self:TriggerEvent('UNIT_SPELLCAST_CHANNEL_START', name, nil, nil, castID) --need to update for channeling				end			elseif self.endTime ~= endTime then --if the endTime changes, then the cast was delayed				self:TriggerEvent('UNIT_SPELLCAST_DELAYED',  name, nil, nil, castID, spellID)			end			self.spellname = name		end				if (not isCasting) and self.endTime and self.startTime then			self.showCastbar = nil 			if ((CurrentTime) < ((self.endTime/1000) - .5)) then --the cast was interrupted				self:TriggerEvent('UNIT_SPELLCAST_INTERRUPTED', self.spellname, nil, nil,  self.castID)			else				if self.castType == 'cast' then					self:TriggerEvent('UNIT_SPELLCAST_STOP', self.spellname, nil, nil,  self.castID)				elseif self.castType == 'channel' then					self:TriggerEvent('UNIT_SPELLCAST_CHANNEL_STOP', self.spellname, nil, nil,  self.castID)				end			end			self.castType = nil			self.spellID = nil			self.startTime = nil			self.endTime = true			self.spellname = nil			self.seconds = ''			self.stop = true		else			if self:IsShown()	then				self:ApplyShown(true)			end		end				if self.endTime and type(self.endTime) == "number" then			self.seconds = string.format('%.1f' , (self.endTime / 1000) - CurrentTime)			self.time:SetText(self.seconds)		else			self.time:SetText("")		end		if self.spellname then			self.text:SetText(name)		end				if self.value and self.value > 0 then			self:ApplyShown()			local min, max = self:GetMinMaxValues()			if min ~= 0 then				if min > 0 then					max = max - min				elseif max < 0 then					max = max + math.abs(min)				end				min = 0			end			local orientation = self:GetOrientation()			local fillstyle = self:GetFillStyle()			if (fillstyle == "STANDARD_NO_RANGE_FILL") and (min == max) then				self.spark:Hide()				self.subspark:Hide()			elseif fillstyle == "REVERSE" then				self.spark:Hide()				self.subspark:Show()			elseif fillstyle == "CENTER" then				self.spark:Show()				self.subspark:Show()			else				self.spark:Show()				self.subspark:Hide()			end		end				if not self.value then		--	return		end				if ( castType == "cast" ) then			self.value = self.value + elapsed;			self:GetMaxValue()						if ( self.value >= self.maxValue ) then				self:SetValue(self.maxValue);				self:FinishSpell(self.Spark, self.Flash);				return;			end			self:SetValue(self.value);		elseif ( castType == "channel" ) then			self.value = self.value - elapsed;			if ( self.value <= 0 ) then				self:FinishSpell(self.Spark, self.Flash);				return;			end			self:SetValue(self.value);		elseif ( self.fadeOut ) then			local alpha = self:GetAlpha() - CASTING_BAR_ALPHA_STEP;			if ( alpha > 0 ) then				self:ApplyAlpha(alpha);			else				self.fadeOut = nil;				self:ApplyShown(true)			end		end		self.lastGUID = curGUIDendendlocal hori = {'LEFT', 'CENTER', 'RIGHT'}local vert = {'TOP',  'MIDDLE', 'BOTTOM'}local modName = ...local title = "Cast"--Cast Barlocal widget = Addon:NewWidget(title, 'StatusBar')widget.defaults = {	basic = {		advanced = {			enable = true,			tooltip = true,		},		position = {			y = -13,			x = 7,			frameLevel = 5,			anchor = "TopLeft",			frameStrata = 2,		},		size = {			enable = true,			scale = 100,			height = 16,			width = 116,		},	},	text = {		text = {			justifyH = 1,			enable = true,			file = "Friz Quadrata TT",			justifyV = 2,			color = {				a = 1,				b = 0,				g = 1,				r = 1,			},		},		size = {			height = 100,			size = 9,			width = 90,		},		position = {			anchor = "Left",			x = 0,			y = 0,		},	},--[[	visibility = {		spark = {			y = 0,			offset = 0,		},		background = {			enable = true,			file = "Raid",			solid = true,			color = {				a = 0,				b = 0,				g = 0,				r = 0,			},		},		border = {			hpadding = 0,			vthickness = 30,			vpadding = 0,			color = {				a = 0.5,				b = 0,				g = 0,				r = 0,			},			file = "Border",			hthickness = 50,		},		texture = {			orientation = "HORIZONTAL",			fillstyle = "STANDARD",			file = "Raid",			opacity = 100,		},	},--]]	visibility = {		background = {			enable = true,			color = {				a = 0.5,				b = 0,				g = 0,				r = 0,			},		},		border = {			hpadding = 13,			vthickness = 17,			vpadding = -4,			color = {				a = 1,				b = 1,				g = 1,				r = 1,			},			file = "WoodBoards",			hthickness = 21,			inset = 0,		},		texture = {			orientation = "HORIZONTAL",			file = "Druid",			fillStyle = "STANDARD",			opacity = 100,		},	},		time = {		text = {			enable = true,			file = "Friz Quadrata TT",			color = {				a = 1,				b = 0,				g = 1,				r = 1,			},			size = 9,		},		position = {			anchor = "Right",			x = 0,			y = 0,		},	},}		function widget:New(parent)		local bar = self:Bind(CreateFrame("Frame", name, parent.box))		bar.status = StatusBar:New(bar) --CreateFrame("StatusBar", name, bar)	bar.status:SetAllPoints(bar)	bar.status.ApplyStatusBarTexture = bar.status.ApplyStatusBarTexture or bar.status.SetStatusBarTexture		bar.status:ApplyStatusBarTexture('Interface\\RaidFrame\\Raid-Bar-Hp-Fill', 'BORDER')	bar.status:SetStatusBarColor(0,1,0,1)	bar.status:EnableMouse(false)	bar.status:Show()	bar.status.id = parent.id	bar.text = bar.text or bar:CreateFontString(nil, 'ARTWORK', 'TextStatusBarText')	bar.text:SetTextColor(1.0,1.0,1.0)		bar.time = bar.time or bar:CreateFontString(nil, 'ARTWORK', 'TextStatusBarText')	bar.time:SetTextColor(1.0,1.0,1.0)	bar:SetFrameLevel(3)	bar.drop = bar.drop or CreateFrame('StatusBar', nil, bar)	bar.drop:SetMinMaxValues(0,1)	bar.drop:SetValue(1)	bar.drop:SetAllPoints(bar)	bar.drop:SetFrameLevel(bar:GetFrameLevel()-2)	bar.spark = bar:CreateTexture(nil, 'ARTWORK')	bar.spark:SetPoint("Center", bar.status.scrollFrame, "Right")	bar.spark:SetSize(30,30)	bar.spark:SetTexture("Interface/CastingBar/UI-CastingBar-Spark")	bar.spark:SetBlendMode("ADD")	bar.subspark = bar:CreateTexture(nil, 'ARTWORK')	bar.subspark:SetPoint("Center", bar.status.scrollFrame, "Left")	bar.subspark:SetSize(30,30)	bar.subspark:SetTexture("Interface/CastingBar/UI-CastingBar-Spark")	bar.subspark:SetBlendMode("ADD")	bar.status.time = bar.time	bar.status.text = bar.text	bar.status.spark = bar.spark	bar.status.subspark = bar.subspark	bar.owner = parent	bar.title = title	bar.handler = parent.id	return barendfunction widget:Layout()	if self.sets.basic.advanced.enable == true then		self:Show()		self.noUpdate = nil	else		self:Hide()		self.noUpdate = true		return	end	self:Resize()	self:Reposition()		self:LayoutText()	self:LayoutTime()	self:SetVisibility()	self:SetSpark()		if self.status.EnableBorder then		local border = self.sets.visibility.border		self.status:EnableBorder(border.enable)		if border.enable == true then			self.status:SetBorderTexture(border.file, border.flipVertical, border.inset)			self.status:SetBorderPadding(border.hpadding, border.vpadding)			self.status:SetBorderThickness(border.hthickness, border.vthickness)			self.status:SetBorderColor(border.color.r,border.color.g,border.color.b,border.color.a)		end	end		self:Update()endfunction widget:SetSpark()    if self.sets.visibility.texture.rotateTexture == true then        self.spark:SetRotation(math.rad(-90))    else        self.spark:SetRotation(math.rad(0))    end			local orientation = self.status:GetOrientation()			self.spark:ClearAllPoints()		self.subspark:ClearAllPoints()			if orientation == "VERTICAL" then		self.spark:SetPoint("Center", self.status.scrollFrame, "Top")		self.subspark:SetPoint("Center", self.status.scrollFrame, "Bottom")	else		self.spark:SetPoint("Center", self.status.scrollFrame, "Right")		self.subspark:SetPoint("Center", self.status.scrollFrame, "Left")	end		local fillstyle = self.status:GetFillStyle()	if (fillstyle == "STANDARD_NO_RANGE_FILL") and (min == max) then		self.spark:Hide()		self.subspark:Hide()	elseif fillstyle == "REVERSE" then		self.spark:Hide()		self.subspark:Show()	elseif fillstyle == "CENTER" then		self.spark:Show()		self.subspark:Show()	else		self.spark:Show()		self.subspark:Hide()	end		endlocal function LookForSets(frame)	if not frame:GetParent() then		return nil, "Dead End"	elseif frame:GetParent().sets then		return frame:GetParent().sets	else		return LookForSets(frame:GetParent())	endendfunction widget:Resize()	local size = self.sets.basic.size		local width, height = (size.width), (size.height)	self:SetHeight(height)		local scale = size.scale/100	self:SetScale(scale)		local set = LookForSets(self)	if set then		local w = set.width		if set.magicWidth then			local d = w - 191			self:SetWidth((size.width  + d)/ scale)		else			self:SetWidth(width)		end	else		self:SetWidth(width)	endendfunction widget:Reposition()	local position = self.sets.basic.position	local scale = self.sets.basic.size.scale/100	self:ClearAllPoints()	self:SetPoint(position.anchor, self:GetParent(), position.x / scale, position.y / scale)		local lay = Addon.layers[position.frameStrata]	self:SetFrameStrata(lay)	self.status:SetFrameStrata(lay)	local level = position.frameLevel	self:SetFrameLevel(level+2)	self.status:SetFrameLevel(level)endfunction widget:LayoutText()	local text = self.text			local font = self.sets.text.text	if font.enable then		text:Show()	else		text:Hide()		return	end	text:SetJustifyH(hori[font.justifyH] or font.justifyH or "CENTER") -- Sets horizontal text justification ('LEFT','RIGHT', or 'CENTER')	text:SetFont(self:GetMediaPath("font", font.file), font.size or 12)	text:SetTextColor(font.color.r, font.color.g, font.color.b, font.color.a)		local position = self.sets.text.position	text:ClearAllPoints()	local point	if font.justifyH == 1 then		point = "Left"	elseif font.justifyH == 2 then		point = "Center"	else		point = "Right"	end		if string.find(position.anchor, "Top") then		if point == "Center" then point = "" end		point = "Top"..point	elseif string.find(position.anchor, "Bottom") then		if point == "Center" then point = "" end		point = "Bottom"..point	end		text:SetPoint(point, self, position.anchor, position.x, position.y)	text:SetSize(self.sets.text.size.width, self.sets.text.size.height)endfunction widget:LayoutTime()	local text = self.time			local font = self.sets.time.text	if font.enable then		text:Show()	else		text:Hide()		return	end	text:SetFont(self:GetMediaPath("font", font.file), font.size or 12)	text:SetTextColor(font.color.r, font.color.g, font.color.b, font.color.a)		local position = self.sets.time.position	text:ClearAllPoints()	text:SetPoint(position.anchor, self, position.anchor, position.x, position.y)endfunction widget:SetVisibility()	local visibility = self.sets.visibility		local background = visibility.background    if background.enable then        self.drop:SetStatusBarColor(background.color.r, background.color.g, background.color.b, background.color.a)    else        self.drop:SetStatusBarTexture("")    end	local texture = visibility.texture	self.status:SetOrientation(texture.orientation) -- "HORIZONTAL" or "VERTICAL"	self.drop:SetOrientation(texture.orientation)	--texture.fillStyle = "STANDARD"		self.status:SetFillStyle(texture.fillStyle)		self.status:ApplyStatusBarTexture(self:GetMediaPath('statusbar', texture.file) or texture.file)	self.drop:SetStatusBarTexture(self:GetMediaPath('statusbar', texture.file) or texture.file)        self.status:SetRotatesTexture(texture.rotateTexture)    self.drop:SetRotatesTexture(texture.rotateTexture)endfunction widget:Update()	if self.noUpdate then		return	end	if self.OnUpdate then		self:OnUpdate()	endendfunction widget:SetValues(current, minimum, maximum, overide, overideText)	local font = self.sets.time.text	self.status:SetMinMaxValues(minimum or 0, maximum or 0)	self.status:SetValue(current or 0)endfunction widget:SetColor(r, g, b, a)	if ( r ~= self.r or g ~= self.g or b ~= self.b) or (a ~= self.a) then		self.status:SetStatusBarColor(r, g, b)		self.r, self.g, self.b, self.a = r, g, b, a	endendfunction widget:GetMediaPath(kind, fileName)	if Addon.lib then		return Addon.lib:Fetch(kind, fileName)	endendfunction widget:GetCastingInfo(unit)	local castType, func	if UnitCastingInfo(unit) then		castType, func = 'cast', UnitCastingInfo	elseif UnitChannelInfo(unit) then		castType, func = 'channel', UnitChannelInfo	end	if castType and func then		return castType, func(unit)	endendfunction widget:OnUpdate()	local unit = self.owner.id	local currentGUID = UnitGUID(unit)	local currentTime = GetTime()		if not (unit and currentGUID) then		return	end		local castType, name, nameSubtext, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = self:GetCastingInfo(unit)	if (castType == 'cast') and startTime then		self.value = currentTime - (startTime / 1000)	elseif (castType == 'channel') and endTime then		self.value = (endTime / 1000) - currentTime	else		self.value = 0	end		if name then		self:Show()		self.status:Show()				local maxValue = (endTime - startTime) / 1000;		if ( self.text ) then			self.text:SetText(name);		end				self.seconds = (startTime / 1000) - currentTime		if castType == "channel" then			self.seconds = (endTime / 1000) - currentTime		end				self.time:SetText(string.format('%.1f' , math.abs(self.seconds)))		self:SetValues(self.value, 0, maxValue)	elseif self.TEST then		self.text:SetText("Regrowth")		self.status:SetMinMaxValues(0, 1)		self.status:SetValue(.5)		self:Show()		self.status:Show()		self.time:SetText(0.5)		return	else		self:Hide()		self.status:Hide()	endendwidget.Options = {	{		name = "Basic",		kind = "Panel",		key = "basic",		panel = "Basic",		options = {			{				name = 'Scale',				kind = 'Slider',				key = 'scale',				min = 25,				max = 200,				panel = 'size',			},			{				name = 'Width',				kind = 'Slider',				key = 'width',				min = 10,				max = 200,				panel = 'size',			},			{				name = 'Height',				kind = 'Slider',				key = 'height',				min = 10,				max = 200,				panel = 'size',			},			{				name = 'X Offset',				kind = 'Slider',				key = 'x',				panel = 'position',				min = -400,				max = 400,			},			{				name = 'Y Offset',				kind = 'Slider',				key = 'y',				panel = 'position',				min = -400,				max = 400,			},			{				name = 'Anchor',				kind = 'Menu',				key = 'anchor',				panel = 'position',				table = {					'TopLeft',					'Top',					'TopRight',					'Right',					'BottomRight',					'Bottom',					'BottomLeft',					'Left',					'Center',				},			},			{				kind = "Button",				name = "Test Mode",				handler = "cast",				func = function(owner)					owner.TEST = not owner.TEST					owner:Layout()				end,				panel = "advanced",			},		{			name = "Frame Level",			kind = "Slider",			key = "frameLevel",			panel = 'position',			min = 1,			max = 100,		},		{			name = "Frame Strata",			kind = "Slider",			key = "frameStrata",			panel = 'position',			min = 1,			max = 7,		},			{				name = 'Enable',				kind = 'CheckButton',				key = 'enable',				panel = "advanced",			},			{				name = 'Tooltip',				kind = 'CheckButton',				key = 'tooltip',				panel = "advanced",			},		}	},		{ 		name = "Text",		kind = "Panel",		key = "text",		panel = "Text",		options = {			{				name = 'Enable',				kind = 'CheckButton',				key = 'enable',				panel = "text",			},			{				name = 'Font',				kind = 'Media',				key = 'file',				mediaType = 'Font',				panel = 'text',			},			{				name = 'Size',				kind = 'Slider',				key = 'size',				min = 1,				max = 25,				panel = 'size',			},			{				name = 'Width',				kind = 'Slider',				key = 'width',				min = 1,				max = 150,				panel = 'size',			},			{				name = 'Height',				kind = 'Slider',				key = 'height',				min = 1,				max = 150,				panel = 'size',			},			{				name = 'Color',				kind = 'ColorPicker',				key = 'color',				panel = 'text',			},			{				name = 'X Offset',				kind = 'Slider',				key = 'x',				panel = 'position',				min = -400,				max = 400,			},			{				name = 'Y Offset',				kind = 'Slider',				key = 'y',				panel = 'position',				min = -400,				max = 400,			},			{				name = 'Justify Horizontal',				kind = 'Slider',				key = 'justifyH',				panel = 'text',				min = 1,				max = 3,			},			{				name = 'Justify Vertical',				kind = 'Slider',				key = 'justifyV',				panel = 'text',				min = 1,				max = 3,			},			{				name = 'Anchor',				kind = 'Menu',				key = 'anchor',				panel = 'position',				table = {					'TopLeft',					'Top',					'TopRight',					'Right',					'BottomRight',					'Bottom',					'BottomLeft',					'Left',					'Center',				},			},		}	},	{ 		name = "Time",		kind = "Panel",		key = "time",		panel = "Time",		options = {			{				name = 'Enable',				kind = 'CheckButton',				key = 'enable',				panel = "text",			},			{				name = 'Font',				kind = 'Media',				key = 'file',				mediaType = 'Font',				panel = 'text',			},			{				name = 'Size',				kind = 'Slider',				key = 'size',				min = 1,				max = 25,				panel = 'text',			},			{				name = 'Color',				kind = 'ColorPicker',				key = 'color',				panel = 'text',			},			{				name = 'X Offset',				kind = 'Slider',				key = 'x',				panel = 'position',				min = -400,				max = 400,			},			{				name = 'Y Offset',				kind = 'Slider',				key = 'y',				panel = 'position',				min = -400,				max = 400,			},			{				name = 'Anchor',				kind = 'Menu',				key = 'anchor',				panel = 'position',				table = {					'TopLeft',					'Top',					'TopRight',					'Right',					'BottomRight',					'Bottom',					'BottomLeft',					'Left',					'Center',				},			},		}	},	{		name = "visibility",		kind = "Panel",		key = "visibility",		panel = "visibility",		options = {			{				name = 'Rotate Texture',				kind = 'CheckButton',				key = 'rotateTexture',				panel = "texture",			},			{				name = 'Fill Style',				kind = 'Menu',				key = 'fillStyle',				panel = 'texture',				table = {					'REVERSE',					'STANDARD_NO_RANGE_FILL',					'STANDARD',					'CENTER',				},			},						{				name = 'Texture',				kind = 'Media',				key = 'file',				mediaType = 'statusbar',				panel = 'texture',			},			{				name = 'Opacity',				kind = 'Slider',				key = 'opacity',				min = 0,				max = 100,				panel = 'texture',			},			{				name = 'Orientation',				kind = 'Menu',				key = 'orientation',				panel = 'texture',				table = {					'HORIZONTAL',					'VERTICAL',					'BOTH',				},			},			{				name = 'Enable',				kind = 'CheckButton',				key = 'enable',				panel = "background",			},			{				name = 'Background Color',				kind = 'ColorPicker',				key = 'color',				panel = 'background',			},			{				name = 'texture',				kind = 'Media',				key = 'file',				mediaType = 'Castborder',				panel = "border",			},				{				name = 'Enable',				kind = 'CheckButton',				key = 'enable',				panel = "border",			},				{				name = 'Flip Upside Down',				kind = 'CheckButton',				key = 'flipVertical',				panel = "border",			},			{				name = 'Solid Texture',				kind = 'CheckButton',				key = 'solid',				panel = "background",			},			{				name = 'Vertical Padding',				kind = 'Slider',				key = 'vpadding',				min = -50,				max = 50,				panel = 'border',			},						{				name = 'Horizontal Padding',				kind = 'Slider',				key = 'hpadding',				min = -50,				max = 50,				panel = 'border',			},			{				name = 'Vertical Thickness',				kind = 'Slider',				key = 'vthickness',				min = 1,				max = 50,				panel = 'border',			},			{				name = 'Horizontal Thickness',				kind = 'Slider',				key = 'hthickness',				min = 1,				max = 50,				panel = 'border',			},			{				name = 'Inset',				kind = 'Slider',				key = 'inset',				min = -50,				max = 50,				panel = 'border',			},			{				name = 'Border Color',				kind = 'ColorPicker',				key = 'color',				panel = 'border',			},		}	},}