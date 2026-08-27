package objects.freeplay;

import flixel.util.FlxDestroyUtil;

class SongCapsule extends FlxSpriteGroup
{
    public var capsule:FlxSprite;
    public var icon:HealthIcon;
    public var songText:CapsuleText;

    public var targetY:Int = 0;
    public var startPosition:FlxPoint = FlxPoint.get();
    public var distancePerItem:FlxPoint = FlxPoint.get(0, 120);

    public var targetPos:FlxPoint = FlxPoint.get();
    public var doLerp:Bool = false;

    var bpmText:FlxSprite;
    var difficultyText:FlxSprite;
    var weekText:FlxSprite;
    var bpmNumbers:Array<CapsuleNumber> = [];
    var difficultyNumbers:Array<CapsuleNumber> = [];

    public var selected(default, set):Bool = false;

    public var realScaled:Float = 0.8;

    public function new(x:Float, y:Float, songName:String, character:String, bpm:Int, difficultyRating:Int, weekName:String)
    {
        super(x, y);
        final _antialias = ClientPrefs.data.antialiasing; 

        capsule = new FlxSprite();
        capsule.frames = Paths.getSparrowAtlas('freeplay/freeplayCapsule/capsule/freeplayCapsule');
        capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
        capsule.animation.addByPrefix('unselected', 'mp3 capsule w backing NOT SELECTED', 24);
        capsule.animation.play('unselected');
        capsule.antialiasing = _antialias;
        capsule.scale.set(realScaled, realScaled);
        add(capsule);

        bpmText = new FlxSprite(144, 87).loadGraphic(Paths.image('freeplay/freeplayCapsule/bpmtext'));
        bpmText.setGraphicSize(Std.int(bpmText.width * 0.9));
        bpmText.antialiasing = _antialias;
        add(bpmText);

        difficultyText = new FlxSprite(414, 87).loadGraphic(Paths.image('freeplay/freeplayCapsule/difficultytext'));
        difficultyText.setGraphicSize(Std.int(difficultyText.width * 0.9));
        difficultyText.antialiasing = _antialias;
        add(difficultyText);

        weekText = new FlxSprite(291, 88);
        weekText.scale.set(0.9, 0.9);
        weekText.visible = false;
        weekText.active = false;
        weekText.antialiasing = _antialias;
        add(weekText);

        createWeekTextGraphic(weekName);
        weekText.loadGraphic(FlxG.bitmap.get(weekName));

        for (i in 0...2)
        {
            var num:CapsuleNumber = new CapsuleNumber(466 + (i * 30), 32, true, 0);
            num.antialiasing = _antialias;
            add(num);
            difficultyNumbers.push(num);
        }

        for (i in 0...3)
        {
            var num:CapsuleNumber = new CapsuleNumber(185 + (i * 11), 88.5, false, 0);
            num.antialiasing = _antialias;
            add(num);
            bpmNumbers.push(num);
        }

        // TODO: a system to detect and switch the regular icon for the pixelated one
        icon = new HealthIcon(character);
        icon.setPosition(30, -15);
        icon.antialiasing = _antialias;
        add(icon);

        songText = new CapsuleText(capsule.width * 0.26, 35, 'Random', Std.int(40 * realScaled));
        songText.clipWidth = 290;
        songText.text = songName;
        songText.updateHitbox();
        songText.resetText();
        add(songText);

        icon.setGraphicSize(Std.int(icon.width * 0.6), Std.int(icon.height * 0.6));

        startPosition.set(x, y);
        targetPos.set(x, y);

        updateBPM(bpm);
        updateDifficultyRating(difficultyRating);
    }

    public function updateBPM(newBPM:Int):Void
    {
        var shiftX:Float = 191;
        var tempShift:Float = 0;

        if (Math.floor(newBPM / 100) == 1) shiftX = 186;

        for (i in 0...bpmNumbers.length) {
            bpmNumbers[i].x = this.x + (shiftX + (i * 11));
            switch (i) {
                case 0:
                    bpmNumbers[i].digit = (newBPM < 100) ? 0 : Math.floor(newBPM / 100) % 10;
                case 1:
                    bpmNumbers[i].digit = (newBPM < 10) ? 0 : Math.floor(newBPM / 10) % 10;
                    if (newBPM < 10) tempShift = 0;
                    else if (Math.floor(newBPM / 10) % 10 == 1) tempShift = -4;
                case 2:
                    bpmNumbers[i].digit = newBPM % 10;
                    if (newBPM % 10 == 1) tempShift -= 4;
            }
            bpmNumbers[i].x += tempShift;
        }
    }

    public function updateDifficultyRating(newRating:Int):Void
    {
        for (i in 0...difficultyNumbers.length)
        {
            switch (i)
            {
                case 0: difficultyNumbers[i].digit = (newRating < 10) ? 0 : Math.floor(newRating / 10);
                case 1: difficultyNumbers[i].digit = newRating % 10;
            }
        }
    }

    public function intendedX(index:Float):Float {
        return 270 + (60 * (FlxMath.fastSin(index)));
    }

    public function intendedY(index:Float):Float {
        return (index * ((capsule.height * realScaled) + 10) + (120 * 2));
    }

    function createWeekTextGraphic(text:String) {
        if (FlxG.bitmap.checkCache(text)) return;

        var weekTextBase:FlxText = new FlxText(0, 0, 0, text).setFormat("YoureGone-Regular", 20, 0xFF21242E);
        @:privateAccess weekTextBase.regenGraphic();

        FlxG.bitmap.add(weekTextBase.pixels.clone(), false, text);
    }

    function set_selected(value:Bool):Bool
    {
        final wasSelected:Bool = selected;
        selected = value;

        if (wasSelected != selected)
            updateSelected();

        return selected;
    }

    public function updateSelected():Void
    {
        final isSelected:Bool = (this.selected);

        songText.alpha = isSelected ? 1 : 0.6;
        songText.blurredText.visible = isSelected ? true : false;
        capsule.offset.x = isSelected ? 0 : -5;
        capsule.animation.play(isSelected ? 'selected' : 'unselected');
        // ranking.alpha = isSelected ? 1 : 0.7;
        // favIcon.alpha = isSelected ? 1 : 0.6;
        // favIconBlurred.alpha = isSelected ? 1 : 0;
        // ranking.color = isSelected ? 0xFFFFFFFF : 0xFFAAAAAA;

        if (songText.tooLong) songText.resetText();

        if (selected && songText.tooLong) songText.initMove();
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);


        if (doLerp) {
            x = FlxMath.lerp(targetPos.x, x, Math.exp(-elapsed * 12));
            // y = FlxMath.lerp(targetPos.y, y, Math.exp(-elapsed * 12));

            if (Math.abs(x - targetPos.x) <= 0.5) x = targetPos.x;
            // if (Math.abs(y - targetPos.y) <= 0.5) y = targetPos.y;
        }
    }

    override function destroy():Void
    {
        startPosition = FlxDestroyUtil.put(startPosition);
        distancePerItem = FlxDestroyUtil.put(distancePerItem);
        targetPos = FlxDestroyUtil.put(targetPos);
        super.destroy();
    }
}

class CapsuleNumber extends FlxSprite
{
    public var digit(default, set):Int = 0;

    function set_digit(val):Int
    {
        animation.play(numToString[val], true, false, 0);
        centerOffsets(false);

        switch (val)
        {
            case 1: offset.x -= 4;
            case 3: offset.x -= 1;
            default: centerOffsets(false);
        }
        return val;
    }

    var numToString:Array<String> = ['ZERO','ONE','TWO','THREE','FOUR','FIVE','SIX','SEVEN','EIGHT','NINE'];

    public function new(x:Float, y:Float, big:Bool = false, ?initDigit:Int = 0)
    {
        super(x, y);

        frames = Paths.getSparrowAtlas(big ? 'freeplay/freeplayCapsule/bignumbers' : 'freeplay/freeplayCapsule/smallnumbers');

        for (i in 0...10)
        {
            var stringNum:String = numToString[i];
            animation.addByPrefix(stringNum, '$stringNum', 24, false);
        }

        this.digit = initDigit;
        animation.play(numToString[initDigit], true);

        setGraphicSize(Std.int(width * 0.9));
        updateHitbox();
    }
}