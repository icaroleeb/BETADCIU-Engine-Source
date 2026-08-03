package objects.notes;

import backend.Paths;
import flixel.animation.FlxAnimationController;

typedef LaneAnimations = Array<Array<AnimationData>>;

typedef AnimationData =
{
	var anim:String;
	var xmlName:String;

	@:optional var offsets:Array<Float>;
	@:optional var fps:Int;
	@:optional var looping:Bool;
	@:optional var indices:Array<Int>;
}

typedef NoteSkinConfigData =
{
	@:optional var noteTexture:String;
	@:optional var strumTexture:String;
	@:optional var holdTexture:String;

	@:optional var splashTexture:String;

	@:optional var noteAnimations:LaneAnimations;
	@:optional var receptorAnimations:LaneAnimations;
	@:optional var sustainAnimations:LaneAnimations;

	@:optional var noteSplashAnimations:LaneAnimations;
	@:optional var sustainSplashAnimations:LaneAnimations;

	@:optional var singAnimations:Array<String>;

	@:optional var rgbEnabled:Bool;
	@:optional var antialiasing:Bool;
	@:optional var splashesEnabled:Bool;
	@:optional var inGameColoring:Bool;

	@:optional var isPixel:Bool;

	@:optional var pixelScale:Array<Float>;

	@:optional var sustainSuffix:String;

	@:optional var splashOffsets:Array<Float>;
}

typedef SkinAnimData = { // splashes and hold covers
	name:String,
	noteData:Int,
	prefix:String,
	indices:Array<Int>,
	offsets:Array<Float>,
	fps:Array<Int>
}

typedef SkinAnimConfig = { // splashes and hold covers²
	animations:Map<String, SkinAnimData>,
	scale:Float,
	allowRGB:Bool,
	allowPixel:Bool,
	rgb:Array<Null<NoteColoring.NullableRGB>>
}

class NoteSkinConfig
{
	static var configs:Map<String, NoteSkinConfigData> = [];

    public static function clear()
    {
		for (key in configs.keys()){
			configs.remove(key);
			Paths.clearAssetFromMemory('$key.json', "text");
		}
    }

	public static function getConfigPath(skin:String):String
	{
		final flat = 'noteSkins/$skin';
		final folder = 'noteSkins/$skin/config';

		if (Paths.fileExists('images/$flat.json', TEXT))
			return flat;

		if (Paths.fileExists('images/$folder.json', TEXT))
			return folder;

		return null;
	}

	public static function get(path:String):NoteSkinConfigData
	{
		if (!configs.exists(path))
		{
			try
			{
				var parsed:NoteSkinConfigData =
					cast tjson.TJSON.parse(
						Paths.getTextFromFile('$path.json')
					);

				applyDefaults(parsed, path);

				configs.set(path, parsed);
			}
			catch (e)
			{
				trace('Failed to load NoteSkinConfig: $path');
				trace(e);

				configs.set(path, dummy());
			}
		}

		return configs.get(path);
	}

	static function applyDefaults(config:NoteSkinConfigData, path:String)
	{
		if (config.noteTexture == null)
			config.noteTexture = path;

		if (config.holdTexture == null)
			config.holdTexture = config.noteTexture;

		if (config.strumTexture == null)
			config.strumTexture = config.noteTexture;

		if (config.antialiasing == null)
			config.antialiasing = true;

		if (config.splashesEnabled == null)
			config.splashesEnabled = true;

		if (config.sustainSuffix == null)
			config.sustainSuffix = "ENDS";

        if (config.inGameColoring == null)
			config.inGameColoring = false;

        if (config.isPixel == null)
			config.isPixel = false;
	}

	static function dummy():NoteSkinConfigData
	{
		return {
			noteTexture: "noteSkins/NOTE_assets",
			strumTexture: "noteSkins/NOTE_assets",
			holdTexture: "noteSkins/NOTE_assets"
		};
	}

	// old configs 
	public static function createConfig():SkinAnimConfig
	{
		return {
			animations: new Map(),
			scale: 1,
			allowRGB: true,
			allowPixel: true,
			rgb: null
		}
	}

	public static function applyConfig(sprite:FlxSprite, animation:FlxAnimationController, config:SkinAnimConfig,
		noteDataMap:Map<Int, String>, clearExisting:Bool = false):SkinAnimConfig
	{
		if (config == null) config = createConfig();

		if (clearExisting)
		{
			@:privateAccess
			animation.clearAnimations();
		}

		noteDataMap.clear();

		for (i in config.animations)
		{
			var key:String = i.name;
			if (i.prefix.length > 0 && key != null && key.length > 0)
			{
				if (i.indices != null && i.indices.length > 0)
					animation.addByIndices(key, i.prefix, i.indices, "", i.fps[1], false);
				else
					animation.addByPrefix(key, i.prefix, i.fps[1], false);

				noteDataMap.set(i.noteData, key);
			}
		}

		sprite.scale.set(config.scale, config.scale);
		return config;
	}
}