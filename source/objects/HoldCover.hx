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
import objects.FunkinSprite;

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

class CoverSprite extends FunkinSprite
{
	public var spawned:Bool = false;

	public var spriteId:String = "";
	public var texture(default, set):String = null;

	public var rgbShader:RGBShaderReference;

	public var hColor:String = "";
	public var noteIndex:Int = 0;

	public var isCustomHoldCoverSkin:Bool = true;

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


	public function initAnimations(i:Int, hColor:String)
	{
		this.animation.addByPrefix("start" + Std.string(i), 'holdCoverStart'+hColor+'0', 24, false);
		this.animation.addByPrefix("loop" + Std.string(i), 'holdCover'+hColor+'0', 22, true);
		this.animation.addByPrefix("end" + Std.string(i), 'holdCoverEnd'+hColor+'0', 24, false);

		this.animation.onFinish.add((anim) -> {
			if (anim.contains("start" + Std.string(i))) this.animation.play("loop" + Std.string(i), false);
			if (anim.contains("end" + Std.string(i))) {
				this.visible = false;
				this.kill();
			}
		});	
	}
}

class HoldCover extends FlxTypedSpriteGroup<CoverSprite>
{
	public var enabled:Bool = true;
	public var isPlayer:Bool = false;

	public var config(default, set):NoteHoldCoverConfig;
	public static var configs:Map<String, NoteHoldCoverConfig> = new Map();
	var noteDataMap:Map<Int, String> = new Map();

	var activeCovers:Map<Int, CoverSprite> = new Map();

	public function new(enabled:Bool, isPlayer:Bool)
	{
		this.enabled = enabled;
		this.isPlayer = isPlayer;
		
		super(0, 0, 0);
	}

	function spawnNewCover(i:Int, hColor:String, noteTexture:String):CoverSprite
	{
		var hold:CoverSprite = new CoverSprite();
		hold.initFrames(i, hColor, noteTexture != null ? noteTexture : "");
		hold.initAnimations(i, hColor);
		hold.visible = true;
		hold.spriteId = '$hColor-$i';
		this.add(hold);
		return hold;
	}

	public function spawnOnNoteHit(note:Note, isReady:Bool):Void
	{
		if (note == null || !enabled || !isReady) return;

		config = null;
		var noteData:Int = note.noteData;
		var isHoldEnd:Bool = false;
		if (note.animation.curAnim != null) isHoldEnd = note.animation.curAnim.name.endsWith('end');

		var tempConfig:NoteHoldCoverConfig = createConfig();

		var data:Int = Std.int(noteData) % 4;
		var colors:Array<String> = ["Purple", "Blue", "Green", "Red", "Purple", "Blue", "Green", "Red"];
		var hColor:String = colors[data];

		if (!note.isSustainNote) 
			return;

		var existingCover:CoverSprite = activeCovers.get(data);
		if (note.texture != null && note.texture.length > 0 && existingCover != null && existingCover.texture != note.texture && !existingCover.spawned) 
			existingCover.texture = note.texture;

		if (isHoldEnd) {
			if (existingCover != null && existingCover.spawned && isPlayer) {
				existingCover.animation.play("end" + Std.string(data), false);
				existingCover.spawned = false;
				activeCovers.remove(data);
			} else if (existingCover != null && existingCover.spawned) {
				new FlxTimer().start(0.075, function(tmr:FlxTimer) {
					existingCover.visible = false;
					existingCover.spawned = false;
					existingCover.kill();
					activeCovers.remove(data);
				});
			}
			return;
		}

		if (existingCover == null || !existingCover.spawned) {
			var newCover:CoverSprite = spawnNewCover(data, hColor, note.texture);
			newCover.spawned = true;

			newCover.antialiasing = (ClientPrefs.data.antialiasing && !newCover.texture.contains('pixel'));

			newCover.rgbShader = new RGBShaderReference(newCover, initializeGlobalRGBShader(data));
			if (note.shader != null && note.rgbShader.enabled || !newCover.isCustomHoldCoverSkin) newCover.rgbShader.enabled = true;
			else newCover.rgbShader.enabled == false;

			newCover.animation.play("start" + Std.string(data), false);

			activeCovers.set(data, newCover);
		}
	}

	public static var globalRgbShaders:Array<RGBPalette> = [];

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if(globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			var arr:Array<FlxColor> = (!PlayState.isPixelStage) ? ClientPrefs.data.arrowRGB[noteData] : ClientPrefs.data.arrowRGBPixel[noteData];
			
			if (arr != null && noteData > -1 && noteData <= arr.length)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
			else
			{
				newRGB.r = 0xFFFF0000;
				newRGB.g = 0xFF00FF00;
				newRGB.b = 0xFF0000FF;
			}
			
			globalRgbShaders[noteData] = newRGB;
		}
		return globalRgbShaders[noteData];
	}

	public function despawnOnMiss(isReady:Bool, direction:Int, ?note:Note = null):Void
	{
		var data:Int = (note != null ? Std.int(note.noteData) % 4 : direction);
		if (enabled && isReady)
		{
			var cover:CoverSprite = activeCovers.get(data);
			if (cover != null)
			{
				cover.antialiasing = (ClientPrefs.data.antialiasing && !cover.texture.contains('pixel'));
				cover.visible = false;
				cover.animation.stop();
				cover.spawned = false;
				cover.kill();
				activeCovers.remove(data);
			}
		}
	}

	public function updateHold(elapsed:Float, isReady:Bool):Void
	{
		if (enabled && isReady)
		{
			for (member in members) 
				if (member != null && !member.alive) this.remove(member, true);

			for (data => cover in activeCovers) {
				if (cover == null || !cover.alive) {
					activeCovers.remove(data);
					continue;
				}
				if (cover.x != ni(data, "x") - 110) cover.x = ni(data, "x") - 110;
				if (cover.y != ni(data, "y") - 100) cover.y = ni(data, "y") - 100;
				if (cover.alpha != ni(data, "alpha")) cover.alpha = ni(data, "alpha");
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