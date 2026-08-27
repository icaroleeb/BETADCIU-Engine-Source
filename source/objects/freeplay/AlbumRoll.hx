package objects.freeplay;

import objects.freeplay.DifficultyStars;

class AlbumRoll extends FlxSpriteGroup
{
    final _antialias = ClientPrefs.data.antialiasing; // just because im lazy to type that long ass thing

	public var currentAlbum(default, null):String = "template";

	// the album cover
	public var albumArt:FunkinSprite;
    public var albumTitle:Null<FunkinSprite> = null;
    public var difficultyStars:DifficultyStars;

	public function new(?initialAlbum:String = "template") {
		super();

		albumArt = new FunkinSprite(FlxG.width - 360, 280);
		albumArt.antialiasing = _antialias;
		albumArt.angle = 10;
		add(albumArt);

        difficultyStars = new DifficultyStars(FlxG.width - 353.5, 215);
        add(difficultyStars);

        albumTitle = new FunkinSprite(FlxG.width - 365, 480);
        albumTitle.antialiasing = _antialias;
        add(albumTitle);

		updateImage(initialAlbum);
	}

    // TODO: try to add animated albums to this
    // updates the art and title of the album
	public function updateImage(albumName:String):Void
	{
		if (albumName == null || albumName.length == 0) albumName = "template";
		if (albumName == currentAlbum && albumArt.graphic != null) return;

        var _imagePath = 'freeplay/AlbumRoll/$albumName';

        // art
		if (Paths.image(_imagePath) == null) _imagePath = 'freeplay/AlbumRoll/template';    
		albumArt.loadGraphic(Paths.image(_imagePath));
        
        // title
        if (Paths.fileExists('images/$_imagePath-text.png', IMAGE)) {
            albumTitle.frames = Paths.getSparrowAtlas('$_imagePath-text');
            albumTitle.animation.addByPrefix('idle', 'idle0', 24, true);
            albumTitle.animation.addByPrefix('switch', 'switch0', 24, false);
            albumTitle.animation.play('switch');
            albumTitle.updateHitbox();
            albumTitle.visible = true;
            
            albumTitle.animation.onFinish.add(function(name) { if (name == 'switch') albumTitle.animation?.play('idle'); });
        } else {
            albumTitle.visible = false;
        }
        
        currentAlbum = albumName;
        // lil tween to make the album change look better
		FlxTween.cancelTweensOf(albumArt);
		albumArt.y = 285;
		FlxTween.tween(albumArt, {y: 280}, 0.2, {ease: FlxEase.cubeOut});
	}
}