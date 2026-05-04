mouthOffsetX = 461
mouthOffsetY = -80
mouthOffsetAngle = -5

function onCreate()
    makeFlxAnimateSprite('sakura_bfMouth', getProperty('boyfriend.x') + mouthOffsetX, getProperty('boyfriend.y') + mouthOffsetY, 'backgrounds/sserafim/sserafim-lipsync')

    --addAnimationBySymbolIndices('sakuraMouth', 'idle', 'lip sync all', (3), 24, false)
    --playAnim('sakura_bfMouth', 'idle', true, false)

    setProperty('sakura_bfMouth.flipX', true)
    setProperty('sakura_bfMouth.angle', -5)
    setProperty('sakura_bfMouth.shader', getProperty('boyfriend.shader'))
    --setProperty("sakura_bfMouth.alpha", 0.4)

    addLuaSprite('sakura_bfMouth', true)
end

singAnimations = {'singLEFT', 'singDOWN', 'singUP', 'singRIGHT'}

function onUpdatePost(elapsed)
    local curFrame = getProperty('boyfriend.atlas.anim.curFrame')

    if getProperty('boyfriend.atlas.anim.curSymbol.name') == "idle" then
        if curFrame == 0 then
            mouthOffsetX = 434
            mouthOffsetY = -84
            mouthAngle = -10
        elseif curFrame == 2 then
            mouthOffsetX = 435
            mouthOffsetY = -84
            mouthAngle = -9.8
        elseif curFrame == 4 then -- continue
            mouthOffsetX = 450
            mouthOffsetY = -83
            mouthAngle = -7
        elseif curFrame == 6 then --
            mouthOffsetX = 453.3
            mouthOffsetY = -84
            mouthAngle = -6.7
        elseif curFrame == 9 then
            mouthOffsetX = 460.6
            mouthOffsetY = -79.7
            mouthAngle = -5
        elseif curFrame == 11 then
            mouthOffsetX = 461
            mouthOffsetY = -80
            mouthAngle = -5
        elseif curFrame == 12 then
            mouthOffsetX = 461
            mouthOffsetY = -80
            mouthAngle = -5
        end

        setProperty('sakura_bfMouth.angle', mouthAngle)
        setProperty("sakura_bfMouth.x", getProperty("boyfriend.x") + mouthOffsetX)
        setProperty("sakura_bfMouth.y", getProperty("boyfriend.y") + mouthOffsetY)
        setProperty("sakura_bfMouth.alpha", 1)
    end
end

function goodNoteHit()
    if getProperty('sakura_bfMouth.alpha') == 0 then
        setProperty("sakura_bfMouth.alpha", 1)
    end
end

function noteMiss()
    if getProperty('sakura_bfMouth.alpha') == 1 then
        setProperty("sakura_bfMouth.alpha", 0)
    end
end