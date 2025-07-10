local SpeedrunSplits_UpdateInterval = 1.0 --Time in seconds for update frequency
local SpeedrunSplitsDeltaDiff = 300 --Time for delta clock to start counting down when nearing the time for the next level
local SpeedrunSplitsDeltaXP = 0.90 --Percent for delta clock to start counting down when nearing the XP for the next level
local SpeedrunSplitsFont = "Fonts\\ARIALN.ttf"

local SpeedrunSplitsLevel = nil
local SpeedrunSplitsClassID = nil
local SpeedrunSplitsRaceID = nil
local SpeedrunSplitsTotalTime = 0
local SpeedrunSplitsExpansionTime = 0
local SpeedrunSplitsLevelTime = 0
local SpeedrunSplitsDeltaTime = 0
local TimeSinceLastUpdate = 0
local SpeedrunSplitsMax = nil
local SpeedrunSplitsMin = nil
local SpeedrunSplitsXP = nil
local SpeedrunSplitsXPMax = nil
local SpeedrunSplitsXPWindow = false
local SpeedrunSplitsLevelUp = false
local SpeedrunSplitsDeltaUpdate = true
local SpeedrunSplitsPBCopy = {}

local xpos1 = 0
local ypos1 = 0
local xpos2 = 0
local ypos2 = 0
local xpos3 = 0
local ypos3 = 0

--/run SpeedrunSplitsPB["NightElf"]["HUNTER"][2]=100

function SpeedrunSplitsDefaults()
	SpeedrunSplitsOptions["xpos"] = 5
	SpeedrunSplitsOptions["ypos"] = -120
	SpeedrunSplitsOptions["PBLevel"] = 40
	SpeedrunSplitsOptions["LevelRange"] = 9
	SpeedrunSplitsOptions["FontSize"] = 13
	SpeedrunSplitsOptions["Show"] = true
	SpeedrunSplitsOptions["Move"] = false
	SpeedrunSplitsOptions["Days"] = false
	SpeedrunSplitsOptions["Delta"] = false
	SpeedrunSplitsOptions["Next"] = false
	SpeedrunSplitsOptions["Colour"] = false
end

local NAME, S = ...
local f = CreateFrame("Frame","SpeedrunSplitsTimer",UIParent)
f:SetWidth(1) 
f:SetHeight(1) 
f:SetAlpha(1)
f:RegisterForDrag("LeftButton")

f.text = f:CreateFontString(nil,"ARTWORK") 
f.text:SetPoint("TOPLEFT",0,0)
f.text:SetJustifyH("LEFT")
f.text:SetJustifyV("TOP")

f.timer = f:CreateFontString(nil,"ARTWORK") 
f.timer:SetPoint("TOPLEFT",f.text,"BOTTOMLEFT",0,-5)
f.timer:SetJustifyH("LEFT")
f.timer:SetJustifyV("TOP")

f.delta = f:CreateFontString(nil,"ARTWORK") 
f.delta:SetPoint("TOPLEFT",f.text,"TOPRIGHT",5,0)
f.delta:SetJustifyH("LEFT")
f.delta:SetJustifyV("TOP")

f.times = f:CreateFontString(nil,"ARTWORK") 
f.times:SetPoint("TOPLEFT",f.delta,"TOPRIGHT",5,0)
f.times:SetJustifyH("LEFT")
f.times:SetJustifyV("TOP")

local panel = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
panel.name = NAME
InterfaceOptions_AddCategory(panel) --currently broken by Blizzard

panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
panel.title:SetPoint("TOPLEFT", 16, -16)
panel.title:SetText(NAME)

panel.subtext = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
panel.subtext:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -8)
panel.subtext:SetText("Created by Karmond")

panel.FontSlider = CreateFrame("Slider", "SpeedrunSplitsFontSlider", panel, "OptionsSliderTemplate")
panel.FontSlider:SetOrientation('HORIZONTAL')
panel.FontSlider.tooltipText = 'Size of the text displayed on screen for SpeedrunSplits'
_G["SpeedrunSplitsFontSliderLow"]:SetText("10");
_G["SpeedrunSplitsFontSliderHigh"]:SetText("20");
panel.FontSlider:SetPoint("TOPLEFT", panel.subtext, "BOTTOMLEFT", 0, -26)
panel.FontSlider:SetMinMaxValues(10,20)
panel.FontSlider:SetValueStep(1)
panel.FontSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

panel.RangeSlider = CreateFrame("Slider", "SpeedrunSplitsRangeSlider", panel, "OptionsSliderTemplate")
panel.RangeSlider:SetOrientation('HORIZONTAL')
panel.RangeSlider.tooltipText = 'Number of levels (rows) displayed on screen for SpeedrunSplits'
_G["SpeedrunSplitsRangeSliderLow"]:SetText("5");
_G["SpeedrunSplitsRangeSliderHigh"]:SetText(MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]-1);
panel.RangeSlider:SetPoint("TOPLEFT", panel.FontSlider, "TOPRIGHT", 20, 0)
panel.RangeSlider:SetMinMaxValues(5,MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]-1)
panel.RangeSlider:SetValueStep(1)
panel.RangeSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

panel.PBSlider = CreateFrame("Slider", "SpeedrunSplitsPBSlider", panel, "OptionsSliderTemplate")
panel.PBSlider:SetOrientation('HORIZONTAL')
panel.PBSlider.tooltipText = 'The level for SpeedrunSplits to automatically save character times upon reaching with a time faster than previously set'
_G["SpeedrunSplitsPBSliderLow"]:SetText("5");
_G["SpeedrunSplitsPBSliderHigh"]:SetText(MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]);
panel.PBSlider:SetPoint("TOPLEFT", panel.RangeSlider, "TOPRIGHT", 20, 0)
panel.PBSlider:SetMinMaxValues(5,MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()])
panel.PBSlider:SetValueStep(1)
panel.PBSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

panel.ShowHideCheckButton = CreateFrame("CheckButton", "SpeedrunSplitsShowHideCheckButton", panel, "ChatConfigCheckButtonTemplate");
panel.ShowHideCheckButton.tooltip = "Show/Hide SpeedrunSplits";
_G["SpeedrunSplitsShowHideCheckButtonText"]:SetText("Show SpeedrunSplits");
panel.ShowHideCheckButton:SetPoint("TOPLEFT", panel.FontSlider, "BOTTOMLEFT", 0, -26);

panel.MoveCheckButton = CreateFrame("CheckButton", "SpeedrunSplitsMoveCheckButton", panel, "ChatConfigCheckButtonTemplate");
panel.MoveCheckButton.tooltip = "SpeedrunSplits can be moved with the Interface Options window open";
_G["SpeedrunSplitsMoveCheckButtonText"]:SetText("Move SpeedrunSplits");
panel.MoveCheckButton:SetPoint("TOPLEFT", panel.ShowHideCheckButton, "BOTTOMLEFT", 0, 0);

panel.DaysCheckButton = CreateFrame("CheckButton", "SpeedrunSplitsDaysCheckButton", panel, "ChatConfigCheckButtonTemplate");
panel.DaysCheckButton.tooltip = "Display days in timers [D:HH:MM:SS]";
_G["SpeedrunSplitsDaysCheckButtonText"]:SetText("Display days in timers [D:HH:MM:SS]");
panel.DaysCheckButton:SetPoint("TOPLEFT", panel.MoveCheckButton, "BOTTOMLEFT", 0, 0);

panel.DeltaCheckButton = CreateFrame("CheckButton", "SpeedrunSplitsDeltaCheckButton", panel, "ChatConfigCheckButtonTemplate");
panel.DeltaCheckButton.tooltip = "Hides the Delta comparison times column";
_G["SpeedrunSplitsDeltaCheckButtonText"]:SetText("Hide Delta times");
panel.DeltaCheckButton:SetPoint("TOPLEFT", panel.DaysCheckButton, "BOTTOMLEFT", 0, 0);

panel.NextCheckButton = CreateFrame("CheckButton", "SpeedrunSplitsNextCheckButton", panel, "ChatConfigCheckButtonTemplate");
panel.NextCheckButton.tooltip = "Hides the next level from SpeedrunSplits";
_G["SpeedrunSplitsNextCheckButtonText"]:SetText("Hide next level time");
panel.NextCheckButton:SetPoint("TOPLEFT", panel.DeltaCheckButton, "BOTTOMLEFT", 0, 0);

panel.ColourCheckButton = CreateFrame("CheckButton", "SpeedrunSplitsColourCheckButton", panel, "ChatConfigCheckButtonTemplate");
panel.ColourCheckButton.tooltip = "Disables the colour comparisons in SpeedrunSplits";
_G["SpeedrunSplitsColourCheckButtonText"]:SetText("Disable colours");
panel.ColourCheckButton:SetPoint("TOPLEFT", panel.NextCheckButton, "BOTTOMLEFT", 0, 0);

panel.SaveButton = CreateFrame("Button", "SpeedrunSplitsSaveButton", panel, "UIPanelButtonTemplate");
panel.SaveButton:SetSize(144,22)
_G["SpeedrunSplitsSaveButtonText"]:SetText("Save Current Times");
panel.SaveButton:SetPoint("TOPLEFT", panel.PBSlider, "BOTTOMLEFT", 0, -20);

panel.PrintButton = CreateFrame("Button", "SpeedrunSplitsPrintButton", panel, "UIPanelButtonTemplate");
panel.PrintButton:SetSize(144,22)
_G["SpeedrunSplitsPrintButtonText"]:SetText("Print Times To Chat");
panel.PrintButton:SetPoint("TOPLEFT", panel.SaveButton, "BOTTOMLEFT", 0, -5);

panel.default = function (self)
	SpeedrunSplitsDefaults()
	SpeedrunSplitsInitialise()
	SpeedrunSplitsGenerateAll()
	print("[SpeedrunSplits] Settings have been reset to default.")
end

function SpeedrunSplitsExpansionLevel()
	ExpansionLevel = GetExpansionLevel()
end

SLASH_SpeedrunSplits1 = "/srs"
SLASH_SpeedrunSplits2 = "/speedrunsplits"
SlashCmdList["SpeedrunSplits"] = function(msg)
	InterfaceOptionsFrame_OpenToCategory(panel);
	InterfaceOptionsFrame_OpenToCategory(panel);
end

function f:OnEvent(event, arg1, arg2)
	if (event == "ADDON_LOADED" and arg1 == NAME) then
		_, SpeedrunSplitsRaceID = UnitRace("player")
		_, SpeedrunSplitsClassID = UnitClass("player")
		
		if SpeedrunSplitsPB == nil then
			SpeedrunSplitsPB = {}
		end
		if SpeedrunSplitsGold == nil then
			SpeedrunSplitsGold = {}
		end
		if SpeedrunSplitsOptions == nil or SpeedrunSplitsOptions["xpos"] == nil or	SpeedrunSplitsOptions["ypos"] == nil or SpeedrunSplitsOptions["PBLevel"] == nil or SpeedrunSplitsOptions["LevelRange"] == nil or SpeedrunSplitsOptions["FontSize"] == nil or SpeedrunSplitsOptions["Show"] == nil then
			SpeedrunSplitsOptions = {}
			SpeedrunSplitsDefaults()
		end
		if ExpansionTime == nil then
			ExpansionDiscount = 0
			ExpansionDiscountTotal = 0
			ExpansionTime = 0
		end
		f:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" and not self.isMoving and SpeedrunSplitsOptions["Move"] then
				_, _, _, xpos1, ypos1 = f:GetPoint(1)
				self:StartMoving();
				_, _, _, xpos2, ypos2 = f:GetPoint(1)
				self.isMoving = true;
			end
		end)
		f:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" and self.isMoving and SpeedrunSplitsOptions["Move"] then
				_, _, _, xpos3, ypos3 = f:GetPoint(1)
				self:StopMovingOrSizing()
				self.isMoving = false;
				SpeedrunSplitsOptions["xpos"] = xpos1 + xpos3 - xpos2
				SpeedrunSplitsOptions["ypos"] = ypos1 + ypos3 - ypos2
				self:SetPoint("TOPLEFT",SpeedrunSplitsOptions["xpos"],SpeedrunSplitsOptions["ypos"])
			end
		end)
		f:SetScript("OnHide", function(self)
			if self.isMoving then
				self:StopMovingOrSizing();
				self.isMoving = false;
			end
		end)

		panel.FontSlider:SetScript("OnValueChanged", function(self, newvalue)
			newvalue = floor(newvalue+0.5)
			SpeedrunSplitsOptions["FontSize"] = newvalue
			_G["SpeedrunSplitsFontSliderText"]:SetText("Font Size ("..newvalue..")");
			panel.FontSlider:SetValue(newvalue)
			f.timer:SetFont(SpeedrunSplitsFont, newvalue, "OUTLINE")
			f.text:SetFont(SpeedrunSplitsFont, newvalue, "OUTLINE")
			f.delta:SetFont(SpeedrunSplitsFont, newvalue, "OUTLINE")
			f.times:SetFont(SpeedrunSplitsFont, newvalue, "OUTLINE")
			f.times:SetWidth(f.times:GetStringWidth()+1)
		end)
		panel.PBSlider:SetScript("OnValueChanged", function(self, newvalue)
			newvalue = floor(newvalue+0.5)
			_G["SpeedrunSplitsPBSliderText"]:SetText("Automatic Save Level ("..newvalue..")");
			panel.PBSlider:SetValue(newvalue)
			SpeedrunSplitsOptions["PBLevel"] = newvalue
		end)
		panel.ShowHideCheckButton:SetScript("OnClick",function()
			if panel.ShowHideCheckButton:GetChecked() then
				f:Show()
				SpeedrunSplitsOptions["Show"] = true
			else
				SpeedrunSplitsOptions["Show"] = false
				f:Hide()
			end
		end)
		panel.MoveCheckButton:SetScript("OnClick",function()
			if panel.MoveCheckButton:GetChecked() then
				SpeedrunSplitsOptions["Move"] = true
				SpeedrunSplitsMovable()
			else
				SpeedrunSplitsOptions["Move"] = false
				f:SetMovable(false)
				f:EnableMouse(false)
			end
		end)
		panel.DaysCheckButton:SetScript("OnClick",function()
			if panel.DaysCheckButton:GetChecked() then
				SpeedrunSplitsOptions["Days"] = true
			else
				SpeedrunSplitsOptions["Days"] = false
			end
			SpeedrunSplitsGenerateAll()
		end)
		panel.DeltaCheckButton:SetScript("OnClick",function()
			if panel.DeltaCheckButton:GetChecked() then
				SpeedrunSplitsOptions["Delta"] = true
				f.times:SetPoint("TOPLEFT",f.text,"TOPRIGHT",5,0)
				f.delta:Hide()
			else
				SpeedrunSplitsOptions["Delta"] = false
				f.delta:Show()
				f.times:SetPoint("TOPLEFT",f.delta,"TOPRIGHT",5,0)
			end
			SpeedrunSplitsGenerateAll()
		end)
		panel.NextCheckButton:SetScript("OnClick",function()
			if panel.NextCheckButton:GetChecked() then
				SpeedrunSplitsOptions["Next"] = true
			else
				SpeedrunSplitsOptions["Next"] = false
			end
			SpeedrunSplitsRange(SpeedrunSplitsOptions["LevelRange"], SpeedrunSplitsLevel)
			SpeedrunSplitsGenerateAll()
		end)
		panel.ColourCheckButton:SetScript("OnClick",function()
			if panel.ColourCheckButton:GetChecked() then
				SpeedrunSplitsOptions["Colour"] = true
			else
				SpeedrunSplitsOptions["Colour"] = false
			end
			SpeedrunSplitsGenerateAll()
		end)
		panel.SaveButton:SetScript("OnClick",SpeedrunSplitsSave)
		panel.PrintButton:SetScript("OnClick",SpeedrunSplitsPrint)

		if not SpeedrunSplitsPB[SpeedrunSplitsRaceID] then
			SpeedrunSplitsPB[SpeedrunSplitsRaceID] = {}
			SpeedrunSplitsGold[SpeedrunSplitsRaceID] = {}
		end
		if not SpeedrunSplitsPB[SpeedrunSplitsRaceID][SpeedrunSplitsClassID] then
			SpeedrunSplitsPB[SpeedrunSplitsRaceID][SpeedrunSplitsClassID] = {}
			SpeedrunSplitsPB[SpeedrunSplitsRaceID][SpeedrunSplitsClassID][1] = 0
			SpeedrunSplitsGold[SpeedrunSplitsRaceID][SpeedrunSplitsClassID] = {}
			SpeedrunSplitsGold[SpeedrunSplitsRaceID][SpeedrunSplitsClassID][1] = 0
		end
		
		SpeedrunSplitsInitialise()
		
		for key , value in pairs(SpeedrunSplitsPB[SpeedrunSplitsRaceID][SpeedrunSplitsClassID]) do
			SpeedrunSplitsPBCopy[key] = value
		end
		
		f:SetScript("OnUpdate", f.OnUpdate)
	elseif (event == "PLAYER_LOGIN") then
		SpeedrunSplitsLevel = UnitLevel("player")
		SpeedrunSplitsXP = UnitXP("player")
		SpeedrunSplitsXPMax = UnitXPMax("player")
		if SpeedrunSplitsXP / SpeedrunSplitsXPMax > SpeedrunSplitsDeltaXP then
			SpeedrunSplitsXPWindow = true
		end

		if SpeedrunSplits == nil or SpeedrunSplitsLevel == 1 then
			SpeedrunSplits = {}
			SpeedrunSplits[1] = 0
		end

		f:RegisterEvent("TIME_PLAYED_MSG")
		f:RegisterEvent("PLAYER_XP_UPDATE")

		RequestTimePlayed()

		SpeedrunSplitsRange(SpeedrunSplitsOptions["LevelRange"], SpeedrunSplitsLevel)
		
		panel.RangeSlider:SetScript("OnValueChanged", function(self, newvalue)
			newvalue = floor(newvalue+0.5)
			_G["SpeedrunSplitsRangeSliderText"]:SetText("Level Range ("..newvalue..")");
			panel.RangeSlider:SetValue(newvalue)
			SpeedrunSplitsOptions["LevelRange"] = newvalue
			SpeedrunSplitsRange(newvalue, SpeedrunSplitsLevel)
			SpeedrunSplitsGenerateAll()
		end)
	elseif (event == "PLAYER_XP_UPDATE") then
		if UnitXP("player") < SpeedrunSplitsXP then
			SpeedrunSplitsXPMax = UnitXPMax("player")
		end
		SpeedrunSplitsXP = UnitXP("player")
		if SpeedrunSplitsXP / SpeedrunSplitsXPMax > SpeedrunSplitsDeltaXP then
			SpeedrunSplitsXPWindow = true
		else
			SpeedrunSplitsXPWindow = false
		end
	elseif (event == "PLAYER_LEVEL_UP") then
		SpeedrunSplitsLevel = arg1
		SpeedrunSplitsLevelUp = true
		SpeedrunSplitsXPWindow = false
		f:RegisterEvent("TIME_PLAYED_MSG")
		RequestTimePlayed()
		panel.SaveButton:SetEnabled(true)
		SpeedrunSplitsRange(SpeedrunSplitsOptions["LevelRange"], arg1)
	elseif (event == "TIME_PLAYED_MSG") then
		f:UnregisterEvent("TIME_PLAYED_MSG")
		local Discount = 0
		local DiscountTotal = 0

		if (SpeedrunSplitsLevelUp == false and ExpansionLevel ~= GetExpansionLevel()) then
			SpeedrunSplitsExpansionLevel()
			if (ExpansionLevel > 0) then
				ExpansionTime = arg1
				if (SpeedrunSplitsLevel == MAX_PLAYER_LEVEL_TABLE[ExpansionLevel-1]) then
					ExpansionDiscount = arg2
					ExpansionDiscountTotal = ExpansionDiscountTotal + ExpansionDiscount
				end
			end
		end

		SpeedrunSplits[SpeedrunSplitsLevel] = arg1 - arg2

		if (ExpansionLevel > 0) then
			if (SpeedrunSplitsLevel > MAX_PLAYER_LEVEL_TABLE[ExpansionLevel-1]) then
				DiscountTotal = ExpansionDiscountTotal
				SpeedrunSplits[SpeedrunSplitsLevel] = SpeedrunSplits[SpeedrunSplitsLevel] - DiscountTotal
			elseif (SpeedrunSplitsLevel == MAX_PLAYER_LEVEL_TABLE[ExpansionLevel-1]) then
				Discount = ExpansionDiscount
				DiscountTotal = ExpansionDiscountTotal
			end
		end

		SpeedrunSplitsTotalTime = arg1 - DiscountTotal
		SpeedrunSplitsExpansionTime = arg1 - ExpansionTime
		SpeedrunSplitsLevelTime = arg2 - Discount
		
		if SpeedrunSplitsLevel > 1 then
			if not SpeedrunSplitsPBCopy[SpeedrunSplitsLevel] then
				SpeedrunSplitsPB[SpeedrunSplitsRaceID][SpeedrunSplitsClassID][SpeedrunSplitsLevel] = SpeedrunSplits[SpeedrunSplitsLevel]
				SpeedrunSplitsPBCopy[SpeedrunSplitsLevel] = SpeedrunSplits[SpeedrunSplitsLevel]
				if SpeedrunSplits[SpeedrunSplitsLevel-1] then
					SpeedrunSplitsGold[SpeedrunSplitsRaceID][SpeedrunSplitsClassID][SpeedrunSplitsLevel] = SpeedrunSplits[SpeedrunSplitsLevel] - SpeedrunSplits[SpeedrunSplitsLevel-1]
				end
			end
			if SpeedrunSplitsPBCopy[SpeedrunSplitsLevel-1] and SpeedrunSplits[SpeedrunSplitsLevel-1] then
				if (SpeedrunSplitsPBCopy[SpeedrunSplitsLevel] - SpeedrunSplitsPBCopy[SpeedrunSplitsLevel-1] >= SpeedrunSplits[SpeedrunSplitsLevel] - SpeedrunSplits[SpeedrunSplitsLevel-1]) then
					SpeedrunSplitsGold[SpeedrunSplitsRaceID][SpeedrunSplitsClassID][SpeedrunSplitsLevel] = SpeedrunSplits[SpeedrunSplitsLevel] - SpeedrunSplits[SpeedrunSplitsLevel-1]
				end
			end
		end

		SpeedrunSplitsGenerateAll()

		if (SpeedrunSplitsOptions["PBLevel"] == SpeedrunSplitsLevel or SpeedrunSplitsLevel == MAX_PLAYER_LEVEL_TABLE[ExpansionLevel]) and SpeedrunSplitsLevelUp == true and SpeedrunSplits[SpeedrunSplitsLevel] < SpeedrunSplitsPB[SpeedrunSplitsRaceID][SpeedrunSplitsClassID][SpeedrunSplitsLevel] then
			print("[SpeedrunSplits] CONGRATULATIONS! You've beat your previous level", SpeedrunSplitsLevel, "time by", SpeedrunSplitsTime(SpeedrunSplitsPB[SpeedrunSplitsRaceID][SpeedrunSplitsClassID][SpeedrunSplitsLevel]-SpeedrunSplits[SpeedrunSplitsLevel]), "! Your current times have been recorded to be compared against for future runs.")
			SpeedrunSplitsSave()
		end

		SpeedrunSplitsTimers(SpeedrunSplits_UpdateInterval-TimeSinceLastUpdate)
		
		SpeedrunSplitsLevelUp = false
	elseif (event == "UPDATE_EXPANSION_LEVEL") then
		SpeedrunSplitsExpansionLevel()
	end
end

function f:OnUpdate(arg1)
	SpeedrunSplitsTimers(arg1)
end

function SpeedrunSplitsTimers(arg1)
	local TotalText = "";
	local ExpansionText = "";
	local LevelText = "";
	TimeSinceLastUpdate = TimeSinceLastUpdate + arg1;
	if (f.timer:GetText() == nil or (TimeSinceLastUpdate >= SpeedrunSplits_UpdateInterval and SpeedrunSplitsTotalTime >= 0)) then
		if (SpeedrunSplitsLevel < MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]) then
			SpeedrunSplitsTotalTime = SpeedrunSplitsTotalTime + SpeedrunSplits_UpdateInterval
			TotalText = "Total Time: "..SpeedrunSplitsTime(SpeedrunSplitsTotalTime).."\n"
			SpeedrunSplitsLevelTime = SpeedrunSplitsLevelTime + SpeedrunSplits_UpdateInterval
			LevelText = "Level Time: "..SpeedrunSplitsTime(SpeedrunSplitsLevelTime)
		else
			SpeedrunSplitsTotalTime = SpeedrunSplits[SpeedrunSplitsLevel] - ExpansionDiscountTotal
			TotalText = "Total Time: "..SpeedrunSplitsTime(SpeedrunSplits[SpeedrunSplitsLevel]).."\n"
		end

		SpeedrunSplitsGenerateDelta()
		
		if (GetExpansionLevel() > 0 and SpeedrunSplitsLevel >= MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()-1]) then
			if (SpeedrunSplitsLevel < MAX_PLAYER_LEVEL_TABLE[ExpansionLevel]) then
				SpeedrunSplitsExpansionTime = SpeedrunSplitsExpansionTime + SpeedrunSplits_UpdateInterval
			else
				SpeedrunSplitsExpansionTime = SpeedrunSplits[SpeedrunSplitsLevel] - ExpansionTime
			end
			ExpansionText = MAX_PLAYER_LEVEL_TABLE[ExpansionLevel-1].."-"..MAX_PLAYER_LEVEL_TABLE[ExpansionLevel].." Time: "..SpeedrunSplitsTime(SpeedrunSplitsExpansionTime).."\n"
		end
		if (SpeedrunSplitsLevel < MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]) then
		end
		if SpeedrunSplitsTotalTime > 0 then
			f.timer:SetText(TotalText..ExpansionText..LevelText)
		end

		TimeSinceLastUpdate = TimeSinceLastUpdate - SpeedrunSplits_UpdateInterval;
	end
	if (SpeedrunSplitsLevel == MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]) then 
		f:SetScript("OnUpdate", nil)
	end
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("UPDATE_EXPANSION_LEVEL")

f:SetScript("OnEvent", f.OnEvent)

function SpeedrunSplitsTime(time, diff)
	local plusminus = "+"
	local d = 0
	local h = 0
	if diff == 1 and time < 0 then
		time = -time
		plusminus = "-"
	end
	if SpeedrunSplitsOptions["Days"] == true then
		d = floor(time/60/60/24)
		h = floor(time/60/60-d*24)
	else
		h = floor(time/60/60)
	end
	local m = floor(time/60-d*24*60-h*60)
	local s = floor(time-d*24*60*60-h*60*60-m*60)
	if (h < 10) then
		h = "0"..tostring(h)
	else
		h = tostring(h)
	end
	if (m < 10) then
		m = "0"..tostring(m)
	else
		m = tostring(m)
	end
	if (s < 10) then
		s = "0"..tostring(s)
	else
		s = tostring(s)
	end
	if diff == nil then
		plusminus = ""
	end
	if d > 0 then
		d = d..":"
	else
		d = ""
	end
	if d == "" and h == "00" then
		h = ""
	else
		h = h..":"
	end
	if h == "" and m == "00" then
		m = ""
	else
		m = m..":"
	end
	if m == "" and s == "00" then
		s = ""
		plusminus = ""
	end

	return plusminus..d..h..m..s
end

function SpeedrunSplitsGenerateAll()
	SpeedrunSplitsDeltaUpdate = true
	SpeedrunSplitsGenerate()
	SpeedrunSplitsGenerateDelta()
end

function SpeedrunSplitsGenerate()
	if SpeedrunSplitsMax > 1 then
		local SpeedrunSplitsText = ""
		local SpeedrunSplitsSplitTime = ""
		for i=SpeedrunSplitsMin,SpeedrunSplitsMax do
			local SpeedrunSplitsDiffColor = "|cffffffff"
			if i > SpeedrunSplitsMin then
				SpeedrunSplitsText = SpeedrunSplitsText.."\n"
				SpeedrunSplitsSplitTime = SpeedrunSplitsSplitTime.."\n"
			end
			SpeedrunSplitsText = SpeedrunSplitsText.."Level "..i
			if i <= SpeedrunSplitsLevel and SpeedrunSplitsPBCopy[i] and SpeedrunSplits[i] then
				local SpeedrunSplitsDiff = SpeedrunSplits[i]-SpeedrunSplitsPBCopy[i]
				if not SpeedrunSplitsOptions["Colour"] then
					if SpeedrunSplitsDiff < 0 then
						SpeedrunSplitsDiffColor = "|cff00aa00"
					elseif SpeedrunSplitsDiff > 0 then
						SpeedrunSplitsDiffColor = "|cffff0000"
					end
					if SpeedrunSplitsGold[SpeedrunSplitsRaceID][SpeedrunSplitsClassID][i] and SpeedrunSplits[i-1] and not SpeedrunSplitsOptions["Delta"] then
						if SpeedrunSplitsGold[SpeedrunSplitsRaceID][SpeedrunSplitsClassID][i] == SpeedrunSplits[i]-SpeedrunSplits[i-1] then
							SpeedrunSplitsDiffColor = "|cffffff00"
						end
					end
				end
				SpeedrunSplitsSplitTime = SpeedrunSplitsSplitTime..SpeedrunSplitsDiffColor..SpeedrunSplitsTime(SpeedrunSplits[i]).."|r"
			elseif SpeedrunSplitsPBCopy[i] then
				SpeedrunSplitsSplitTime = SpeedrunSplitsSplitTime..SpeedrunSplitsTime(SpeedrunSplitsPBCopy[i])
			end
		end

		f.text:SetText(SpeedrunSplitsText)
		f.times:SetText(SpeedrunSplitsSplitTime)
		
		f.times:SetWidth(f.times:GetStringWidth()+1)
	end
end

function SpeedrunSplitsGenerateDelta()
	if not SpeedrunSplitsOptions["Delta"] or SpeedrunSplitsMax > 1 then
		local SpeedrunSplitsDiffColor = "|cffffffff"
		local SpeedrunSplitsDeltaTime = 0
		local SpeedrunSplitsDelta = ""
		if SpeedrunSplitsLevel < MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()] and SpeedrunSplitsPBCopy[SpeedrunSplitsLevel+1] and not SpeedrunSplitsOptions["Next"] then
			if SpeedrunSplitsPBCopy[SpeedrunSplitsLevel+1] - SpeedrunSplitsDeltaDiff < SpeedrunSplitsTotalTime or SpeedrunSplitsXPWindow then
				SpeedrunSplitsDeltaUpdate = true
				SpeedrunSplitsDeltaTime = SpeedrunSplitsTotalTime - SpeedrunSplitsPBCopy[SpeedrunSplitsLevel+1]
				if not SpeedrunSplitsOptions["Colour"] then
					if SpeedrunSplitsDeltaTime < 0 then
						SpeedrunSplitsDiffColor = "|cff00aa00"
					elseif SpeedrunSplitsDeltaTime > 0 then
						SpeedrunSplitsDiffColor = "|cffff0000"
					end
				end
				SpeedrunSplitsDelta = SpeedrunSplitsDiffColor..SpeedrunSplitsTime(SpeedrunSplitsDeltaTime,1).."|r"
			end
		end

		if SpeedrunSplitsDeltaUpdate then
			for i=SpeedrunSplitsLevel,SpeedrunSplitsMin,-1 do
				if SpeedrunSplits[i] and SpeedrunSplitsPBCopy[i] then
					SpeedrunSplitsDeltaTime = SpeedrunSplits[i]-SpeedrunSplitsPBCopy[i]
					if not SpeedrunSplitsOptions["Colour"] then
						if SpeedrunSplitsDeltaTime < 0 then
							SpeedrunSplitsDiffColor = "|cff00aa00"
						elseif SpeedrunSplitsDeltaTime > 0 then
							SpeedrunSplitsDiffColor = "|cffff0000"
						end
					end
				end
				if SpeedrunSplits[i] then
					SpeedrunSplitsDelta = SpeedrunSplitsDiffColor..SpeedrunSplitsTime(SpeedrunSplitsDeltaTime,1).."|r\n"..SpeedrunSplitsDelta
				else
					SpeedrunSplitsDelta = "\n"..SpeedrunSplitsDelta
				end
			end

			f.delta:SetText(SpeedrunSplitsDelta)
			SpeedrunSplitsDeltaUpdate = false
			if f.delta:GetWidth() < f.delta:GetStringWidth()+1 then
				f.delta:SetWidth(f.delta:GetStringWidth()+1)
			end
			if SpeedrunSplitsOptions["Move"] then
				SpeedrunSplitsMovable()
			end
		end
	end
end

function SpeedrunSplitsSave()
	for i=2,SpeedrunSplitsLevel do
		if SpeedrunSplits[i] then
			SpeedrunSplitsPB[SpeedrunSplitsRaceID][SpeedrunSplitsClassID][i] = SpeedrunSplits[i]
		end
	end
	print("[SpeedrunSplits] Current character times have been recorded up to level", SpeedrunSplitsLevel, ". Times will be compared against for future runs.")
	panel.SaveButton:SetEnabled(false)
end

function SpeedrunSplitsPrint()
	for i=2,SpeedrunSplitsLevel do
		if SpeedrunSplits[i] then
			print("Level", i, ":", SpeedrunSplitsTime(SpeedrunSplits[i]))
		end
	end
end

function SpeedrunSplitsMovable()
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetWidth(f.text:GetStringWidth()+f.delta:GetWidth()+f.times:GetWidth()+10) 
	f:SetHeight(f.text:GetStringHeight()+f.timer:GetStringHeight()+5)
end

function SpeedrunSplitsRange(range, level)
	if SpeedrunSplitsOptions["Next"] then
		SpeedrunSplitsMax = level
		SpeedrunSplitsMin = SpeedrunSplitsMax - range + 1
		if SpeedrunSplitsMin < 2 then
			SpeedrunSplitsMin = 2
		end
	else
		SpeedrunSplitsMax = level + 1
		if SpeedrunSplitsMax > MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()] then
			SpeedrunSplitsMax = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
		elseif SpeedrunSplitsMax < range + 1 then
			SpeedrunSplitsMax = range + 1
		end
		SpeedrunSplitsMin = SpeedrunSplitsMax - range + 1
	end
end

function SpeedrunSplitsInitialise()
	f:SetPoint("TOPLEFT",SpeedrunSplitsOptions["xpos"],SpeedrunSplitsOptions["ypos"])

	if SpeedrunSplitsOptions["Show"] then
		f:Show()
	else
		f:Hide()
	end

	if SpeedrunSplitsOptions["Delta"] then
		f.times:SetPoint("TOPLEFT",f.text,"TOPRIGHT",5,0)
		f.delta:Hide()
	else
		f.delta:Show()
		f.times:SetPoint("TOPLEFT",f.delta,"TOPRIGHT",5,0)
	end

	f.text:SetFont(SpeedrunSplitsFont, SpeedrunSplitsOptions["FontSize"], "OUTLINE")
	f.timer:SetFont(SpeedrunSplitsFont, SpeedrunSplitsOptions["FontSize"], "OUTLINE")
	f.delta:SetFont(SpeedrunSplitsFont, SpeedrunSplitsOptions["FontSize"], "OUTLINE")
	f.times:SetFont(SpeedrunSplitsFont, SpeedrunSplitsOptions["FontSize"], "OUTLINE")

	panel.FontSlider:SetValue(SpeedrunSplitsOptions["FontSize"])
	panel.RangeSlider:SetValue(SpeedrunSplitsOptions["LevelRange"])
	panel.PBSlider:SetValue(SpeedrunSplitsOptions["PBLevel"])
	panel.ShowHideCheckButton:SetChecked(SpeedrunSplitsOptions["Show"])
	panel.MoveCheckButton:SetChecked(SpeedrunSplitsOptions["Move"])
	panel.DaysCheckButton:SetChecked(SpeedrunSplitsOptions["Days"])
	panel.DeltaCheckButton:SetChecked(SpeedrunSplitsOptions["Delta"])
	panel.NextCheckButton:SetChecked(SpeedrunSplitsOptions["Next"])
	panel.ColourCheckButton:SetChecked(SpeedrunSplitsOptions["Colour"])

	_G["SpeedrunSplitsFontSliderText"]:SetText("Font Size ("..SpeedrunSplitsOptions["FontSize"]..")");
	_G["SpeedrunSplitsRangeSliderText"]:SetText("Level Range ("..SpeedrunSplitsOptions["LevelRange"]..")");
	_G["SpeedrunSplitsPBSliderText"]:SetText("Automatic Save Level ("..SpeedrunSplitsOptions["PBLevel"]..")");
end