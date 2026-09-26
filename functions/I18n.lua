function FarmingLive:loadLocale(langCode)

    local base = self.modDir or self.modDirectory or self.directory
                 or (self.modDesc and self.modDesc.modDirectory)
                 or g_currentModDirectory
    if base and base:sub(-1) ~= "/" then base = base .. "/" end


    local rel  = ("i18n/%s.lua"):format(langCode)
    local path = base and Utils.getFilename(rel, base) or rel
    if not fileExists(path) then
        print(("[FarmingLive][i18n] No language file for '%s' at %s"):format(langCode, path))
        self.i18n.lang, self.i18n.map = "builtin", {}
        return
    end


    _G.FARMINGLIVE_I18N = nil


    source(path)

    local tbl = rawget(_G, "FARMINGLIVE_I18N")
    if type(tbl) ~= "table" then
        print(("[FarmingLive][i18n][ERROR] No FARMINGLIVE_I18N table found after loading %s"):format(path))
        self.i18n.lang, self.i18n.map = "builtin", {}
        return
    end

    self.i18n.lang, self.i18n.map = langCode, tbl
    local c = 0; for _ in pairs(tbl) do c = c + 1 end
    print(("[FarmingLive][i18n] Loaded '%s' from %s (%d entries)."):format(langCode, path, c))
end

function FarmingLive:detectLanguage()
  local function short(code)
    if not code then return nil end
    code = tostring(code):lower()
    local s = code:match("^([a-z][a-z])")
    if s == "de" then return "de" end
    return s
  end

  local candidates = {}


  if g_i18n and g_i18n.getLanguage then
    local v = g_i18n:getLanguage()
    if v then table.insert(candidates, v) end
  end
  if g_i18n and g_i18n.languageShort then table.insert(candidates, g_i18n.languageShort) end
  if _G.g_languageShort then table.insert(candidates, _G.g_languageShort) end


  local uniq, ordered = {}, {}
  local function push(x) if x and not uniq[x] then uniq[x]=true; table.insert(ordered, x) end end
  push("de")
  for _, c in ipairs(candidates) do push(short(c) or c) end
  push("en")

  for _, cand in ipairs(ordered) do
    local base = self.modDir or g_currentModDirectory
    local try = string.format("%s/i18n/%s.lua", base, cand)
    if fileExists(try) then return cand end
  end
  return "de"
end

function FarmingLive:traw(key)
  return (key and self.i18n.map[key]) or nil
end

function FarmingLive:resolveTemplate(maybeKey, defaultTemplate)
    if type(maybeKey) == "string" then

        local singleKey = maybeKey:match("^@([A-Z0-9_%.%-]+)$")
        if singleKey then
            local tr = self:traw(singleKey)
            if tr then return tr end
        end

        local replaced = maybeKey:gsub("@([A-Z0-9_%.%-]+)", function(k)
            return self:traw(k) or "@"..k
        end)
        return replaced
    end
    return defaultTemplate or maybeKey
end

function FarmingLive:formatMessage(message, par1, par2, par3, par4)
  if not message then return "" end
  message = self:resolveTemplate(message, message)
  local formattedMessage = message
  if par1 ~= nil then formattedMessage = formattedMessage:gsub("%%p", tostring(par1)) end
  if par2 ~= nil then formattedMessage = formattedMessage:gsub("%%d", tostring(par2)) end
  if par3 ~= nil then formattedMessage = formattedMessage:gsub("%%s", tostring(par3)) end
  if par4 ~= nil then formattedMessage = formattedMessage:gsub("%%v", tostring(par4)) end
  return formattedMessage
end
