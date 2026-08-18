package states.editors;

import objects.Note;
import objects.NoteSplash;
import objects.StrumNote;

import openfl.net.FileFilter;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import haxe.Json;

import haxe.ui.components.*;
import haxe.ui.containers.*;
import haxe.ui.core.Screen;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.backend.flixel.CursorHelper;
import haxe.ui.layouts.AbsoluteLayout;

import backend.Controls;

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/ui/splashEditor.xml"))
class NoteSplashEditorUI extends HBox {}

@:access(objects.NoteSplash)
class NoteSplashEditorState extends UIState // MUST EXTEND UI STATE needed for access to a root
{
    var strums:FlxTypedSpriteGroup<StrumNote> = new FlxTypedSpriteGroup();
    var splashes:FlxTypedSpriteGroup<NoteSplash> = new FlxTypedSpriteGroup();
    var config = NoteSplash.createConfig();

    var tipText:FlxText;
    var errorText:FlxText;
    var curText:FlxText;

    static var imageSkin:String = null;
    var splash:NoteSplash;

    var UI:NoteSplashEditorUI;

    override function create()
    {
        if (imageSkin == null)
            imageSkin =  NoteSplash.defaultNoteSplash;

        FlxG.mouse.visible = true;

        Conductor.bpm = 128.0;
		FlxG.sound.playMusic(Paths.music('offsetSong'), 1, true);

        #if DISCORD_ALLOWED
        DiscordClient.changePresence('Note Splash Editor');
        #end

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.scrollFactor.set();
        bg.color = 0xFF505050;
        add(bg);      

        for (i in 0...4)
        {
            var babyArrow:StrumNote = new StrumNote(-273, 50, i % 4, 1);
            babyArrow.playerPosition();
            babyArrow.screenCenter(Y);
            babyArrow.ID = i;
            babyArrow.texture = "NOTE_assets";
            babyArrow.updateHitbox();
            strums.add(babyArrow);
        }

        add(strums);
        add(splashes);

        splash = new NoteSplash(0, 0, imageSkin); // this cannot be recycled
        splash.inEditor = true;
        splash.alpha = .0;
        splashes.add(splash);

        if (splash.config != null)
            config = splash.config;

        parseRGB();

        buildUI();

        errorText = new FlxText();
        errorText.setFormat(null, 16, FlxColor.RED);
        errorText.text = "ERROR!";
        errorText.y = FlxG.height - errorText.height;
        errorText.alpha = .0;
        add(errorText);

        curText = new FlxText();
        curText.setFormat(null, 24, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        curText.text = 'Copied Offsets: [0, 0]\nCurrent Animation: NONE';
        curText.y = FlxG.height - curText.height;
        curText.x += 5;
        add(curText);

        super.create();
    }

    var nameInput:TextField;
    var prefixInput:TextField;
    var indicesInput:TextField;
	var isTextFieldFocused:Bool = false;

    var noteDataStepper:NumberStepper;

    function buildUI() {
        UI = new NoteSplashEditorUI();
        add(UI);
        UI.x = FlxG.width - 300;
        UI.y = 20;

        setupUIEvents();
        setAnimDropDown();
        
        var tip = new Label();
        tip.text = "Press F1 for Help";
        tip.styleString = "font-size: 20px;";
        tip.x = tip.y = 20;
        tip.textAlign = "right";
        add(tip);
    }

    function setupUIEvents() {
        // setting up the variables
        nameInput = UI.findComponent("nameInput", TextField);
        prefixInput = UI.findComponent("prefixInput", TextField);
        indicesInput = UI.findComponent("indicesInput", TextField);
        noteDataStepper = UI.findComponent("noteDataStepper", NumberStepper);
        var minFps = UI.findComponent("minFps", NumberStepper);
        var maxFps = UI.findComponent("maxFps", NumberStepper);
        animDropDown = UI.findComponent("animDropDown", DropDown);
        addButton = UI.findComponent("addButton", Button);
        var allowRGB = UI.findComponent("allowRGB", CheckBox);
        var allowPixel = UI.findComponent("allowPixel", CheckBox);
        scaleNumericStepper = UI.findComponent("scaleNumericStepper", NumberStepper);
        imageInputText = UI.findComponent("imageInputText", TextField);

        // setup
        imageInputText.text = imageSkin;
        allowRGB.selected = allowPixel.selected = true;

        // functions
        animDropDown.onChange = function(_) {
            var name = animDropDown.selectedItem;

            if (config != null && name != null) {
                var i = config.animations.get(name);
                if (i != null) {
                    nameInput.text = name;
                    prefixInput.text = i.prefix;
                    noteDataStepper.value = i.noteData;
                    minFps.value = i.fps[0];
                    maxFps.value = i.fps[1];
                    curAnim = name;

                    playStrumAnim(curAnim, i.noteData);
                }
            }
        };

        addButton.onClick = function(_) {
            var indices:Array<Int> = [];
            if (indicesInput.text.indexOf(",") != -1) {
                for (i in indicesInput.text.split(",")) {
                    var n = Std.parseInt(i);
                    if (n != null) indices.push(n);
                }
            }

            config = NoteSplash.addAnimationToConfig(
                config,
                scaleNumericStepper.value,
                nameInput.text,
                prefixInput.text,
                [Std.int(minFps.value), Std.int(maxFps.value)],
                [0, 0],
                indices,
                Std.int(noteDataStepper.value)
            );

            curAnim = nameInput.text;
            playStrumAnim(curAnim, Std.int(noteDataStepper.value));
            refreshDropdown();
        };

        UI.findComponent("removeButton", Button).onClick = function(_) {
            if (config != null && config.animations.exists(curAnim)) {
                config.animations.remove(curAnim);
                
                nameInput.text = "";
                prefixInput.text = "";
                indicesInput.text = "";
                noteDataStepper.value = 0;

                refreshDropdown();
            }
        };

        UI.findComponent("noteSkinReloadButton", Button).onClick = function(_) {
            for (strum in strums) {
                strum.texture = UI.findComponent("noteSkinInput", TextField).text;
                strum.updateHitbox();
            }
        };

        UI.findComponent("templateButton", Button).onClick = function(_) { // this is making all the animations vanish, but i'll assume that this is how it should be since the "createConfig" function actually wipes everything
            NoteSplash.configs.clear(); 
            config = NoteSplash.createConfig(); 

            curAnim = null;
            nameInput.text = "";
            prefixInput.text = "";        
            indicesInput.text = "";  
            noteDataStepper.value = 0;
            minFps.value = 22;
            maxFps.value = 26;
            
            setAnimDropDown();
            parseRGB();
        };

        reloadImage = function() {
            imageSkin = imageInputText.text;

            errorText.color = FlxColor.RED;
            FlxTween.cancelTweensOf(errorText);

            var image = Paths.image(imageSkin);
            if (image == null)
            {
                errorText.text = 'ERROR! Couldn\'t find $imageSkin.png';
                errorText.alpha = 1;
                return;
            }
            else
            {
                errorText.color = FlxColor.GREEN;
                errorText.alpha = 1;
                errorText.text = 'Succesfully loaded $imageSkin.png';
            }

            NoteSplash.configs.clear();

            FlxTween.tween(errorText, {alpha: 0}, 1, {startDelay: 1, onComplete: (twn) -> {
                errorText.color = FlxColor.RED;
            }});

            splash.loadSplash(imageSkin);
            splash.alpha = 0.0001;

            if (splash.config != null) config = splash.config;
            else config = NoteSplash.createConfig();

            curAnim = null;
            nameInput.text = "";
            prefixInput.text = "";        
            indicesInput.text = "";  
            noteDataStepper.value = 0;
            minFps.value = 22;
            maxFps.value = 26;
            setAnimDropDown();
            parseRGB();
            // shaderDropdown.selectedIndex = 0; 
            // shaderDropdown.dispatch(new haxe.ui.events.UIEvent(haxe.ui.events.UIEvent.CHANGE));  
        }

        UI.findComponent("imageReloadButton", Button).onClick = function(_) { reloadImage(); };
        UI.findComponent("saveButton", Button).onClick = function(_) { saveSplash(); };
        allowRGB.onChange = function(_) { if (config != null) config.allowRGB = allowRGB.selected; };
        allowPixel.onChange = function(_) { if (config != null) config.allowPixel = allowPixel.selected; };
    }

    function setAnimDropDown() {
        var anims:Array<String> = [];
        if (config != null && config.animations != null) 
            for (i in config.animations.keys()) anims.push(i);

        if (anims.length < 1) anims.push("");
        if (curAnim == null && anims[0].length > 0) curAnim = anims[0];

        var ds = new ArrayDataSource<String>();
        for (anim in anims) ds.add(anim);
        animDropDown.dataSource = ds;

        var selectedIndex = anims.indexOf(curAnim);
        if (selectedIndex >= 0) animDropDown.selectedIndex = selectedIndex;
        else animDropDown.selectedIndex = 0;
            
        if (anims[selectedIndex] != null) 
            animDropDown.text = anims[selectedIndex];

        animDropDown.dispatch(new haxe.ui.events.UIEvent(haxe.ui.events.UIEvent.CHANGE));
    }

    function refreshDropdown() {
        var list:Array<String> = [];
        if (config != null) for (k in config.animations.keys()) list.push(k);
        if (list.length == 0) list.push("");

        animDropDown.dataSource = makeDataSource(list);
        animDropDown.selectedItem = curAnim;
        animDropDown.dispatch(new haxe.ui.events.UIEvent(haxe.ui.events.UIEvent.CHANGE));
    }

    function makeDataSource(arr:Array<String>):ArrayDataSource<String> {
        var ds = new ArrayDataSource<String>();
        for (v in arr) ds.add(v);
        return ds;
    }

    var animDropDown:DropDown;
    var curAnim:String;
    var addButton:Button;
    var curAnimText = null;

    var imageInputText:TextField;
    var scaleNumericStepper:NumberStepper;

    var redEnabled:Bool = true;
    var blueEnabled:Bool = true;
    var greenEnabled:Bool = true;
    var redShader:Array<Int> = [0, 0, 0];
    var greenShader:Array<Int> = [0, 0, 0];
    var blueShader:Array<Int> = [0, 0, 0];

    dynamic function reloadImage() // Dynamic because needs to be changed later
    {
        //
    }

    var holdingArrowsTime:Float = 0;
    var holdingArrowsElapsed:Float = 0;
    var copiedOffset:Array<Float> = [0, 0];
    override function update(elapsed:Float)
    { 
        super.update(elapsed);
        ToolKitUtils.update();

        isTextFieldFocused = (ToolKitUtils.currentFocus != null);

        errorText.x = FlxG.width - errorText.width - 5;

        curText.text = 'Copied Offsets: ${Std.string(copiedOffset).replace(',', ', ')}\n';
        curText.text += 'Current Animation: ${curAnim == null || curAnim.length < 1  ? "NONE" : curAnim}';

        if (config != null && !curText.text.contains('NONE'))
        {
            var offsets:Array<Float> = try config.animations.get(curAnim).offsets catch (e) [0, 0];
            curText.text += ' ($offsets)'.replace(',', ', ');
        }

        if (config != null)
        {
            var currentAnim:String = nameInput != null ? nameInput.text : "";
            if (config.animations.exists(currentAnim) && config.animations.get(currentAnim) != null)
                addButton.text = 'Update';
            else
                addButton.text = 'Add';

            config.scale = scaleNumericStepper.value;
        }
        
    if (!isTextFieldFocused && config != null && config.animations != null && config.animations.exists(curAnim) && curAnim != null && curAnim.length > 0)
        {
            function splash()
            {
                if (config.animations.get(curAnim) != null)
                {
                    playStrumAnim(curAnim, config.animations.get(curAnim).noteData);
                    FlxTween.cancelTweensOf(errorText);
                    errorText.alpha = 0;
                }
            }

            var changedOffset = false;
            if (FlxG.keys.pressed.CONTROL && config.animations.get(curAnim) != null)
            {
                if (FlxG.keys.justPressed.C)
                {
                    copiedOffset = config.animations.get(curAnim).offsets.copy();
                }
                else if (FlxG.keys.justPressed.V)
                {
                    var conf = config.animations.get(curAnim);
                    conf.offsets = copiedOffset.copy(); 
                    config.animations.set(curAnim, conf);
                    changedOffset = true;
                }
                else if(FlxG.keys.justPressed.R)
                {
                    var conf = config.animations.get(curAnim);
                    conf.offsets = [0, 0];
                    config.animations.set(curAnim, conf);
                    changedOffset = true;
                }
            }

            var multiplier:Int = (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER)) ? 10 : 1;

            var moveKeysP = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
            if(moveKeysP.contains(true))
            {
                config.animations[curAnim].offsets[0] += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * multiplier;
                config.animations[curAnim].offsets[1] += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * multiplier;
                changedOffset = true;
            }
    
            var moveKeys = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
            if(moveKeys.contains(true))
            {
                holdingArrowsTime += elapsed;
                if(holdingArrowsTime > 0.6)
                {
                    holdingArrowsElapsed += elapsed;
                    while(holdingArrowsElapsed > (1/60))
                    {
                        config.animations[curAnim].offsets[0] += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * multiplier;
                        config.animations[curAnim].offsets[1] += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * multiplier;
                        holdingArrowsElapsed -= (1/60);
                        changedOffset = true;
                    }
                }
            }
            else holdingArrowsTime = 0;

            if(changedOffset || FlxG.keys.justPressed.SPACE) splash();
        }

        if (!isTextFieldFocused)
        {
            FlxG.sound.muteKeys = [FlxKey.ZERO];
            FlxG.sound.volumeDownKeys = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
            FlxG.sound.volumeUpKeys = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

            if (controls.BACK)
                MusicBeatState.switchState(new MasterEditorMenu());
            if (FlxG.keys.justPressed.F1)
                openSubState(new NoteSplashEditorHelpSubState());
        } else {
            FlxG.sound.muteKeys = [];
            FlxG.sound.volumeDownKeys = [];
            FlxG.sound.volumeUpKeys = [];
        }

        if (FlxG.mouse.overlaps(strums))
        {
            strums.forEach(function(strum:StrumNote)
            {
                if (FlxG.mouse.overlaps(strum))
                {
                    if (!FlxG.mouse.justPressed)
                    {
                        if (strum.animation.curAnim.name != 'pressed' && strum.animation.curAnim.name != 'confirm')
                            strum.playAnim('pressed');
                    }
                    else
                    {
                        strum.playAnim('confirm', true);
                        //strum.holdTimer = Math.POSITIVE_INFINITY;

                        var splash:NoteSplash = new NoteSplash(0, 0, imageSkin);
                        splash.inEditor = true;
                        splash.config = config;
                        splash.babyArrow = strum;
                        splash.spawnSplashNote(0, 0, strum.ID % 4);
                        splashes.add(splash);
                    }
                }
                else strum.playAnim('static');
            });
        }
        else
        {
            for (strum in strums)
                strum.playAnim('static');
        }
    }

    function playStrumAnim(?name:String, noteData:Int)
    {
        var splash:NoteSplash = new NoteSplash(0, 0, imageSkin);
        splash.inEditor = true;
        splash.config = config;
        if (noteData < 0) noteData = 0;

        if (name != null && splash.animation.exists(name))
        {
            splash.babyArrow = strums.members[noteData % 4];
            splash.spawnSplashNote(0, 0, noteData, null, false);
            splash.alpha = 1;
            splashes.add(splash);
        }
        else
        {
            errorText.alpha = 1;
            errorText.text = "ERROR while playing splash";
            
            FlxTween.cancelTweensOf(errorText);
            FlxTween.tween(errorText, {alpha: 0}, {startDelay: 1});
        }
    }

    function resetRGB()
    {
        redShader = [0, 0, 0];
        greenShader = [0, 0, 0];
        blueShader = [0, 0, 0];
    }

    function parseRGB()
    {
        resetRGB();
        if (config.rgb != null)
            for (i in 0...config.rgb.length)
            {
                if (i > 2) break;

                var rgb = config.rgb[i];
                if (rgb == null)
                { 
                    if (i == 0)
                        redEnabled = false;
                    else if (i == 1)
                        greenEnabled = false;
                    else if (i == 2)
                        blueEnabled = false;

                    continue;
                }
                else
                {
                    if (i == 0)
                        redEnabled = true;
                    else if (i == 1)
                        greenEnabled = true;
                    else if (i == 2)
                        blueEnabled = true;
                }
                
                var colors = [rgb.r, rgb.g, rgb.b];
                if (i == 0)
                    redShader = colors;
                else if (i == 1)
                    greenShader = colors;
                else if (i == 2)
                    blueShader = colors;
            }
        else
        {
            resetRGB(); 
            redEnabled = blueEnabled = greenEnabled = false;
        }
    }

    function setConfigRGB()
    {
        if (config == null)
            config = NoteSplash.createConfig();
        
        if (!redEnabled && !greenEnabled && !blueEnabled)
        {
            config.rgb = null;
            return;
        }

        config.rgb = [];

        if (redEnabled)
            config.rgb.push({r: redShader[0], g: redShader[1], b: redShader[2]});
        else
            config.rgb.push(null);

        if (greenEnabled)
            config.rgb.push({r: greenShader[0], g: greenShader[1], b: greenShader[2]});
        else
            config.rgb.push(null);

        if (blueEnabled)
            config.rgb.push({r: blueShader[0], g: blueShader[1], b: blueShader[2]});
        else
            config.rgb.push(null);
    }

    var _file:FileReference;
    function onSaveComplete(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.notice("Successfully saved file.");
    }

    /**
     * Called when the save file dialog is cancelled.
     */
    function onSaveCancel(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
    }

    /**
     * Called if there is an error while saving the gameplay recording.
     */
    function onSaveError(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.error("Problem saving file");
    }

    function saveSplash()
    {
        // imageSkin = imageInputText.text;
        var data:String = Json.stringify(config, "\t");
        if (data.length > 0)
        {
            _file = new FileReference();
            _file.addEventListener(Event.COMPLETE, onSaveComplete);
            _file.addEventListener(Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
            _file.save(data, imageSkin + ".json");
        }
    }

    public function loadTxt()
    {
        var jsonFilter:FileFilter = new FileFilter('Select a note splash TXT', '*.txt');
        _file = new FileReference();
        _file.addEventListener(Event.SELECT, onLoadComplete);
        _file.addEventListener(Event.CANCEL, onLoadCancel);
        _file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        _file.browse([jsonFilter]);
    }

    function onLoadComplete(_):Void
    {
        _file.removeEventListener(Event.SELECT, onLoadComplete);
        _file.removeEventListener(Event.CANCEL, onLoadCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

        try 
        {
            var txtLoaded:Dynamic = Json.parse(Json.stringify(_file));
            var txt:String = null;
            var file:String = "config.json";
            #if MODS_ALLOWED
            if (txtLoaded.__path != null)
            {
                try txt = File.getContent(txtLoaded.__path) catch (e) txt = null;
                file = txtLoaded.__path;
                file = file.substring(0, file.length - 4) + ".json";
            }

            var conf = parseTxt(txt);
            _file = new FileReference();
            _file.addEventListener(Event.COMPLETE, onSaveComplete);
            _file.addEventListener(Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
            _file.save(Json.stringify(conf, "\t"), file);
            #end
        }
        catch (e)
        {
            trace(e.stack);
        }
    }

    /**
     * Called when the save file dialog is cancelled.
     */
    function onLoadCancel(_):Void
    {
        _file.removeEventListener(Event.SELECT, onLoadComplete);
        _file.removeEventListener(Event.CANCEL, onLoadCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        _file = null;
        trace("Cancelled file loading.");
    }

    /**
     * Called if there is an error while saving the gameplay recording.
     */
    function onLoadError(_):Void
    {
        _file.removeEventListener(Event.SELECT, onLoadComplete);
        _file.removeEventListener(Event.CANCEL, onLoadCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        _file = null;
        trace("Problem loading file");
    }

    override function destroy()
    {
        NoteSplash.configs.clear();
        super.destroy();

        FlxG.sound.playMusic(Paths.music('freakyMenu'));

        // FlxG.sound.music.volume = 1;
        // FlxG.sound.muteKeys = [FlxKey.ZERO];
        // FlxG.sound.volumeDownKeys = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
        // FlxG.sound.volumeUpKeys = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
    }

    public static function parseTxt(content:String):NoteSplashConfig
    {
        var config = NoteSplash.createConfig();
        if (content == null)
            return config;

        var trim:String = content.trim();
        if (trim.length < 1) // empty txt
            return config;

        var configs = content.split('\n');
        // checks for empty txts
        if (configs.length < 2 || configs[0].trim() == "")
            return config;

        var animation:String = configs[0].rtrim();
        var fps:Array<Null<Int>> = [22, 26];
        if (configs[1] != null && configs[1].trim() != "")
        {
            var newFps = configs[1].trim().split(" ");
            fps = [Std.parseInt(newFps[0]), Std.parseInt(newFps[1])];
            if (fps[0] == null) fps[0] = 22;
            if (fps[1] == null) fps[1] = 26;
        }

        var offsets:Array<Array<Null<Float>>> = [[0, 0]];
        if (configs.length > 2)
        {
            offsets = [];
            for (i in 2...configs.length)
            {
                var offset = configs[i].trim();
                if (offset != "")
                {
                    var offset:Array<String> = offset.split(" ");
                    var x:Float = Std.parseFloat(offset[0]);
                    var y:Float = Std.parseFloat(offset[1]);
                    if (Math.isNaN(x)) x = 0;
                    if (Math.isNaN(y)) y = 0;
                    offsets.push([x, y]);
                }
            }
        }

        var i = 0;
        var k = 1;
        while (true)
        {
            for (col in Note.colArray)
            {
                var anim = k <= 1 ? col : '$col' + k;
                var offset = offsets[FlxMath.wrap(i, 0, Std.int(offsets.length - 1))];

                config = NoteSplash.addAnimationToConfig(config, 1, anim, '$animation $col $k', fps, offset, [], i);
                i++;
            }
            if (offsets[i] == null) break;
            k++;
        }

        return config;
    }
}


class NoteSplashEditorHelpSubState extends MusicBeatSubstate
{
    public function new()
    {
        super();

        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.6;
        add(bg);

        var str:Array<String> = ["Click on a Strum or Press Space",
        "to spawn a Splash",
        "",
        "Arrow Keys - Move Offset",
        "Hold Shift - Move Offsets 10x faster",
        "",
        "Ctrl + C - Copy Current Offset",
        "Ctrl + V - Paste Copied Offset on Current Splash",
        "Ctrl + R - Reset Current Offset",
        "",
        "On every 4 subsequent note datas",
        "an extra set of animations will be added"];

        var helpTexts:FlxSpriteGroup = new FlxSpriteGroup();
        for (i => txt in str)
        {
            if(txt.length < 1) continue;

            var helpText:FlxText = new FlxText(0, 0, 0, txt, 24);
            helpText.setFormat(null, 24, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
            helpText.borderColor = FlxColor.BLACK;
            helpText.scrollFactor.set();
            helpText.borderSize = 1;
            helpText.screenCenter();
            add(helpText);
            helpText.y += ((i - str.length/2) * 32) + 16;
            helpTexts.add(helpText);
        }
        add(helpTexts);

        var noteDataText:FlxText = new FlxText();
        noteDataText.setFormat(null, 24, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
        noteDataText.text = "NOTE DATAS:\nLEFT: 0\nDOWN: 1\nUP: 2\nRIGHT: 3";
        noteDataText.x = FlxG.width - noteDataText.width - 5;
        noteDataText.y = FlxG.height - noteDataText.height - 5;

        add(noteDataText);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (controls.BACK || FlxG.keys.justPressed.F1)
            close();
    }
}