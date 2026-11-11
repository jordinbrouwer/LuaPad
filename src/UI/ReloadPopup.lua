LuaPad = LuaPad or {}
local LP = LuaPad
local UI = LP.UI
local T = UI.THEME

local popup, shade

function LP.NeedsReload(code)
  code = (code or ""):gsub("%-%-%[(=*)%[.-%]%1%]", ""):gsub("%-%-[^\n]*", "")
  if code:find("HookScript%s*%(") then return "HookScript" end
  if code:find("SetScript%s*%(") then return "SetScript" end
end

local function Build()
  -- The shade leaves the title bar uncovered so its X still closes LuaPad.
  local host = LuaPadFrame or UIParent
  shade = CreateFrame("Frame", nil, host)
  if host == UIParent then
    shade:SetAllPoints(UIParent)
  else
    shade:SetPoint("TOPLEFT", host, "TOPLEFT", 1, -31)
    shade:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -1, 1)
  end
  shade:SetFrameLevel(host:GetFrameLevel() + 200)
  shade:EnableMouse(true)
  shade:EnableMouseWheel(true)
  shade:SetScript("OnMouseWheel", function() end)
  shade:Hide()
  local dim = shade:CreateTexture(nil, "BACKGROUND")
  dim:SetAllPoints(shade)
  dim:SetColorTexture(0.03, 0.03, 0.04, 0.72)

  popup = CreateFrame("Frame", "LuaPadReloadPopup", shade)
  popup:SetSize(440, 160)
  popup:SetPoint("CENTER", shade, "CENTER", 0, 20)
  popup:SetFrameStrata("FULLSCREEN_DIALOG")
  popup:SetClampedToScreen(true)
  popup:EnableMouse(true)
  local bg = popup:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(popup)
  bg:SetColorTexture(unpack(T.WINDOW))
  UI.AddBorder(popup, T.GOLD)

  local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", popup, "TOPLEFT", 20, -18)
  title:SetText("You need to reload")
  title:SetTextColor(unpack(T.GOLD))

  popup.Text = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  popup.Text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
  popup.Text:SetPoint("RIGHT", popup, "RIGHT", -20, 0)
  popup.Text:SetJustifyH("LEFT")
  popup.Text:SetJustifyV("TOP")

  local now = UI.CreateButton(popup, "Reload now", 150, true, function() ReloadUI() end)
  now:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -20, 18)
  local later = UI.CreateButton(popup, "I'll do that later", 150, false, function() shade:Hide() end)
  later:SetPoint("RIGHT", now, "LEFT", -10, 0)
end

function LP.CheckReload(code)
  local call = LP.NeedsReload(code)
  if not call then return end
  if not popup then Build() end
  popup.Text:SetText(("This snippet uses |cffe6333f%s|r. Those changes can't be undone while the game is running, so old versions keep running until you reload the UI."):format(call))
  local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
  if focus and focus.ClearFocus then focus:ClearFocus() end
  shade:Show()
end
