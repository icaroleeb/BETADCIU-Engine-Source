package states.stages;

import states.stages.objects.*;
import shaders.DropShadowShader;

class TankErect extends BaseStage
{
	var sniper:BGSprite;
	var guy:BGSprite;

	var bfRim:DropShadowShader;
	var dadRim:DropShadowShader;
	var gfRim:DropShadowShader;

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

		if (ClientPrefs.data.shaders) 
			setupCharShaders();
	}

	function setupCharShaders()
	{
		bfRim = new DropShadowShader();
		bfRim.setAdjustColor(-46, -38, -25, -20);
		bfRim.color = 0xFFDFEF3C;

		dadRim = new DropShadowShader();
		dadRim.setAdjustColor(-46, -38, -25, -20);
		dadRim.color = 0xFFDFEF3C;

		gfRim = new DropShadowShader();
		gfRim.setAdjustColor(-46, -38, -25, -20);
		gfRim.color = 0xFFDFEF3C;

		dad.shader = dadRim;
		gf.shader = gfRim;
		boyfriend.shader = bfRim;

		bfRim.attachedSprite = boyfriend;
		gfRim.attachedSprite = gf;
		dadRim.attachedSprite = dad;

		// bf
		bfRim.angle = 90;

		// gf
		gfRim.angle = 90;
		gfRim.maskThreshold = 0.4;
        gfRim.useAltMask = true;

		// dad
		if (dad.curCharacter == "tankman")
			dadRim.angle = 135;
		else
			dadRim.angle = 25;

        dadRim.threshold = 0.3;

		boyfriend.animation.callback = function(anim, frame, index)
		{
			bfRim.updateFrameInfo(boyfriend.frame);
		};

		dad.animation.callback = function(anim, frame, index)
		{
			dadRim.updateFrameInfo(dad.frame);
		};

		gf.animation.callback = function(anim, frame, index)
		{
			gfRim.updateFrameInfo(gf.frame);
		};
	}

	override function beatHit()
	{
		if (sniper != null) 
			sniper.animation.play('Tankmanidlebaked instance 1');

		if (guy != null) 
			guy.animation.play('BLTank2 instance 1');

		if (FlxG.random.bool(2))
			sniper.animation.play('tanksippingBaked instance 1');
	}

	override function eventCalled(eventName:String, value1:String, value2:String, value3:String, flValue1:Null<Float>, flValue2:Null<Float>, flValue3:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "Change Character":
				if (ClientPrefs.data.shaders){
					var character:objects.Character = psychlua.LuaUtils.getObjectDirectly(value1);

					/*
					if (character != null && character.isSpeakerChar){
						character.shader = gfRim;
						return;
					}
					*/

					if (character != null){
						if(character.isPlayer)
							character.shader = bfRim;
						else 
							character.shader = dadRim;
					}
				}
		}
	}
}