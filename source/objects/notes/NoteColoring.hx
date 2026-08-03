package objects.notes;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import openfl.display.BitmapData;
import openfl.geom.Point;

import objects.Note;
import shaders.RGBPalette;
import states.PlayState;

// everything about note coloring should go here

typedef NullableRGB = { // hold covers and note splashes
	r:Null<Int>,
	g:Null<Int>,
	b:Null<Int>
}

class NoteRGBShader 
{
    public static var globalRgbShaders:Array<RGBPalette> = [];

    public static function initializeGlobalRGBShader(noteData:Int, ?pixel:Bool=false)
	{
		var newRGB:RGBPalette = new RGBPalette();
		var arr:Array<FlxColor> = pixel ? ClientPrefs.data.arrowRGBPixel[noteData] : ClientPrefs.data.arrowRGB[noteData];
			
		if (arr != null && noteData > -1 && noteData <= arr.length) {
			newRGB.r = arr[0];
			newRGB.g = arr[1];
			newRGB.b = arr[2];
			// newRGB.saturation = 5; // mainly for hold covers so imma adjust it there
		} else {
			newRGB.r = 0xFFFF0000;
			newRGB.g = 0xFF00FF00;
			newRGB.b = 0xFF0000FF;
		}
		// trace('R: ${newRGB.r}, G: ${newRGB.g}, B: ${newRGB.b} for noteData: $noteData');
			
		globalRgbShaders[noteData] = newRGB;

		return globalRgbShaders[noteData];
	}

    public static function applyDefaultColors(shader:RGBShaderReference, noteData:Int, pixel:Bool = false):Void
    {
        var index:Int = Std.int(Math.abs(noteData) % 4);
        var arr:Array<FlxColor> = pixel ? ClientPrefs.data.arrowRGBPixel[index] : ClientPrefs.data.arrowRGB[index];

        if (arr != null && index <= arr.length)
        {
            shader.r = arr[0];
            shader.g = arr[1];
            shader.b = arr[2];
        }
    }
}

class NoteColorExtractor // most of this code only works if you have the note image in the ram, so remember to always load the image with the allowGPU false if needed.
{
    public static function getDominantColor(note:Note):FlxColor {
        if (note.frame == null || note.graphic == null) return FlxColor.WHITE;

        var bmp:BitmapData = new BitmapData(Std.int(note.width), Std.int(note.height), true, 0x00000000);
        note.frame.paint(bmp, new Point(0, 0), false);

        if (bmp.width <= 1 || bmp.height <= 1) return FlxColor.WHITE;

        var bestColor:FlxColor = FlxColor.WHITE;
        var bestScore:Float = -1;
        var step:Int = 2;

        var x:Int = 0;
        while (x < bmp.width) {
            var y:Int = 0;
            while (y < bmp.height) {
                var px:Int = bmp.getPixel32(x, y);
                var a:Int = (px >> 24) & 0xFF;

                if (a > 128) {
                    var r:Int = (px >> 16) & 0xFF;
                    var g:Int = (px >> 8) & 0xFF;
                    var b:Int = px & 0xFF;

                    var maxC:Int = Std.int(Math.max(r, Math.max(g, b)));
                    var minC:Int = Std.int(Math.min(r, Math.min(g, b)));

                    if (!(maxC < 40 || minC > 235)) {
                        var sat:Float = (maxC == 0) ? 0 : (maxC - minC) / maxC;
                        var lightBias:Float = 1 - Math.abs((maxC - 128) / 128);
                        var score:Float = sat * 0.85 + lightBias * 0.15;

                        if (score > bestScore) {
                            bestScore = score;
                            bestColor = FlxColor.fromRGB(r, g, b);
                        }
                    }
                }
                y += step;
            }
            x += step;
        }

        bmp.dispose();

        return bestColor;
    }

    public static function generateTones(base:FlxColor):{ shadow:FlxColor, mid:FlxColor, highlight:FlxColor }
    {
        var sat:Float = Math.max(base.saturation, 0.55);

        var boosted:FlxColor = FlxColor.fromHSL(base.hue, sat, FlxMath.bound(base.lightness, 0.3, 0.65));

        return {
            shadow: FlxColor.fromHSL(boosted.hue, boosted.saturation, FlxMath.bound(boosted.lightness - 0.14, 0.08, 1)),
            mid: boosted,
            highlight: FlxColor.fromHSL(boosted.hue, FlxMath.bound(boosted.saturation - 0.08, 0, 1), FlxMath.bound(boosted.lightness + 0.16, 0.08, 0.95))
        };
    }
}

class PixelNoteShaderRef
{
	public var shader:PixelNoteShader = new PixelNoteShader();
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
	}
}


class PixelNoteShader extends FlxShader
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