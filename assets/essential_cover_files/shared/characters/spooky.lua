function onUpdatePost(elapsed)
    local iconAnim = getProperty('iconP1.animation.name')
    local iconFlipped = getProperty('iconP1.flipX')
    local bfCharacter = getProperty('boyfriend.curCharacter')

    if iconAnim == 'spooky' and not iconFlipped and bfCharacter == 'spooky' then
        setProperty('iconP1.flipX', true)
    elseif iconAnim ~= 'spooky' and iconFlipped then
        setProperty('iconP1.flipX', false)
        close(true)
    end
end
