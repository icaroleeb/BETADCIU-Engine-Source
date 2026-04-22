package objects;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;

class FunkinSprite extends FlxAnimate
{
    public static function create(x:Float = 0.0, y:Float = 0.0, key:String)
    {
        return new FunkinSprite(x, y, Paths.image(key));
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