package states.stages;

import states.stages.objects.*;
import substates.GameOverSubstate;
import cutscenes.DialogueBox;

import backend.FunkinSprite;

import openfl.utils.Assets as OpenFlAssets;

class School extends BaseStage
{
	var bgGirls:BackgroundGirls;
	var pixelPerfectEffectArray:Array<FlxSprite> = []; // long array name lol

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

		//var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
		var bgSky:FunkinSprite = FunkinSprite.create(0, 0, 'weeb/weebSky');
		bgSky.scrollFactor.set(0.1, 0.1);
		stageVars.set("bgSky", bgSky);
		add(bgSky);
		bgSky.antialiasing = false;
		pixelPerfectEffectArray.push(bgSky);

		var repositionShit = -200;

		//var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
		var bgSchool:FunkinSprite = FunkinSprite.create(repositionShit, 0, 'weeb/weebSchool');
		bgSchool.scrollFactor.set(0.6, 0.90);
		stageVars.set("bgSchool", bgSchool);
		add(bgSchool);
		bgSchool.antialiasing = false;
		pixelPerfectEffectArray.push(bgSchool);

		//var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
		var bgStreet:FunkinSprite = FunkinSprite.create(repositionShit, 0, 'weeb/weebStreet');
		bgStreet.scrollFactor.set(0.95, 0.95);
		stageVars.set("bgStreet", bgStreet);
		add(bgStreet);
		bgStreet.antialiasing = false;
		pixelPerfectEffectArray.push(bgStreet);

		var widShit = Std.int(bgSky.width * PlayState.daPixelZoom);
		if(!ClientPrefs.data.lowQuality) {
			//var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
			var fgTrees:FunkinSprite = FunkinSprite.create(repositionShit + 170, 130, 'weeb/weebTreesBack');
			fgTrees.scrollFactor.set(0.9, 0.9);
			fgTrees.setGraphicSize(Std.int(widShit * 0.8));
			fgTrees.updateHitbox();
			stageVars.set("fgTrees", fgTrees);
			add(fgTrees);
			fgTrees.antialiasing = false;
			pixelPerfectEffectArray.push(fgTrees);
		}

		//var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
		var bgTrees:FunkinSprite = FunkinSprite.create(repositionShit - 380, -800, null);
		bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
		bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
		bgTrees.animation.play('treeLoop');
		bgTrees.scrollFactor.set(0.85, 0.85);
		stageVars.set("bgTrees", bgTrees);
		add(bgTrees);
		bgTrees.antialiasing = false;
		pixelPerfectEffectArray.push(bgTrees);

		if(!ClientPrefs.data.lowQuality) {
			//var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
			var treeLeaves:FunkinSprite = FunkinSprite.create(repositionShit, -40, null);
			treeLeaves.frames = Paths.getSparrowAtlas('weeb/petals');
			treeLeaves.scrollFactor.set(0.85, 0.85);
			treeLeaves.animation.addByPrefix('PETALS ALL', 'PETALS ALL', 24, true);
			treeLeaves.animation.play('PETALS ALL');
			treeLeaves.setGraphicSize(widShit);
			treeLeaves.updateHitbox();
			stageVars.set("treeLeaves", treeLeaves);
			add(treeLeaves);
			treeLeaves.antialiasing = false;
			pixelPerfectEffectArray.push(treeLeaves);
		}

		bgSky.setGraphicSize(widShit);
		bgSchool.setGraphicSize(widShit);
		bgStreet.setGraphicSize(widShit);
		bgTrees.setGraphicSize(Std.int(widShit * 1.4));

		bgSky.updateHitbox();
		bgSchool.updateHitbox();
		bgStreet.updateHitbox();
		bgTrees.updateHitbox();

		if(!ClientPrefs.data.lowQuality) {
			bgGirls = new BackgroundGirls(-100, 190);
			bgGirls.scrollFactor.set(0.9, 0.9);
			stageVars.set("bgGirls", bgGirls);
			add(bgGirls);
			pixelPerfectEffectArray.push(bgGirls);
			
		}
		setDefaultGF('gf-pixel');

		if (ClientPrefs.data.perfectPixel == "inGame") {
			for (sprite in pixelPerfectEffectArray)
			{
				sprite.pixelPerfectPosition = true;
				sprite.pixelPerfectRender = true;
			}
		}

		switch (songName)
		{
			case 'senpai':
				FlxG.sound.playMusic(Paths.music('Lunchbox'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			case 'roses':
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
		}
		if(isStoryMode && !seenCutscene)
		{
			if(songName == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
			initDoof();
			setStartCallback(schoolIntro);
		}
	}

	override function beatHit()
	{
		if(bgGirls != null) bgGirls.dance();
	}

	// For events
	override function eventCalled(eventName:String, value1:String, value2:String, value3:String, flValue1:Null<Float>, flValue2:Null<Float>, flValue3:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "BG Freaks Expression":
				if(bgGirls != null) bgGirls.swapDanceType();
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
		
		//var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		var black:FunkinSprite = FunkinSprite.create(-100, -100, null);
		black.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		PlayState.instance.variables.get("stageVariables").set("black", black);
		if(songName == 'senpai') add(black);

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha <= 0)
			{
				if (doof != null)
					add(doof);
				else
					startCountdown();

				remove(black);
				black.destroy();
			}
			else tmr.reset(0.3);
		});
	}
}