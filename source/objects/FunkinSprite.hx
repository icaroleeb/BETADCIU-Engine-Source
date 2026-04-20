package backend;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxRect;
import flixel.math.FlxMatrix;
import animate.FlxAnimate;

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

  // ZOOM FACTOR
  public var zoomFactor:Float = 1;
  public var zoomFactorEnabled:Bool = true;
  var _rect2:FlxRect;

  // semi stolen from FlxSkewedSprite
	static var _skewMatrix:FlxMatrix = new FlxMatrix();
  public static var USE_LEGACY_ZOOM_FACTOR:Null<Bool> = null;

	private inline function __shouldDoZoomFactor()
		return zoomFactorEnabled && zoomFactor != 1;

	private inline function __prepareZoomFactor(?rect:FlxRect, camera:FlxCamera):FlxRect {
		if (USE_LEGACY_ZOOM_FACTOR)
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

  function prepareDrawMatrix(matrix:FlxMatrix, camera:FlxCamera):Void {
		prepareDrawMatrixFlxAnimate(matrix, camera);

		if (__shouldDoZoomFactor()) {
			__prepareZoomFactor(_rect2, camera);
			matrix.setTo(
				matrix.a * _rect2.width, matrix.b * _rect2.height,
				matrix.c * _rect2.width, matrix.d * _rect2.height,
				(matrix.tx - _rect2.x) * _rect2.width + _rect2.x,
				(matrix.ty - _rect2.y) * _rect2.height + _rect2.y,
			);
		}
	}

  function prepareDrawMatrixFlxAnimate(matrix:FlxMatrix, camera:FlxCamera):Void
	{
		final doStageMatrix:Bool = (isAnimate && applyStageMatrix);

		if (doStageMatrix)
		{
			matrix.translate(timeline._bounds.x, timeline._bounds.y);
		}

		matrix.translate(-origin.x, -origin.y);
		matrix.scale(scale.x, scale.y);

		if (angle != 0)
		{
			updateTrig();
			matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		if (skew.x != 0 || skew.y != 0)
		{
			updateSkew();
			matrix.concat(_skewMatrix);
		}

		if (doStageMatrix) // TODO: add some way to customize the order of this thing
		{
			matrix.concat(library.matrix);
		}

		getScreenPosition(_point, camera);
		_point.x += origin.x - offset.x;
		_point.y += origin.y - offset.y;
		matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
			preparePixelPerfectMatrix(matrix);
	}

  /*
	override function preparePixelPerfectMatrix(matrix:FlxMatrix):Void
	{
		matrix.tx = Math.floor(matrix.tx);
		matrix.ty = Math.floor(matrix.ty);
	}
    */
}