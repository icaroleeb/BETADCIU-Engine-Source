package psychlua;

import openfl.utils.Assets;
import psychlua.LuaUtils;

import objects.FunkinSprite;

#if (LUA_ALLOWED)
class FlxAnimateFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		Lua_helper.add_callback(lua, "makeFlxAnimateSprite", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?loadFolder:String = null) {
			tag = tag.replace('.', '');
			var lastSprite = MusicBeatState.getVariables().get(tag);
			if(lastSprite != null)
			{
				lastSprite.kill();
				PlayState.instance.remove(lastSprite);
				lastSprite.destroy();
			}

			// var mySprite:ModchartAnimateSprite = new ModchartAnimateSprite(x, y);
			var mySprite:FunkinSprite = FunkinSprite.create(x, y, null);

			if(loadFolder != null && loadFolder.length > 0)
			{
				LuaUtils.loadFrames(mySprite, loadFolder, 'animateatlas');
			}

			var variables = MusicBeatState.getVariables();
			variables.set(tag, mySprite);

			switch(funk.scriptType.toLowerCase()){
				case "stage":
					if (!variables.exists("stageVariables")){
						variables.set("stageVariables", new Map<String, FlxSprite>());
					}
		
					var stageVars = variables.get("stageVariables");
					stageVars.set(tag, mySprite);
				case "stagecamera":
					if (!variables.exists("stageCameraVariables")){
						variables.set("stageCameraVariables", new Map<String, FlxSprite>());
					}

					var stageVars = variables.get("stageCameraVariables");
					stageVars.set(tag, mySprite);
			}
			
			mySprite.active = true;
		});

		Lua_helper.add_callback(lua, "loadAnimateAtlas", function(tag:String, loadFolder:String) {
			var spr:ModchartAnimateSprite = MusicBeatState.getVariables().get(tag);
			if(loadFolder != null && loadFolder.length > 0)
			{
				LuaUtils.loadFrames(spr, loadFolder, 'animateatlas');
			}
		});
		
		Lua_helper.add_callback(lua, "addAnimationBySymbol", function(tag:String, name:String, symbol:String, ?framerate:Float = 24, ?loop:Bool = false)
		{
			var obj:ModchartAnimateSprite = cast MusicBeatState.getVariables().get(tag);
			if(obj == null) return false;

			obj.anim.addBySymbol(name, symbol, framerate, loop);
			// if(obj.anim.curSymbol == null)
			// {
			// 	var obj2:ModchartAnimateSprite = cast (obj, ModchartAnimateSprite);
			// 	if(obj2 != null) obj2.playAnim(name, true); //is ModchartAnimateSprite
			// 	else obj.anim.play(name, true);
			// }
			return true;
		});

		Lua_helper.add_callback(lua, "addAnimationBySymbolIndices", function(tag:String, name:String, symbol:String, ?indices:Any = null, ?framerate:Float = 24, ?loop:Bool = false)
		{
			var obj:ModchartAnimateSprite = cast MusicBeatState.getVariables().get(tag);
			if(obj == null) return false;

			if(indices == null)
				indices = [0];
			else if(Std.isOfType(indices, String))
			{
				var strIndices:Array<String> = cast (indices, String).trim().split(',');
				var myIndices:Array<Int> = [];
				for (i in 0...strIndices.length) {
					myIndices.push(Std.parseInt(strIndices[i]));
				}
				indices = myIndices;
			}

			obj.anim.addBySymbolIndices(name, symbol, indices, framerate, loop);
			// if(obj.anim.curSymbol == null)
			// {
			// 	var obj2:ModchartAnimateSprite = cast (obj, ModchartAnimateSprite);
			// 	if(obj2 != null) obj2.playAnim(name, true); //is ModchartAnimateSprite
			// 	else obj.anim.play(name, true);
			// }
			return true;
		});
	}
}
#end