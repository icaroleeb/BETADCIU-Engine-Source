function onCreatePost()
    makeAbotSpeaker("gf")
end

function makeAbotSpeaker(char)
    local abotStuff = {}

    makeAnimatedLuaSprite('abotHead', 'characters/abotPixel/abotHead', 0, 0)
    setProperty('abotHead.antialiasing', false)
    addAnimationByPrefix('abotHead', 'toleft', 'toleft0', 24, false)
    addAnimationByPrefix('abotHead', 'toright', 'toright0', 24, false)
    addLuaSprite('abotHead')
    table.insert(abotStuff, "abotHead")

    makeAnimatedLuaSprite("abot", 'characters/abotPixel/aBotPixelBody')
    scaleObject("abot", 6, 6, false)
    setProperty('abot.origin.x', math.floor(getProperty('abot.origin.x')))
    setProperty('abot.origin.y', math.floor(getProperty('abot.origin.y')))
    setProperty("abot.antialiasing", false)
    setProperty('abot.x', getProperty('gf.x'))
    setProperty('abot.y', getProperty('gf.y'))
    addAnimationByPrefix('abot', 'danceLeft', 'danceLeft', 24, false)
    addAnimationByPrefix('abot', 'danceRight', 'danceRight', 24, false)
    addAnimationByPrefix('abot', 'lowerKnife', 'return', 24, false)
    table.insert(abotStuff, "abot")

    makeLuaSprite("abotSpeaker", 'characters/abotPixel/aBotPixelSpeaker')
    scaleObject("abotSpeaker", 6, 6, false)
    setProperty('abotSpeaker.origin.x', math.floor(getProperty('abotSpeaker.origin.x')))
    setProperty('abotSpeaker.origin.y', math.floor(getProperty('abotSpeaker.origin.y')))
    scaleObject("abotSpeaker.antialiasing", false)
    scaleObject("abotSpeaker.x", getProperty('gf.x'))
    scaleObject("abotSpeaker.y", getProperty('gf.y'))
    addAnimationByPrefix('abotSpeaker', 'danceLeft', 'danceLeft', 24, false)
    table.insert(abotStuff, "abotSpeaker")

    makeLuaSprite("abotBack", 'characters/abotPixel/aBotPixelBack')
    scaleObject("abotBack", 6.1, 6, false)
    setProperty("abotBack.antialiasing", false)
    setProperty("abotBack.x", getProperty("gf.x"))
    setProperty("abotBack.y", getProperty("gf.y"))
    table.insert(abotStuff, abotBack)

    for i = 1,#abotSprites do
        sprite = abotSprites[i]

        addLuaSprite(sprite)
    end
end