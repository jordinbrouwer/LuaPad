LuaPad = LuaPad or {}
local LP = LuaPad
local B = LP.Builder
local TEXT_Y = B.TEXT_Y

local Fx = {}
LP.Fx = Fx

local function RGB(color)
  local c = B.Find(B.COLORS, color)
  return c and c.rgb or (type(color) == "table" and color) or { 1, 1, 1 }
end

function Fx.Sound(id)
  id = tonumber(id)
  if id then PlaySound(id, "Master") end
end

local textFrame
function Fx.Text(message, color, size, duration, pos)
  if not textFrame then
    textFrame = CreateFrame("Frame", nil, UIParent)
    textFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    textFrame:SetSize(2, 2)
    textFrame.Text = textFrame:CreateFontString(nil, "OVERLAY")
    textFrame.Text:SetPoint("CENTER")
    textFrame:Hide()
    textFrame:SetScript("OnUpdate", function(self)
      local left = self.expire - GetTime()
      if left <= 0 then
        self:Hide()
      elseif left < 0.5 then
        self:SetAlpha(left / 0.5)
      end
    end)
  end
  local rgb = RGB(color)
  textFrame.Text:SetFont(STANDARD_TEXT_FONT, tonumber(size) or 36, "OUTLINE")
  textFrame.Text:SetTextColor(rgb[1], rgb[2], rgb[3], 1)
  textFrame.Text:SetText(tostring(message or ""))
  textFrame:ClearAllPoints()
  textFrame:SetPoint("CENTER", UIParent, "CENTER", 0, TEXT_Y[pos] or TEXT_Y.top)
  textFrame.expire = GetTime() + (tonumber(duration) or 3)
  textFrame:SetAlpha(1)
  textFrame:Show()
end

local statusFrames = {}

local function StatusFrame(key)
  local f = statusFrames[key]
  if f then return f end
  f = CreateFrame("Frame", nil, UIParent)
  f:SetFrameStrata("HIGH")
  f:SetSize(10, 10)
  f.Icon = f:CreateTexture(nil, "ARTWORK")
  f.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  f.Text = f:CreateFontString(nil, "OVERLAY")
  f.Bar = CreateFrame("StatusBar", nil, f)
  f.Bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
  f.Bar:SetHeight(8)
  f.Bar:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -4)
  f.Bar:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -4)
  f.BarBg = f.Bar:CreateTexture(nil, "BACKGROUND")
  f.BarBg:SetAllPoints(f.Bar)
  f.BarBg:SetColorTexture(0, 0, 0, 0.55)
  f.Bar:Hide()
  f:Hide()
  statusFrames[key] = f
  return f
end

local function FormatTime(s)
  if s >= 60 then return ("%d:%02d"):format(math.floor(s / 60), math.floor(s % 60)) end
  if s >= 10 then return tostring(math.floor(s)) end
  return ("%.1f"):format(s)
end

-- info = { name, stacks, expires, duration }, all optional.
local function ExpandText(text, info)
  text = tostring(text or "")
  if not text:find("%%") then return text end
  info = info or {}
  local stacks = (type(info.stacks) == "number" and info.stacks > 0) and tostring(info.stacks) or ""
  local time = ""
  if type(info.expires) == "number" and info.expires > 0 then
    time = FormatTime(math.max(0, info.expires - GetTime()))
  end
  local name = type(info.name) == "string" and info.name or ""
  text = text:gsub("%%stacks", function() return stacks end)
  text = text:gsub("%%time", function() return time end)
  text = text:gsub("%%name", function() return name end)
  return text
end

local function RefreshStatus(f)
  local info = f.info
  f.Text:SetText(ExpandText(f.raw, info))
  local w = math.max(10, (f.iconW or 0) + f.Text:GetStringWidth())
  -- Never shrink while shown, so the text doesn't wobble as the digits change.
  if f.keepW and f.keepW > w then w = f.keepW end
  f.keepW = w
  f:SetSize(w, math.max((f.size or 36) * 1.1, f.Text:GetStringHeight()))
  if f.barOn and info and type(info.expires) == "number" and type(info.duration) == "number" and info.duration > 0 then
    local left = math.max(0, math.min(info.duration, info.expires - GetTime()))
    f.Bar:SetMinMaxValues(0, info.duration)
    f.Bar:SetValue(left)
    f.Bar:Show()
  else
    f.Bar:Hide()
  end
end

local function StatusTick(f, elapsed)
  f.acc = (f.acc or 0) + elapsed
  if f.acc < 0.1 then return end
  f.acc = 0
  RefreshStatus(f)
end

local function DrawStatus(f, text, color, size, x, y, icon, info, bar)
  size = tonumber(size) or 36
  local rgb = RGB(color)
  f.raw, f.info, f.size, f.barOn = text, info, size, bar and true or false
  f.Text:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
  f.Text:SetTextColor(rgb[1], rgb[2], rgb[3], 1)
  f.Bar:SetStatusBarColor(rgb[1], rgb[2], rgb[3], 1)
  f.Text:SetText(ExpandText(text, info))
  f.Text:ClearAllPoints()
  f.Icon:ClearAllPoints()
  local iconW = 0
  if icon then
    iconW = math.floor(size * 1.1)
    f.Icon:SetTexture(icon)
    f.Icon:SetSize(iconW, iconW)
    f.Icon:SetPoint("LEFT", f, "LEFT", 0, 0)
    f.Icon:Show()
    f.Text:SetPoint("LEFT", f.Icon, "RIGHT", math.floor(size * 0.3), 0)
    iconW = iconW + math.floor(size * 0.3)
  else
    f.Icon:Hide()
    f.Text:SetPoint("LEFT", f, "LEFT", 0, 0)
  end
  f.iconW = iconW
  f:ClearAllPoints()
  f:SetPoint("CENTER", UIParent, "CENTER", tonumber(x) or 0, tonumber(y) or TEXT_Y.top)
  RefreshStatus(f)
  local ticking = type(info) == "table" and type(info.expires) == "number" and info.expires > 0
  f:SetScript("OnUpdate", ticking and StatusTick or nil)
end

function Fx.Status(owner, slot, on, text, color, size, x, y, icon, info, bar)
  local key = tostring(owner) .. ":" .. tostring(slot)
  if not on then
    local f = statusFrames[key]
    if f then
      f.keepW = nil
      f:Hide()
    end
    return
  end
  local f = StatusFrame(key)
  f.owner = owner
  DrawStatus(f, text, color, size, x, y, icon, info, bar)
  f:Show()
end

local function SampleInfo()
  return { name = "Aura", stacks = 3, expires = GetTime() + 30, duration = 30 }
end

function Fx.HideOwner(owner)
  for _, f in pairs(statusFrames) do
    if f.owner == owner then
      f.keepW = nil
      f:Hide()
    end
  end
end

-- Draggable preview for the Move button; a = nil hides it.
function Fx.Preview(a, icon, onMoved)
  local f = StatusFrame("preview")
  if not a then
    f:Hide()
    return
  end
  if not f.Hl then
    f.Hl = f:CreateTexture(nil, "BACKGROUND")
    f.Hl:SetPoint("TOPLEFT", f, "TOPLEFT", -8, 8)
    f.Hl:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 8, -8)
    f.Hl:SetColorTexture(0.9, 0.2, 0.25, 0.25)
    f.Hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.Hint:SetPoint("TOP", f, "BOTTOM", 0, -12)
    f.Hint:SetText("Drag me where you want. Click Done in LuaPad when finished.")
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
      local cx, cy = self:GetCenter()
      local ux, uy = UIParent:GetCenter()
      local t = self.target
      if t and cx then
        t.x, t.y = math.floor(cx - ux + 0.5), math.floor(cy - uy + 0.5)
      end
      if self.onMoved then self.onMoved() end
    end)
  end
  f.target, f.onMoved = a, onMoved
  local text = (a.text and a.text ~= "") and a.text or "Your text"
  f.keepW = nil
  DrawStatus(f, text, a.color, a.size, a.x, a.y or TEXT_Y[a.pos or "top"], icon, SampleInfo(), a.bar == "bar")
  f:Show()
end

local flashFrame
function Fx.Flash(color, duration)
  if not flashFrame then
    flashFrame = CreateFrame("Frame", nil, UIParent)
    flashFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    flashFrame:SetAllPoints(UIParent)
    flashFrame.Tex = flashFrame:CreateTexture(nil, "BACKGROUND")
    flashFrame.Tex:SetAllPoints(flashFrame)
    flashFrame.Tex:SetColorTexture(1, 1, 1, 1)
    flashFrame:Hide()
    flashFrame:SetScript("OnUpdate", function(self)
      local left = self.expire - GetTime()
      if left <= 0 then self:Hide() else self:SetAlpha(0.35 * left / self.duration) end
    end)
  end
  local rgb = RGB(color)
  flashFrame.Tex:SetVertexColor(rgb[1], rgb[2], rgb[3], 1)
  flashFrame.duration = math.max(0.1, tonumber(duration) or 1)
  flashFrame.expire = GetTime() + flashFrame.duration
  flashFrame:SetAlpha(0.35)
  flashFrame:Show()
end

function B.RunAction(a, icon, persist)
  if a.type == "text" and persist then
    Fx.Status("test", 1, true, a.text, a.color, a.size, a.x, a.y or TEXT_Y[a.pos or "top"], a.icon ~= "text" and icon or nil,
      SampleInfo(), a.bar == "bar")
    C_Timer.After(3, function() Fx.Status("test", 1, false) end)
  elseif a.type == "sound" then
    Fx.Sound(a.sound == "custom" and a.custom or a.sound)
  elseif a.type == "text" then
    Fx.Text(a.text, a.color, a.size, a.duration, a.pos)
  elseif a.type == "flash" then
    Fx.Flash(a.color, a.duration)
  elseif a.type == "chat" then
    print(a.text or "")
  end
end
