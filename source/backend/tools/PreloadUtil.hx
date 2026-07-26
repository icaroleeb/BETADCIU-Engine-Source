package backend.tools;

import states.PlayState;
import objects.Character;
import haxe.Json;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end

class PreloadUtil
{
    public static var isPreloading:Bool = false;
    public static var stagesToLoad:Array<String> = [];
    public static var charactersToLoad:Array<String> = [];
    public static var imagesToLoad:Array<String> = [];
    public static var soundsToLoad:Array<String> = [];

    public static function preload(?chars:Array<String>, ?images:Array<String>, ?stages:Array<String>, ?sounds:Array<String>) {
        if (chars != null) charactersToLoad = charactersToLoad.concat(chars);
        if (images != null) imagesToLoad = imagesToLoad.concat(images);
        if (stages != null) stagesToLoad = stagesToLoad.concat(stages);
        if (sounds != null) soundsToLoad = soundsToLoad.concat(sounds);

        charactersToLoad = CoolUtil.removeDupe(charactersToLoad);
        imagesToLoad = CoolUtil.removeDupe(imagesToLoad);
        stagesToLoad = CoolUtil.removeDupe(stagesToLoad);
        soundsToLoad = CoolUtil.removeDupe(soundsToLoad);

        if (charactersToLoad.length > 0) {
            var dummyChar:Character = null;
            for (char in charactersToLoad) {
                if (dummyChar == null) dummyChar = new Character(0, 0, char);
                else dummyChar.resetCharacter(0, 0, char);
                
                if (FlxG.state is PlayState) {
                    PlayState.instance.startCharacterScripts(char);
                    PlayState.instance.stopCharacterScripts(char);
                }
                trace(dummyChar.missingCharacter ? 'Failed to load character: $char' : 'Loaded character: $char');
            }
            if (dummyChar != null) dummyChar.destroy();
            charactersToLoad = [];
        }

        if ((FlxG.state is PlayState) && stagesToLoad.length > 0) {
            var ogStage = PlayState.instance.curStage;
            for (stage in stagesToLoad) {
                PlayState.instance.changeStage(stage, true);
                trace('Stage Loaded: $stage');
            }
            stagesToLoad = [];
            PlayState.instance.changeStage(ogStage, true); 
        }

        for (image in imagesToLoad) {
            Paths.image(image, ClientPrefs.data.cacheOnGPU);
        }
        imagesToLoad = [];

        for (sound in soundsToLoad) {
            Paths.sound(sound);
        }
        soundsToLoad = [];

        isPreloading = false;
    }

    public static function grabStuffToPreload() {
        var songPath:String = PlayState.instance.songName;
        
        var checkAndPush = function(path:String, list:Array<String>) {
            if (FileSystem.exists(path)) {
                var items = CoolUtil.coolTextFile(path);
                for (item in items) list.push(item.split(' ')[0]);
                isPreloading = true;
            }
        };

        checkAndPush(Paths.txt('$songPath/preload'), charactersToLoad);
        checkAndPush(Paths.txt('$songPath/preload-stage'), stagesToLoad);

        // JSON Parsing
        var jsonPath:String = Paths.json('$songPath/preload');
        if (FileSystem.exists(jsonPath)) {
            try {
                var content:String = Paths.getContent(jsonPath);
                var data:Dynamic = Json.parse(content);

                if (data.characters != null) charactersToLoad = charactersToLoad.concat(cast data.characters);
                if (data.stages != null) stagesToLoad = stagesToLoad.concat(cast data.stages);
                if (data.images != null) imagesToLoad = imagesToLoad.concat(cast data.images);
                if (data.sounds != null) soundsToLoad = soundsToLoad.concat(cast data.sounds);
                isPreloading = true;
            } catch (e:Dynamic) {
                trace("Error parsing JSON: " + e);
            }
        }
    }
}