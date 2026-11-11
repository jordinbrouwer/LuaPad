LuaPad = LuaPad or {}

local UI = {}
LuaPad.UI = UI

UI.WHITE = "Interface\\Buttons\\WHITE8X8"

UI.THEME = {
  GOLD = { 0.9, 0.2, 0.25, 1 },
  WINDOW = { 0.06, 0.06, 0.07, 0.97 },
  TITLE = { 0.11, 0.11, 0.12, 1 },
  BORDER = { 0.32, 0.32, 0.35, 1 },
  LINE = { 0.25, 0.25, 0.28, 1 },
  INSET = { 0.1, 0.1, 0.11, 1 },
  CODE = { 0.075, 0.078, 0.09, 1 },
  BUTTON = { 0.14, 0.14, 0.16, 0.95 },
  BUTTON_ON = { 0.3, 0.06, 0.08, 0.95 },
  TRACK = { 0.2, 0.2, 0.23, 1 },
  RED = { 0.95, 0.42, 0.42, 1 },
  GREEN = { 0.4, 0.85, 0.5, 1 },
  GRAY = { 0.5, 0.52, 0.58, 1 },
}
local THEME = UI.THEME

function UI.Clamp(v, lo, hi)
  if v < lo then return lo elseif v > hi then return hi end
  return v
end

function UI.AddBorder(frame, color)
  local function Edge(p1, p2, x1, y1, x2, y2)
    local line = frame:CreateTexture(nil, "BORDER")
    line:SetColorTexture(unpack(color))
    line:SetPoint(p1, frame, p1, x1, y1)
    line:SetPoint(p2, frame, p2, x2, y2)
    return line
  end
  return {
    Edge("TOPLEFT", "TOPRIGHT", 0, 0, 0, -1),
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", 0, 1, 0, 0),
    Edge("TOPLEFT", "BOTTOMLEFT", 0, 0, 1, 0),
    Edge("TOPRIGHT", "BOTTOMRIGHT", -1, 0, 0, 0),
  }
end

function UI.SetBorderColor(lines, color)
  for _, line in ipairs(lines) do
    line:SetColorTexture(unpack(color))
  end
end

function UI.AddTooltip(frame, text)
  frame:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(type(text) == "function" and text() or text, nil, nil, nil, nil, true)
    GameTooltip:Show()
  end)
  frame:HookScript("OnLeave", GameTooltip_Hide)
end

function UI.CreateButton(parent, text, width, primary, onClick, tooltipText)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(width, 24)
  button.Background = button:CreateTexture(nil, "BACKGROUND")
  button.Background:SetAllPoints(button)
  button.Border = UI.AddBorder(button, primary and THEME.GOLD or THEME.BORDER)
  button.Label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  button.Label:SetPoint("CENTER", button, "CENTER", 0, 0)
  button.Label:SetText(text)
  function button:Rest()
    self.Background:SetColorTexture(unpack(primary and THEME.BUTTON_ON or THEME.BUTTON))
    if primary then self.Label:SetTextColor(unpack(THEME.GOLD)) else self.Label:SetTextColor(1, 1, 1, 1) end
    UI.SetBorderColor(self.Border, primary and THEME.GOLD or THEME.BORDER)
  end
  button:Rest()
  button:SetScript("OnEnter", function()
    button.Background:SetColorTexture(0.24, 0.24, 0.28, 0.98)
    UI.SetBorderColor(button.Border, THEME.GOLD)
  end)
  button:SetScript("OnLeave", function() button:Rest() end)
  button:SetScript("OnMouseDown", function() button.Label:SetPoint("CENTER", button, "CENTER", 0, -1) end)
  button:SetScript("OnMouseUp", function() button.Label:SetPoint("CENTER", button, "CENTER", 0, 0) end)
  button:SetScript("OnClick", onClick)
  if tooltipText then UI.AddTooltip(button, tooltipText) end
  return button
end

function UI.CreateToggle(parent, text, onChange)
  local toggle = CreateFrame("Button", nil, parent)
  toggle:SetSize(110, 24)
  toggle.Track = toggle:CreateTexture(nil, "BACKGROUND")
  toggle.Track:SetSize(34, 16)
  toggle.Track:SetPoint("LEFT", toggle, "LEFT", 0, 0)
  toggle.Knob = toggle:CreateTexture(nil, "ARTWORK")
  toggle.Knob:SetSize(12, 12)
  toggle.Label = toggle:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  toggle.Label:SetPoint("LEFT", toggle.Track, "RIGHT", 8, 0)
  toggle.Label:SetText(text)
  function toggle:SetChecked(value)
    self.checked = value and true or false
    self.Knob:ClearAllPoints()
    if self.checked then
      self.Track:SetColorTexture(0.5, 0.1, 0.13, 1)
      self.Knob:SetColorTexture(unpack(THEME.GOLD))
      self.Knob:SetPoint("RIGHT", self.Track, "RIGHT", -2, 0)
    else
      self.Track:SetColorTexture(unpack(THEME.TRACK))
      self.Knob:SetColorTexture(0.6, 0.6, 0.65, 1)
      self.Knob:SetPoint("LEFT", self.Track, "LEFT", 2, 0)
    end
  end
  toggle:SetChecked(false)
  toggle:SetScript("OnClick", function()
    toggle:SetChecked(not toggle.checked)
    if onChange then onChange(toggle.checked) end
  end)
  return toggle
end

function UI.CreateEdit(parent, width, height)
  local edit = CreateFrame("EditBox", nil, parent)
  edit:SetSize(width, height or 24)
  edit:SetAutoFocus(false)
  edit:SetFontObject("GameFontHighlight")
  edit:SetTextInsets(10, 10, 0, 0)
  edit.Background = edit:CreateTexture(nil, "BACKGROUND")
  edit.Background:SetAllPoints(edit)
  edit.Background:SetColorTexture(unpack(THEME.INSET))
  edit.Border = UI.AddBorder(edit, THEME.BORDER)
  edit:SetScript("OnEditFocusGained", function() UI.SetBorderColor(edit.Border, THEME.GOLD) end)
  edit:SetScript("OnEditFocusLost", function() UI.SetBorderColor(edit.Border, THEME.BORDER) end)
  edit:SetScript("OnEscapePressed", edit.ClearFocus)
  return edit
end

-- Values are scroll offsets: 0 is the top / left.
function UI.CreateScrollbar(parent, vertical)
  local bar = CreateFrame("Slider", nil, parent)
  bar:SetOrientation(vertical and "VERTICAL" or "HORIZONTAL")
  if vertical then bar:SetWidth(8) else bar:SetHeight(8) end
  bar.Track = bar:CreateTexture(nil, "BACKGROUND")
  bar.Track:SetAllPoints(bar)
  bar.Track:SetColorTexture(0.2, 0.2, 0.23, 0.45)
  bar:SetThumbTexture(UI.WHITE)
  bar.Thumb = bar:GetThumbTexture()
  bar.Thumb:SetColorTexture(0.42, 0.42, 0.48, 1)
  function bar:SetThumbLength(length)
    if vertical then self.Thumb:SetSize(8, length) else self.Thumb:SetSize(length, 8) end
  end
  if vertical then
    -- A vertical Slider has its minimum at the bottom, so values are flipped here. The wanted
    -- value is remembered because the offset often arrives before the range and would be clamped.
    local rawMinMax, rawSet, rawGet, rawSetScript = bar.SetMinMaxValues, bar.SetValue, bar.GetValue, bar.SetScript
    local max, val, internal = 0, 0, false
    local function Apply(self)
      internal = true
      rawSet(self, max - math.max(0, math.min(max, val)))
      internal = false
    end
    function bar:SetMinMaxValues(lo, hi)
      max = hi
      internal = true
      rawMinMax(self, lo, hi)
      internal = false
      Apply(self)
    end
    function bar:SetValue(v)
      val = v
      Apply(self)
    end
    function bar:GetValue() return max - rawGet(self) end
    function bar:SetScript(name, fn)
      if name == "OnValueChanged" and fn then
        rawSetScript(self, name, function(s, value, ...)
          if not internal then val = max - value end
          fn(s, max - value, ...)
        end)
      else
        rawSetScript(self, name, fn)
      end
    end
  end

  bar:EnableMouse(true)
  bar:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" then return end
    local x, y = GetCursorPosition()
    local scale = self:GetEffectiveScale()
    x, y = x / scale, y / scale
    local thumb = self.Thumb
    local tl, tr, tt, tb = thumb:GetLeft(), thumb:GetRight(), thumb:GetTop(), thumb:GetBottom()
    if tl and x >= tl and x <= tr and y >= tb and y <= tt then return end
    local _, hi = self:GetMinMaxValues()
    if not hi or hi <= 0 then return end
    local frac
    if vertical then
      local len = thumb:GetHeight()
      frac = ((self:GetTop() - y) - len / 2) / math.max(1, self:GetHeight() - len)
    else
      local len = thumb:GetWidth()
      frac = ((x - self:GetLeft()) - len / 2) / math.max(1, self:GetWidth() - len)
    end
    self:SetValue(math.max(0, math.min(1, frac)) * hi)
  end)

  bar:SetThumbLength(30)
  bar:SetMinMaxValues(0, 0)
  bar:SetValue(0)
  return bar
end

local menu, catcher

function UI.CloseMenu()
  if menu then menu:Hide() end
  if catcher then catcher:Hide() end
end

local function EnsureMenu()
  if menu then return end
  catcher = CreateFrame("Button", nil, UIParent)
  catcher:SetFrameStrata("FULLSCREEN_DIALOG")
  catcher:SetAllPoints(UIParent)
  catcher:SetScript("OnClick", UI.CloseMenu)
  catcher:Hide()
  menu = CreateFrame("Frame", nil, UIParent)
  menu:SetFrameStrata("FULLSCREEN_DIALOG")
  menu:SetFrameLevel(catcher:GetFrameLevel() + 10)
  menu:EnableMouse(true)
  menu.bg = menu:CreateTexture(nil, "BACKGROUND")
  menu.bg:SetAllPoints(menu)
  menu.bg:SetColorTexture(0.09, 0.09, 0.1, 0.99)
  menu.border = UI.AddBorder(menu, THEME.GOLD)
  menu.rows = {}
  menu:Hide()
end

local function MenuRow(i)
  local row = menu.rows[i]
  if row then return row end
  row = CreateFrame("Button", nil, menu)
  row:SetHeight(20)
  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints(row)
  row.bg:SetColorTexture(0, 0, 0, 0)
  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.label:SetPoint("LEFT", row, "LEFT", 10, 0)
  row.label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
  row.label:SetJustifyH("LEFT")
  row.label:SetWordWrap(false)
  row:SetScript("OnEnter", function(self) self.bg:SetColorTexture(0.24, 0.07, 0.09, 1) end)
  row:SetScript("OnLeave", function(self) self.bg:SetColorTexture(0, 0, 0, 0) end)
  row:SetScript("OnClick", function(self)
    UI.CloseMenu()
    if self.onPick then self.onPick(self.item) end
  end)
  menu.rows[i] = row
  return row
end

function UI.OpenMenu(anchor, items, current, onPick)
  EnsureMenu()
  local rowH = 20
  for i, item in ipairs(items) do
    local row = MenuRow(i)
    row.item, row.onPick = item, onPick
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", menu, "TOPLEFT", 2, -2 - (i - 1) * rowH)
    row:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -2, -2 - (i - 1) * rowH)
    row.label:SetText(item.label)
    if item.value == current then row.label:SetTextColor(unpack(THEME.GOLD)) else row.label:SetTextColor(1, 1, 1, 1) end
    row:Show()
  end
  for i = #items + 1, #menu.rows do menu.rows[i]:Hide() end
  menu:SetSize(math.max(anchor:GetWidth(), 140), #items * rowH + 4)
  menu:ClearAllPoints()
  if (anchor:GetBottom() or 0) - menu:GetHeight() < 20 then
    menu:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
  else
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
  end
  catcher:Show()
  menu:Show()
end

-- items = { { value = ..., label = "..." }, ... }
function UI.CreateDropdown(parent, width, items, onSelect)
  local dd = CreateFrame("Button", nil, parent)
  dd:SetSize(width, 24)
  dd.items = items
  dd.Background = dd:CreateTexture(nil, "BACKGROUND")
  dd.Background:SetAllPoints(dd)
  dd.Background:SetColorTexture(unpack(THEME.BUTTON))
  dd.Border = UI.AddBorder(dd, THEME.BORDER)
  dd.Label = dd:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  dd.Label:SetPoint("LEFT", dd, "LEFT", 10, 0)
  dd.Label:SetPoint("RIGHT", dd, "RIGHT", -24, 0)
  dd.Label:SetJustifyH("LEFT")
  dd.Label:SetWordWrap(false)
  dd.Arrow = dd:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  dd.Arrow:SetPoint("RIGHT", dd, "RIGHT", -9, 0)
  dd.Arrow:SetText("v")
  dd.Arrow:SetTextColor(unpack(THEME.GOLD))
  function dd:SetValue(value)
    self.value = value
    local text = "Select..."
    for _, item in ipairs(self.items) do
      if item.value == value then text = item.label break end
    end
    self.Label:SetText(text)
  end
  dd:SetScript("OnEnter", function() UI.SetBorderColor(dd.Border, THEME.GOLD) end)
  dd:SetScript("OnLeave", function() UI.SetBorderColor(dd.Border, THEME.BORDER) end)
  dd:SetScript("OnClick", function(self)
    UI.OpenMenu(self, self.items, self.value, function(item)
      self:SetValue(item.value)
      if onSelect then onSelect(item.value, item) end
    end)
  end)
  return dd
end
