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

	public var loopAnim:String = "";

	public function initAnimations(i:Int, hColor:String)
	{
		// this.animation.addByPrefix(Std.string(i), 'holdCover'+hColor+'0', 24, true);
		this.animation.addByIndices(Std.string(i), 'holdCover' + hColor, [0,1,2,3], "", 24, true);
		this.animation.addByPrefix(Std.string(i) + 'p', 'holdCoverEnd'+hColor+'0', 24, false);
		loopAnim = Std.string(i);
		this.animation.play(Std.string(i), false);
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


	// I can't change the color without create multiple shaders :HeartBreaking:
	public var rgbShaderPurple:PixelHoldShaderRef;
	public var rgbShaderBlue:PixelHoldShaderRef;
	public var rgbShaderGreen:PixelHoldShaderRef;
	public var rgbShaderRed:PixelHoldShaderRef;

	public var config(default, set):NoteHoldCoverConfig;
	public static var configs:Map<String, NoteHoldCoverConfig> = new Map();
	var noteDataMap:Map<Int, String> = new Map();

	public function new(enabled:Bool, isPlayer:Bool)
	{
		this.enabled = enabled;
		this.isPlayer = isPlayer;

		rgbShaderPurple = new PixelHoldShaderRef();
		rgbShaderBlue = new PixelHoldShaderRef();
		rgbShaderGreen = new PixelHoldShaderRef();
		rgbShaderRed = new PixelHoldShaderRef();
		
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
		if (note == null || !enabled || !isReady) return;

		config = null;
		var noteData:Int = note.noteData;
		var isHoldEnd:Bool = false;
		if (note.animation.curAnim != null) isHoldEnd = note.animation.curAnim.name.endsWith('end');
		var rgbShader:Array<PixelHoldShaderRef> = [rgbShaderPurple, rgbShaderBlue, rgbShaderGreen, rgbShaderRed];

		// HoldCovers with no json
		var tempConfig:NoteHoldCoverConfig = createConfig();

		var data:Int = Std.int(noteData) % 4;

		if (!note.isSustainNote) 
			return;

		var coverSpriteMember = this.members[data];

		if (note.texture != null && note.texture.length > 0 && coverSpriteMember.texture != note.texture) {
			coverSpriteMember.texture = note.texture;
		}

		coverSpriteMember.smoothSprite();
		// RGB shader hold cover stuff

		var daShadersInString:Array<String> = ["rgbShaderPurple", "rgbShaderBlue", "rgbShaderGreen", "rgbShaderRed"];
		for (i in 0... daShadersInString.length) {
			var daShader:PixelHoldShaderRef = Reflect.getProperty(this, daShadersInString[i]);

			daShader.copyValues(Note.globalRgbShaders[i % Note.colArray.length]);
			if (!config.allowPixel || !note.isPixelNote) daShader.pixelAmount = 1;
			else if (config.allowPixel && note != null && note.isPixelNote) daShader.pixelAmount = 6;

			if (tempConfig.allowRGB) this.members[i].shader = daShader.shader;
			else this.members[i].shader = null;
		}

		if (CoverSprite.isCustomHoldCoverSkin)
			tempConfig.allowRGB = false;


		// end RGB shader hold cover stuff
		// if (coverSpriteMember.animation.curAnim == null || coverSpriteMember.animation.curAnim.name != Std.string(data)) {
			// coverSpriteMember.animation.play(Std.string(data), false);
			if (!coverSpriteMember.boom) coverSpriteMember.visible = true;
				// coverSpriteMember.animation.curAnim.curFrame = 0; 
			
		// }

		if (isHoldEnd) {
			if (isPlayer) {
				coverSpriteMember.boom = true;
				coverSpriteMember.animation.play(Std.string(data) + 'p', false);
			} else {
				coverSpriteMember.boom = false;
				hideHoldCoverLater(data, 0.075);
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

			if (this.members[i].boom)
			{
				if (this.members[i].animation.curAnim != null && this.members[i].animation.curAnim.finished)
				{
				this.members[i].visible = false;
				this.members[i].boom = false;
				this.members[i].animation.play(this.members[i].loopAnim);
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

	private function createConfig():NoteHoldCoverConfig
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