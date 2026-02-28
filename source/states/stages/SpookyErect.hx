package states.stages;

import backend.HapticUtil;
import shaders.RainShader;

class SpookyErect extends BaseStage
{
	var rainShader:RainShader;
	var bgTrees:BGSprite;
	var bgLight:BGSprite;
	var stairsLight:BGSprite;

	var halloweenWhite:BGSprite;

	var lightningStrikeBeat:Int = 0;
  	var lightningStrikeOffset:Int = 8;

	override function create()
	{
		if (!PlayState.instance.variables.exists("stageVariables")){
			PlayState.instance.variables.set("stageVariables", new Map<String, FlxSprite>());
		}
		var stageVars = PlayState.instance.variables.get("stageVariables");

		var solid:FlxSprite = new FlxSprite(-300, -500).makeGraphic(2400, 2000, 0xFF242336);
		stageVars.set("solid", solid);
		add(solid);

		if(!ClientPrefs.data.lowQuality)
		{
			bgTrees = new BGSprite('erect/bgtrees', 200, 50, 0.8, 0.8, ['bgtrees'], true);
			bgTrees.animation.curAnim.frameRate = 5;
			stageVars.set("bgTrees", bgTrees);
			add(bgTrees);
		}

		var bgDark = new BGSprite('erect/bgDark', -560, -220);
		stageVars.set("bgDark", bgDark);
		add(bgDark);

		if(!ClientPrefs.data.lowQuality)
		{
			bgLight = new BGSprite('erect/bgLight', -560, -220);
			stageVars.set("bgLight", bgLight);
			add(bgLight);
		}

		//PRECACHE SOUNDS
		Paths.sound('thunder_1');
		Paths.sound('thunder_2');

	}
	override function createPost()
	{
		var stairsDark = new BGSprite('erect/stairsDark', 966, -225);
		PlayState.instance.variables.get("stageVariables").set("stairsDark", stairsDark);
		add(stairsDark);

		if(!ClientPrefs.data.lowQuality)
		{
			stairsLight = new BGSprite('erect/stairsLight', 966, -225);
			PlayState.instance.variables.get("stageVariables").set("stairsLight", stairsLight);
			add(stairsLight);
		}

		bgLight.alpha = 0.0001;
    	stairsLight.alpha = 0.0001;

		if(ClientPrefs.data.shaders)
		{
			rainShader = new RainShader();

			// adjust this value so that the rain looks nice
			rainShader.scale = FlxG.height / 200 * 2;
			rainShader.intensity = 0.4;
			rainShader.spriteMode = true;
			if (bgTrees != null) bgTrees.shader = rainShader;
		}

		halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
		halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
		halloweenWhite.alpha = 0;
		halloweenWhite.blend = ADD;
		PlayState.instance.variables.get("stageVariables").set("halloweenWhite", halloweenWhite);
		add(halloweenWhite);
	}

	override function update(elapsed:Float)
	{
		if(rainShader != null){
			rainShader.updateFrameInfo(bgTrees.frame);
			rainShader.update(elapsed);
		}
	}

	override function beatHit()
	{
		if (curBeat == 4 && songName == "spookeez")
		{
			doLightningStrike(false, curBeat);
		}

		if (FlxG.random.bool(10) && curBeat > (lightningStrikeBeat + lightningStrikeOffset))
		{
			doLightningStrike(true, curBeat);
		}
	}

	var postShockCounter:Int = 0;
  	var counterTargetNum:Int = 10;

	override function stepHit()
	{
		if (doPostShockHaptics)
		{
			postShockCounter++;

			var postShockAmplitude:Float = 0.05 * (counterTargetNum - postShockCounter) * 2.5;
			HapticUtil.vibrate(0, 0.01, postShockAmplitude, 0);

			if (postShockCounter == counterTargetNum)
			{
				doPostShockHaptics = false;
				postShockCounter = 0;
			}
		}
	}

	function doLightningStrike(playSound:Bool, beat:Int):Void
	{
		if (playSound)
			FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));

		//if(!ClientPrefs.data.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');
		bgLight.alpha = 1;
		stairsLight.alpha = 1;
		boyfriend.alpha = 0;
		dad.alpha = 0;
		gf.alpha = 0;
		if(ClientPrefs.data.flashing) halloweenWhite.alpha = 0.4;

		new FlxTimer().start(0.06, function(_) {
			bgLight.alpha = 0;
			stairsLight.alpha = 0;
			boyfriend.alpha = 1;
			dad.alpha = 1;
			gf.alpha = 1;
			if(ClientPrefs.data.flashing) halloweenWhite.alpha = 0;
		});

		new FlxTimer().start(0.12, function(_) {
			bgLight.alpha = 1;
			stairsLight.alpha = 1;
			boyfriend.alpha = 0;
			dad.alpha = 0;
			gf.alpha = 0;
			if(ClientPrefs.data.flashing) halloweenWhite.alpha = 0.4;
			FlxTween.tween(bgLight, {alpha: 0}, 1.5);
			FlxTween.tween(stairsLight, {alpha: 0}, 1.5);
			FlxTween.tween(boyfriend, {alpha: 1}, 1.5);
			FlxTween.tween(dad, {alpha: 1}, 1.5);
			FlxTween.tween(gf, {alpha: 1}, 1.5);
			if(ClientPrefs.data.flashing) FlxTween.tween(halloweenWhite, {alpha: 0}, 1.5);
		});

		lightningStrikeBeat = beat;
		lightningStrikeOffset = FlxG.random.int(8, 24);

		if (boyfriend.hasAnimation('scared') && boyfriend.animation.name != 'cheer')
			boyfriend.playAnim('scared', true);

		if (gf.hasAnimation('scared'))
			gf.playAnim('scared', true);

		if(ClientPrefs.data.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!game.camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		triggerLightningHaptics();
	}

	var doPostShockHaptics:Bool = false;

	function triggerLightningHaptics()
	{
		HapticUtil.vibrate(0, 0.05, 1);

		doPostShockHaptics = true;
	}
}