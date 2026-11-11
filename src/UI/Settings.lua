LuaPad = LuaPad or {}
local LP = LuaPad

local STEPS = { 3, 5, 8, 10, 15, 20, 30, 60 }

function LP.OpenSettings()
  if Settings and Settings.OpenToCategory and LP.SettingsCategory then
    Settings.OpenToCategory(LP.SettingsCategory:GetID())
  end
end

local function Build()
  if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
  local panel = CreateFrame("Frame")
  panel.name = "LuaPad"

  local icon = panel:CreateTexture(nil, "ARTWORK")
  icon:SetSize(40, 40)
  icon:SetPoint("TOPLEFT", 16, -16)
  icon:SetTexture("Interface\\AddOns\\LuaPad\\LuaPad")

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
  title:SetPoint("LEFT", icon, "RIGHT", 10, 0)
  title:SetText("LuaPad")
  title:SetTextColor(0.9, 0.2, 0.25, 1)

  local open = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  open:SetSize(280, 32)
  open:SetPoint("CENTER", panel, "CENTER", 0, 0)
  open:SetText("Open LuaPad")
  open:SetScript("OnClick", function()
    if SettingsPanel and HideUIPanel then HideUIPanel(SettingsPanel) end
    LP.ToggleEditor()
  end)

  local box = CreateFrame("Frame", nil, panel)
  box:SetSize(280, 70)
  box:SetPoint("TOP", open, "BOTTOM", 0, -28)

  local check = CreateFrame("CheckButton", nil, box, "UICheckButtonTemplate")
  check:SetSize(26, 26)
  check:SetPoint("TOPLEFT", box, "TOPLEFT", 0, 0)
  local checkLabel = box:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  checkLabel:SetPoint("LEFT", check, "RIGHT", 4, 0)
  checkLabel:SetText("Show a popup when a snippet has an error")

  local durLabel = box:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  durLabel:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -40)
  durLabel:SetText("Show it for")
  local minus = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
  minus:SetSize(26, 22)
  minus:SetPoint("LEFT", durLabel, "RIGHT", 12, 0)
  minus:SetText("-")
  local value = box:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  value:SetWidth(64)
  value:SetPoint("LEFT", minus, "RIGHT", 4, 0)
  local plus = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
  plus:SetSize(26, 22)
  plus:SetPoint("LEFT", value, "RIGHT", 4, 0)
  plus:SetText("+")

  local function Refresh()
    if not LuaPadDB then return end
    local on = LP.ErrorPopupEnabled()
    local secs = LP.ErrorPopupTime()
    check:SetChecked(on)
    value:SetText(secs .. " sec")
    durLabel:SetAlpha(on and 1 or 0.4)
    value:SetAlpha(on and 1 or 0.4)
    minus:SetEnabled(on and secs > STEPS[1])
    plus:SetEnabled(on and secs < STEPS[#STEPS])
  end

  local function Step(dir)
    local secs = LP.ErrorPopupTime()
    local pick = secs
    if dir > 0 then
      for _, s in ipairs(STEPS) do if s > secs then pick = s break end end
    else
      for i = #STEPS, 1, -1 do if STEPS[i] < secs then pick = STEPS[i] break end end
    end
    LuaPadDB.errorPopupTime = pick
    Refresh()
  end

  check:SetScript("OnClick", function(self)
    if not LuaPadDB then return end
    LuaPadDB.errorPopup = self:GetChecked() and true or false
    Refresh()
  end)
  minus:SetScript("OnClick", function() Step(-1) end)
  plus:SetScript("OnClick", function() Step(1) end)
  panel:SetScript("OnShow", Refresh)

  LP.SettingsCategory = Settings.RegisterCanvasLayoutCategory(panel, "LuaPad")
  Settings.RegisterAddOnCategory(LP.SettingsCategory)
end

Build()
