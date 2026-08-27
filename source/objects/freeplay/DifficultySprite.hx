package objects.freeplay;

/**
 * The sprite for the difficulty
 */
// @:nullSafety
class DifficultySprite extends FlxSpriteGroup
{
    public var difficultyId:String;

    public var sprite:FlxSprite;
    public var text:FlxText;

    public var arrowLeft:FlxSprite;
    public var arrowRight:FlxSprite;

    var _baseX:Float = 0;

    public function new(diffId:String, x:Float, y:Float) {
        super();

        sprite = new FlxSprite(x,y);
        sprite.antialiasing = ClientPrefs.data.antialiasing;
        add(sprite);

        text = new FlxText(x, y-16, 0, '', 16);
        text.setFormat(Paths.font("phantomMuff.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);// phantomMuff fits better for the this
        text.antialiasing = ClientPrefs.data.antialiasing;
		add(text);

        arrowLeft = new FlxSprite(x, y-10);
        arrowLeft.frames = Paths.getSparrowAtlas("freeplay/freeplaySelector");
        arrowLeft.animation.addByPrefix("idle", "arrow pointer loop", 24, true);
        arrowLeft.animation.play("idle");
        add(arrowLeft);

        arrowRight = new FlxSprite(x, y-10);
        arrowRight.frames = Paths.getSparrowAtlas("freeplay/freeplaySelector");
        arrowRight.animation.addByPrefix("idle", "arrow pointer loop", 24, true);
        arrowRight.animation.play("idle");
        arrowRight.flipX = true;
        add(arrowRight);

        _baseX = x;

        updateSprite(diffId);
    }

    var _imageName:String = "";

    public function updateSprite(diffId:String, ?fromSide:String="center") {
        this.difficultyId = diffId;
        text.visible = false;

        var assetDiffId:String = diffId.toLowerCase();
        if ((!Paths.fileExists('images/freeplay/freeplay${assetDiffId}.png', IMAGE))) {
            // trace("Could not find difficulty asset:" + 'images/freeplay/freeplay${assetDiffId}.png');
            assetDiffId = "notfound"; // made it return this instead of tracing, so non terminal users can have a visual cue
            text.visible = true;
        }

        // Check for an XML to use an animation instead of an image.
        if (Paths.fileExists('images/freeplay/freeplay${assetDiffId}.xml', TEXT)) {
            sprite.frames = Paths.getSparrowAtlas('freeplay/freeplay${assetDiffId}');
            sprite.animation.addByPrefix('idle', 'idle0', 24, true);
            if (ClientPrefs.data.flashing) sprite.animation.play('idle');
        } else {
            sprite.loadGraphic(Paths.image('freeplay/freeplay' + assetDiffId));
            // trace('Loaded difficulty asset: freeplay/freeplay/${assetDiffId} (from ${diffId})');
        }

        sprite.updateHitbox();

        final _xPos = (_baseX*2.7) - (sprite.width/2);

        text.text = '($difficultyId)';
        text.x = (_baseX*2.7)- (text.width/2);

        arrowLeft.x = _xPos - arrowLeft.width - 5;
        arrowRight.x = _xPos + sprite.width + 5;

        if (fromSide == "center" || _imageName == assetDiffId) {
            sprite.x = _xPos;
            return;
        }

        FlxTween.cancelTweensOf(sprite);
        sprite.x = _xPos + (fromSide == "left" ? -500 - sprite.width : 500 + sprite.width); 
        FlxTween.tween(sprite, {x: _xPos}, 0.3, {ease: FlxEase.cubeOut});

        _imageName = assetDiffId;
    }
}