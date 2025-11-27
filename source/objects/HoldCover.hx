package objects;

import openfl.Assets;
import flixel.FlxSprite;
import objects.Note;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxTimer;
import states.PlayState;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import flixel.system.FlxAssets.FlxShader;

using StringTools;

typedef RGB2 = {
	r:Null<Int>,
	g:Null<Int>,
	b:Null<Int>
}

typedef NoteHoldCoverAnim = {
	name:String,
	noteData:Int,
	prefix:String,
	indices:Array<Int>,
	offsets:Array<Float>,
	fps:Array<Int>
}

typedef NoteHoldCoverConfig = {
	animations:Map<String, NoteHoldCoverAnim>,
	scale:Float,
	allowRGB:Bool,
	allowPixel:Bool,
	rgb:Array<Null<RGB2>>
}

//Most of the Original code from Mr.Bruh (mr.bruh69)
//Ported to haxe and edited by glowsoony // thanks man!

class CoverSprite extends FlxSprite
{
	public var boom:Bool = false;
	public var isPlaying:Bool = false;
	public var activatedSprite:Bool = true;

	public var spriteId:String = "";
	public var texture(default, set):String = null;

	public var hColor:String = "";
	public var noteIndex:Int = 0;

	public static var isCustomHoldCoverSkin:Bool = true;

	private function set_texture(value:String):String {
		if(texture != value) {
			value = reloadCover(value);
		}
		return value;
	}

	public function reloadCover(newTexture:String = '', postfix:String = '') {
		initFrames(noteIndex, hColor, newTexture);
		initAnimations(noteIndex, hColor);

		return newTexture;
	}

	public function initFrames(i:Int, hColor:String, skin:String = "")
	{
		this.hColor = hColor;
		this.noteIndex = i;

		trace("SKIN IS " + skin);
		if (hColor.length < 0) {
			if (Paths.fileExists('images/holdCovers/$skin/holdCover$hColor.png', IMAGE)){
				this.frames = Paths.getSparrowAtlas(skin.length > 0 ? 
					'holdCovers/$skin/holdCover$hColor' : 
					'holdCovers/holdCover$hColor');
			}
			else{
				this.frames = Paths.getSparrowAtlas('holdCovers/holdCover$hColor');
			}

			isCustomHoldCoverSkin = true;
		}else{
			if (Paths.fileExists('images/holdCovers/$skin/holdCover.png', IMAGE)){
				this.frames = Paths.getSparrowAtlas(skin.length > 0 ? 
					'holdCovers/$skin/holdCover' : 
					'holdCovers/holdCover');
			}
			else{
				this.frames = Paths.getSparrowAtlas('holdCovers/holdCover');
			}

			isCustomHoldCoverSkin = false;
		}
	}

	public function initAnimations(i:Int, hColor:String)
	{
		this.animation.addByPrefix(Std.string(i), 'holdCover$hColor', 24, true);
		this.animation.addByPrefix(Std.string(i) + 'p', 'holdCoverEnd$hColor', 24, false);
	}

	public function smoothSprite()
	{
		this.antialiasing = ClientPrefs.data.antialiasing;
		if (texture.contains('pixel') || !ClientPrefs.data.antialiasing)
			this.antialiasing = false;
	}
}

class HoldCover extends FlxTypedSpriteGroup<CoverSprite>
{
	public var enabled:Bool = true;
	public var isPlayer:Bool = false;
	public var rgbShader:PixelHoldShaderRef;
	public var config(default, set):NoteHoldCoverConfig;
	public static var configs:Map<String, NoteHoldCoverConfig> = new Map();
	var noteDataMap:Map<Int, String> = new Map();

	public function new(enabled:Bool, isPlayer:Bool)
	{
		this.enabled = enabled;
		this.isPlayer = isPlayer;

		rgbShader = new PixelHoldShaderRef();
		
		super(0, 0, 4);
		for (i in 0...maxSize)
			addHolds(i);
	}

	public function addHolds(i:Int)
	{
		var colors:Array<String> = ["Purple", "Blue", "Green", "Red", "Purple", "Blue", "Green", "Red"];
		var hColor:String = colors[i];
		var hold:CoverSprite = new CoverSprite();
		hold.initFrames(i, hColor);
		hold.initAnimations(i, hColor);
		hold.boom = false;
		hold.isPlaying = false;
		hold.visible = false;
		hold.activatedSprite = enabled;
		hold.spriteId = '$hColor-$i';
		this.add(hold);
	}

	public function spawnOnNoteHit(note:Note, isReady:Bool):Void
	{
		if (note == null) return;

		config = null;
		var noteData:Int = note.noteData;
		var isSus:Bool = note.isSustainNote;
		var isHoldEnd:Bool = false;
		if (note.animation.curAnim != null) isHoldEnd = note.animation.curAnim.name.endsWith('end');

		// HoldCovers with no json
		var tempConfig:NoteHoldCoverConfig = createConfig();

		if (enabled && isReady)
		{
			var data:Int = Std.int(noteData) % 4;

			if (isSus)
			{
				var coverSpriteMember = this.members[data];

				if (note.texture != null && note.texture.length > 0 && coverSpriteMember.texture != note.texture) {
					coverSpriteMember.texture = note.texture;
				}

				coverSpriteMember.smoothSprite();
				// RGB shader hold cover stuff
				var tempShader:RGBPalette = null;
				if (config.allowRGB)
				{
					Note.initializeGlobalRGBShader(noteData % Note.colArray.length);
					if ((note == null || note.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB))
					{
						tempShader = new RGBPalette();
						// If Note RGB is enabled:
						if ((note == null || !note.noteSplashData.useGlobalShader))
						{
							var colors = config.rgb;
							if (colors != null)
							{
								for (i in 0...3)
								{
									var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData % Note.colArray.length];
									if (note != null && note.isPixelNote) arr = ClientPrefs.data.arrowRGBPixel[noteData % Note.colArray.length];

									var rgb = colors[i];
									if (rgb == null)
									{
										if (i == 0) tempShader.r = arr[0];
										else if (i == 1) tempShader.g = arr[1];
										else if (i == 2) tempShader.b = arr[2];
										continue;
									}

									var r:Null<Int> = rgb.r;
									var g:Null<Int> = rgb.g;
									var b:Null<Int> = rgb.b;

									if (r == null || Math.isNaN(r) || r < 0) r = arr[0];
									if (g == null || Math.isNaN(g) || g < 0) g = arr[1];
									if (b == null || Math.isNaN(b) || b < 0) b = arr[2];

									var color:FlxColor = FlxColor.fromRGB(r, g, b);
									if (i == 0) tempShader.r = color;
									else if (i == 1) tempShader.g = color;
									else if (i == 2) tempShader.b = color;
								}
							}
							else tempShader.copyValues(Note.globalRgbShaders[noteData % Note.colArray.length]);

							if (note != null)
							{
								if (note.noteSplashData.r != -1) tempShader.r = note.noteSplashData.r;
								if (note.noteSplashData.g != -1) tempShader.g = note.noteSplashData.g;
								if (note.noteSplashData.b != -1) tempShader.b = note.noteSplashData.b;
							}
						}
						else tempShader.copyValues(Note.globalRgbShaders[noteData % Note.colArray.length]);
					}
				}
				rgbShader.copyValues(tempShader);
				if (!config.allowPixel) rgbShader.pixelAmount = 1;
				else if (note != null && note.isPixelNote) rgbShader.pixelAmount = 6;

				if(tempConfig.allowRGB) 
					coverSpriteMember.shader = rgbShader.shader;
				else
					coverSpriteMember.shader = null;

				if (CoverSprite.isCustomHoldCoverSkin){
					tempConfig.allowRGB = false;
				}

				// end RGB shader hold cover stuff

					if (isHoldEnd)
					{
						coverSpriteMember.isPlaying = false;
						coverSpriteMember.boom = true;
						coverSpriteMember.animation.play(Std.string(data) + 'p');
					}
					else
					{
						coverSpriteMember.isPlaying = false;
						coverSpriteMember.boom = false;
						hideHoldCoverLater(data, 0.075);
					}
				}
				else
				{
					if (coverSpriteMember.isPlaying == false)
					{
						if (coverSpriteMember.boom == false){
							coverSpriteMember.visible = true;
						}
							
						coverSpriteMember.animation.play(Std.string(data));
						coverSpriteMember.isPlaying = false;
					}
				}
			}
		}
	}

	public function despawnOnMiss(isReady:Bool, direction:Int, ?note:Note = null):Void
	{
		var noteData:Int = (note != null ? Std.int(note.noteData) % 4 : direction);
		if (enabled && isReady)
		{
			var data:Int = noteData;
			this.members[data].smoothSprite();
			this.members[data].isPlaying = false;
			this.members[data].boom = false;
			this.members[data].visible = false;
			this.members[data].animation.stop();
		}
	}

	private function hideHoldCoverLater(data:Int, delay:Float):Void
	{
		var timer:FlxTimer = new FlxTimer();
		var tag:String = "hideHoldCoverFromStrum" + data;
		PlayState.instance.variables.set(tag, timer.start(delay, function(timer:FlxTimer)
		{
		this.members[data].visible = false;
		PlayState.instance.variables.remove(tag);
		}));
	}

	public function updateHold(elapsed:Float, isReady:Bool):Void
	{
		if (enabled && isReady)
		{
			for (i in 0...this.members.length)
			{
			if (this.members[i].x != ni(i, "x") - 110)
			{
				this.members[i].x = ni(i, "x") - 110;
			}
			if (this.members[i].y != ni(i, "y") - 100)
			{
				this.members[i].y = ni(i, "y") - 100;
			}
			if (this.members[i].alpha != ni(i, "alpha"))
			{
				this.members[i].alpha = ni(i, "alpha");
			}

			if (this.members[i].boom == true)
			{
				if (this.members[i].animation.curAnim.finished)
				{
				this.members[i].visible = false;
				this.members[i].boom = false;
				}
			}
			}
		}
  	}

	function ni(note, info):Float
	{
		if (enabled && PlayState.instance != null && !PlayState.instance.inCutscene)
		{
		var game:PlayState = PlayState.instance;
		if (game == null) return 110;
		else
		{
			if (game.strumLineNotes != null)
			{
				if (info == "x") return game.strumLineNotes.members[isPlayer ? note + 4 : note].x;
				else if (info == "y") return game.strumLineNotes.members[isPlayer ? note + 4 : note].y;
				else if (info == "alpha") return game.strumLineNotes.members[isPlayer ? note + 4 : note].alpha;
			}
			return 0;
		}
		}
		return 0;
	}

	function set_config(value:NoteHoldCoverConfig):NoteHoldCoverConfig 
	{
		if (value == null) value = createConfig();

		@:privateAccess
		noteDataMap.clear();

		for (i in value.animations)
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

		scale.set(value.scale, value.scale);
		return config = value;
	}

	public static function createConfig():NoteHoldCoverConfig
	{
		return {
			animations: new Map(),
			scale: 1,
			allowRGB: true,
			allowPixel: true,
			rgb: null
		}
	}
}

class PixelHoldShaderRef 
{
	public var shader:PixelHoldShader = new PixelHoldShader();
	public var enabled(default, set):Bool = true;
	public var pixelAmount(default, set):Float = 1;

	public function copyValues(tempShader:RGBPalette)
	{
		if (tempShader != null)
		{
			for (i in 0...3)
			{
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
		}
		else enabled = false;
	}

	public function set_enabled(value:Bool)
	{
		enabled = value;
		shader.mult.value = [value ? 1 : 0];
		return value;
	}

	public function set_pixelAmount(value:Float)
	{
		pixelAmount = value;
		shader.uBlocksize.value = [value, value];
		return value;
	}

	public function reset()
	{
		shader.r.value = [0, 0, 0];
		shader.g.value = [0, 0, 0];
		shader.b.value = [0, 0, 0];
	}

	public function new()
	{
		reset();
		enabled = true;

		if (!PlayState.isPixelStage) pixelAmount = 1;
		else pixelAmount = PlayState.daPixelZoom;
		//trace('Created shader ' + Conductor.songPosition);
	}
}

class PixelHoldShader extends FlxShader
{
	@:glFragmentHeader('
		#pragma header

		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;
		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;
			vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
			if (!hasTransform) {
				return color;
			}

			if (color.a == 0.0 || mult == 0.0) {
				return color * openfl_Alphav;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;

			color = mix(color, newColor, mult);

			if (color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')

	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')

	public function new()
	{
		super();
	}
}
