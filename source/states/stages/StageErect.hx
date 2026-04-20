package states.stages;

import states.stages.objects.*;
import objects.Character;
import psychlua.LuaUtils;
import shaders.AdjustColorShader;

class StageErect extends BaseStage
{
	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleFog:DadBattleFog;

	public static var inGameplay:Bool = true;

	var colorShaderBf:AdjustColorShader;
	var colorShaderDad:AdjustColorShader;
	var colorShaderGf:AdjustColorShader;

	override function create()
	{
		var stageVars:Map<String, FlxSprite> = new Map<String, FlxSprite>(); // offset menu fix.

		if(FlxG.state is options.NoteOffsetState){ 
			inGameplay = false;
		}
		
		if (inGameplay){
			if (!PlayState.instance.variables.exists("stageVariables")){
				PlayState.instance.variables.set("stageVariables", new Map<String, FlxSprite>());
			}
			stageVars = PlayState.instance.variables.get("stageVariables");
		}

		var solid:FlxSprite = new FlxSprite(-500, -1000).makeGraphic(2400, 2000, 0xFF222026);
		solid.scrollFactor.set();
		if (inGameplay) stageVars.set("solid", solid);
		add(solid);

		var crowd:BGSprite = new BGSprite('erect/crowd', 682, 290, 0.8, 0.8, ['idle0'], true);
		if (crowd.animation.curAnim != null) crowd.animation.curAnim.frameRate = 12;
		if (inGameplay) stageVars.set("crowd", crowd);
		add(crowd);

		var brightLightSmall:BGSprite = new BGSprite('erect/brightLightSmall', 967, -103, 1.2, 1.2);
		brightLightSmall.blend = ADD;
		if (inGameplay) stageVars.set("brightLightSmall", brightLightSmall);
		add(brightLightSmall);

		var bg:BGSprite = new BGSprite('erect/bg', -765, -247, 1, 1);
		if (inGameplay) stageVars.set("bg", bg);
		add(bg);

		var server:BGSprite = new BGSprite('erect/server', -991, 205, 1, 1);
		if (inGameplay) stageVars.set("server", server);
		add(server);

		var lights:BGSprite = new BGSprite('erect/lights', 189, -500, 1.2, 1.2);
		if (inGameplay) stageVars.set("lights", lights);
		add(lights);

		var orangeLight:BGSprite = new BGSprite('erect/orangeLight', 189, -500, 1, 1);
		orangeLight.scale.set(1, 1700);
		orangeLight.updateHitbox();
		orangeLight.blend = ADD;
		if (inGameplay) stageVars.set("orangeLight", orangeLight);
		add(orangeLight);

		var lightgreen:BGSprite = new BGSprite('erect/lightgreen', -171, 242, 1, 1);
		lightgreen.blend = ADD;
		if (inGameplay) stageVars.set("lightgreen", lightgreen);
		add(lightgreen);

		var lightred:BGSprite = new BGSprite('erect/lightred', -101, 560, 1, 1);
		lightred.blend = ADD;
		if (inGameplay) stageVars.set("lightred", lightred);
		add(lightred);
	}

	override function createPost()
	{
		var lights:BGSprite = new BGSprite('erect/lights', -847, -245, 1.2, 1.2);
		if (inGameplay) PlayState.instance.variables.get("stageVariables").set("lights", lights);
		add(lights);

		var lightAbove:BGSprite = new BGSprite('erect/lightAbove', 804, -117, 1, 1);
		lightAbove.blend = ADD;
		if (inGameplay) PlayState.instance.variables.get("stageVariables").set("lightAbove", lightAbove);
		add(lightAbove);

		if(ClientPrefs.data.shaders){
			applyCharacterShader("boyfriend");
			applyCharacterShader("dad");
			if (gf != null) applyCharacterShader("gf");

			for (value in modchartCharacters.keys()) // apply for the lua characters too
			{
				// var daLuaChars:Character = modchartCharacters.get(value);
				applyCharacterShader(value);
			}
		}
	}

	function applyCharacterShader(char:String)
	{
		var character:Character = LuaUtils.getObjectDirectly(char);
		var colorShader = new AdjustColorShader();

		if (character != null) {
			if(character.isPlayer) setShaderVals(colorShader, -23, 12, 7, 0);
			else if(character.isSpeakerChar) setShaderVals(colorShader, -30, -9, -4, 0);
			else setShaderVals(colorShader, -33, -32, -23, 0);
		}

		character.shader = colorShader.shader;
	}

	function setShaderVals(shader:AdjustColorShader, b:Float, h:Float, c:Float, s:Float) {
		shader.brightness = b;
		shader.hue = h;
		shader.contrast = c;
		shader.saturation = s;
	}

	override function eventPushed(event:objects.Note.EventNote)
	{
		switch(event.event)
		{
			case "Dadbattle Spotlight":
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				if (inGameplay) PlayState.instance.variables.get("stageVariables").set("dadbattleBlack", dadbattleBlack);
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;
				if (inGameplay) PlayState.instance.variables.get("stageVariables").set("dadbattleLight", dadbattleLight);
				add(dadbattleLight);

				dadbattleFog = new DadBattleFog();
				dadbattleFog.visible = false;
				if (inGameplay) PlayState.instance.variables.get("stageVariables").set("dadbattleFog", dadbattleFog);
				add(dadbattleFog);
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, value3:String, flValue1:Null<Float>, flValue2:Null<Float>, flValue3:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "Dadbattle Spotlight":
				if(flValue1 == null) flValue1 = 0;
				var val:Int = Math.round(flValue1);

				switch(val)
				{
					case 1, 2, 3: //enable and target dad
						if(val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleFog.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if(val > 2) who = boyfriend;
						//2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);
						FlxTween.tween(dadbattleFog, {alpha: 0.7}, 1.5, {ease: FlxEase.quadInOut});

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleFog, {alpha: 0}, 0.7, {onComplete: function(twn:FlxTween) dadbattleFog.visible = false});
				}
		}
	}

	override function characterChangePost(charExist:String, charNew:String) {
		if (ClientPrefs.data.shaders)
		{
			if (charExist == "bf") 
				charExist = "boyfriend";
			else if (charExist == "girlfriend")
				charExist = "gf";
			else if (charExist == "opponent")
				charExist = "dad";

			applyCharacterShader(charExist);
		}
	}

	override public function destroy():Void {
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