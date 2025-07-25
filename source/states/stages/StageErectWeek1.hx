package states.stages;

import states.stages.objects.*;
import objects.Character;

import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;

import shaders.AdjustColorShader;

class StageErectWeek1 extends BaseStage
{

	var colorShaderBf:AdjustColorShader;
	var colorShaderDad:AdjustColorShader;
	var colorShaderGf:AdjustColorShader;
	var lights:BGSprite;
	var lightAbove:BGSprite;

	var crowd:BGSprite;

	override function create()
	{
		if (!PlayState.instance.variables.exists("stageVariables")){
			PlayState.instance.variables.set("stageVariables", new Map<String, FlxSprite>());
		}

		var stageVars = PlayState.instance.variables.get("stageVariables");

		var backDark:BGSprite = new BGSprite('erect/backDark', 729, -170, 1, 1);
		stageVars.set("backDark", backDark);
		add(backDark);

		crowd = new BGSprite('erect/crowd', 560, 290, 0.8, 0.8, ['Symbol 2 instance 1'], true);
		crowd.animation.curAnim.frameRate = 12;
		stageVars.set("crowd", crowd);
		add(crowd);

		var brightLightSmall:BGSprite = new BGSprite('erect/brightLightSmall', 967, -103, 1.2, 1.2);
		brightLightSmall.blend = ADD;
		stageVars.set("brightLightSmall", brightLightSmall);
		add(brightLightSmall);

		var bg:BGSprite = new BGSprite('erect/bg', -603, -187, 1, 1);
		stageVars.set("bg", bg);
		add(bg);

		var server:BGSprite = new BGSprite('erect/server', -361, 205, 1, 1);
		stageVars.set("server", server);
		add(server);

		var lightgreen:BGSprite = new BGSprite('erect/lightgreen', -171, 242, 1, 1);
		lightgreen.blend = ADD;
		stageVars.set("lightgreen", lightgreen);
		add(lightgreen);

		var lightred:BGSprite = new BGSprite('erect/lightred', -101, 560, 1, 1);
		lightred.blend = ADD;
		stageVars.set("lightred", lightred);
		add(lightred);

		var orangeLight:BGSprite = new BGSprite('erect/orangeLight', 189, -195, 1, 1);
		orangeLight.blend = ADD;
		stageVars.set("orangeLight", orangeLight);
		add(orangeLight);

		setDefaultGF('gf');

		lights = new BGSprite('erect/lights', -601, -147, 1.2, 1.2);
		stageVars.set("lights", lights);

		lightAbove = new BGSprite('erect/lightAbove', 804, -117, 1, 1);
		lightAbove.blend = ADD;
		stageVars.set("lightAbove", lightAbove);
	}

	override function createPost(){
		var stageVars = PlayState.instance.variables.get("stageVariables");

		add(lights);
		add(lightAbove);

		if(ClientPrefs.data.shaders) setupCharactersShaders();
	}

	function setupCharactersShaders(){
		if (PlayState.instance.curStage.toLowerCase() != "stageerect") 
			return;

		var colorShaderBf = new AdjustColorShader();
		var colorShaderDad = new AdjustColorShader();
		var colorShaderGf = new AdjustColorShader();

		colorShaderBf.brightness = -23;
		colorShaderBf.hue = 12;
		colorShaderBf.contrast = 7;
		colorShaderBf.saturation = 0;

    	colorShaderGf.brightness = -30;
   		colorShaderGf.hue = -9;
    	colorShaderGf.contrast = -4;
		colorShaderGf.saturation = 0;

    	colorShaderDad.brightness = -33;
    	colorShaderDad.hue = -32;
    	colorShaderDad.contrast = -23;
		colorShaderDad.saturation = 0;

		// this is not final version yet!
		var bfShaders = [];
		var dadShaders = [];
		var gfShaders = [];

		boyfriend.shader = colorShaderBf.shader;
		dad.shader = colorShaderDad.shader;
		gf.shader = colorShaderGf.shader;
	}

	override public function destroy():Void {
		// this is not final version yet!

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
}