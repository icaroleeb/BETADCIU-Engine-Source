package states.editors.content;

import backend.StageData;
import objects.Character;
import flixel.FlxSprite;
import psychlua.ModchartSprite;

class StageEditorMetaSprite
{
	public var sprite:FlxSprite;
	public var type:String;
	public var name:String;
	public var filters:LoadFilters = (LOW_QUALITY)|(HIGH_QUALITY);
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var alpha(get, set):Float;
	public var angle(get, set):Float;

	function get_x() return sprite.x;
	function set_x(v:Float) return (sprite.x = v);
	function get_y() return sprite.y;
	function set_y(v:Float) return (sprite.y = v);
	function get_alpha() return sprite.alpha;
	function set_alpha(v:Float) return (sprite.alpha = v);
	function get_angle() return sprite.angle;
	function set_angle(v:Float) return (sprite.angle = v);

	public var color(default, set):String = 'FFFFFF';
	function set_color(v:String) {
		sprite.color = CoolUtil.colorFromString(v);
		return (color = v);
	}

	public var image(default, set):String = 'unknown';
	function set_image(v:String) {
		try {
			if(type == 'sprite') sprite.loadGraphic(Paths.image(v));
			else if(type == 'animatedSprite') sprite.frames = Paths.getAtlas(v);
		} catch(e:Dynamic) {}
		sprite.updateHitbox();
		return (image = v);
	}

	public var antialiasing(default, set):Bool = true;
	function set_antialiasing(v:Bool) {
		sprite.antialiasing = (v && ClientPrefs.data.antialiasing);
		return (antialiasing = v);
	}

	public function setScale(w:Float, h:Float) {
		sprite.scale.set(w, h);
		sprite.updateHitbox();
	}

	public function setScrollFactor(x:Float, y:Float) {
		sprite.scrollFactor.set(x, y);
	}

	public var visible(get, set):Bool;
	function get_visible() return sprite.visible;
	function set_visible(v:Bool) return (sprite.visible = v);

	public var firstAnimation:String;
	public var animations:Array<AnimArray>;

	public function new(data:Dynamic, spr:FlxSprite) {
		this.sprite = spr;
		if(data == null) return;
		this.type = data.type;
		this.name = data.name != null ? data.name : "unnamed";
		if(data.image != null) image = data.image;
		if(data.animations != null) this.animations = data.animations;
		if(data.firstAnimation != null) this.firstAnimation = data.firstAnimation;
	}

	public function formatToJson() {
		return {
			type: type,
			name: name,
			image: image,
			x: x,
			y: y
		};
	}

	public function update(f:LoadFilters, e:Float) { sprite.update(e); }
	public function draw(f:LoadFilters) { sprite.draw(); }
}