DEFAULT_CHARACTERS = {"gf", "dad", "boyfriend"}
daModchartCharacters = {}
ABOT_PATH = "characters/abot/"
BAR_COUNT = 7

PupilState = {LEFT, RIGHT}

function onCreate()
    addHaxeLibrary('LuaUtils', 'psychlua')

    for c = 1, #DEFAULT_CHARACTERS do
        local charName = DEFAULT_CHARACTERS[c]
        if getProperty(charName .. ".curCharacter") == "nene-christmas" then
            createAbotSpeaker(charName) 
        end
    end

    daModchartCharacters = getProperty('modchartCharacters')

    if #daModchartCharacters >= 1 then
        for c = 1, #daModchartCharacters do
            local modchartCharName = DEFAULT_CHARACTERS[c]
            if getProperty(daModchartCharacters[c]..'.curCharacter') == "nene-christmas" then
                createAbotSpeaker(modchartCharName)
            end
        end
    end
end

function onCharacterChangePost(charObj, charCur)
    if charCur == "nene-christmas" then
        createAbotSpeaker(charObj)
        setupAnalyzers(charObj)
    end
end

function onSongStart()
    for c = 1, #DEFAULT_CHARACTERS do
        local charName = DEFAULT_CHARACTERS[c]
        if getProperty(charName .. ".curCharacter") == "nene-christmas" then
            setupAnalyzers(charName)
        end
    end

    daModchartCharacters = getProperty('modchartCharacters')

    if #daModchartCharacters >= 1 then
        for c = 1, #daModchartCharacters do
            local modchartCharName = DEFAULT_CHARACTERS[c]
            if getProperty(daModchartCharacters[c]..'.curCharacter') == "nene-christmas" then
                setupAnalyzers(modchartCharName)
            end
        end
    end
end

function setupAnalyzers(char)
    initLuaAnalyzerAudio(char .. "analyzer", BAR_COUNT, 0.1, 40)
    setProperty(char .. "analyzer.minDb", -65)
    setProperty(char .. "analyzer.maxDb", -25)
    setProperty(char .. "analyzer.maxFreq", 22000)

    setProperty(char .. "analyzer.minFreq", 10)
end

function onUpdatePost(elapsed)
    if not getProperty("startingSong") then
        for c = 1, #DEFAULT_CHARACTERS do
            local levels = getLuaAnalyzerLevels(DEFAULT_CHARACTERS[c] .. "analyzer")

            for i = 1, math.min(#levels, BAR_COUNT) do
                local name = 'viz' .. i
                local animFrame = math.round(levels[i] * 6)

                setProperty(name .. '.visible', animFrame > 0)

                animFrame = animFrame - 1;

                animFrame = math.floor(math.min(5, animFrame))
                animFrame = math.floor(math.max(0, animFrame))

                animFrame = math.floor(math.abs(animFrame - 5))

                setProperty(name .. '.animation.curAnim.curFrame', animFrame)
            end
        end
    end
end

function onMoveCamera(focus)
    if getProperty(focus .. ".isPlayer") then
        playAnim("gfAbotPupil", 'lookright', true)
    else
        playAnim("gfAbotPupil", 'lookleft', true)
    end
end

function onBeatHit()
    for c = 1, #DEFAULT_CHARACTERS do
        local charName = DEFAULT_CHARACTERS[c]
        playAnim(charName .. "Abot", "idle", true)
    end

    daModchartCharacters = getProperty('modchartCharacters')

    if #daModchartCharacters >= 1 then
        for c = 1, #daModchartCharacters do
            local modchartCharName = DEFAULT_CHARACTERS[c]
            playAnim(modchartCharName .. "Abot", "idle", true)
        end
    end
end

function createAbotSpeaker(char)
    makeLuaSprite(char .. "StereoBG", ABOT_PATH .. "stereoBG", 0, 0)
    addLuaSprite(char .. "StereoBG")

    local positionX = {0, 59, 56, 66, 54, 52, 51}
    local positionY = {0, -8, -3.5, -0.4, 0.5, 4.7, 7}
    local visCount = BAR_COUNT + 1

    makeLuaSpriteGroup(char .. "AbotViz")
    addLuaSprite(char .. "AbotViz")

    for index = 1, visCount - 1 do
        local function sum(num, total)
            return total + num
        end

        local posX = 0
        for i = 1, index do
            posX = sum(positionX[i], posX)
        end

        local posY = 0
        for i = 1, index do
            posY = sum(positionY[i], posY)
        end

        local visStr = 'viz';
        makeAnimatedLuaSprite("viz" .. index, ABOT_PATH .. "aBotViz", posX, posY)
        addAnimationByPrefix("viz" .. index, "VIZ", visStr .. index .. "0", 24, false)
        playAnim("viz" .. index, 'VIZ', false, false, 1)
        setProperty("viz" .. index .. ".visible", false)
        groupAddSprite(char .. "AbotViz", "viz" .. index)
    end

    makeLuaSprite(char .. "EyeWhites", nil, 0, 0)
    makeGraphic(char .. "EyeWhites", 160, 60, "FFFFFF")
    addLuaSprite(char .. "EyeWhites")

    makeFlxAnimateSprite(char .. "AbotPupil", 0, 0, ABOT_PATH .. "systemEyes")
    addAnimationBySymbolIndices(char .. "AbotPupil", 'lookleft', 'a bot eyes lookin', "0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17", 24, false)
	addAnimationBySymbolIndices(char .. "AbotPupil", 'lookright', 'a bot eyes lookin', "18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35", 24, false)
    addLuaSprite(char .. "AbotPupil")

    makeFlxAnimateSprite(char .. "Abot", 0, 0, ABOT_PATH .. "abotSystem")
    addAnimationBySymbol(char .. "Abot", "idle", "Abot System", 24, false)
    addLuaSprite(char .. "Abot")

    refreshAbotSpeakerPosition(char)
end

function removeAbotSpeaker(char)
    removeLuaSprite(char .. "StereoBG", true)
    removeLuaSprite(char .. "AbotViz", true)

    for index = 1, visCount - 1 do
        removeLuaSprite("viz" .. index, true)
    end

    removeLuaSprite(char .. "EyeWhites", true)
    removeLuaSprite(char .. "AbotPupil", true)
    removeLuaSprite(char .. "Abot", true)
end

function refreshAbotSpeakerPosition(char)
    setProperty(char .. 'Abot.x', getProperty(char .. '.x') - 95)
    setProperty(char .. 'Abot.y', getProperty(char .. '.y') + 316)

    local abotX = getProperty(char .. 'Abot.x')
    local abotY = getProperty(char .. 'Abot.y')

    setProperty(char .. 'AbotViz.x', abotX + 207)
    setProperty(char .. 'AbotViz.y', abotY + 84)
    
    setProperty(char .. 'EyeWhites.x', abotX + 40)
    setProperty(char .. 'EyeWhites.y', abotY + 250)

    setProperty(char .. 'AbotPupil.x', abotX + 50)
    setProperty(char .. 'AbotPupil.y', abotY + 238)

    setProperty(char .. 'StereoBG.x', abotX + 150)
    setProperty(char .. 'StereoBG.y', abotY + 30)
end

function math.round(n)
    return math.floor(n + 0.5)
end

function onDestroy()
    for c = 1, #DEFAULT_CHARACTERS do
        local charName = DEFAULT_CHARACTERS[c]
        if getProperty(charName .. ".curCharacter") == "nene-christmas" then
            removeAbotSpeaker(charName) 
        end
    end

    daModchartCharacters = getProperty('modchartCharacters')

    if #daModchartCharacters >= 1 then
        for c = 1, #daModchartCharacters do
            local modchartCharName = DEFAULT_CHARACTERS[c]
            if getProperty(daModchartCharacters[c]..'.curCharacter') == "nene-christmas" then
                removeAbotSpeaker(modchartCharName)
            end
        end
    end
end