package options;

import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxG;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.FlxCamera;
import openfl.utils.Assets;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;

import psychlua.FunkinLua;
import psychlua.DebugLuaText;

import objects.Character;
import objects.Character.CharacterFile;
import backend.Song.SwagSong;
import backend.StageData.StageFile;

using StringTools;

class ModpackMakerState extends MusicBeatState {
    private var camEditor:FlxCamera;
    private var camHUD:FlxCamera;
    private var camMenu:FlxCamera;

    public var camFollow:FlxObject;
    var UI_box:PsychUIBox;

    var directoryDropDown:PsychUIDropDownMenu;
    var songDirectoryDropDown:PsychUIDropDownMenu;

    var swagDirectory:String;
    var swagSongDirectory:String;
    var swagSuf:String = "";
    var songIsBETADCIU:Bool = false;

    private var blockPressWhileScrolling:Array<Dynamic> = [];

    public var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

    public function new() {
        super();
    }

    override function create() {
        camEditor = initPsychCamera();

        camHUD = new FlxCamera();
        camHUD.bgColor.alpha = 0;
        camMenu = new FlxCamera();
        camMenu.bgColor.alpha = 0;

        FlxG.cameras.add(camHUD, false);
        FlxG.cameras.add(camMenu, false);

        luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
        add(luaDebugGroup);
        luaDebugGroup.cameras = [camMenu];

        setupBackgroundAndTitle();

        camFollow = new FlxObject(0, 0, 2, 2);
        camFollow.screenCenter();
        add(camFollow);

        FlxG.camera.follow(camFollow);

        UI_box = new PsychUIBox(FlxG.width - 360, 25, 350, 350, ['Setup']);
        UI_box.scrollFactor.set(1, 1);
        UI_box.cameras = [camMenu];
        add(UI_box);

        addSetupUI();
        UI_box.selectedName = 'Setup';

        FlxG.mouse.visible = true;
        reloadSetupOptions();

        new ModpackAssetRegistry();

        super.create();
    }

    private function setupBackgroundAndTitle():Void {
        var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = 0xFFea71fd;
        bg.screenCenter();
        bg.antialiasing = ClientPrefs.data.antialiasing;
        add(bg);

        var titleText = createText("MODPACK MAKER!!!", 50, 50, 48, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, 3, camMenu);
        add(titleText);

        var descText = createText(
            "A helpful tool that allows you to make Modpacks from Master Folders.",
            50, 600, 32, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, 2.4, null
        );
        descText.width = 1180;
        descText.scrollFactor.set();
        descText.screenCenter();
        descText.y += 270;
        add(descText);
    }

    private function createText(text:String, x:Float, y:Float, size:Int, color:FlxColor, borderStyle:FlxTextBorderStyle, borderSize:Float, cam:FlxCamera):FlxText {
        var txt = new FlxText(x, y, 0, text, size);
        txt.setFormat(Paths.font("vcr.ttf"), size, color, CENTER, borderStyle, FlxColor.BLACK);
        txt.borderSize = borderSize;
        if (cam != null) txt.cameras = [cam];
        return txt;
    }

    function addSetupUI():Void {
        var tabGroup = UI_box.getTab("Setup").menu;

        directoryDropDown = new PsychUIDropDownMenu(15, 45, [''], onDirectorySelected);
        blockPressWhileScrolling.push(directoryDropDown);

        songDirectoryDropDown = new PsychUIDropDownMenu(directoryDropDown.x + 170, 45, [''], onSongDirectorySelected);
        blockPressWhileScrolling.push(songDirectoryDropDown);

        var createButton = new FlxButton(directoryDropDown.x, 275, "Create Modpack", copyAndWriteFiles);
        createButton.setGraphicSize(80, 30);
        createButton.updateHitbox();

        tabGroup.add(new FlxText(directoryDropDown.x, directoryDropDown.y - 18, 0, 'Mod Directory:'));
        tabGroup.add(new FlxText(songDirectoryDropDown.x, songDirectoryDropDown.y - 18, 0, 'Song Directory:'));

        for (item in [directoryDropDown, songDirectoryDropDown, createButton])
            tabGroup.add(item);
    }

    private function onDirectorySelected(selected:Int, pressed:String):Void {
        swagDirectory = directoryDropDown.selectedLabel;
        Mods.currentModDirectory = swagDirectory;
        reloadDirectoryDropDown("data");
    }

    private function onSongDirectorySelected(selected:Int, pressed:String):Void {
        swagSongDirectory = songDirectoryDropDown.selectedLabel;
    }

    function copyAndWriteFiles():Void {
        for (dataType in ["data", "songs"]) {
            var folder = Paths.modFolders(swagDirectory + "/" + dataType + "/" + swagSongDirectory + "/");
            var modpackFolder = Paths.modFolders("Da Modpack/" + dataType + "/" + swagSongDirectory + "/");
            processFolder(folder, modpackFolder, dataType);
        }

        ModpackAssetRegistry.instance.processAll(swagDirectory);
        createWeekFile();
    }

    function createWeekFile():Void {
        var weeksPath = Paths.modFolders("Da Modpack/weeks");
        if (!FileSystem.exists(weeksPath)) FileSystem.createDirectory(weeksPath);

        if (!songIsBETADCIU) return;

        var folder = Paths.modFolders(swagDirectory + "/data/" + swagSongDirectory + "/");
        var p2Icon = "bf";
        var p2HC:Array<Int> = [0, 0, 0];
        var daSongName = "tutorial";

        for (file in FileSystem.readDirectory(folder)) {
            if (file.endsWith("-hard.json") && file.startsWith(swagSongDirectory)) {
                var path = folder + file;
                var rawJson = FileSystem.exists(path) ? File.getContent(path).trim() : Assets.getText(path).trim();
                var json:SwagSong = cast Json.parse(rawJson).song;

                if (json.player2 != null) {
                    var charData = loadCharacterFile(json.player2);
                    if (charData != null) {
                        p2Icon = charData.healthicon;
                        p2HC = charData.healthbar_colors;
                    }
                }
                daSongName = json.song;
            }
        }

        var templateWeek = 
            '{ "storyName": "WEEK FILE", "hideFreeplay": false, "weekBackground": "bruh", "difficulties": "Hard", ' +
            '"weekBefore": "tutorial", "startUnlocked": true, "weekCharacters": ["", "bf", ""], "songs": [[' +
            '"' + daSongName + '", "' + p2Icon + '", ' + p2HC + ']], "hideStoryMode": false, "weekName": "' + swagSongDirectory + ' BETADCIU" }';

        File.saveContent(weeksPath + "/" + swagSongDirectory + "-betadciu.json", templateWeek);
    }

    private function loadCharacterFile(characterId:String):CharacterFile {
        var path = Paths.getPath('images/characters/jsons/' + characterId + '.json', TEXT);
        #if MODS_ALLOWED
        if (FileSystem.exists(Paths.modFolders('characters/' + characterId + '.json')) || Assets.exists(Paths.modFolders('characters/' + characterId + '.json')))
            path = Paths.modFolders('characters/' + characterId + '.json');
        #end
        if (!FileSystem.exists(path) && !Assets.exists(path)) {
            path = Paths.getPath('images/characters/jsons/' + Character.DEFAULT_CHARACTER + ".json", TEXT);
        }
        var rawJson = FileSystem.exists(path) ? File.getContent(path) : Assets.getText(path);
        return cast Json.parse(rawJson);
    }

    function processFolder(folder:String, modpackFolder:String, dataType:String):Void {
        if (!FileSystem.exists(modpackFolder)) FileSystem.createDirectory(modpackFolder);

        for (file in FileSystem.readDirectory(folder)) {
            var initPath = folder + file;
            var modifiedPath = modpackFolder + file;

            if (FileSystem.isDirectory(initPath)) {
                processFolder(initPath + "/", modifiedPath + "/", dataType);
                continue;
            }

            if (file.endsWith('.lua')) {
                var openLua = new FunkinLua(initPath, "modpack");
                openLua.call("onCreate", []);
                openLua.call("onCreatePost", []);
            }

            if (dataType == "data") {
                processDataFile(file, initPath);
            }

            sys.io.File.copy(initPath, modifiedPath);
        }
    }

    private function processDataFile(file:String, initPath:String):Void {
        if (file.endsWith("-hard.json") && file.startsWith(swagSongDirectory)) {
            var rawJson = FileSystem.exists(initPath) ? File.getContent(initPath).trim() : Assets.getText(initPath).trim();
            var json:SwagSong = cast Json.parse(rawJson).song;

            copyNoteStyleAssets(json.noteStyle);
            copyEventAssets(json.events);
            copyNoteTypeAssets(json.notes);
        }

        if (file == 'arrowSwitches.txt') {
            copyArrowSwitches(initPath);
        }

        if (file == "preload" + swagSuf + ".txt") {
            copyCharacterAssets(initPath);
        }

        if (file == "preload-stage" + swagSuf + ".txt") {
            copyStageAssets(initPath);
        }

		 if (file == "preload" + swagSuf + ".json") {
            processPreloadAssets(initPath);
        }
    }

	private function processPreloadAssets(initPath:String):Void {
		if (!FileSystem.exists(initPath)) return;

		try {
			var rawJson = File.getContent(initPath).trim();
			var preloadData:Dynamic = Json.parse(rawJson);

			// Handle characters (expects array of strings: character names)
			if (Reflect.hasField(preloadData, "characters")) {
				var chars:Array<String> = cast preloadData.characters;
				for (charName in chars) {
					copyCharacterFromName(charName);
				}
			}

			// Handle images (expects array of paths)
			if (Reflect.hasField(preloadData, "images")) {
				var images:Array<String> = cast preloadData.images;
				for (image in images) {
					ModpackAssetRegistry.instance.addAsset("images", image);
				}
			}

			// Handle sounds (expects array of paths)
			if (Reflect.hasField(preloadData, "sounds")) {
				var sounds:Array<String> = cast preloadData.sounds;
				for (sound in sounds) {
					ModpackAssetRegistry.instance.addAsset("sounds", sound);
				}
			}

			// Handle fonts
			if (Reflect.hasField(preloadData, "fonts")) {
				var fonts:Array<String> = cast preloadData.fonts;
				for (font in fonts) {
					ModpackAssetRegistry.instance.addAsset("fonts", font);
				}
			}

			// Handle videos
			if (Reflect.hasField(preloadData, "videos")) {
				var videos:Array<String> = cast preloadData.videos;
				for (vid in videos) {
					ModpackAssetRegistry.instance.addAsset("videos", vid);
				}
			}

			// Handle shaders
			if (Reflect.hasField(preloadData, "shaders")) {
				var shaders:Array<String> = cast preloadData.shaders;
				for (shader in shaders) {
					ModpackAssetRegistry.instance.addAsset("shaders", shader);
				}
			}

			// Handle stages
			if (Reflect.hasField(preloadData, "stages")) {
				var stages:Array<String> = cast preloadData.stages;
				for (stageName in stages) {
					copyStageFromName(stageName);
				}
			}

		} catch (e:Dynamic) {
			trace("Error processing preload file: " + e);
		}
	}


    private function copyNoteStyleAssets(noteStyle:String):Void {
        if (noteStyle == null || noteStyle.length == 0) return;

        var noteFolder = Paths.modFolders(swagDirectory + "/images/notes/");
        var noteModpackFolder = Paths.modFolders("Da Modpack/images/notes/");
        doCopyShit(noteFolder, noteModpackFolder, [
            noteStyle + ".png",
            noteStyle + ".xml",
            noteStyle + "ENDS.png",
            "noteSplashes-" + noteStyle + ".png",
            "noteSplashes-" + noteStyle + ".xml"
        ]);
    }

    private function copyEventAssets(events:Array<Dynamic>):Void {
        if (events == null || events.length == 0) return;

        var pushedEvents:Array<String> = [];
        for (event in events) {
            for (i in 0...event[1].length) {
                var evName = Std.string(event[1][i][0]);
                if (pushedEvents.indexOf(evName) < 0) pushedEvents.push(evName);
            }
        }

        var eventFolder = Paths.modFolders(swagDirectory + "/custom_events/");
        var eventModpackFolder = Paths.modFolders("Da Modpack/custom_events/");
        var evCopyArray:Array<String> = [];

        for (ev in pushedEvents) {
            var luaPath = Paths.modFolders("custom_events/" + ev + ".lua");
            if (FileSystem.exists(luaPath)) {
			
                var openLua = new FunkinLua(luaPath, "modpack");
                openLua.call("onCreate", []);
                openLua.call("onCreatePost", []);
            }
            evCopyArray.push(ev + ".txt");
            evCopyArray.push(ev + ".lua");
        }
        doCopyShit(eventFolder, eventModpackFolder, evCopyArray);
    }

    private function copyNoteTypeAssets(notes:Array<Dynamic>):Void {
		if (notes == null || notes.length == 0) return;

        var pushedNoteTypes:Array<String> = [];
        for (section in notes) {
			var sectionNotes:Array<Dynamic> = section.sectionNotes;

            for (songNotes in sectionNotes) {
                var noteType = songNotes[3];
                if (noteType != "" && pushedNoteTypes.indexOf(noteType) < 0) {
                    pushedNoteTypes.push(noteType);
                }
            }
        }

        if (pushedNoteTypes.length == 0) return;

        var ntCopyArray:Array<String> = [];
        var noteTypeFolder = Paths.modFolders(swagDirectory + "/custom_notetypes/");
        var noteTypeModpackFolder = Paths.modFolders("Da Modpack/custom_notetypes/");

        for (nt in pushedNoteTypes) {
            var luaPath = Paths.modFolders("custom_notetypes/" + nt + ".lua");
            if (FileSystem.exists(luaPath)) {
                var openLua = new FunkinLua(luaPath, "modpack");
                openLua.call("onCreate", []);
                openLua.call("onCreatePost", []);
            }
            ntCopyArray.push(nt + ".txt");
            ntCopyArray.push(nt + ".lua");
        }
        doCopyShit(noteTypeFolder, noteTypeModpackFolder, ntCopyArray);
    }

    private function copyArrowSwitches(initPath:String):Void {
        var stuff = CoolUtil.coolTextFile(initPath);
        var noteFolder = Paths.modFolders(swagDirectory + "/images/notes/");
        var noteModpackFolder = Paths.modFolders("Da Modpack/images/notes/");

        if (!FileSystem.exists(noteModpackFolder)) FileSystem.createDirectory(noteModpackFolder);
        if (stuff == null || stuff.length == 0) return;

        for (line in stuff) {
            var data = line.split(' ');
            var noteskinFolder = noteFolder + data[1] + "/";
            if (FileSystem.exists(noteskinFolder)) {
                copyDirectory(noteskinFolder, noteModpackFolder);
            }
            for (file in FileSystem.readDirectory(noteFolder)) {
                if (file == data[1] + ".png" || file == data[1] + ".xml" || file == data[1] + "ENDS.png" ||
                    file == "noteSplashes-" + data[1] + ".png" || file == "noteSplashes-" + data[1] + ".xml") {
                    sys.io.File.copy(noteFolder + file, noteModpackFolder + file);
                }
            }
        }
    }

    private function copyCharacterAssets(initPath:String):Void {
        var characters = CoolUtil.coolTextFile(initPath);
        var charFolder = Paths.modFolders(swagDirectory + "/characters/");
        var charModpackFolder = Paths.modFolders("Da Modpack/characters/");

        if (!FileSystem.exists(charModpackFolder)) FileSystem.createDirectory(charModpackFolder);

        songIsBETADCIU = characters.length >= 16;

       for (character in characters) {
			copyCharacterFromName(character);
		}
    }

    private function copyCharacterImages(json:CharacterFile):Void {
        for (folderName in ["characters", "icons"]) {
            var basePath = Paths.modFolders(swagDirectory + "/images/");
            var modpackPath = Paths.modFolders("Da Modpack/images/");
            var imagePath = (folderName == "icons") ? "icons/icon-" + json.healthicon : json.image;
            var parts = imagePath.split('/');

            for (i in 0...parts.length - 1) {
                basePath += parts[i] + "/";
                modpackPath += parts[i] + "/";
            }
            doCopyShit(basePath, modpackPath, [parts[parts.length - 1] + ".png", parts[parts.length - 1] + ".xml"]);
        }
    }

	private function copyCharacterFromName(name:String):Void {
		if (name.contains("-embed")) return;

		var charFolder = Paths.modFolders(swagDirectory + "/characters/");
		var charModpackFolder = Paths.modFolders("Da Modpack/characters/");
		if (!FileSystem.exists(charModpackFolder)) FileSystem.createDirectory(charModpackFolder);

		for (file in FileSystem.readDirectory(charFolder)) {
			if (file == name + ".json" || file == name + ".lua") {
				if (file.endsWith(".json")) {
					var rawJson = FileSystem.exists(charFolder + file) ? File.getContent(charFolder + file) : Assets.getText(charFolder + file);
					var json:CharacterFile = cast Json.parse(rawJson);
					copyCharacterImages(json);
				}
				if (file.endsWith(".lua")) {
					var openLua = new FunkinLua(charFolder + file, "modpack");
					openLua.call("onCreate", []);
					openLua.call("onCreatePost", []);
				}
				sys.io.File.copy(charFolder + file, charModpackFolder + file);
			}
		}
	}

    private function copyStageAssets(initPath:String):Void {
        var stages = CoolUtil.coolTextFile(initPath);
        var stageFolder = Paths.modFolders(swagDirectory + "/stages/");
        var stageModpackFolder = Paths.modFolders("Da Modpack/stages/");

        if (!FileSystem.exists(stageModpackFolder)) FileSystem.createDirectory(stageModpackFolder);

        for (stage in stages) {
			copyStageFromName(stage);
		}
    }

    private function copyStageRelatedAssets(stageData:StageFile):Void {
        if (stageData.ratingSkin != null) {
            copyRatingSkinAssets(stageData.ratingSkin);
        }
        if (stageData.countdownAssets != null) {
            for (asset in stageData.countdownAssets) {
                copyCountdownAsset(asset);
            }
        }
    }

	private function copyStageFromName(name:String):Void {
		if (name.contains("-embed")) return;

		var stageFolder = Paths.modFolders(swagDirectory + "/stages/");
		var stageModpackFolder = Paths.modFolders("Da Modpack/stages/");
		if (!FileSystem.exists(stageModpackFolder)) FileSystem.createDirectory(stageModpackFolder);

		for (file in FileSystem.readDirectory(stageFolder)) {
			if (file == name + ".json" || file == name + ".lua") {
				if (file.endsWith(".json")) {
					var rawJson = FileSystem.exists(stageFolder + file) ? File.getContent(stageFolder + file) : Assets.getText(stageFolder + file);
					var stageData:StageFile = cast Json.parse(rawJson);
					copyStageRelatedAssets(stageData);
				}
				if (file.endsWith(".lua")) {
					var openLua = new FunkinLua(stageFolder + file, "modpack");
					openLua.call("onCreate", []);
					openLua.call("onCreatePost", []);
				}
				sys.io.File.copy(stageFolder + file, stageModpackFolder + file);
			}
		}
	}


    private function copyRatingSkinAssets(ratingSkin:Array<String>):Void {
        var parts = ratingSkin[0].split('/');
        var ratingFolder = Paths.modFolders(swagDirectory + "/images/");
        var ratingModpackFolder = Paths.modFolders("Da Modpack/images/");

        for (i in 0...parts.length - 1) {
            ratingFolder += parts[i] + "/";
            ratingModpackFolder += parts[i] + "/";
        }

        if (!FileSystem.exists(ratingModpackFolder)) FileSystem.createDirectory(ratingModpackFolder);

        for (file in FileSystem.readDirectory(ratingFolder)) {
            if (!FileSystem.isDirectory(ratingFolder + file) &&
                (file.endsWith(ratingSkin[1] + ".png") || file.endsWith(ratingSkin[1] + ".xml"))) {
                sys.io.File.copy(ratingFolder + file, ratingModpackFolder + file);
            }
        }
    }

    private function copyCountdownAsset(assetPath:String):Void {
        var parts = assetPath.split('/');
        var baseFolder = Paths.modFolders(swagDirectory + "/images/");
        var modpackFolder = Paths.modFolders("Da Modpack/images/");

        for (i in 0...parts.length - 1) {
            baseFolder += parts[i] + "/";
            modpackFolder += parts[i] + "/";
        }

        doCopyShit(baseFolder, modpackFolder, [parts[parts.length - 1] + ".png", parts[parts.length - 1] + ".xml"]);
    }

    private function copyDirectory(src:String, dest:String):Void {
        if (!FileSystem.exists(dest)) FileSystem.createDirectory(dest);
        for (entry in FileSystem.readDirectory(src)) {
            var srcPath = src + entry;
            var destPath = dest + entry;
            if (FileSystem.isDirectory(srcPath)) copyDirectory(srcPath + "/", destPath + "/");
            else sys.io.File.copy(srcPath, destPath);
        }
    }

    override function update(elapsed:Float) {
        if (FlxG.keys.justPressed.ESCAPE) {
            MusicBeatState.switchState(new options.OptionsState());
            FlxG.mouse.visible = false;
            return;
        }
        super.update(elapsed);
    }

    function reloadDirectoryDropDown(type:String):Void {
        var lowerType = type.toLowerCase();
        if (lowerType == "data") {
            var directories = getDirectories(swagDirectory + "/data/");
            songDirectoryDropDown.list = directories;
        } else {
            var directories = Paths.getModDirectories();
            directoryDropDown.list = directories;
        }
    }

    private function getDirectories(basePath:String):Array<String> {
        var dirs = new Array<String>();
		var modDirectoryPath = Paths.modFolders(basePath);

        if (FileSystem.exists(modDirectoryPath)) {
            for (folder in FileSystem.readDirectory(modDirectoryPath)) {
                var path = haxe.io.Path.join([modDirectoryPath, folder]);
                if (FileSystem.isDirectory(path) && !Paths.ignoreModFolders.contains(folder) && !dirs.contains(folder))
                    dirs.push(folder);
            }
        }
        if (dirs.length == 0) dirs.push("NO DIRECTORIES");
        return dirs;
    }

    function reloadSetupOptions():Void {
        if (UI_box != null) reloadDirectoryDropDown("");
    }

    public function addTextToDebug(text:String, ?color:FlxColor = FlxColor.RED):Void {
        var newText = luaDebugGroup.recycle(DebugLuaText);
        newText.text = text;
        newText.color = color;
        newText.disableTime = 6;
        newText.alpha = 1;
        newText.setPosition(10, 8 - newText.height);

        luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
            spr.y += newText.height + 2;
        });
        luaDebugGroup.add(newText);

        Sys.println(text);
    }
}

// Helper function for copying files with optional filtering
function doCopyShit(srcFolder:String, destFolder:String, checkFiles:Array<String> = null):Void {
    if (!FileSystem.exists(srcFolder)) return;
    if (!FileSystem.exists(destFolder)) FileSystem.createDirectory(destFolder);

    for (file in FileSystem.readDirectory(srcFolder)) {
        if (checkFiles != null && checkFiles.length > 0) {
            if (checkFiles.indexOf(file) >= 0) {
                sys.io.File.copy(srcFolder + file, destFolder + file);
            }
        } else {
            sys.io.File.copy(srcFolder + file, destFolder + file);
        }
    }
}

class ModpackAssetGroup {
    public var subDir:String;
    public var extensions:Array<String>;
    private var assets:Map<String, Bool>; // acts like a Set

    public function new(subDir:String, extensions:Array<String>) {
        this.subDir = subDir;
        this.extensions = extensions;
        this.assets = new Map();
    }

    public function add(path:String):Void {
        assets.set(path, true); // no duplicates
    }

    public function clear():Void {
        assets.clear();
    }

    public function getList():Array<String> {
        return [for (k in assets.keys()) k];
    }
}

class ModpackAssetRegistry {
    public static var instance:ModpackAssetRegistry;

    private var groups:Map<String, ModpackAssetGroup>;

    public function new() {
        groups = new Map();

        addGroup("images", [".png", ".xml"]);
        addGroup("fonts", [""]);
        addGroup("sounds", [".ogg", ".mp3"]);
        addGroup("videos", [".mp4", ".webm"]);
        addGroup("shaders", [".frag", ".vert", ".glsl"]);

        ModpackAssetRegistry.instance = this;
    }

    private function addGroup(type:String, extensions:Array<String>):Void {
        groups.set(type, new ModpackAssetGroup(type, extensions));
    }

    public function addAsset(type:String, path:String):Void {
        if (groups.exists(type) && path != null && path.length > 0){
			trace('[addAsset] Adding $path to $type');
			groups.get(type).add(path);
		}
    }

    public function processAll(swagDirectory:String):Void {
        for (group in groups.iterator()) {
            processLuaList(group.getList(), group.subDir, group.extensions, swagDirectory);
            group.clear();
        }
    }

    public function processLuaList(luaList:Array<String>, subDir:String, extensions:Array<String>, swagDirectory:String):Void {
        if (luaList == null) return;

        for (item in luaList) {
            var parts = item.split('/');
            var baseFolder = Paths.modFolders('$swagDirectory/$subDir/');
            var modpackFolder = Paths.modFolders('Da Modpack/$subDir/');

            for (i in 0...parts.length - 1) {
                baseFolder += parts[i] + '/';
                modpackFolder += parts[i] + '/';
            }

            var fileBase = parts[parts.length - 1];
            var filesToCopy = extensions.map(ext -> fileBase + ext);

            doCopyShit(baseFolder, modpackFolder, filesToCopy);
        }
        luaList.splice(0, luaList.length); // clear after processing
    }
}