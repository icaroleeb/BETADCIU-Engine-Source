package states.stages;

import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import shaders.RainShader;

import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.frames.FlxAtlasFrames;

import substates.GameOverSubstate;
import states.stages.objects.*;

import objects.Note;

import cutscenes.CutsceneHandler;

import flixel.addons.display.FlxBackdrop;

import shaders.AdjustColorShader;

enum NeneState2
{
	STATE_DEFAULT;
	STATE_PRE_RAISE;
	STATE_RAISE;
	STATE_READY;
	STATE_LOWER;
}

class PhillyStreetsErect extends BaseStage
{
	final MIN_BLINK_DELAY:Int = 3;
	final MAX_BLINK_DELAY:Int = 7;
	final VULTURE_THRESHOLD:Float = 0.5;
	var blinkCountdown:Int = 3;

	var rainShader:RainShader;
	var rainShaderStartIntensity:Float = 0.01;
	var rainShaderEndIntensity:Float = 0.02;
	
	var scrollingSky:FlxTiledSprite;
	var phillyTraffic:BGSprite;

	var phillyCars:BGSprite;
	var phillyCars2:BGSprite;

	var picoFade:FlxSprite;
	var spraycan:SpraycanAtlasSprite;
	var spraycanPile:BGSprite;

	var mist0:FlxBackdrop;
	var mist1:FlxBackdrop;
	var mist2:FlxBackdrop;
	var mist3:FlxBackdrop;
	var mist4:FlxBackdrop;
	var mist5:FlxBackdrop;

	override function create()
	{
		if (!PlayState.instance.variables.exists("stageVariables")){
			PlayState.instance.variables.set("stageVariables", new Map<String, FlxSprite>());
		}
		var stageVars = PlayState.instance.variables.get("stageVariables");

		if(!ClientPrefs.data.lowQuality)
		{
			scrollingSky = new FlxTiledSprite(Paths.image('phillyStreets/erect/phillySkybox'), 2922, 718, true, false);
			scrollingSky.antialiasing = ClientPrefs.data.antialiasing;
			scrollingSky.setPosition(-650, -375);
			scrollingSky.scrollFactor.set(0.1, 0.1);
			scrollingSky.scale.set(0.65, 0.65);
			stageVars.set('scrollingSky', scrollingSky);
			add(scrollingSky);
		
			var phillySkyline:BGSprite = new BGSprite('phillyStreets/erect/phillySkyline', -545, -273, 0.2, 0.2);
			stageVars.set('phillySkyline', phillySkyline);
			add(phillySkyline);

			var phillyForegroundCity:BGSprite = new BGSprite('phillyStreets/erect/phillyForegroundCity', 625, 94, 0.3, 0.3);
			stageVars.set('phillyForegroundCity', phillyForegroundCity);
			add(phillyForegroundCity);
		}

		mist5 = new FlxBackdrop(Paths.image('phillyStreets/erect/mistMid'), X);
		mist5.setPosition(-650, -100);
		mist5.scrollFactor.set(0.5, 0.5);
		mist5.blend = ADD;
		mist5.color = 0xFF5c5c5c;
		mist5.alpha = 1;
		mist5.velocity.x = 20;
		mist5.scale.set(1.1, 1.1);
		stageVars.set('mist5', mist5);
		add(mist5);

		var phillyConstruction:BGSprite = new BGSprite('phillyStreets/erect/phillyConstruction', 1800, 364, 0.7, 1);
		stageVars.set('phillyConstruction', phillyConstruction);
		add(phillyConstruction);

		var phillyHighwayLights:BGSprite = new BGSprite('phillyStreets/erect/phillyHighwayLights', 284, 305, 1, 1);
		stageVars.set('phillyHighwayLights', phillyHighwayLights);
		add(phillyHighwayLights);

		if(!ClientPrefs.data.lowQuality)
		{
			var phillyHighwayLightsLightmap:BGSprite = new BGSprite('phillyStreets/phillyHighwayLights_lightmap', 284, 305, 1, 1);
			phillyHighwayLightsLightmap.blend = ADD;
			phillyHighwayLightsLightmap.alpha = 0.6;
			stageVars.set('phillyHighwayLightsLightmap', phillyHighwayLightsLightmap);
			add(phillyHighwayLightsLightmap);
		}

		var phillyHighway:BGSprite = new BGSprite('phillyStreets/erect/phillyHighway', 139, 209, 1, 1);
		stageVars.set('phillyHighway', phillyHighway);
		add(phillyHighway);

		if(!ClientPrefs.data.lowQuality)
		{
			for (i in 0...2)
			{
				var car:BGSprite = new BGSprite('phillyStreets/erect/phillyCars', 1200, 818, 0.9, 1, ['car1', 'car2', 'car3', 'car4'], false);
				add(car);
				switch(i)
				{
					case 0: {
						phillyCars = car;
						stageVars.set('phillyCars', car);
					}
					case 1: {
						phillyCars2 = car;
						stageVars.set('phillyCars2', car);
					}
				}
			}
			phillyCars2.flipX = true;

			phillyTraffic = new BGSprite('phillyStreets/erect/phillyTraffic', 1840, 608, 0.9, 1, ['redtogreen', 'greentored'], false);
			stageVars.set('phillyTraffic', phillyTraffic);
			add(phillyTraffic);

			var phillyTrafficLightmap:BGSprite = new BGSprite('phillyStreets/erect/phillyTraffic_lightmap', 1840, 608, 0.9, 1);
			phillyTrafficLightmap.blend = ADD;
			phillyTrafficLightmap.alpha = 0.6;
			stageVars.set('phillyTrafficLightmap', phillyTrafficLightmap);
			add(phillyTrafficLightmap);
		}

		mist4 = new FlxBackdrop(Paths.image('phillyStreets/erect/mistBack'), X, 0, 0);
		mist4.setPosition(-650, -100);
		mist4.scrollFactor.set(0.8, 0.8);
		mist4.blend = ADD;
		mist4.color = 0xFF5c5c5c;
		mist4.alpha = 1;
		mist4.velocity.x = 40;
		mist4.scale.set(0.7, 0.7);
		stageVars.set('mist4', mist4);
		add(mist4);

		var gray1:BGSprite = new BGSprite('phillyStreets/erect/greyGradient', 88, 317, 1, 1);
		gray1.alpha = 0.3;
		gray1.blend = ADD;
		stageVars.set('gray1', gray1);
		add(gray1);

		var gray2:BGSprite = new BGSprite('phillyStreets/erect/greyGradient', 88, 317, 1, 1);
		gray2.alpha = 0.8;
		gray2.blend = MULTIPLY;
		stageVars.set('gray2', gray2);
		add(gray2);

		mist3 = new FlxBackdrop(Paths.image('phillyStreets/erect/mistMid'), X);
		mist3.setPosition(-650, -100);
		mist3.scrollFactor.set(0.95, 0.95);
   		mist3.blend = ADD;
		mist3.color = 0xFF5c5c5c;
		mist3.alpha = 0.5;
		mist3.velocity.x = -50;
		mist3.scale.set(0.8, 0.8);
		stageVars.set('mist3', mist3);
		add(mist3);

		var phillyForeground:BGSprite = new BGSprite('phillyStreets/erect/phillyForeground', 88, 317, 1, 1);
		stageVars.set('phillyForeground', phillyForeground);
		add(phillyForeground);

		mist0 = new FlxBackdrop(Paths.image('phillyStreets/erect/mistMid'), X, 0, 0);
		mist0.setPosition(-650, -100);
		mist0.scrollFactor.set(1.2, 1.2);
		mist0.blend = ADD;
		mist0.color = 0xFF5c5c5c;
		mist0.alpha = 0.6;
		mist0.velocity.x = 172;
		stageVars.set('mist0', mist0);

		mist1 = new FlxBackdrop(Paths.image('phillyStreets/erect/mistMid'), X, 0, 0);
		mist1.setPosition(-650, -100);
		mist1.scrollFactor.set(1.1, 1.1);
		mist1.blend = ADD;
		mist1.color = 0xFF5c5c5c;
		mist1.alpha = 0.6;
		mist1.velocity.x = 150;
		stageVars.set('mist1', mist1);
	
		mist2 = new FlxBackdrop(Paths.image('phillyStreets/erect/mistBack'), X, 0, 0);
		mist2.setPosition(-650, -100);
		mist2.scrollFactor.set(1.2, 1.2);
		mist2.blend = ADD;
		mist2.color = 0xFF5c5c5c;
		mist2.alpha = 0.8;
		mist2.velocity.x = -80;
		stageVars.set('mist2', mist2);
		
		if(ClientPrefs.data.shaders)
			setupRainShader();

		var _song = PlayState.SONG;
		if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pico';
		if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pico';
		if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pico';
		if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'pico-dead';
		setDefaultGF('nene');
	}

	var noteTypes:Array<String> = [];
	override function createPost()
	{
		if(gf != null)
		{
			gf.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int)
			{
				switch(currentNeneState)
				{
					case STATE_PRE_RAISE:
						if (name == 'danceLeft' && frameNumber >= 14)
						{
							animationFinished = true;
							transitionState();
						}
					default:
						// Ignore.
				}
			}
		}

		add(mist0);
		add(mist1);
		add(mist2);

		if(ClientPrefs.data.shaders)
			setupCharactersShader();
	}

	override public function destroy():Void {
		if (PlayState.instance.camGame.filters != null) {
			var filters = PlayState.instance.camGame.filters;

			filters = filters.filter(function(f:BitmapFilter) {
				var shaderF = Std.downcast(f, ShaderFilter);
				return shaderF == null || shaderF.shader != rainShader;
			});
			PlayState.instance.camGame.filters = filters;
		}

		if (boyfriend.shader != null) {
			boyfriend.shader = null;
		}
		if (dad.shader != null) {
			dad.shader = null;
		}
		if (gf.shader != null) {
			gf.shader = null;
		}

		super.destroy();
	}

	override function startSong()
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return; 
		gf.animation.finishCallback = onNeneAnimationFinished;
	}
	
	function onNeneAnimationFinished(name:String)
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return; 

		if(!game.startedCountdown) return;

		switch(currentNeneState)
		{
			case STATE_RAISE, STATE_LOWER:
				if (name == 'raiseKnife' || name == 'lowerKnife')
				{
					animationFinished = true;
					transitionState();
				}

			default:
				// Ignore.
		}
	}

	function setupRainShader()
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return; 

		rainShader = new RainShader();
		rainShader.scale = FlxG.height / 200;
		switch (songName.toLowerCase())
		{
			case 'darnell' | 'darnell erect' | 'darnell (bf mix)':
				rainShaderStartIntensity = 0;
				rainShaderEndIntensity = 0.01;
			case 'lit up' | 'lit up erect' | 'lit up (bf mix)':
				rainShaderStartIntensity = 0.01;
				rainShaderEndIntensity = 0.02;
			case '2hot' | '2hot erect' | '2hot (bf mix)':
				rainShaderStartIntensity = 0.02;
				rainShaderEndIntensity = 0.04;
		}
		rainShader.intensity = rainShaderStartIntensity;
        rainShader.rainColor = 0xFFa8adb5;

		var filters = [];

		if (PlayState.instance.camGame.filters != null){
			filters = PlayState.instance.camGame.filters;
		}

		filters.push(new ShaderFilter(rainShader));
		PlayState.instance.camGame.filters = filters;
	}

	function setupCharactersShader()
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return;

		var colorShader = new AdjustColorShader();

		colorShader.brightness = -20;
		colorShader.hue = -5;
		colorShader.contrast = -25;
		colorShader.saturation = -40;

		// this is not final version yet!
		var bfShaders = [];
		var dadShaders = [];
		var gfShaders = [];

		boyfriend.shader = colorShader.shader;
		dad.shader = colorShader.shader;
		gf.shader = colorShader.shader;
	}
	
	var currentNeneState:NeneState2 = STATE_DEFAULT;
	var animationFinished:Bool = false;

	var _timer:Float = 0;
	override function update(elapsed:Float)
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return; 

		if(scrollingSky != null) scrollingSky.scrollX -= elapsed * 22;

		if(rainShader != null)
		{
			var remappedIntensityValue:Float = FlxMath.remapToRange(Conductor.songPosition, 0, (FlxG.sound.music != null ? FlxG.sound.music.length : 0), rainShaderStartIntensity, rainShaderEndIntensity);
			rainShader.intensity = remappedIntensityValue;
			rainShader.updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
			rainShader.update(elapsed);
		}

		_timer += elapsed;
		if(mist0 != null) mist0.y = 660 + (Math.sin(_timer*0.35)*70);
		if(mist1 != null) mist1.y = 500 + (Math.sin(_timer*0.3)*80);
		if(mist2 != null) mist2.y = 540 + (Math.sin(_timer*0.4)*60);
		if(mist3 != null) mist3.y = 230 + (Math.sin(_timer*0.3)*70);
		if(mist4 != null) mist4.y = 170 + (Math.sin(_timer*0.35)*50);
		if(mist5 != null) mist5.y = -80 + (Math.sin(_timer*0.08)*100);
		// mist3.y = -20 + (Math.sin(_timer*0.5)*200);
		// mist4.y = -180 + (Math.sin(_timer*0.4)*300);
		// mist5.y = -450 + (Math.sin(_timer*0.2)*1xxx50);
		
		if(gf == null || !game.startedCountdown) return;

		animationFinished = gf.isAnimationFinished();
		transitionState();
	}

	function transitionState()
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return; 

		switch (currentNeneState)
		{
			case STATE_DEFAULT:
				if (game.health <= VULTURE_THRESHOLD)
				{
					currentNeneState = STATE_PRE_RAISE;
					gf.skipDance = true;
				}

			case STATE_PRE_RAISE:
				if (game.health > VULTURE_THRESHOLD)
				{
					currentNeneState = STATE_DEFAULT;
					gf.skipDance = false;
				}
				else if (animationFinished)
				{
					currentNeneState = STATE_RAISE;
					gf.playAnim('raiseKnife');
					gf.skipDance = true;
					gf.danced = true;
					animationFinished = false;
				}

			case STATE_RAISE:
				if (animationFinished)
				{
					currentNeneState = STATE_READY;
					animationFinished = false;
				}

			case STATE_READY:
				if (game.health > VULTURE_THRESHOLD)
				{
					currentNeneState = STATE_LOWER;
					gf.playAnim('lowerKnife');
				}

			case STATE_LOWER:
				if (animationFinished)
				{
					currentNeneState = STATE_DEFAULT;
					animationFinished = false;
					gf.skipDance = false;
				}
		}
	}

	var lightsStop:Bool = false;
	var lastChange:Int = 0;
	var changeInterval:Int = 8;

	var carWaiting:Bool = false;
	var carInterruptable:Bool = true;
	var car2Interruptable:Bool = true;

	override function beatHit()
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return; 

		switch(currentNeneState) {
			case STATE_READY:
				if (blinkCountdown == 0)
				{
					gf.playAnim('idleKnife', false);
					blinkCountdown = FlxG.random.int(MIN_BLINK_DELAY, MAX_BLINK_DELAY);
				}
				else blinkCountdown--;

			default:
				// In other states, don't interrupt the existing animation.
		}

		if(ClientPrefs.data.lowQuality) return;

		if (FlxG.random.bool(10) && curBeat != (lastChange + changeInterval) && carInterruptable == true)
		{
			if(lightsStop == false)
				driveCar(phillyCars);
			else
				driveCarLights(phillyCars);
		}

		if(FlxG.random.bool(10) && curBeat != (lastChange + changeInterval) && car2Interruptable == true && lightsStop == false)
			driveCarBack(phillyCars2);

		if (curBeat == (lastChange + changeInterval)) changeLights(curBeat);
	}
	
	function changeLights(beat:Int):Void
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return; 

		lastChange = beat;
		lightsStop = !lightsStop;

		if(lightsStop)
		{
			phillyTraffic.animation.play('greentored');
			changeInterval = 20;
		}
		else
		{
			phillyTraffic.animation.play('redtogreen');
			changeInterval = 30;

			if(carWaiting == true) finishCarLights(phillyCars);
		}
	}

	function finishCarLights(sprite:BGSprite):Void
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return; 

		carWaiting = false;
		var duration:Float = FlxG.random.float(1.8, 3);
		var rotations:Array<Int> = [-5, 18];
		var offset:Array<Float> = [306.6, 168.3];
		var startdelay:Float = FlxG.random.float(0.2, 1.2);

		var path:Array<FlxPoint> = [
			FlxPoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15),
			FlxPoint.get(2400 - offset[0], 980 - offset[1] - 50),
			FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 40)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.sineIn, startDelay: startdelay});
		FlxTween.quadPath(sprite, path, duration, true, {ease: FlxEase.sineIn, startDelay: startdelay, onComplete: function(_) carInterruptable = true});
	}

	function driveCarLights(sprite:BGSprite):Void
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return; 

		carInterruptable = false;
		FlxTween.cancelTweensOf(sprite);
		var variant:Int = FlxG.random.int(1,4);
		sprite.animation.play('car' + variant);
		var extraOffset = [0, 0];
		var duration:Float = 2;

		switch(variant)
		{
			case 1:
				duration = FlxG.random.float(1, 1.7);
			case 2:
				extraOffset = [20, -15];
				duration = FlxG.random.float(0.9, 1.5);
			case 3:
				extraOffset = [30, 50];
				duration = FlxG.random.float(1.5, 2.5);
			case 4:
				extraOffset = [10, 60];
				duration = FlxG.random.float(1.5, 2.5);
		}
		var rotations:Array<Int> = [-7, -5];
		var offset:Array<Float> = [306.6, 168.3];
		sprite.offset.set(extraOffset[0], extraOffset[1]);

		var path:Array<FlxPoint> = [
			FlxPoint.get(1500 - offset[0] - 20, 1049 - offset[1] - 20),
			FlxPoint.get(1770 - offset[0] - 80, 994 - offset[1] + 10),
			FlxPoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.cubeOut} );
		FlxTween.quadPath(sprite, path, duration, true, {ease: FlxEase.cubeOut, onComplete: function(_)
		{
			carWaiting = true;
			if(lightsStop == false) finishCarLights(phillyCars);
		}});
	}
	
	function driveCar(sprite:BGSprite):Void
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return; 

		carInterruptable = false;
		FlxTween.cancelTweensOf(sprite);
		var variant:Int = FlxG.random.int(1,4);
		sprite.animation.play('car' + variant);

		var extraOffset = [0, 0];
		var duration:Float = 2;
		switch(variant)
		{
			case 1:
				duration = FlxG.random.float(1, 1.7);
			case 2:
				extraOffset = [20, -15];
				duration = FlxG.random.float(0.6, 1.2);
			case 3:
				extraOffset = [30, 50];
				duration = FlxG.random.float(1.5, 2.5);
			case 4:
				extraOffset = [10, 60];
				duration = FlxG.random.float(1.5, 2.5);
		}

		var offset:Array<Float> = [306.6, 168.3];
		sprite.offset.set(extraOffset[0], extraOffset[1]);

		var rotations:Array<Int> = [-8, 18];
		var path:Array<FlxPoint> = [
				FlxPoint.get(1570 - offset[0], 1049 - offset[1] - 30),
				FlxPoint.get(2400 - offset[0], 980 - offset[1] - 50),
				FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 40)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration);
		FlxTween.quadPath(sprite, path, duration, true, {onComplete: function(_) carInterruptable = true});
	}

	function driveCarBack(sprite:FlxSprite):Void
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return; 

		car2Interruptable = false;
		FlxTween.cancelTweensOf(sprite);
		var variant:Int = FlxG.random.int(1,4);
		sprite.animation.play('car' + variant);

		var extraOffset = [0, 0];
		var duration:Float = 2;
		switch(variant)
		{
			case 1:
				duration = FlxG.random.float(1, 1.7);
			case 2:
				extraOffset = [20, -15];
				duration = FlxG.random.float(0.6, 1.2);
			case 3:
				extraOffset = [30, 50];
				duration = FlxG.random.float(1.5, 2.5);
			case 4:
				extraOffset = [10, 60];
				duration = FlxG.random.float(1.5, 2.5);
		}

		var offset:Array<Float> = [306.6, 168.3];
		sprite.offset.set(extraOffset[0], extraOffset[1]);

		var rotations:Array<Int> = [18, -8];
		var path:Array<FlxPoint> = [
				FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 60),
				FlxPoint.get(2400 - offset[0], 980 - offset[1] - 30),
				FlxPoint.get(1570 - offset[0], 1049 - offset[1] - 10)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration);
		FlxTween.quadPath(sprite, path, duration, true, {onComplete: function(_) car2Interruptable = true});
	}

	override function goodNoteHit(note:Note)
	{
		if (PlayState.instance.curStage.toLowerCase() != "phillystreetserect") 
			return; 

		// 10% chance of playing combo50/combo100 animations for Nene
		if(FlxG.random.bool(10))
		{
			switch(game.combo)
			{
				case 50, 100:
					var animToPlay:String = 'combo${game.combo}';
					if(gf.animation.exists(animToPlay))
					{
						gf.playAnim(animToPlay);
						gf.specialAnim = true;
					}
			}
		}
	}
}