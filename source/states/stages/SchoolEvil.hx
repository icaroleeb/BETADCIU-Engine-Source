package states.stages;

import flixel.addons.effects.FlxTrail;
import states.stages.objects.*;
import substates.GameOverSubstate;
import cutscenes.DialogueBox;
import objects.FunkinSprite;
import shaders.WiggleEffect;
import openfl.utils.Assets as OpenFlAssets;

class SchoolEvil extends BaseStage
{
	var pixelPerfectEffectArray:Array<FlxSprite> = []; // long array name lol

	var backTrees:FunkinSprite;
	var school:FunkinSprite;
	var street:FunkinSprite;
	var trees:FunkinSprite;

	var wiggleBack:WiggleEffect;
	var wiggleSchool:WiggleEffect;
	var wiggleGround:WiggleEffect;
	var wiggleTrees:WiggleEffect;

	override function create()
	{
		if (!PlayState.instance.variables.exists("stageVariables")){
			PlayState.instance.variables.set("stageVariables", new Map<String, FlxSprite>());
		}
		var stageVars = PlayState.instance.variables.get("stageVariables");

		var _song = PlayState.SONG;
		if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
		if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
		if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
		if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';

		var solid:FlxSprite = new FlxSprite(-500, -1000).makeGraphic(2400, 2000, 0xFF000000);
		solid.scrollFactor.set();
		stageVars.set("solid", solid);
		add(solid);

		backTrees = new FunkinSprite(-842, -80, Paths.image('weeb/evil/weebBackTrees'));
		backTrees.scrollFactor.set(0.5, 0.5);
		stageVars.set("backTrees", backTrees);
		add(backTrees);
		backTrees.antialiasing = false;
		pixelPerfectEffectArray.push(backTrees);

		school = new FunkinSprite(-816, -38, Paths.image('weeb/evil/weebSchool'));
		school.scrollFactor.set(0.75, 0.75);
		stageVars.set("school", school);
		add(school);
		school.antialiasing = false;
		pixelPerfectEffectArray.push(school);

		street = new FunkinSprite(-662, 6, Paths.image('weeb/evil/weebStreet'));
		street.scrollFactor.set(0.75, 0.75);
		stageVars.set("street", street);
		add(street);
		street.antialiasing = false;
		pixelPerfectEffectArray.push(street);

		trees = new FunkinSprite(-662, 6, Paths.image('weeb/evil/weebTrees'));
		trees.scrollFactor.set(0.75, 0.75);
		stageVars.set("trees", trees);
		add(trees);
		trees.antialiasing = false;
		pixelPerfectEffectArray.push(trees);
		
		setDefaultGF('gf-pixel');

		if (ClientPrefs.data.perfectPixel == "inGame") {
			for (sprite in pixelPerfectEffectArray)
			{
				sprite.pixelPerfectPosition = true;
				sprite.pixelPerfectRender = true;
			}
		}

		for (sprite in pixelPerfectEffectArray)
		{ 
			sprite.scale.set(6, 6);
			sprite.updateHitbox();
		}

		if (PlayState.instance.startingSong){
			FlxG.sound.playMusic(Paths.music('LunchboxScary'), 0);
			FlxG.sound.music.fadeIn(1, 0, 0.8);
			if(isStoryMode && !seenCutscene)
			{
				initDoof();
				setStartCallback(schoolIntro);
			}
		}
	}

	override function createPost()
	{
		var trail:FlxTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
		PlayState.instance.variables.get("stageVariables").set("trail", trail);
		addBehindDad(trail);

		if(!ClientPrefs.data.shaders)
			return;

		wiggleBack = new WiggleEffect(2 * 0.8, 4 * 0.4, 0.011, WiggleEffectType.DREAMY);
		wiggleSchool = new WiggleEffect(2, 4, 0.017, WiggleEffectType.DREAMY);
		wiggleGround = new WiggleEffect(2, 4, 0.007, WiggleEffectType.DREAMY);
		wiggleTrees = new WiggleEffect(2, 4, 0.007, WiggleEffectType.DREAMY);

		backTrees.shader = wiggleBack.shader;
		school.shader = wiggleSchool.shader;
		street.shader = wiggleGround.shader;
		trees.shader = wiggleTrees.shader;
	}

	override function update(elapsed:Float)
	{
		if (wiggleBack != null) wiggleBack.update(elapsed);
		if (wiggleSchool != null) wiggleSchool.update(elapsed);
		if (wiggleGround != null) wiggleGround.update(elapsed);
		if (wiggleTrees != null) wiggleTrees.update(elapsed);
	}

	// Ghouls event
	var bgGhouls:FunkinSprite;
	override function eventCalled(eventName:String, value1:String, value2:String, value3:String, value4:String, flValue1:Null<Float>, flValue2:Null<Float>, flValue3:Null<Float>, flValue4:Null<Float>, strumTime:Float)	{
		switch(eventName)
		{
			case "Trigger BG Ghouls":
				if(!ClientPrefs.data.lowQuality)
				{
					//bgGhouls.dance(true);
					bgGhouls.animation.play('bgFreak');
					bgGhouls.visible = true;
				}
		}
	}
	override function eventPushed(event:objects.Note.EventNote)
	{
		// used for preloading assets used on events
		switch(event.event)
		{
			case "Trigger BG Ghouls":
				if(!ClientPrefs.data.lowQuality)
				{
					//bgGhouls = new BGSprite('weeb/bgGhouls', posX, posY, 0.9, 0.9, ['BG freaks glitch instance'], false);

					bgGhouls = new FunkinSprite(-100, 190, null);
					bgGhouls.frames = Paths.getSparrowAtlas("weeb/animatedEvilSchool");
					bgGhouls.scrollFactor.set(0.9, 0.9);
					bgGhouls.animation.addByPrefix('bgFreak', 'BG freaks glitch instance', 24, true);
					bgGhouls.animation.play('bgFreak');

					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * PlayState.daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					bgGhouls.animation.finishCallback = function(name:String)
					{
						if(name == 'BG freaks glitch instance')
							bgGhouls.visible = false;
					}
					addBehindGF(bgGhouls);

					if (ClientPrefs.data.perfectPixel == "inGame") {
						bgGhouls.pixelPerfectPosition = true;
						bgGhouls.pixelPerfectRender = true;
					}
				}
		}
	}

	var doof:DialogueBox = null;
	function initDoof()
	{
		var file:String = Paths.txt('$songName/${songName}Dialogue_${ClientPrefs.data.language}'); //Checks for vanilla/Senpai dialogue
		#if MODS_ALLOWED
		if (!FileSystem.exists(file))
		#else
		if (!OpenFlAssets.exists(file))
		#end
		{
			file = Paths.txt('$songName/${songName}Dialogue');
		}

		#if MODS_ALLOWED
		if (!FileSystem.exists(file))
		#else
		if (!OpenFlAssets.exists(file))
		#end
		{
			startCountdown();
			return;
		}

		doof = new DialogueBox(false, CoolUtil.coolTextFile(file));
		doof.cameras = [camHUD];
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = PlayState.instance.startNextDialogue;
		doof.skipDialogueThing = PlayState.instance.skipDialogue;
	}
	
	function schoolIntro():Void
	{
		inCutscene = true;
		var red:FunkinSprite = new FunkinSprite(-100, -100, null);
		red.makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();
		PlayState.instance.variables.get("stageVariables").set("red", red);
		add(red);

		var senpaiEvil:FunkinSprite = new FunkinSprite(0, 0, null);
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;
		camHUD.visible = false;
		PlayState.instance.variables.get("stageVariables").set("senpaiEvil", senpaiEvil);

		new FlxTimer().start(2.1, function(tmr:FlxTimer)
		{
			if (doof != null)
			{
				add(senpaiEvil);
				senpaiEvil.alpha = 0;
				new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
				{
					senpaiEvil.alpha += 0.15;
					if (senpaiEvil.alpha < 1)
					{
						swagTimer.reset();
					}
					else
					{
						senpaiEvil.animation.play('idle');
						FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
						{
							remove(senpaiEvil);
							senpaiEvil.destroy();
							remove(red);
							red.destroy();
							FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
							{
								add(doof);
								camHUD.visible = true;
							}, true);
						});
						new FlxTimer().start(3.2, function(deadTime:FlxTimer)
						{
							FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
						});
					}
				});
			}
		});
	}
}