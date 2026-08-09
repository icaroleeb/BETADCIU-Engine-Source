package backend.tools;

import openfl.Lib;
import flixel.util.FlxStringUtil;
import backend.tools.FunkinStatsGraph;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

import backend.Conductor;

/**
 * A debug overlay showing useful info.
 */
#if cpp
@:access(lime._internal.backend.native.NativeCFFI)
#end
class FunkinDebugDisplay extends Sprite
{
	static final UPDATE_DELAY:Int = 100;
	static final INNER_RECT_DIFF:Int = 3;
	static final OUTER_RECT_DIMENSIONS:Array<Int> = [234, 201];
	static final OTHERS_OFFSET:Int = 8;

	/**
	 * Indicates whether the debug display is in advanced mode.
	 */
	public var isAdvanced(default, set):Bool = false;

	/**
	 * The opacity of the debug display's background.
	 */
	public var backgroundOpacity(default, set):Float = 0.5;

	var deltaTimeout:Float;
	var times:Array<Float>;
	var color:Int;

	public var fps:Int;
	var fpsPeak:Int;

	var gcMem:Float;
	var gcMemPeak:Float;

	var taskMem:Float;
	var taskMemPeak:Float;

	var background:Shape;
	var chartBackground:Shape;

	var fpsGraph:FunkinStatsGraph;
	var gcMemGraph:FunkinStatsGraph;
	var taskMemGraph:FunkinStatsGraph;

	var infoDisplay:TextField;
	var chartInfo:TextField;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000):Void
	{
		super();

		this.x = x;
		this.y = y;

		this.deltaTimeout = 0.0;
		this.times = [];
		this.color = color;

		this.fps = 0;
		this.fpsPeak = 0;
		this.gcMem = 0.0;
		this.gcMemPeak = 0.0;
		this.taskMem = 0.0;
		this.taskMemPeak = 0.0;

		this.backgroundOpacity = 0.6;
		this.isAdvanced = false;
	}

	function buildDebugDisplay(advanced:Bool):Void
	{
		removeChildren(0, numChildren);

		final BG_WIDTH_MULTIPLIER:Float = 1;
		final BG_HEIGHT_MULTIPLIER:Float = advanced ? 1 : (MemoryUtil.supportsTaskMem()) ? 0.3 : 0.2;

		background = new Shape();
		background.graphics.beginFill(0x3d3f41, 1);
		background.graphics.drawRect(0, 0, (OUTER_RECT_DIMENSIONS[0] * BG_WIDTH_MULTIPLIER) + (INNER_RECT_DIFF * 2),
			(OUTER_RECT_DIMENSIONS[1] * BG_HEIGHT_MULTIPLIER) + (INNER_RECT_DIFF * 2));
		background.graphics.endFill();
		background.graphics.beginFill(0x2c2f30, 1);
		background.graphics.drawRect(INNER_RECT_DIFF, INNER_RECT_DIFF, OUTER_RECT_DIMENSIONS[0] * BG_WIDTH_MULTIPLIER,
			OUTER_RECT_DIMENSIONS[1] * BG_HEIGHT_MULTIPLIER);
		background.graphics.endFill();
		background.alpha = backgroundOpacity;
		addChild(background);

		if (advanced)
		{
			createAdvancedElements();
			updateAdvancedDisplay();
		}
		else
		{
			createSimpleElements();
			updateSimpleDisplay();
		}
	}

	function createAdvancedElements():Void
	{
		final graphsWidth:Int = OUTER_RECT_DIMENSIONS[0] + (INNER_RECT_DIFF * 2) - (OTHERS_OFFSET * 3);
		final graphsHeight:Int = 25;

		fpsGraph = new FunkinStatsGraph(OTHERS_OFFSET, OTHERS_OFFSET + 49, graphsWidth, graphsHeight, color);
		fpsGraph.textDisplay.y = -49;
		fpsGraph.minValue = 0;
		addChild(fpsGraph);

		gcMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (fpsGraph.y + fpsGraph.axisHeight) + 22), graphsWidth, graphsHeight, color);
		gcMemGraph.minValue = 0;
		addChild(gcMemGraph);

		if (MemoryUtil.supportsTaskMem())
		{
			taskMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (gcMemGraph.y + gcMemGraph.axisHeight) + 22), graphsWidth,
				graphsHeight, color);
			taskMemGraph.minValue = 0;
			addChild(taskMemGraph);
		}
	}

	function createSimpleElements():Void
	{
		infoDisplay = new TextField();
		infoDisplay.x = OTHERS_OFFSET;
		infoDisplay.y = OTHERS_OFFSET;
		infoDisplay.width = 500;
		infoDisplay.selectable = false;
		infoDisplay.mouseEnabled = false;
		infoDisplay.defaultTextFormat = new TextFormat('Monsterrat', 12, color, JUSTIFY);
		infoDisplay.antiAliasType = NORMAL;
		infoDisplay.sharpness = 100;
		infoDisplay.multiline = true;
		addChild(infoDisplay);
	}

	function createChartStuff() {
		final BG_WIDTH_MULTIPLIER:Float = 0.45;
		final BG_HEIGHT_MULTIPLIER:Float = 0.45;

		chartBackground = new Shape();
		chartBackground.graphics.beginFill(0x3d3f41, 1);
		chartBackground.graphics.drawRect(0, 0, (OUTER_RECT_DIMENSIONS[0] * BG_WIDTH_MULTIPLIER) + (INNER_RECT_DIFF * 2),
			(OUTER_RECT_DIMENSIONS[1] * BG_HEIGHT_MULTIPLIER) + (INNER_RECT_DIFF * 2));
		chartBackground.graphics.endFill();
		chartBackground.graphics.beginFill(0x2c2f30, 1);
		chartBackground.graphics.drawRect(INNER_RECT_DIFF, INNER_RECT_DIFF, OUTER_RECT_DIMENSIONS[0] * BG_WIDTH_MULTIPLIER,
			OUTER_RECT_DIMENSIONS[1] * BG_HEIGHT_MULTIPLIER);
		chartBackground.graphics.endFill();
		chartBackground.alpha = backgroundOpacity;
		addChild(chartBackground);

		chartInfo = new TextField();
		chartInfo.selectable = false;
		chartInfo.mouseEnabled = false;
		chartInfo.defaultTextFormat = new TextFormat('Monsterrat', 12, color, JUSTIFY);
		chartInfo.antiAliasType = NORMAL;
		chartInfo.sharpness = 100;
		chartInfo.multiline = true;
		addChild(chartInfo);
	}

	override function __enterFrame(deltaTime:Float):Void
	{
		if(!visible) return;
		final currentTime:Float = haxe.Timer.stamp() * 1000;

		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		if (deltaTimeout < UPDATE_DELAY)
		{
			deltaTimeout += deltaTime;
			return;
		}

		fps = times.length;

		if (fps > fpsPeak) fpsPeak = fps;

		gcMem = MemoryUtil.getGCMemory();

		if (gcMem > gcMemPeak)
			gcMemPeak = gcMem;

		if (MemoryUtil.supportsTaskMem())
		{
			taskMem = MemoryUtil.getTaskMemory();

			if (taskMem > taskMemPeak)
				taskMemPeak = taskMem;
		}

		if (isAdvanced)
		{
			updateAdvancedDisplay();
		}
		else
		{
			updateSimpleDisplay();
		}

		updateChartInfo();

		deltaTimeout = 0.0;
	}

	function updateAdvancedDisplay():Void
	{
		updateFPSGraph();
		updateGcMemGraph();
		updateTaskMemGraph();

		final info:Array<String> = [];
		info.push('FPS: $fps');
		info.push('AVG FPS: ${Math.floor(fpsGraph.average())}');
		info.push('1% LOW FPS: ${Math.floor(fpsGraph.lowest())}');
		fpsGraph.textDisplay.text = info.join('\n');

		gcMemGraph.textDisplay.text = 'GC MEM: ${FlxStringUtil.formatBytes(gcMem).toLowerCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toLowerCase()}';

		if (taskMemGraph != null)
		{
			taskMemGraph.textDisplay.text = 'TASK MEM: ${FlxStringUtil.formatBytes(taskMem).toLowerCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toLowerCase()}';
		}
	}

	function updateSimpleDisplay():Void
	{
		if (infoDisplay != null)
		{
			final info:Array<String> = [];

			info.push('FPS: $fps');

			info.push('GC MEM: ${FlxStringUtil.formatBytes(gcMem).toLowerCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toLowerCase()}');

			if (MemoryUtil.supportsTaskMem())
				info.push('TASK MEM: ${FlxStringUtil.formatBytes(taskMem).toLowerCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toLowerCase()}');

			infoDisplay.text = info.join('\n');
		}
	}

	function updateChartInfo() {
		if (!ClientPrefs.data.debugChartDisplay) return;

		final game:PlayState = PlayState.instance;

		if (chartBackground == null && game != null && PlayState.chartingMode) createChartStuff();

		if (!Std.isOfType(FlxG.state, PlayState) && chartBackground != null) {
			removeChild(chartBackground);
			removeChild(chartInfo);
			
			chartBackground = null;
			chartInfo = null;
		}

		if (chartInfo != null && game != null) {
			final info:Array<String> = [];

			info.push("Chart Info:");
			@:privateAccess
			info.push('curStep: ${game.curStep}\ncurBeat: ${game.curBeat}\ncurSection: ${game.curSection}\nBPM: ${Conductor.bpm}');

			chartInfo.text = info.join("\n");

			chartBackground.x = Lib.current.stage.stageWidth - chartBackground.width - 20;
			chartInfo.x = chartBackground.x + OTHERS_OFFSET;
			chartInfo.y = chartBackground.y + OTHERS_OFFSET;

			if (chartBackground.width != (chartInfo.width + (OTHERS_OFFSET * 2))) chartBackground.width = chartInfo.width + (OTHERS_OFFSET * 2);
		}
	}

	function updateFPSGraph():Void
	{
		fpsGraph.maxValue = fpsPeak;
		fpsGraph.update(times.length);
	}

	function updateGcMemGraph():Void
	{
		gcMemGraph.maxValue = gcMemPeak;
		gcMemGraph.update(gcMem);
	}

	function updateTaskMemGraph():Void
	{
		if (taskMemGraph != null)
		{
			taskMemGraph.maxValue = taskMemPeak;
			taskMemGraph.update(taskMem);
		}
	}

	function set_isAdvanced(value:Bool):Bool
	{
		buildDebugDisplay(value);

		return isAdvanced = value;
	}

	function set_backgroundOpacity(value:Float):Float
	{
		if (background != null)
			background.alpha = value;

		return backgroundOpacity = value;
	}
}