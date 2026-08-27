package objects;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.math.FlxRect;

typedef AtlasSpriteSettings =
{
  /**
   * If true, the texture atlas will behave as if it was exported as an SWF file.
   * Notably, this allows MovieClip symbols to play.
   */
  @:optional
  var swfMode:Bool;

  /**
   * If true, filters and masks will be cached when the atlas is loaded, instead of during runtime.
   */
  @:optional
  var cacheOnLoad:Bool;

  /**
   * The filter quality.
   * Available values are: HIGH, MEDIUM, LOW, and RUDY.
   *
   * If you're making an atlas sprite in HScript, you pass an Int instead:
   *
   * HIGH - 0
   * MEDIUM - 1
   * LOW - 2
   * RUDY - 3
   */
  @:optional
  var filterQuality:FilterQuality;

  /**
   * Optional, an array of spritemaps for the atlas to load.
   */
  @:optional
  var spritemaps:Array<SpritemapInput>;

  /**
   * Optional, string of the metadata.json contents.
   */
  @:optional
  var metadataJson:String;

  /**
   * Optional, force the cache to use a specific key to index the texture atlas.
   */
  @:optional
  var cacheKey:String;

  /**
   * If true, the texture atlas will use a new slot in the cache.
   */
  @:optional
  var uniqueInCache:Bool;

  /**
   * Optional callback for when a symbol is created.
   */
  @:optional
  var onSymbolCreate:animate.internal.SymbolItem->Void;

  /**
   * Whether to apply the stage matrix, if it was exported from a symbol instance.
   * Also positions the Texture Atlas as it displays in Animate.
   * Turning this on is only recommended if you prepositioned the character in Animate.
   * For other cases, it should be turned off to act similarly to a normal FlxSprite.
   */
  @:optional
  var applyStageMatrix:Bool;

  /**
   * If enabled, the sprite will render as one texture instead of rendering multiple limbs.
   * This is useful for stuff like changing alpha, and shaders that require the whole sprite.
   *
   * Only enable this if your sprite either:
   * - Changes alpha to something other than 1.0
   * - Has a shader or blend mode
   */
  @:optional
  var useRenderTexture:Bool;
}

class FunkinSprite extends FlxAnimate
{
    /**
     * Create a new FunkinSprite with an Adobe Animate texture atlas.
     * @param x The starting X position.
     * @param y The starting Y position.
     * @param key The key of the texture to load.
     * @return The new FunkinSprite.
     */
    public static function createTextureAtlas(x:Float = 0.0, y:Float = 0.0, key:String, ?assetLibrary:Null<String>, ?settings:AtlasSpriteSettings):FunkinSprite
    {
        var sprite:FunkinSprite = new FunkinSprite(x, y);
        sprite.loadTextureAtlas(key, assetLibrary ?? "shared", settings);
        return sprite;
    }

    public static function create(x:Float = 0.0, y:Float = 0.0, key:String)
    {
        return new FunkinSprite(x, y, Paths.image(key));
    }

    public override function new(x:Float = 0, y:Float = 0, ?SimpleGraphic:FlxGraphicAsset) {
        super(x, y, SimpleGraphic);
        antialiasing = ClientPrefs.data.antialiasing;
    }

    /**
     * Loads an Adobe Animate texture atlas as the sprite's texture.
     * @param key The key of the texture to load.
     * @param settings Additional settings for loading the atlas.
     * @return This sprite, for chaining.
     */
    public function loadTextureAtlas(key:Null<String>, ?assetLibrary:Null<String>, ?settings:AtlasSpriteSettings):FunkinSprite
    {
        if (key == null)
        {
        throw 'Null path specified for loadTextureAtlas()!';
        }

        if (settings == null)
        {
        settings = getDefaultAtlasSettings();
        }

        this.applyStageMatrix = settings.applyStageMatrix ?? false;
        this.useRenderTexture = settings.useRenderTexture ?? false;

        frames = Paths.getAnimateAtlas(key, assetLibrary, settings);

        return this;
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

    /**
     * Gets the default settings for a texture atlas sprite.
     * @return The default settings for a texture atlas sprite.
     */
    public function getDefaultAtlasSettings():AtlasSpriteSettings
    {
        return {
        swfMode: false,
        cacheOnLoad: false,
        filterQuality: MEDIUM,
        spritemaps: null,
        metadataJson: null,
        cacheKey: null,
        uniqueInCache: false,
        onSymbolCreate: null,
        applyStageMatrix: false,
        useRenderTexture: false
        };
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