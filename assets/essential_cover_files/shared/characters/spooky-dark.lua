function onCreate()
    makeLuaCharacter("dadNormal", "spooky", false)
    setObjectOrder("dadNormal", getObjectOrder("dad") - 1)
    setProperty("dadNormal.stopIdle", true)
end

function onUpdatePost(elapsed)
    local iconAnim = getProperty('iconP1.animation.name')
    local iconFlipped = getProperty('iconP1.flipX')
    local bfCharacter = getProperty('boyfriend.curCharacter')

    if iconAnim == 'spooky-dark' and not iconFlipped and bfCharacter == 'spooky-dark' then
        setProperty('iconP1.flipX', true)
    elseif iconAnim ~= 'spooky-dark' and iconFlipped then
        setProperty('iconP1.flipX', false)
    end

    setProperty("dadNormal.animation.name", getProperty("dad.animation.name"))

    if getProperty("dad.alpha") ~= 1 then
        setProperty("dadNormal.alpha", 1)
    else
        setProperty("dadNormal.alpha", 0.0001)
    end
end

function onDestroy()
    setProperty('iconP1.flipX', false)
end