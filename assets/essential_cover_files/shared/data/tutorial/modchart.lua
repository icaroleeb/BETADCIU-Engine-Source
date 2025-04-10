function onCreate() -- do nothing
    
end

function onUpdate(elapsed)
    if difficulty == 2 and curStep > 400 then
        local currentBeat = (songPos / 1000)*(bpm/60)
		for i=0,7 do
			setActorX(_G['defaultStrum'..i..'X'] + 32 * math.sin((currentBeat + i*0.25) * math.pi), i)
			setActorY(_G['defaultStrum'..i..'Y'] + 32 * math.cos((currentBeat + i*0.25) * math.pi), i)
		end
    end
end

function onMoveCamera(tag)
    if tag == "dad" then
        doTweenZoom("GFZoom", "camGame", 1.3,(crochet * 4) / 1000)
    elseif tag == "boyfriend" then
        doTweenZoom("GFZoom", "camGame", 1,(crochet * 4) / 1000)
    end
end

function onBeatHit() -- do nothing
    if curBeat % 16 == 15 and curBeat > 16 and curBeat < 48 then
        playActorAnimation('boyfriend', 'hey', true, false)
        playActorAnimation('dad', 'cheer', true, false)
    end

end

function onStepHit() -- do nothing

end