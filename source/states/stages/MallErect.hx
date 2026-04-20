package states.stages;

import states.stages.objects.*;
import shaders.AdjustColorShader;

class MallErect extends BaseStage
{
	var upperBoppers:BGSprite;
	var bottomBoppers:MallCrowd;
	var santa:BGSprite;

	override function create()
	{
		if (!PlayState.instance.variables.exists("stageVariables")){
			PlayState.instance.variables.set("stageVariables", new Map<String, FlxSprite>());
		}
		var stageVars = PlayState.instance.variables.get("stageVariables");

		var bgWalls:BGSprite = new BGSprite('christmas/erect/bgWalls', -726, -566, 0.2, 0.2);
		bgWalls.setGraphicSize(Std.int(bgWalls.width * 0.9));
		bgWalls.updateHitbox();
		stageVars.set("bgWalls", bgWalls);
		add(bgWalls);

		if(!ClientPrefs.data.lowQuality) {
			upperBoppers = new BGSprite('christmas/erect/upperBop', -374, -98, 0.28, 0.28, ['upperBop']);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			stageVars.set("upperBoppers", upperBoppers);
			add(upperBoppers);

			var bgEscalator:BGSprite = new BGSprite('christmas/erect/bgEscalator', -1100, -540, 0.3, 0.3);
			bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
			bgEscalator.updateHitbox();
			stageVars.set("bgEscalator", bgEscalator);
			add(bgEscalator);
		}

		var christmasTree:BGSprite = new BGSprite('christmas/erect/christmasTree', 370, -250, 0.4, 0.4);
		stageVars.set("christmasTree", christmasTree);
		add(christmasTree);

		var fog:BGSprite = new BGSprite('christmas/erect/white', -1000, 100, 0.85, 0.85);
		fog.setGraphicSize(Std.int(fog.width * 0.9));
		fog.updateHitbox();
		stageVars.set("fog", fog);
		add(fog);

		bottomBoppers = new MallCrowd(-410, 100, 'christmas/erect/bottomBop', 'bottomBop');
		bottomBoppers.scrollFactor.set(0.9, 0.9);
		stageVars.set("bottomBoppers", bottomBoppers);
		add(bottomBoppers);

		var snowUnder:FlxSprite = new FlxSprite(-1500, 800).makeGraphic(5700, 3000, 0xFFF3F4F5);
		stageVars.set("snowUnder", snowUnder);
		add(snowUnder);

		var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -1150, 680);
		stageVars.set("fgSnow", fgSnow);
		add(fgSnow);

		Paths.sound('Lights_Shut_off');
		setDefaultGF('gf-christmas');

		if(isStoryMode && !seenCutscene)
			setEndCallback(eggnogEndCutscene);
	}

	override function createPost()
	{
		santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
		PlayState.instance.variables.get("stageVariables").set("santa", santa);
		add(santa);

		if (ClientPrefs.data.shaders)
		{
			applyCharacterShader("boyfriend");
			applyCharacterShader("dad");
			if (gf != null) applyCharacterShader("gf");

			for (value in modchartCharacters.keys()) // apply for the lua characters too
			{
				// var daLuaChars:Character = modchartCharacters.get(value);
				applyCharacterShader(value);
			}

			if (santa != null) {
				var santaSolorShader = new AdjustColorShader();

				santaSolorShader.hue = 5;
				santaSolorShader.saturation = 20;

				santa.shader = santaSolorShader.shader;
			}
		}
	}

	override function countdownTick(count:Countdown, num:Int) everyoneDance();
	override function beatHit() 
	{
		if (curBeat % (gfSpeed * speedBaseMod) == 0) everyoneDance();
	}

	override function eventCalled(eventName:String, value1:String, value2:String, value3:String, flValue1:Null<Float>, flValue2:Null<Float>, flValue3:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			/*
			case "Hey!":
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						return;
				}
				bottomBoppers.animation.play('hey', true);
				bottomBoppers.heyTimer = flValue2;
			*/
		}
	}

	function everyoneDance()
	{
		if(!ClientPrefs.data.lowQuality)
			upperBoppers.dance(true);

		bottomBoppers.dance(true);
		santa.dance(true);
	}

	function eggnogEndCutscene()
	{
		if(PlayState.storyPlaylist[1] == null)
		{
			endSong();
			return;
		}

		var nextSong:String = Paths.formatToSongPath(PlayState.storyPlaylist[1]);
		if(nextSong == 'winter-horrorland')
		{
			FlxG.sound.play(Paths.sound('Lights_Shut_off'));

			var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
				-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			blackShit.scrollFactor.set();
			PlayState.instance.variables.get("stageVariables").set("blackShit", blackShit);
			add(blackShit);
			camHUD.visible = false;

			inCutscene = true;
			canPause = false;

			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				endSong();
			});
		}
		else endSong();
	}

	override function characterChangePost(charExist:String, charNew:String) {
		if (ClientPrefs.data.shaders){
			if (charExist == "bf") 
				charExist = "boyfriend";

			applyCharacterShader(charExist);
		}
	}

	function applyCharacterShader(char:String)
	{
		var character:objects.Character = psychlua.LuaUtils.getObjectDirectly(char);
		var colorShader = new AdjustColorShader();

		colorShader.hue = 5;
    	colorShader.saturation = 20;

		character.shader = colorShader.shader;
	}

	override public function destroy():Void
	{
		if (ClientPrefs.data.shaders)
		{
			for (defaultChars in [boyfriend, dad, gf])
			{
				if (defaultChars.shader != null) defaultChars.shader = null;
			}

			for (value in modchartCharacters.keys()) 
			{
				var luaChars = modchartCharacters.get(value);
				if (luaChars.shader != null) luaChars.shader = null;
			}
		}

		super.destroy();
	}
}