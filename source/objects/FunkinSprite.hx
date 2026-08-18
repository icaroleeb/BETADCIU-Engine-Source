package objects;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.math.FlxRect;

class FunkinSprite extends FlxAnimate
{
    public var zoomFactor:Float = 1;
    public var zoomFactorEnabled:Bool = true;
    public var useLegacyZoomFactor:Bool = true;
    public var forceIsOnScreen:Bool = false;

    public static function create(x:Float = 0.0, y:Float = 0.0, key:String)
    {
        return new FunkinSprite(x, y, Paths.image(key));
    }

    public override function new(x:Float = 0, y:Float = 0, ?SimpleGraphic:FlxGraphicAsset) {
        super(x, y, SimpleGraphic);
        antialiasing = ClientPrefs.data.antialiasing;
    }

    /**
     * Returns the screen position of this object.
     *
     * @param   result  Optional arg for the returning point
     * @param   camera  The desired "screen" coordinate space. If `null`, `FlxG.camera` is used.
     * @return  The screen position of this object.
     */
    public override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
    {
        if (result == null) result = FlxPoint.get();

        if (camera == null) camera = FlxG.camera;

        result.set(x, y);
        if (pixelPerfectPosition)
        {
          _rect.width = _rect.width / this.scale.x;
          _rect.height = _rect.height / this.scale.y;
          _rect.x = _rect.x / this.scale.x;
          _rect.y = _rect.y / this.scale.y;
          _rect.round();
          _rect.x = _rect.x * this.scale.x;
          _rect.y = _rect.y * this.scale.y;
          _rect.width = _rect.width * this.scale.x;
          _rect.height = _rect.height * this.scale.y;
        }

        return result.subtract(camera.scroll.x * scrollFactor.x, camera.scroll.y * scrollFactor.y);
    }

    override function drawSimple(camera:FlxCamera):Void
    {
        getScreenPosition(_point, camera).subtractPoint(offset);
        if (isPixelPerfectRender(camera))
        {
          _point.x = _point.x / this.scale.x;
          _point.y = _point.y / this.scale.y;
          _point.round();

          _point.x = _point.x * this.scale.x;
          _point.y = _point.y * this.scale.y;
        }

        _point.copyToFlash(_flashPoint);
        camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, colorTransform, blend, antialiasing);
    }

    override function drawComplex(camera:FlxCamera):Void
    {
        _frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
        _matrix.translate(-origin.x, -origin.y);
        _matrix.scale(scale.x, scale.y);

        if (bakedRotationAngle <= 0)
        {
          updateTrig();

          if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
        }

        getScreenPosition(_point, camera).subtractPoint(offset);
        _point.add(origin.x, origin.y);
        _matrix.translate(_point.x, _point.y);

        if (isPixelPerfectRender(camera))
        {
          _matrix.tx = Math.round(_matrix.tx / this.scale.x) * this.scale.x;
          _matrix.ty = Math.round(_matrix.ty / this.scale.y) * this.scale.y;
        }

        camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
    }

    // ZOOM FACTOR
	private inline function __shouldDoZoomFactor()
		return zoomFactorEnabled && zoomFactor != 1;

	private inline function __prepareZoomFactor(?rect:FlxRect, camera:FlxCamera):FlxRect {
		if (useLegacyZoomFactor)
			return (rect ?? FlxRect.get()).set(
				camera.width * 0.5,
				camera.height * 0.5,
				(camera.scaleX > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleX, 1, zoomFactor)),
				(camera.scaleY > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleY, 1, zoomFactor))
			);
		else
			return (rect ?? FlxRect.get()).set(
				camera.width * 0.5 + camera.scroll.x * scrollFactor.x,
				camera.height * 0.5 + camera.scroll.y * scrollFactor.y,
				(camera.scaleX > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleX, 1, zoomFactor)),
				(camera.scaleY > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleY, 1, zoomFactor))
			);
	}

	override public function isOnScreen(?camera:FlxCamera):Bool
	{
		if (forceIsOnScreen)
			return true;

		if (camera == null)
			camera = FlxG.camera;

		var bounds = getScreenBounds(_rect, camera);
		if (bounds.width == 0 && bounds.height == 0)
			return false;
		return camera.containsRect(bounds);
	}

    // Offset Stuff
    public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
    public var animPlayerOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

    public function addOffset(name:String, x:Float = 0, y:Float = 0)
    {
        animOffsets[name] = [x, y];
    }

    public function addPlayerOffset(name:String, x:Float = 0, y:Float = 0)
    {
        animPlayerOffsets[name] = [x, y];
    }

    public inline function getAnimOffset(name:String) {
        if (animOffsets[name] != null)
            return animOffsets[name];
        return [0,0];
    }

    public inline function getAnimPlayerOffset(name:String) {
        if (animPlayerOffsets[name] != null)
          return animPlayerOffsets[name];
        return [0,0];
    }
}