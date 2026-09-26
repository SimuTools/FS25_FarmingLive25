local function flTrim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function flResolveMode(mode)
    local normalized = flTrim(mode)
    if normalized == "" or normalized:lower() == "default" or normalized:lower() == "global" or normalized:lower() == "inherit" then
        return nil
    end
    return normalized
end

local function flTemplate(template, values)
    local text = FarmingLive:resolveTemplate(template, template)
    return (tostring(text):gsub("{([%w_]+)}", function(key)
        local value = values[key]
        if value == nil then
            return "{" .. tostring(key) .. "}"
        end
        return tostring(value)
    end))
end

local function flGenerateQuestion()
    local operatorRoll = math.random(1, 3)
    local a, b, correct, expr

    if operatorRoll == 1 then
        a = math.random(2, 20)
        b = math.random(2, 20)
        correct = a + b
        expr = string.format("%d + %d", a, b)
    elseif operatorRoll == 2 then
        a = math.random(8, 30)
        b = math.random(1, a - 1)
        correct = a - b
        expr = string.format("%d - %d", a, b)
    else
        a = math.random(2, 12)
        b = math.random(2, 12)
        correct = a * b
        expr = string.format("%d x %d", a, b)
    end

    local wrong = correct
    while wrong == correct or wrong < 0 do
        wrong = correct + math.random(-12, 12)
    end

    local correctSide = (math.random(1, 2) == 1) and "left" or "right"
    local leftValue = (correctSide == "left") and correct or wrong
    local rightValue = (correctSide == "right") and correct or wrong

    return {
        expr = expr,
        correct = correct,
        left = leftValue,
        right = rightValue,
        correctSide = correctSide
    }
end

local function flReadSteeringValue(vehicle, fallbackValue)
    local value = nil

    if vehicle ~= nil and vehicle.spec_drivable ~= nil then
        local spec = vehicle.spec_drivable

        if spec.steeringInput ~= nil then
            value = spec.steeringInput
        end

        if (value == nil or math.abs(value) < 0.001) and spec.axisSide ~= nil then
            value = spec.axisSide
        end

        if (value == nil or math.abs(value) < 0.001) and spec.axisSideInput ~= nil then
            value = spec.axisSideInput
        end

        if (value == nil or math.abs(value) < 0.001) and spec.lastInputValues ~= nil and spec.lastInputValues.axisSide ~= nil then
            value = spec.lastInputValues.axisSide
        end
    end

    if value == nil then
        value = fallbackValue or 0
    end

    value = tonumber(value) or 0
    if value < -1 then
        value = -1
    elseif value > 1 then
        value = 1
    end

    return value
end

local function flForceSteeringNeutral(vehicle)
    if vehicle == nil or vehicle.spec_drivable == nil then
        return
    end

    local spec = vehicle.spec_drivable
    spec.steeringInput = 0
    if spec.axisSide ~= nil then
        spec.axisSide = 0
    end
    if spec.axisSideInput ~= nil then
        spec.axisSideInput = 0
    end
    if spec.lastInputValues ~= nil and spec.lastInputValues.axisSide ~= nil then
        spec.lastInputValues.axisSide = 0
    end

    if vehicle.setSteeringInput ~= nil then
        vehicle:setSteeringInput(0)
    end
end

function FarmingLive:mathGame(playerName)
    if not g_localPlayer or not g_currentMission then
        self:endActiveEvent()
        return
    end

    local rootVehicle = self:requireCurrentVehicle(playerName, self.mathGame, playerName)
    if rootVehicle == nil then
        return
    end

    if rootVehicle.spec_drivable == nil then
        self:queueVehicleRetry(playerName, self.mathGame, playerName)
        return
    end

    local cfg = self.config.mathGame or {}
    local minQuestions = math.max(1, tonumber(cfg.minQuestions) or 3)
    local maxQuestions = math.max(minQuestions, tonumber(cfg.maxQuestions) or minQuestions)
    local totalQuestions = math.random(minQuestions, maxQuestions)
    local minPenalty = math.max(1, tonumber(cfg.minPenaltyMinutes) or 1)
    local maxPenalty = math.max(minPenalty, tonumber(cfg.maxPenaltyMinutes) or minPenalty)
    local betweenQuestionMs = math.max(250, tonumber(cfg.betweenQuestionMs) or 900)
    local questionTimeoutMs = tonumber(cfg.questionTimeoutMs) or 15000
    if questionTimeoutMs < 0 then questionTimeoutMs = 0 end
    local messageMode = flResolveMode(cfg.messageMode)
    local answerThreshold = tonumber(cfg.answerThreshold) or 0.45
    local neutralThreshold = tonumber(cfg.neutralThreshold) or 0.12
    local recenterMs = math.max(0, tonumber(cfg.recenterMs) or 900)
    local startDelayMs = math.max(0, tonumber(cfg.startDelayMs) or 850)
    local hookKey = "mathGameInput"

    local phase = "quiz"
    local questionIndex = 0
    local activeQuestion = nil
    local activeVehicle = nil
    local currentAxisSide = 0
    local waitUntil = (g_time or 0) + startDelayMs
    local readyForAnswer = false
    local questionEndTime = 0
    local recenterUntil = 0
    local totalPenaltyMinutes = 0
    local penaltyEndTime = 0
    local penaltyVehicle = nil
    local penaltyMotorVehicle = nil
    local penaltyOrigStartMotor = nil
    local lastPenaltyWarn = 0

    local function cleanupInputVehicle()
        if activeVehicle ~= nil then
            flForceSteeringNeutral(activeVehicle)
            FarmingLive:detachVehiclePhysicsHook(activeVehicle, hookKey)
        end
        activeVehicle = nil
        currentAxisSide = 0
        readyForAnswer = false
        recenterUntil = 0
    end

    local function cleanupPenaltyVehicle()
        if penaltyMotorVehicle ~= nil and penaltyOrigStartMotor ~= nil then
            penaltyMotorVehicle.startMotor = penaltyOrigStartMotor
        end

        if penaltyVehicle ~= nil and penaltyVehicle.spec_drivable ~= nil then
            penaltyVehicle.spec_drivable.brakeInput = 0
        end

        penaltyVehicle = nil
        penaltyMotorVehicle = nil
        penaltyOrigStartMotor = nil
    end

    local function inputHook(selfVeh, axisForward, axisSide, doHandbrake, dt)
        currentAxisSide = tonumber(axisSide) or 0

        if (g_time or 0) < recenterUntil then
            flForceSteeringNeutral(selfVeh)
            return axisForward, 0, doHandbrake, dt
        end

        return axisForward, axisSide, doHandbrake, dt
    end

    local function attachInputVehicle(vehicle)
        if vehicle == nil or vehicle.spec_drivable == nil then
            return false
        end

        if activeVehicle ~= vehicle then
            cleanupInputVehicle()
            activeVehicle = vehicle
        end

        FarmingLive:attachVehiclePhysicsHook(vehicle, hookKey, inputHook)
        return true
    end

    local function attachPenaltyVehicle(vehicle)
        if vehicle == nil or vehicle.spec_motorized == nil or vehicle.spec_motorized.motor == nil then
            return false
        end

        local motorVehicle = vehicle.spec_motorized.motor.vehicle or vehicle
        if penaltyVehicle == vehicle and penaltyMotorVehicle == motorVehicle then
            if vehicle.spec_drivable ~= nil then
                vehicle.spec_drivable.brakeInput = 1
            end
            return true
        end

        cleanupPenaltyVehicle()

        penaltyVehicle = vehicle
        penaltyMotorVehicle = motorVehicle
        penaltyOrigStartMotor = motorVehicle.startMotor
        motorVehicle.startMotor = function(selfVeh, ...)
            return false
        end

        motorVehicle:stopMotor(true)
        if vehicle.spec_drivable ~= nil then
            vehicle.spec_drivable.brakeInput = 1
        end

        return true
    end

    local function getQuizVehicle()
        local vehicle = FarmingLive:getCurrentVehicleOrLast()
        if vehicle ~= nil and vehicle.spec_drivable ~= nil then
            return vehicle
        end
        return rootVehicle
    end

    local function showMessage(template, durationMs, extra)
        local values = {
            player = tostring(playerName or ""),
            total = totalQuestions,
            index = questionIndex,
            remaining = math.max(0, totalQuestions - questionIndex),
            penaltyTotal = totalPenaltyMinutes
        }

        if type(extra) == "table" then
            for k, v in pairs(extra) do
                values[k] = v
            end
        end

        FarmingLive:showWarning(flTemplate(template, values), durationMs, messageMode)
    end

    local function beginPenalty()
        phase = "penalty"
        penaltyEndTime = (g_time or 0) + (totalPenaltyMinutes * 60 * 1000)
        cleanupInputVehicle()
        activeQuestion = nil
        waitUntil = 0
        questionEndTime = 0
        showMessage(cfg.resultPenalty or DEFAULT_MATHGAME_RESULT_PENALTY, 3200, { penaltyTotal = totalPenaltyMinutes })
        showMessage(cfg.penaltyStart or DEFAULT_MATHGAME_PENALTY_START, 3200, { penaltyTotal = totalPenaltyMinutes })
        lastPenaltyWarn = 0
    end

    local function finishQuizNoPenalty(watcher)
        cleanupInputVehicle()
        cleanupPenaltyVehicle()
        showMessage(cfg.resultNoPenalty or DEFAULT_MATHGAME_RESULT_NOPENALTY, 3200)
        FarmingLive:removeUpdateable(watcher)
        FarmingLive:endActiveEvent()
    end

    local function askNextQuestion()
        questionIndex = questionIndex + 1
        activeQuestion = flGenerateQuestion()
        currentAxisSide = 0
        readyForAnswer = false
        recenterUntil = 0
        if activeVehicle ~= nil then
            flForceSteeringNeutral(activeVehicle)
        end

        if questionTimeoutMs > 0 then
            questionEndTime = (g_time or 0) + questionTimeoutMs
        else
            questionEndTime = 0
        end

        showMessage(cfg.question or DEFAULT_MATHGAME_QUESTION, math.max(1500, questionTimeoutMs > 0 and questionTimeoutMs or 10000), {
            expr = activeQuestion.expr,
            left = activeQuestion.left,
            right = activeQuestion.right,
            seconds = questionTimeoutMs > 0 and math.ceil(questionTimeoutMs / 1000) or "∞",
            limit = questionTimeoutMs > 0 and math.ceil(questionTimeoutMs / 1000) or "∞"
        })
    end

    local function resolveQuestion(wasCorrect, penaltyMinutes, wasTimeout)
        local remaining = math.max(0, totalQuestions - questionIndex)

        if wasCorrect then
            showMessage(cfg.correct or DEFAULT_MATHGAME_CORRECT, 2200, {
                correct = activeQuestion.correct,
                remaining = remaining
            })
        else
            totalPenaltyMinutes = totalPenaltyMinutes + penaltyMinutes
            local wrongTemplate = wasTimeout and (cfg.timeout or DEFAULT_MATHGAME_TIMEOUT) or (cfg.wrong or DEFAULT_MATHGAME_WRONG)
            showMessage(wrongTemplate, 2600, {
                correct = activeQuestion.correct,
                penalty = penaltyMinutes,
                penaltyTotal = totalPenaltyMinutes,
                remaining = remaining
            })
        end

        activeQuestion = nil
        currentAxisSide = 0
        readyForAnswer = false
        if activeVehicle ~= nil then
            flForceSteeringNeutral(activeVehicle)
        end
        if recenterMs > 0 then
            recenterUntil = (g_time or 0) + recenterMs
        else
            recenterUntil = 0
        end
        questionEndTime = 0
        waitUntil = (g_time or 0) + betweenQuestionMs
    end

    attachInputVehicle(rootVehicle)
    showMessage(cfg.start or DEFAULT_MATHGAME_START, 3200, { total = totalQuestions })

    local watcher = {}
    function watcher:update(dt)
        local now = g_time or 0

        if phase == "quiz" then
            local quizVehicle = getQuizVehicle()
            if quizVehicle ~= nil then
                attachInputVehicle(quizVehicle)
                currentAxisSide = flReadSteeringValue(quizVehicle, currentAxisSide)
                if now < recenterUntil and quizVehicle.spec_drivable ~= nil then
                    flForceSteeringNeutral(quizVehicle)
                    currentAxisSide = 0
                end
            end

            if activeQuestion == nil then
                if questionIndex >= totalQuestions then
                    if totalPenaltyMinutes > 0 then
                        beginPenalty()
                    else
                        finishQuizNoPenalty(self)
                    end
                    return
                end

                if now >= waitUntil then
                    askNextQuestion()
                end
                return
            end

            if questionEndTime > 0 and now >= questionEndTime then
                resolveQuestion(false, math.random(minPenalty, maxPenalty), true)
                return
            end

            local absAxis = math.abs(currentAxisSide or 0)

            if not readyForAnswer then
                if absAxis <= neutralThreshold then
                    readyForAnswer = true
                end
                return
            end

            if currentAxisSide <= -answerThreshold then
                resolveQuestion(activeQuestion.correctSide == "left", math.random(minPenalty, maxPenalty), false)
                return
            elseif currentAxisSide >= answerThreshold then
                resolveQuestion(activeQuestion.correctSide == "right", math.random(minPenalty, maxPenalty), false)
                return
            end
        elseif phase == "penalty" then
            if now >= penaltyEndTime then
                cleanupPenaltyVehicle()
                showMessage(cfg.penaltyDone or DEFAULT_MATHGAME_PENALTY_DONE, 2600, { penaltyTotal = totalPenaltyMinutes })
                FarmingLive:removeUpdateable(self)
                FarmingLive:endActiveEvent()
                return
            end

            local penaltyTarget = FarmingLive:getCurrentVehicleOrLast()
            if penaltyTarget ~= nil then
                attachPenaltyVehicle(penaltyTarget)
            end

            if now - lastPenaltyWarn >= 1000 then
                lastPenaltyWarn = now
                showMessage(cfg.penaltyTick or DEFAULT_MATHGAME_PENALTY_TICK, 1200, {
                    seconds = math.ceil((penaltyEndTime - now) / 1000),
                    penaltyTotal = totalPenaltyMinutes
                })
            end
        end
    end

    FarmingLive:addUpdateable(watcher)
end