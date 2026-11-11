LuaPad = LuaPad or {}
local LP = LuaPad
local UI = LP.UI
local T = UI.THEME
local CE = LP.CodeEditor

local Status = {}
LP.StatusPanel = Status

local WARN = { 1, 0.8, 0.3, 1 }
local INFO = { 0.48, 0.64, 0.97, 1 }

local frame, bar, head, msgText, traceText, goButton, clearButton
local syn, lint, goLine

local function LineOf(text, n)
  local i = 0
  for l in ((text or "") .. "\n"):gmatch("([^\n]*)\n") do
    i = i + 1
    if i == n then return l end
  end
end

-- A runtime error comes from the saved code; once its line is edited it is most likely fixed.
local function ErrorIsStale(snippet, st)
  if not snippet.draft or snippet.mode == "simple" then return false end
  if not st.line then return true end
  return LineOf(snippet.code, st.line) ~= LineOf(snippet.draft, st.line)
end

local function SetShown(show)
  frame:SetShown(show)
  LP.Window.SetSidebar(show)
end

function Status.Refresh()
  local snippet = LP.Current()
  if not snippet or not head then return end
  local st = LP.State[snippet.id]
  local color, title, msg, trace, line, canClear, warn
  if syn then
    color, title, msg, line = T.RED, "Syntax error" .. (syn.line and (" · line " .. syn.line) or ""), syn.msg, syn.line
  elseif lint and #lint > 0 then
    color, warn, line = WARN, true, lint[1].line
    title = "Will likely fail · line " .. lint[1].line
    msg = lint[1].msg
    if #lint > 1 then
      local more = {}
      for i = 2, #lint do more[#more + 1] = ("line %d: %s"):format(lint[i].line, lint[i].msg) end
      trace = table.concat(more, "\n")
    end
  elseif st and st.err and ErrorIsStale(snippet, st) then
    color, title = INFO, "Unsaved fix"
    msg = ("The last error%s came from the saved version, and you've changed that since. Press Save to run your changes."):format(
      st.line and (" (line " .. st.line .. ")") or "")
    trace = "Old error: " .. st.err
    canClear = true
  elseif st and st.err then
    color = T.RED
    title = (st.kind == "syntax" and "Syntax error" or "Runtime error") .. (st.line and (" · line " .. st.line) or "")
    if (st.count or 1) > 1 then title = title .. "   ×" .. st.count end
    if st.time then title = title .. "   " .. st.time end
    msg, trace, line, canClear = st.err, st.trace, st.line, true
  elseif not snippet.enabled then
    color, title, msg = T.GRAY, "Not running", "Switch it on to run it."
  else
    color, title = T.GREEN, "No errors"
    msg = "Running" .. ((st or {}).ran and (" since " .. st.ran) or "") .. "."
    if LP.IsDirty(snippet) then
      msg = msg .. "\n\nThis is the saved version. Your unsaved changes only run after Save."
    end
  end
  bar:SetColorTexture(unpack(color))
  head:SetText(title)
  head:SetTextColor(unpack(color))
  msgText:SetText(msg or "")
  traceText:SetText(trace or "")
  goLine = line
  goButton:SetShown(line ~= nil)
  clearButton:SetShown(canClear and true or false)
  CE.SetErrLine(line, warn)
  SetShown(color ~= T.GRAY)
end

-- Simple rules are not linted: their generated code guards itself.
function Status.Validate()
  local snippet = LP.Current()
  if not snippet then return end
  local code = CE.GetCode()
  local msg, line = LP.CheckSyntax(code)
  syn = msg and { msg = msg, line = line } or nil
  lint = nil
  if not syn and snippet.mode ~= "simple" and LP.Lint then
    local ok, res = pcall(LP.Lint, code)
    if ok then lint = res end
  end
  Status.Refresh()
  LP.Toolbar.UpdateLock()
end

function Status.Build(body, main, area)
  frame = CreateFrame("Frame", nil, body)
  frame:SetPoint("TOPLEFT", area, "TOPRIGHT", 8, 0)
  frame:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -12, 10)
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(frame)
  bg:SetColorTexture(unpack(T.INSET))
  UI.AddBorder(frame, T.LINE)
  bar = frame:CreateTexture(nil, "ARTWORK")
  bar:SetHeight(3)
  bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)

  head = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  head:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -14)
  head:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
  head:SetJustifyH("LEFT")
  msgText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  msgText:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -8)
  msgText:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
  msgText:SetJustifyH("LEFT")
  msgText:SetJustifyV("TOP")
  msgText:SetMaxLines(14)
  if msgText.SetNonSpaceWrap then msgText:SetNonSpaceWrap(true) end
  traceText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  traceText:SetPoint("TOPLEFT", msgText, "BOTTOMLEFT", 0, -10)
  traceText:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
  traceText:SetJustifyH("LEFT")
  traceText:SetMaxLines(8)
  if traceText.SetNonSpaceWrap then traceText:SetNonSpaceWrap(true) end
  traceText:SetTextColor(unpack(T.GRAY))

  goButton = UI.CreateButton(frame, "Go to line", 146, true, function() CE.GotoLine(goLine) end)
  goButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 12)
  clearButton = UI.CreateButton(frame, "Clear error", 146, false, function()
    local snippet = LP.Current()
    if snippet then LP.ClearError(snippet.id) end
    Status.Refresh()
    LP.SnippetList.Refresh()
  end)
  clearButton:SetPoint("BOTTOMLEFT", goButton, "TOPLEFT", 0, 6)
end
