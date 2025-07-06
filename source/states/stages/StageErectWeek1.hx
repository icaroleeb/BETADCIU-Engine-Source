package states.stages;

import states.stages.objects.*;
import objects.Character;

import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;

import shaders.AdjustColorShader;

class StageErectWeek1 extends BaseStage
{
	var backDark:BGSprite;
	var crowd:BGSprite;
	var brightLightSmall:BGSprite;
	var bg:BGSprite;
	var server:BGSprite;
	var lightgreen:BGSprite;
	var lightred:BGSprite;
	var lights:BGSprite;
	var orangeLight:BGSprite;
	var lightAbove:BGSprite;
	
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

		//if(ClientPrefs.data.shaders) setupShaders();
	}

	override function createPost()
	{
		var lights:BGSprite = new BGSprite('erect/lights', -601, -147, 1.2, 1.2);
		stageVars.set("lights", lights);
		add(lights);

		var lightAbove:BGSprite = new BGSprite('erect/lightAbove', 804, -117, 1, 1);
		lightAbove.blend = ADD;
		stageVars.set("lightAbove", lightAbove);
		add(lightAbove);
	}

	function setupShaders(){
		if (PlayState.instance.curStage.toLowerCase() != "stageerect") 
			return;

		//gf.shader = makeCoolShader(-9,0,-30,-4);
		//dad.shader = makeCoolShader(-32,0,-33,-23);
		//boyfriend.shader = makeCoolShader(12,0,-23,7);
	}

	/*/
	function makeCoolShader(hue:Float,sat:Float,bright:Float,contrast:Float) {
        var coolShader = new AdjustColorShader();
        coolShader.hue = hue;
        coolShader.saturation = sat;
        coolShader.brightness = bright;
        coolShader.contrast = contrast;

		var shaders = [];

        return coolShader;
    }
	/*/

	override public function destroy():Void {
		if(lights != null){
			remove(lights);
		}

		if(lightAbove != null){
			remove(lightAbove);
		}

		super.destroy();
	}
}