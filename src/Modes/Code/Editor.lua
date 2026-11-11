LuaPad = LuaPad or {}
local LP = LuaPad
local UI = LP.UI
local T = UI.THEME
local Clamp = UI.Clamp

-- Hooks the window fills in: OnLayout(), OnEdited(plain, validateDelay), OnSave().
local CE = {}
LP.CodeEditor = CE

local MAX_UNDO = 300

local font = CreateFont("LuaPadCodeFont")
font:SetFont(STANDARD_TEXT_FONT, 12, "")
font:SetTextColor(0.86, 0.88, 0.92, 1)

local body, hdr, hdrName, hdrInfo, area, areaBorder, measure
local gutterClip, gutter, scroll, content, edit, overlay, errTex, curTex, vbar, hbar
local lineH, lineCount = 14, 1
local errLine, errWarn, lastGutterN, lastGutterErr
local follow, curX, curY, curH
local loading, applying, syncing, lastPlain = false, false, false, ""
local hist = {}

local function UpdateGutter(force)
  local key = errLine and (errLine .. (errWarn and "w" or "e"))
  if not force and lastGutterN == lineCount and lastGutterErr == key then return end
  lastGutterN, lastGutterErr = lineCount, key
  local mark = errWarn and "|cffffcc4d" or "|cffff6b6b"
  local t = {}
  for i = 1, lineCount do
    t[i] = i == errLine and (mark .. i .. "|r") or ("|cff5f6672" .. i .. "|r")
  end
  gutter:SetText(table.concat(t, "\n"))
end

local function PlaceErrLine()
  if errLine and errLine <= lineCount then
    local y = -(6 + (errLine - 1) * lineH)
    errTex:ClearAllPoints()
    errTex:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    errTex:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
    errTex:SetHeight(lineH)
    if errWarn then errTex:SetColorTexture(1, 0.8, 0.3, 0.13) else errTex:SetColorTexture(0.9, 0.25, 0.25, 0.16) end
    errTex:Show()
  else
    errTex:Hide()
  end
end

function CE.SetErrLine(line, warn)
  errLine = line
  errWarn = line and warn or nil
  UpdateGutter()
  PlaceErrLine()
end

function CE.Relayout()
  if not edit then return end
  local text = LP.Strip(edit:GetText())
  overlay:SetText(edit:GetText())
  local _, newlines = text:gsub("\n", "")
  lineCount = newlines + 1
  local viewW, viewH = scroll:GetWidth(), scroll:GetHeight()
  local textW, textH = overlay:GetStringWidth(), overlay:GetStringHeight()
  content:SetSize(math.max(viewW, textW + 40), math.max(viewH, textH + 20))
  if vbar then
    if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
    vbar:SetShown(scroll:GetVerticalScrollRange() > 1)
    hbar:SetShown(scroll:GetHorizontalScrollRange() > 1)
  end
  UpdateGutter()
  PlaceErrLine()
  if CE.OnLayout then CE.OnLayout() end
end
local Relayout = CE.Relayout

local function PlaceGutter(offset)
  gutter:ClearAllPoints()
  gutter:SetPoint("TOPRIGHT", gutterClip, "TOPRIGHT", -8, -6 + offset)
end

function CE.GotoLine(line)
  if not line then return end
  local text = LP.Strip(edit:GetText())
  local pos = 0
  for _ = 2, line do
    local nl = text:find("\n", pos + 1, true)
    if not nl then break end
    pos = nl
  end
  edit:SetFocus()
  edit:SetCursorPosition(LP.MapToColored(edit:GetText(), pos))
  scroll:SetVerticalScroll(Clamp((line - 4) * lineH, 0, scroll:GetVerticalScrollRange()))
end

function CE.GetCode()
  return LP.Strip(edit:GetText())
end

function CE.LineCount()
  return lineCount
end

function CE.SetHeader(name, info)
  if not hdrInfo then return end
  if name then hdrName:SetText(name) end
  hdrInfo:SetText(info)
end

function CE.SetShown(show)
  hdr:SetShown(show)
  area:SetShown(show)
end

function CE.SetRightInset(right)
  area:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", right, 10)
  hdr:SetPoint("TOPRIGHT", body, "TOPRIGHT", right - 1, -45)
end

function CE.Focus()
  edit:SetFocus()
end

function CE.ClearFocus()
  edit:ClearFocus()
end

function CE.MeasureLineHeight()
  local h = measure:GetStringHeight()
  if h and h > 0 then lineH = h end
end

-- Replaces the text without recording an undo step.
function CE.Load(plain, resetView)
  loading = true
  lastPlain = plain
  edit:SetText(LP.Colorize(plain))
  if resetView then edit:SetCursorPosition(0) end
  loading = false
  if resetView then
    scroll:SetVerticalScroll(0)
    scroll:SetHorizontalScroll(0)
  end
end

function CE.ScrollToCursor()
  if not follow then return end
  follow = false
  local vs, vh = scroll:GetVerticalScroll(), scroll:GetHeight()
  if curY < vs then
    scroll:SetVerticalScroll(math.max(0, curY - 4))
  elseif curY + curH > vs + vh then
    scroll:SetVerticalScroll(curY + curH - vh + 4)
  end
  local hs, vw = scroll:GetHorizontalScroll(), scroll:GetWidth()
  if curX < hs then
    scroll:SetHorizontalScroll(math.max(0, curX - 24))
  elseif curX + 24 > hs + vw then
    scroll:SetHorizontalScroll(curX + 24 - vw)
  end
end

local function History(id)
  local h = hist[id]
  if not h then
    h = { undo = {}, redo = {}, t = 0 }
    hist[id] = h
  end
  return h
end

function CE.ForgetHistory(id)
  hist[id] = nil
end

local function DiffAt(a, b)
  local n, i = math.min(#a, #b), 1
  while i <= n and a:byte(i) == b:byte(i) do i = i + 1 end
  return i - 1
end

local function ChangeEnd(a, b)
  local p = DiffAt(a, b)
  local i, j = #a, #b
  while i > p and j > p and a:byte(i) == b:byte(j) do i, j = i - 1, j - 1 end
  return j
end

local function Push(stack, text)
  stack[#stack + 1] = text
  if #stack > MAX_UNDO then table.remove(stack, 1) end
end

-- Typing within a word without pausing becomes a single undo step.
local function Record(id, before, after)
  local h = History(id)
  local now = GetTime()
  local at, delta = DiffAt(before, after), #after - #before
  local ch = delta > 0 and after:sub(at + 1, at + 1) or before:sub(at + 1, at + 1)
  local small = (delta == 1 or delta == -1) and not ch:find("%s")
  local dir = delta > 0 and 1 or -1
  if not (small and h.small and h.dir == dir and now - h.t < 1.2) then
    Push(h.undo, before)
  end
  h.small, h.dir, h.t = small, dir, now
  wipe(h.redo)
end

local function SetPlain(plain, pos)
  loading = true
  lastPlain = plain
  local colored = LP.Colorize(plain)
  edit:SetText(colored)
  loading = false
  edit:SetFocus()
  edit:SetCursorPosition(LP.MapToColored(colored, Clamp(pos or 0, 0, #plain)))
  Relayout()
  if CE.OnEdited then CE.OnEdited(plain, 0.1) end
end

local function Step(from, to)
  local s = LP.Current()
  if not s or s.mode == "simple" then return end
  local h = History(s.id)
  local text = table.remove(h[from])
  if not text then return end
  Push(h[to], lastPlain)
  h.small = false
  SetPlain(text, ChangeEnd(lastPlain, text))
end

function CE.Undo() Step("undo", "redo") end
function CE.Redo() Step("redo", "undo") end

-- Going back to the saved text is itself an undo step.
function CE.Revert(id, saved)
  local h = History(id)
  Push(h.undo, lastPlain)
  wipe(h.redo)
  h.small = false
  SetPlain(saved, ChangeEnd(lastPlain, saved))
end

local function BuildHeader(main)
  hdr = CreateFrame("Frame", nil, body)
  hdr:SetPoint("TOPLEFT", main, "TOPLEFT", 13, -45)
  hdr:SetPoint("TOPRIGHT", main, "TOPRIGHT", -191, -45)
  hdr:SetHeight(22)
  local hbg = hdr:CreateTexture(nil, "BACKGROUND")
  hbg:SetAllPoints(hdr)
  hbg:SetColorTexture(0.115, 0.118, 0.135, 1)
  local hline = hdr:CreateTexture(nil, "ARTWORK")
  hline:SetColorTexture(unpack(T.LINE))
  hline:SetHeight(1)
  hline:SetPoint("BOTTOMLEFT", hdr, "BOTTOMLEFT", 0, 0)
  hline:SetPoint("BOTTOMRIGHT", hdr, "BOTTOMRIGHT", 0, 0)
  local hdot = hdr:CreateTexture(nil, "ARTWORK")
  hdot:SetSize(8, 8)
  hdot:SetPoint("LEFT", hdr, "LEFT", 12, 0)
  hdot:SetColorTexture(0.48, 0.64, 0.97, 1)
  hdrName = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  hdrName:SetPoint("LEFT", hdot, "RIGHT", 8, 0)
  hdrName:SetTextColor(0.82, 0.84, 0.9, 1)
  hdrInfo = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  hdrInfo:SetPoint("RIGHT", hdr, "RIGHT", -12, 0)
end

local function BuildGutter()
  gutterClip = CreateFrame("Frame", nil, area)
  gutterClip:SetPoint("TOPLEFT", area, "TOPLEFT", 1, -23)
  gutterClip:SetPoint("BOTTOMLEFT", area, "BOTTOMLEFT", 1, 1)
  gutterClip:SetWidth(46)
  gutterClip:SetClipsChildren(true)
  local gbg = gutterClip:CreateTexture(nil, "BACKGROUND")
  gbg:SetAllPoints(gutterClip)
  gbg:SetColorTexture(0.055, 0.058, 0.068, 1)
  local gline = gutterClip:CreateTexture(nil, "ARTWORK")
  gline:SetColorTexture(unpack(T.LINE))
  gline:SetWidth(1)
  gline:SetPoint("TOPRIGHT", gutterClip, "TOPRIGHT", 0, 0)
  gline:SetPoint("BOTTOMRIGHT", gutterClip, "BOTTOMRIGHT", 0, 0)
  gutter = gutterClip:CreateFontString(nil, "ARTWORK")
  gutter:SetFontObject(font)
  gutter:SetWidth(38)
  gutter:SetJustifyH("RIGHT")
  gutter:SetJustifyV("TOP")
  gutter:SetSpacing(0)
  PlaceGutter(0)
end

local function OnTextChanged(self)
  if applying then return end
  local raw = self:GetText()
  local plain, pos = LP.Strip(raw, self:GetCursorPosition())
  if plain:find("[\t\r]") then
    plain = plain:gsub("\r", ""):gsub("\t", "  ")
    pos = math.min(pos, #plain)
  elseif not loading then
    plain, pos = LP.AutoFormat(lastPlain, plain, pos)
  end
  if not loading and plain ~= lastPlain then
    local snippet = LP.Current()
    if snippet then Record(snippet.id, lastPlain, plain) end
  end
  lastPlain = plain
  local colored = LP.Colorize(plain)
  if colored ~= raw then
    applying = true
    self:SetText(colored)
    self:SetCursorPosition(LP.MapToColored(colored, pos))
    applying = false
  end
  Relayout()
  if loading then return end
  if CE.OnEdited then CE.OnEdited(plain, 0.35) end
end

local function BuildEditBox()
  scroll = CreateFrame("ScrollFrame", nil, area)
  scroll:SetPoint("TOPLEFT", area, "TOPLEFT", 48, -23)
  scroll:SetPoint("BOTTOMRIGHT", area, "BOTTOMRIGHT", -1, 1)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(10, 10)
  scroll:SetScrollChild(content)

  errTex = content:CreateTexture(nil, "BACKGROUND")
  errTex:SetColorTexture(0.9, 0.25, 0.25, 0.16)
  errTex:Hide()
  curTex = content:CreateTexture(nil, "BACKGROUND")
  curTex:SetColorTexture(1, 1, 1, 0.04)
  curTex:Hide()

  -- Invisible copy of the text, only used to measure it.
  overlay = content:CreateFontString(nil, "ARTWORK")
  overlay:SetFontObject(font)
  overlay:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -6)
  overlay:SetJustifyH("LEFT")
  overlay:SetJustifyV("TOP")
  overlay:SetSpacing(0)
  overlay:SetWordWrap(false)
  overlay:SetAlpha(0)

  edit = CreateFrame("EditBox", nil, content)
  edit:SetAllPoints(content)
  edit:SetMultiLine(true)
  edit:SetAutoFocus(false)
  edit:SetFontObject(font)
  edit:SetTextInsets(8, 8, 6, 6)
  edit:SetSpacing(0)
  edit:SetMaxLetters(0)

  edit:SetScript("OnTextChanged", OnTextChanged)
  edit:SetScript("OnCursorChanged", function(_, x, y, _, h)
    curX, curY, curH, follow = x, -y, h, true
    if edit:HasFocus() then
      curTex:ClearAllPoints()
      local plain, bytePos = LP.Strip(edit:GetText(), edit:GetCursorPosition())
      local _, before = plain:sub(1, bytePos):gsub("\n", "")
      local ty = -(6 + before * lineH)
      curTex:SetPoint("TOPLEFT", content, "TOPLEFT", 0, ty)
      curTex:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, ty)
      curTex:SetHeight(lineH)
      curTex:Show()
    end
  end)
  edit:SetScript("OnTabPressed", function(self) self:Insert("  ") end)
  edit:SetScript("OnEscapePressed", edit.ClearFocus)
  edit:SetScript("OnKeyDown", function(_, key)
    if not IsControlKeyDown() then return end
    if key == "S" then
      if CE.OnSave then CE.OnSave() end
    elseif key == "Z" then
      if IsShiftKeyDown() then CE.Redo() else CE.Undo() end
    elseif key == "Y" then
      CE.Redo()
    end
  end)
  edit:SetScript("OnEditFocusGained", function() UI.SetBorderColor(areaBorder, T.GOLD) end)
  edit:SetScript("OnEditFocusLost", function() UI.SetBorderColor(areaBorder, T.LINE) curTex:Hide() end)
end

local function BuildScrollbars()
  vbar = UI.CreateScrollbar(area, true)
  vbar:SetPoint("TOPRIGHT", area, "TOPRIGHT", -2, -25)
  vbar:SetPoint("BOTTOMRIGHT", area, "BOTTOMRIGHT", -2, 14)
  hbar = UI.CreateScrollbar(area, false)
  hbar:SetPoint("BOTTOMLEFT", area, "BOTTOMLEFT", 50, 2)
  hbar:SetPoint("BOTTOMRIGHT", area, "BOTTOMRIGHT", -14, 2)
  vbar:Hide()
  hbar:Hide()
  vbar:SetFrameLevel(scroll:GetFrameLevel() + 10)
  hbar:SetFrameLevel(scroll:GetFrameLevel() + 10)

  scroll:SetScript("OnScrollRangeChanged", function(self, xrange, yrange)
    syncing = true
    vbar:SetMinMaxValues(0, yrange)
    hbar:SetMinMaxValues(0, xrange)
    syncing = false
    vbar:SetShown(yrange > 1)
    hbar:SetShown(xrange > 1)
    local vh, vw = self:GetHeight(), self:GetWidth()
    vbar:SetThumbLength(Clamp(vh * vh / (vh + yrange), 24, math.max(24, vh)))
    hbar:SetThumbLength(Clamp(vw * vw / (vw + xrange), 24, math.max(24, vw)))
  end)
  scroll:SetScript("OnVerticalScroll", function(_, offset)
    syncing = true
    vbar:SetValue(offset)
    syncing = false
    PlaceGutter(offset)
  end)
  scroll:SetScript("OnHorizontalScroll", function(_, offset)
    syncing = true
    hbar:SetValue(offset)
    syncing = false
  end)
  scroll:SetScript("OnSizeChanged", Relayout)
  vbar:SetScript("OnValueChanged", function(_, value) if not syncing then scroll:SetVerticalScroll(value) end end)
  hbar:SetScript("OnValueChanged", function(_, value) if not syncing then scroll:SetHorizontalScroll(value) end end)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    if IsShiftKeyDown() then
      self:SetHorizontalScroll(Clamp(self:GetHorizontalScroll() - delta * 60, 0, self:GetHorizontalScrollRange()))
    else
      self:SetVerticalScroll(Clamp(self:GetVerticalScroll() - delta * lineH * 3, 0, self:GetVerticalScrollRange()))
    end
  end)
end

function CE.Build(frame, parent, main)
  body = parent
  BuildHeader(main)

  area = CreateFrame("Frame", nil, body)
  area:SetPoint("TOPLEFT", main, "TOPLEFT", 12, -44)
  area:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -190, 10)
  local bg = area:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(area)
  bg:SetColorTexture(unpack(T.CODE))
  -- The border sits on its own frame above the header and code so nothing covers it.
  local edgeFrame = CreateFrame("Frame", nil, area)
  edgeFrame:SetAllPoints(area)
  edgeFrame:SetFrameLevel(area:GetFrameLevel() + 30)
  areaBorder = UI.AddBorder(edgeFrame, T.LINE)
  hdr:SetFrameLevel(area:GetFrameLevel() + 10)

  BuildGutter()
  BuildEditBox()
  BuildScrollbars()

  measure = frame:CreateFontString(nil, "ARTWORK")
  measure:SetFontObject(font)
  measure:SetText("Ag")
  return area
end
