package backend.tools;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.Sprite;

import lime.graphics.opengl.GL;
import lime.utils.Int32Array;

import flixel.FlxG;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/

// thx nightmare vision for the base for this

class DebugDisplay extends Sprite
{
	var updating:Bool = true;
	
	var text:TextField;
	var underlay:Bitmap;
	
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;
	
	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;
    public var memoryPeak:Float = 0;
	
	@:noCompletion private var times:Array<Float>;
	
	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();
		
		this.x = x;
		this.y = y;
		
		underlay = new Bitmap();
		underlay.bitmapData = new BitmapData(1, 1, true, 0x6F000000);
		addChild(underlay);
		
		text = new TextField();
		addChild(text);
		
		currentFPS = 0;
		text.selectable = false;
		text.mouseEnabled = false;
		text.defaultTextFormat = new TextFormat("Monsterrat", 14, color);
		text.autoSize = LEFT;
		text.multiline = true;
		text.text = "FPS: ";
		
		times = [];
		
		FlxG.signals.postStateSwitch.add(() -> updateText = __updateTxt);
	}
	
	var deltaTimeout:Float = 0.0;
	
	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000)
			times.shift();
			
		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 100)
		{
			deltaTimeout += deltaTime;
			return;
		}
		
		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		updateText();
        underlay.width = 370;
		// underlay.width = text.width + 3;
		underlay.height = text.height;
		
		deltaTimeout = 0.0;
	}
	
	dynamic function updateText():Void
	{
		__updateTxt();
	}
	
	function __updateTxt()
	{
		if (!updating) return;
        if (memoryMegas > memoryPeak) memoryPeak = memoryMegas;

        var gpuStr:String = "";

        try {
            gpuStr = 'GPU: ${GL.getString(GL.RENDERER).split("/")[0]}';
        } catch (e) {
            gpuStr = "";
        }

        var ramText:String = 'RAM: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)} (Peak: ${flixel.util.FlxStringUtil.formatBytes(memoryPeak)})';

        var ext = GL.getString(GL.EXTENSIONS);
        if (ext != null && ext.indexOf("GL_NVX_gpu_memory_info") != -1) {  // i don't have a AMD/Intel gpu to test this
            ramText += ' | VRAM: ${flixel.util.FlxStringUtil.formatBytes(get_vramMegas() * 1024)}';
        }

		text.text = 'FPS: $currentFPS\n${ramText}\nState: ${Type.getClassName(Type.getClass(FlxG.state))}\n${gpuStr}';
		
		text.textColor = 0xFFFFFFFF;
		if (currentFPS < FlxG.drawFramerate * 0.5) text.textColor = 0xFFFF0000;
	}

    inline function get_memoryMegas():Float
	{
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#elseif (openfl >= "9.4.0")
		return cast(openfl.system.System.totalMemoryNumber, UInt);
		#else
		return cast(openfl.system.System.totalMemory, UInt);
		#end
	}

    static inline var totalVram = 0x9048;
    static inline var curAvailableVram = 0x9049;

    function get_vramMegas():Float // some times works, some times does this: https://prnt.sc/CYl54ZKOvPN5
    {
        try {
            var total = new Int32Array(1);
            var free  = new Int32Array(1);

            GL.getIntegerv(totalVram, total);
            GL.getIntegerv(curAvailableVram, free);

            return (total[0] - free[0]);
        } catch (e) {}

        return -1;
    }
}