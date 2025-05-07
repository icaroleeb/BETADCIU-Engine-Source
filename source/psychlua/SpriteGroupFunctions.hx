package psychlua;

import flixel.group.*;
import flixel.FlxBasic;

//Ryiuu here -- props to glowsoony he helped A LOT with this
class SpriteGroupFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		Lua_helper.add_callback(lua, "makeLuaSpriteGroup", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var group:FlxSpriteGroup = new FlxSpriteGroup(x, y, maxSize);

			var variables = MusicBeatState.getVariables();
			variables.set(tag, group);
		});

		Lua_helper.add_callback(lua, 'groupInsertSprite', function(tag:String, obj:String, index:Int, pos:Int, removeFromGroup:Bool = false) {
			var group:FlxSpriteGroup = LuaUtils.getObjectDirectly(tag);

			var real = cast(LuaUtils.getObjectDirectly(obj), FlxSprite);
					if(real!=null){
				if (removeFromGroup) group.remove(real, true);
				group.insert(pos, real);  
						return true;
					}

			var killMe:Array<String> = obj.split('.');
					var object:FlxBasic = LuaUtils.getObjectDirectly(killMe[0]);
					if(killMe.length > 1) {
						object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
					}

					if(object != null) {
				var convertedSprite:FlxSprite = cast(object, FlxSprite);
				if (removeFromGroup) group.remove(convertedSprite, true);
				group.insert(pos, convertedSprite);  
						return true;
					}
			return false;
		});

		Lua_helper.add_callback(lua, 'groupRemoveSprite', function(tag:String, obj:String, splice:Bool = false) {
			var group:FlxSpriteGroup = LuaUtils.getObjectDirectly(tag);

			var real = cast(LuaUtils.getObjectDirectly(obj), FlxSprite);
					if(real!=null){
			if (group != null) group.remove(real, splice);
						return true;
					}

			var killMe:Array<String> = obj.split('.');
					var object:FlxBasic = LuaUtils.getObjectDirectly(killMe[0]);
					if(killMe.length > 1) {
						object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
					}
		
					if(object != null) {
			var convertedSprite:FlxSprite = cast(object, FlxSprite);
			if (group != null) group.remove(convertedSprite, splice);
						return true;
					}
			return false;
		});

		Lua_helper.add_callback(lua, 'groupAddSprite', function(tag:String, obj:String) {
			var group:FlxSpriteGroup = LuaUtils.getObjectDirectly(tag);

			var real = cast(LuaUtils.getObjectDirectly(obj), FlxSprite);
					if(real!=null){
			if (group != null) group.add(real);
						return true;
					} 

			var killMe:Array<String> = obj.split('.');
					var object:FlxBasic = LuaUtils.getObjectDirectly(killMe[0]);
					if(killMe.length > 1) {
						object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
					}
		
					if(object != null) {
			var convertedSprite:FlxSprite = cast(object, FlxSprite);
			if (group != null) group.add(convertedSprite);
						return true;
					}
			return false;
		});

		Lua_helper.add_callback(lua, 'setGroupCameras', function(tag:String, cams:Array<String>) {
			var group:FlxSpriteGroup = LuaUtils.getObjectDirectly(tag);
			var cameras:Array<FlxCamera> = [];
			for (i in 0...cams.length)
			{
			cameras.push(LuaUtils.cameraFromString(cams[i]));
			}
			if (group != null) group.cameras = cameras;
		});

		Lua_helper.add_callback(lua, 'setGroupCamera', function(tag:String, cam:String) {
			var group:FlxSpriteGroup = LuaUtils.getObjectDirectly(tag);
			if (group != null) group.camera = LuaUtils.cameraFromString(cam);
		});
  	}
	
  	static function changeSpriteClass(tag:Dynamic):FlxSprite {
		return tag;
	}
}
