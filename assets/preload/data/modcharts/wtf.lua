function start (song)
	print("Song: " .. song .. " @ " .. bpm .. " downscroll: " .. downscroll)

	spinLength = 0
end

local stup = 1

function update(elapsed)
	local currentBeat = (songPos / 1000) * (bpm / 60)

	if spinLength < 32 then
		spinLength = spinLength + 0.2
	end

	for i = 0, 7 do
		setActorX(_G['defaultStrum' .. i .. 'X'] + spinLength * math.sin((currentBeat + i*0.25) * math.pi), i)
		setActorY(_G['defaultStrum' .. i .. 'Y'] + spinLength * math.cos((currentBeat + i*0.25) * math.pi), i)
		setActorAngle(_G['defaultStrum' .. i .. 'Angle'] + spinLength * math.sin((currentBeat + i*0.25) * math.pi), i)

		setActorAlpha(stup,i)
	end

	setHudZoom(stup)
	setHudPosition(((currentBeat % 16) * 10) - 100, ((currentBeat % 16) * 10) - 100)
end

function stepHit(step)
	stup = stup - 0.05

	if stup < 0.2 then
		stup = 1
	end
end

print("Mod Chart script loaded :)")