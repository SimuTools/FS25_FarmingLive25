function FarmingLive:startDebug(object, objectName)
    local modSettingsPath = getUserProfileAppPath() .. "modSettings/" .. FarmingLive.modName .. "/Debug/"

    if not fileExists(modSettingsPath) then
        createDirectoryIfNotExists(modSettingsPath)
    end

    self:debugPrintTable(object, objectName or "RootObject", modSettingsPath)
    print("Debugging abgeschlossen. Die Informationen wurden in die XML-Dateien geschrieben.")
end

function FarmingLive:debugPrintTable(t, objectName, basePath)
    local xmlFile = self:createXMLFileForFunction(objectName, basePath)
    local visitedTables = {}
    local iterationCount = 0
    local maxIterations = 100000000  

    local function recursiveDebug(t, path)
        if visitedTables[t] then
            setXMLString(xmlFile, path .. ".cyclicReference", "Zyklische Referenz erkannt")
            return
        end

        visitedTables[t] = true

        for k, v in pairs(t) do
            iterationCount = iterationCount + 1

            if iterationCount >= maxIterations then
                setXMLString(xmlFile, path .. ".maxIterationsReached", "Maximale Iterationen erreicht")
                return
            end

            local keyString = (type(k) == "table") and "TableKey" or tostring(k)

            if type(v) == "table" then
                setXMLString(xmlFile, path .. "." .. keyString .. ".Type", "Tabelle")
                recursiveDebug(v, path .. "." .. keyString)
            elseif type(v) == "function" then
                setXMLString(xmlFile, path .. "." .. keyString .. ".Type", "Funktion")
                setXMLString(xmlFile, path .. "." .. keyString .. ".Description", "Diese Funktion führt ... aus.")

            else
                setXMLString(xmlFile, path .. "." .. keyString, tostring(v))
            end
        end
    end

    recursiveDebug(t, "debug.entries." .. objectName)

    saveXMLFile(xmlFile)
    delete(xmlFile)
end

function FarmingLive:createXMLFileForFunction(funcName, basePath)
    local xmlFilePath = string.format("%sFarmingLiveDebug_%s.xml", basePath, funcName)
    local xmlFile = createXMLFile("FarmingLiveDebug", xmlFilePath, "debug")

    if xmlFile == nil then
        print("Fehler: XML-Datei konnte nicht erstellt werden für: " .. xmlFilePath)
        return nil
    end

    setXMLString(xmlFile, "debug.functionName", funcName)
    return xmlFile
end
