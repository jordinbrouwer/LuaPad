LuaPad = LuaPad or {}
local LP = LuaPad
local UI = LP.UI
local T = UI.THEME

local List = {}
LP.SnippetList = List

local ROW_H = 32
local listScroll, listContent, delBtn, confirmUntil
local rows = {}

local function GetRow(i)
  local row = rows[i]
  if row then return row end
  row = CreateFrame("Button", nil, listContent)
  row:SetSize(178, ROW_H)
  row:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, -(i - 1) * ROW_H)
  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints(row)
  row.bar = row:CreateTexture(nil, "ARTWORK")
  row.bar:SetColorTexture(unpack(T.GOLD))
  row.bar:SetWidth(3)
  row.bar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
  row.bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
  row.dot = row:CreateTexture(nil, "ARTWORK")
  row.dot:SetSize(8, 8)
  row.dot:SetPoint("LEFT", row, "LEFT", 12, 0)
  row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 28, -4)
  row.name:SetWidth(120)
  row.name:SetJustifyH("LEFT")
  row.name:SetWordWrap(false)
  row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.sub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -1)
  row.sub:SetWidth(120)
  row.sub:SetJustifyH("LEFT")
  row.sub:SetWordWrap(false)
  row:SetScript("OnEnter", function(self)
    if not self.selected then self.bg:SetColorTexture(0.16, 0.16, 0.19, 1) end
  end)
  row:SetScript("OnLeave", function(self)
    if not self.selected then self.bg:SetColorTexture(0, 0, 0, 0) end
  end)
  row:SetScript("OnClick", function(self) LP.SelectSnippet(self.id) end)
  rows[i] = row
  return row
end

function List.ResetDelete()
  confirmUntil = nil
  if delBtn then delBtn:Rest() end
end

function List.Refresh()
  if not listContent then return end
  local snippets = LuaPadDB.snippets
  for i, snippet in ipairs(snippets) do
    local row = GetRow(i)
    row.id = snippet.id
    row.selected = snippet.id == LuaPadDB.selected
    row.name:SetText((snippet.name ~= "" and snippet.name or "Untitled") .. (LP.IsDirty(snippet) and " |cffffcc4d*|r" or ""))
    local kind, text = LP.Status(snippet)
    local color = kind == "error" and T.RED or kind == "ok" and T.GREEN or T.GRAY
    row.dot:SetColorTexture(unpack(color))
    row.sub:SetText((snippet.mode == "simple" and "Simple · " or "Code · ") .. text)
    row.sub:SetTextColor(unpack(color))
    row.bar:SetShown(row.selected)
    if row.selected then row.bg:SetColorTexture(0.19, 0.06, 0.07, 1) else row.bg:SetColorTexture(0, 0, 0, 0) end
    row:Show()
  end
  for i = #snippets + 1, #rows do rows[i]:Hide() end
  delBtn:Hide()
  for i = 1, #snippets do
    if rows[i].selected then
      delBtn:ClearAllPoints()
      delBtn:SetPoint("RIGHT", rows[i], "RIGHT", -8, -7)
      delBtn:Show()
    end
  end
  if confirmUntil and delBtn.confirmId ~= LuaPadDB.selected then
    confirmUntil = nil
    delBtn:Rest()
  end
  listContent:SetSize(178, math.max(1, #snippets * ROW_H))
end

function List.ScrollToEnd()
  listScroll:SetVerticalScroll(listScroll:GetVerticalScrollRange())
end

local function DeleteCurrent()
  local snippet = LP.Current()
  if not snippet then return end
  if not (confirmUntil and GetTime() < confirmUntil and delBtn.confirmId == snippet.id) then
    confirmUntil = GetTime() + 3
    delBtn.confirmId = snippet.id
    delBtn.Label:SetText("Sure?")
    delBtn.Label:SetTextColor(unpack(T.RED))
    C_Timer.After(3.1, function() if confirmUntil and GetTime() >= confirmUntil then List.ResetDelete() end end)
    return
  end
  List.ResetDelete()
  LP.CodeEditor.ForgetHistory(snippet.id)
  LP.Delete(snippet.id)
  local list = LuaPadDB.snippets
  LP.SelectSnippet(list[1] and list[1].id or nil)
end

function List.Build(side)
  local header = side:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  header:SetPoint("TOPLEFT", side, "TOPLEFT", 12, -10)
  header:SetText("SNIPPETS")
  header:SetTextColor(unpack(T.GRAY))

  listScroll = CreateFrame("ScrollFrame", nil, side)
  listScroll:SetPoint("TOPLEFT", side, "TOPLEFT", 0, -28)
  listScroll:SetPoint("BOTTOMRIGHT", side, "BOTTOMRIGHT", -1, 44)
  listContent = CreateFrame("Frame", nil, listScroll)
  listContent:SetSize(178, 1)
  listScroll:SetScrollChild(listContent)
  listScroll:EnableMouseWheel(true)
  listScroll:SetScript("OnMouseWheel", function(self, delta)
    self:SetVerticalScroll(UI.Clamp(self:GetVerticalScroll() - delta * ROW_H, 0, self:GetVerticalScrollRange()))
  end)

  delBtn = CreateFrame("Button", nil, listContent)
  delBtn:SetSize(54, 18)
  delBtn:SetFrameLevel(listContent:GetFrameLevel() + 5)
  delBtn.Label = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  delBtn.Label:SetPoint("RIGHT", delBtn, "RIGHT", 0, 0)
  function delBtn:Rest()
    self.Label:SetText("Delete")
    self.Label:SetTextColor(0.55, 0.56, 0.62, 1)
  end
  delBtn:Rest()
  delBtn:SetScript("OnEnter", function(self) if not confirmUntil then self.Label:SetTextColor(unpack(T.RED)) end end)
  delBtn:SetScript("OnLeave", function(self) if not confirmUntil then self:Rest() end end)
  delBtn:SetScript("OnClick", DeleteCurrent)
  delBtn:Hide()

  local newSimple = UI.CreateButton(side, "+ Simple", 76, true, function() LP.Window.NewSnippet("simple") end, "New rule you build with menus. No code needed.")
  newSimple:SetPoint("BOTTOMLEFT", side, "BOTTOMLEFT", 10, 10)
  local newCode = UI.CreateButton(side, "+ Code", 76, false, function() LP.Window.NewSnippet() end, "New snippet where you write Lua yourself.")
  newCode:SetPoint("BOTTOMRIGHT", side, "BOTTOMRIGHT", -11, 10)

  local sep = side:CreateTexture(nil, "ARTWORK")
  sep:SetColorTexture(unpack(T.LINE))
  sep:SetHeight(1)
  sep:SetPoint("BOTTOMLEFT", side, "BOTTOMLEFT", 0, 42)
  sep:SetPoint("BOTTOMRIGHT", side, "BOTTOMRIGHT", 0, 42)
end
