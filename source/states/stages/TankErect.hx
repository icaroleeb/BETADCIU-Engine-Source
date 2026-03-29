package states.stages;

import states.stages.objects.*;
import shaders.DropShadowShader;

class TankErect extends BaseStage
{
	var sniper:BGSprite;
	var guy:BGSprite;
	
	override function create()
	{
		if (!PlayState.instance.variables.exists("stageVariables")){
			PlayState.instance.variables.set("stageVariables", new Map<String, FlxSprite>());
		}
		var stageVars = PlayState.instance.variables.get("stageVariables");

		var bg:BGSprite = new BGSprite('erect/bg', -985, -805);
		bg.scale.set(1.15, 1.15);
		bg.updateHitbox();
		stageVars.set("bg", bg);
		add(bg);

		sniper = new BGSprite('erect/sniper', -127, 349, 1, 1, ['Tankmanidlebaked instance 1', 'tanksippingBaked instance 1'], false);
		sniper.scale.set(1.15, 1.15);
		sniper.updateHitbox();
		stageVars.set("sniper", sniper);
		add(sniper);

		guy = new BGSprite('erect/guy', 1398, 407, 1, 1, ['BLTank2 instance 1'], false);
		guy.scale.set(1.15, 1.15);
		guy.updateHitbox();
		stageVars.set("guy", guy);
		add(guy);
	}

	override function createPost()
	{
		var tankBricks:BGSprite = new BGSprite('erect/bricksGround', 465, 760);
		tankBricks.scale.set(1.15, 1.15);
		tankBricks.updateHitbox();
		PlayState.instance.variables.get("stageVariables").set("tankBricks", tankBricks);
		add(tankBricks);

		tankBricks.setPosition(445, 774);

		if (ClientPrefs.data.shaders) {
			applyCharacterShader("boyfriend");
			applyCharacterShader("gf");
			applyCharacterShader("dad");

			for (value in modchartCharacters.keys()) // apply for the lua characters too
			{
				// var daLuaChars:Character = modchartCharacters.get(value);
				applyCharacterShader(value);
			}
		}
	}

	function applyCharacterShader(char:String)
	{
		var character:objects.Character = psychlua.LuaUtils.getObjectDirectly(char);

		var charRim = new DropShadowShader();
		charRim.setAdjustColor(-46, -38, -25, -20);
		charRim.color = 0xFFDFEF3C;
		character.shader = charRim;
		charRim.attachedSprite = character;

		if (character.isPlayer)
		{
			charRim.angle = 90;
		}
		else if (character.isSpeakerChar)
		{
			charRim.angle = 90;
			charRim.maskThreshold = 0.4;
		}
		else
		{
			if (character.curCharacter == "tankman")
				charRim.angle = 135;
			else
				charRim.angle = 25;

			charRim.threshold = 0.3;
		}

		var altMaskPath:Dynamic = Paths.image('erect/masks/' + character.curCharacter + '_mask', "week7");

		#if MODS_ALLOWED
		if (FileSystem.exists(altMaskPath))
		#else
		if (OpenFlAssets.exists(altMaskPath))
		#end
		{
			charRim.loadAltMask(altMaskPath);
			charRim.useAltMask = true;
		}

		character.animation.callback = function(animName:String, frameNumber:Int, frameIndex:Int)
		{
			charRim.updateFrameInfo(character.frame);
		}
	}

	override function countdownTick(count:Countdown, num:Int)
	{
		if (sniper != null) 
			sniper.animation.play('Tankmanidlebaked instance 1', true);

		if (guy != null) 
			guy.animation.play('BLTank2 instance 1', true);
	}

	var sniperSpecialAnim:Bool = true;
	var sniperSipTimer:FlxTimer = null;

	override function beatHit()
	{
		if (curBeat % (gfSpeed * speedBaseMod) == 0)
		{
			if (sniper != null && sniperSpecialAnim) 
				sniper.animation.play('Tankmanidlebaked instance 1', true);

			if (guy != null) 
				guy.animation.play('BLTank2 instance 1', true);
		}

		if (sniper != null && FlxG.random.bool(2)){
			sniper.animation.play('tanksippingBaked instance 1', true);
			sniperSpecialAnim = false;
			
			new FlxTimer().start(sniper.animation.curAnim.numFrames / 24, function(tmr:FlxTimer)
			{
				sniperSpecialAnim = true;
			});
		}
	}

	override function characterChangePost(charExist:String, charNew:String) {
		if (ClientPrefs.data.shaders) applyCharacterShader(charExist);
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