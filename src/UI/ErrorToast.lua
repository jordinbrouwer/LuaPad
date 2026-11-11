LuaPad = LuaPad or {}
local LP = LuaPad
local UI = LP.UI
local T = UI.THEME

local toast
LP.TOAST_DEFAULT = 10

function LP.ErrorPopupEnabled()
  return not (LuaPadDB and LuaPadDB.errorPopup == false)
end

function LP.ErrorPopupTime()
  return tonumber(LuaPadDB and LuaPadDB.errorPopupTime) or LP.TOAST_DEFAULT
end

local function Build()
  toast = CreateFrame("Button", "LuaPadErrorToast", UIParent)
  toast:SetSize(360, 80)
  toast:SetPoint("TOP", UIParent, "TOP", 0, -120)
  toast:SetFrameStrata("FULLSCREEN_DIALOG")
  toast:SetClampedToScreen(true)
  toast:RegisterForClicks("LeftButtonUp")
  toast:Hide()
  local bg = toast:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(toast)
  bg:SetColorTexture(unpack(T.WINDOW))
  UI.AddBorder(toast, T.GOLD)

  local icon = toast:CreateTexture(nil, "ARTWORK")
  icon:SetSize(28, 28)
  icon:SetPoint("TOPLEFT", toast, "TOPLEFT", 12, -12)
  icon:SetTexture("Interface\\AddOns\\LuaPad\\LuaPad")

  toast.Title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  toast.Title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1)
  toast.Title:SetPoint("RIGHT", toast, "RIGHT", -12, 0)
  toast.Title:SetJustifyH("LEFT")
  toast.Title:SetWordWrap(false)
  toast.Title:SetTextColor(unpack(T.GOLD))

  toast.Msg = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  toast.Msg:SetPoint("TOPLEFT", toast.Title, "BOTTOMLEFT", 0, -5)
  toast.Msg:SetPoint("RIGHT", toast, "RIGHT", -12, 0)
  toast.Msg:SetJustifyH("LEFT")
  toast.Msg:SetJustifyV("TOP")
  toast.Msg:SetMaxLines(3)
  if toast.Msg.SetNonSpaceWrap then toast.Msg:SetNonSpaceWrap(true) end

  toast.Hint = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  toast.Hint:SetPoint("BOTTOMRIGHT", toast, "BOTTOMRIGHT", -12, 9)
  toast.Hint:SetText("Click to open in LuaPad")
  toast.Hint:SetTextColor(unpack(T.GRAY))

  toast.Bar = toast:CreateTexture(nil, "OVERLAY")
  toast.Bar:SetHeight(2)
  toast.Bar:SetPoint("BOTTOMLEFT", toast, "BOTTOMLEFT", 1, 1)
  toast.Bar:SetColorTexture(unpack(T.GOLD))

  toast:SetScript("OnEnter", function(self) self.paused = true end)
  toast:SetScript("OnLeave", function(self) self.paused = false end)
  toast:SetScript("OnUpdate", function(self, elapsed)
    if not self.paused then self.left = self.left - elapsed end
    if self.left <= 0 then
      self:Hide()
      return
    end
    self.Bar:SetWidth(math.max(1, (self:GetWidth() - 2) * self.left / self.total))
  end)
  toast:SetScript("OnClick", function(self)
    self:Hide()
    if LP.OpenSnippet then LP.OpenSnippet(self.id) end
  end)
end

function LP.ShowErrorToast(snippet, line, text)
  if not LP.ErrorPopupEnabled() then return end
  if LP.IsShowingSnippet and LP.IsShowingSnippet(snippet.id) then return end
  if not toast then Build() end
  toast.id = snippet.id
  local name = (snippet.name and snippet.name ~= "") and snippet.name or "Untitled"
  toast.Title:SetText("Error in " .. name)
  toast.Msg:SetText((line and ("Line " .. line .. ": ") or "") .. tostring(text))
  toast.total = LP.ErrorPopupTime()
  toast.left = toast.total
  toast.paused = toast:IsMouseOver()
  toast:Show()
end
