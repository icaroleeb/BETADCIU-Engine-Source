package psychlua;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;

#if (flixel >= "6.0.0")
import flixel.addons.system.macros.FlxRuntimeShaderMacro;
#end

#end

import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import shaders.ErrorHandledShader;
import sys.io.File;

import options.ModpackMakerState.ModpackAssetRegistry;

class ShaderFunctions
{
	// Found these in FlxGraphicsShader for some reason???
	@:glFragmentHeader("varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;

		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;
		uniform sampler2D bitmap;

		uniform bool hasTransform;  // TODO: Is this still needed? Apparently, yes!
		uniform bool hasColorTransform;
		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
		{
			vec4 color = texture2D(bitmap, coord);
			if (!(hasTransform || openfl_HasColorTransform))
				return color;
			
			if (color.a == 0.0)
				return vec4(0.0, 0.0, 0.0, 0.0);
			
			if (openfl_HasColorTransform || hasColorTransform)
			{
				color = vec4 (color.rgb / color.a, color.a);
				vec4 mult = vec4 (openfl_ColorMultiplierv.rgb, 1.0);
				color = clamp (openfl_ColorOffsetv + (color * mult), 0.0, 1.0);
				
				if (color.a == 0.0)
					return vec4 (0.0, 0.0, 0.0, 0.0);
				
				return vec4 (color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
			}
			
			return color * openfl_Alphav;
		}
	", true)
	@:glFragmentBody("
		gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
	", true)
	
	public function new() {
		
	}

	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		// shader shit
		funk.addLocalCallback("initLuaShader", function(name:String) {
			if(!ClientPrefs.data.shaders) return false;

			if (funk.scriptType == "modpack"){
				ModpackAssetRegistry.instance.addAsset("shaders", name);
				return true;
			}
			#if (!flash && MODS_ALLOWED && sys)
			return initLuaShader(name);
			#else
			FunkinLua.luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		
		funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String, ?keepOtherShaders:Bool = true) {
			if(!ClientPrefs.data.shaders) return false;
			
			if (funk.scriptType == "modpack"){
				ModpackAssetRegistry.instance.addAsset("shaders", shader);
				return true;
			}

			#if (!flash && sys)
			if(!PlayState.instance.runtimeShaders.exists(shader) && !initLuaShader(shader))
			{
				FunkinLua.luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}
	
			var split:Array<String> = obj.split('.');
			var leObj:Dynamic = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}
	
			if(leObj != null) {
				var arr:Array<String> = PlayState.instance.runtimeShaders.get(shader);
				var daShader:ErrorHandledRuntimeShader = new ErrorHandledRuntimeShader(shader, arr[0], arr[1]); 

				if (Std.isOfType(leObj, FlxCamera)){
					var daFilters = (leObj.filters != null && keepOtherShaders) ? leObj.filters : [];
					daFilters.push(new ShaderFilter(daShader));
					leObj.filters = daFilters;
				}
				else{
					var daObj:FlxSprite = leObj;
					daObj.shader = daShader;
				}
			
				return true;
			}
			#else
			FunkinLua.luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

		Lua_helper.add_callback(lua, "removeSpriteShader", function(obj:String, ?shader:String = "") {
			var split:Array<String> = obj.split('.');
			var leObj:Dynamic = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null) {
				if (Std.isOfType(leObj, FlxCamera)) {
					removeCameraShader(leObj, shader); // Left support for this in
				} else {
					leObj.shader = null;
				}
			}
			return false;
		});

		// Dedicated callbacks for cameras now
		funk.addLocalCallback("setCameraShader", function(obj:String, shader:String, ?keepOtherShaders:Bool = true) {
			if(!ClientPrefs.data.shaders) return false;

			#if (!flash && sys)
			if(!PlayState.instance.runtimeShaders.exists(shader) && !initLuaShader(shader))
			{
				FunkinLua.luaTrace('setCameraShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}
	
			var split:Array<String> = obj.split('.');
			var leObj:FlxCamera = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}
	
			if(leObj != null) {
				var arr:Array<String> = PlayState.instance.runtimeShaders.get(shader);
				var daShader:ErrorHandledRuntimeShader = new ErrorHandledRuntimeShader(shader, arr[0], arr[1]); 
				var daFilters = (keepOtherShaders && leObj.filters != null) ? leObj.filters : [];
				daFilters.push(new ShaderFilter(daShader));
				leObj.filters = daFilters;

				return true;
			}
			#else
			FunkinLua.luaTrace("setCameraShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

		Lua_helper.add_callback(lua, "removeCameraShader", function(obj:String, ?shader:String = "") {
			var split:Array<String> = obj.split('.');
			var leObj:FlxCamera = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1) {
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (leObj != null) {
				removeCameraShader(leObj, shader);
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getShaderBool", function(obj:String, prop:String, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBool(prop);
			#else
			FunkinLua.luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderBoolArray", function(obj:String, prop:String, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBoolArray(prop);
			#else
			FunkinLua.luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderInt", function(obj:String, prop:String, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getInt(prop);
			#else
			FunkinLua.luaTrace("getShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderIntArray", function(obj:String, prop:String, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getIntArray(prop);
			#else
			FunkinLua.luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloat", function(obj:String, prop:String, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloat(prop);
			#else
			FunkinLua.luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloatArray", function(obj:String, prop:String, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloatArray(prop);
			#else
			FunkinLua.luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});


		Lua_helper.add_callback(lua, "setShaderBool", function(obj:String, prop:String, value:Bool, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBool(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderBoolArray", function(obj:String, prop:String, values:Dynamic, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBoolArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderInt", function(obj:String, prop:String, value:Int, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setInt(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderIntArray", function(obj:String, prop:String, values:Dynamic, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setIntArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloat", function(obj:String, prop:String, value:Float, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setFloat(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloatArray", function(obj:String, prop:String, values:Dynamic, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			shader.setFloatArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return true;
			#end
		});

		Lua_helper.add_callback(lua, "setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String, ?shaderName:String = "") {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj, shaderName);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderSampler2D: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			// trace('bitmapdatapath: $bitmapdataPath');
			var value = Paths.image(bitmapdataPath);
			if(value != null && value.bitmap != null)
			{
				// trace('Found bitmapdata. Width: ${value.bitmap.width} Height: ${value.bitmap.height}');
				shader.setSampler2D(prop, value.bitmap);
				return true;
			}
			return false;
			#else
			FunkinLua.luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
	}

	public static function processFragmentSource(value:String):String
	{
		if (value == null) return value;

		@:privateAccess
		final header = 
			#if (flixel < "6.0.0")
				FlxRuntimeShader.BASE_FRAGMENT_HEADER;
			#else
				FlxRuntimeShaderMacro.retrieveMetadata("glFragmentHeader");
			#end

		@:privateAccess
		final body = 
			#if (flixel < "6.0.0")
				FlxRuntimeShader.BASE_FRAGMENT_BODY;
			#else
				FlxRuntimeShaderMacro.retrieveMetadata("glFragmentBody");
			#end

		value = value.replace("#pragma header", header).replace("#pragma body", body);
		return value;
	}

	#if (!flash && sys)
	public static function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		
		if(!ClientPrefs.data.shaders) return false;

		#if (!flash && sys)
		if(PlayState.instance.runtimeShaders.exists(name))
		{
			FunkinLua.luaTrace('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for(mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if(FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					PlayState.instance.runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		FunkinLua.luaTrace('Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
		#else
		FunkinLua.luaTrace('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}
	#end
	
	#if (!flash && MODS_ALLOWED && sys)
	public static function getShader(obj:String, ?shaderName:String):FlxRuntimeShader
	{
		var split:Array<String> = obj.split('.');
		var target:Dynamic = null;
		if (split.length > 1) {
			target = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
		} else {
			target = LuaUtils.getObjectDirectly(split[0]);
		}

		if (target == null) {
			FunkinLua.luaTrace('Error on getting shader: Object $obj not found', false, false, FlxColor.RED);
			return null;
		}

		var shader:Dynamic = null;

		if (Std.isOfType(target, FlxCamera)) {
			var daFilters = (target.filters != null && target.filters.length > 0) ? target.filters : [];
			
			if (shaderName != null && shaderName.length > 0) {
				var arr:Array<String> = PlayState.instance.runtimeShaders.get(shaderName);
				
				if (arr == null || arr.length == 0) {
					FunkinLua.luaTrace('Error: Shader $shaderName not found in runtimeShaders', false, false, FlxColor.RED);
					return null;
				}

				for (i in 0...daFilters.length) {
					var filter:ShaderFilter = daFilters[i];

					if (filter.shader.glFragmentSource.replace("\r", "").trim() == processFragmentSource(arr[0]).replace("\r", "").trim()) {
						shader = filter.shader;
						break;
					}
				}
			} else {
				shader = daFilters.length > 0 ? daFilters[0].shader : null;
			}
		} else {
			shader = target.shader;
		}

		if (shader == null) {
			FunkinLua.luaTrace('Error: No shader found for the target object.', false, false, FlxColor.RED);
			return null;
		}

		return shader;
	}

	static function removeCameraShader(leObj:Dynamic, ?shader:String = ""){
		var newCamEffects = [];

		if (shader != "" && shader.length > 0)
		{
			var daFilters = [];
			var swagFilters = [];

			if (leObj.filters != null){
				daFilters = leObj.filters;
				swagFilters = leObj.filters;
			}

			var arr:Array<String> = PlayState.instance.runtimeShaders.get(shader);
			
			for (i in 0...daFilters.length){	
				var filter:ShaderFilter = daFilters[i];

				if (filter.shader.glFragmentSource.replace("\r", "").trim() == processFragmentSource(arr[0]).replace("\r", "").trim()){
					swagFilters.remove(filter);
					break;
				}
			}
			
			newCamEffects = swagFilters;
		}
		
		leObj.filters = newCamEffects;
	}
	#end
}