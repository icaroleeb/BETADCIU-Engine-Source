package objects.notes;

import backend.Paths;

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
		final folder = 'noteSkins/${haxe.io.Path.directory(skin)}/config';

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
}