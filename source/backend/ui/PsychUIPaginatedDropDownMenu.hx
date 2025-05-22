package backend.ui;

import backend.ui.PsychUIBox.UIStyleData;

class PsychUIDropDownMenu extends PsychUIInputText {
    public static final CLICK_EVENT = "dropdown_click";

    public var list(default, set):Array<String> = [];
    public var button:FlxSprite;
    public var onSelect:Int->String->Void;

    public var selectedIndex(default, set):Int = -1;
    public var selectedLabel(default, set):String = null;

    var _curFilter:Array<String>;
    var _itemWidth:Float = 0;
    var _items:Array<PsychUIDropDownItem> = [];
    public var curScroll:Int = 0;
    public var broadcastDropDownEvent:Bool = true;

    // Pagination variables
    public var pageSize:Int = 10;
    public var currentPage:Int = 0;

    public function new(x:Float, y:Float, list:Array<String>, callback:Int->String->Void, ?width:Float = 100, ?pageSize:Int = 10) {
        super(x, y);
        if (list == null) list = [];
        
        _itemWidth = width - 2;
        setGraphicSize(width, 20);
        updateHitbox();
        textObj.y += 2;

        this.pageSize = pageSize;

        button = new FlxSprite(behindText.width + 1, 0).loadGraphic(Paths.image('psych-ui/dropdown_button', 'embed'), true, 20, 20);
        button.animation.add('normal', [0], false);
        button.animation.add('pressed', [1], false);
        button.animation.play('normal', true);
        add(button);

        onSelect = callback;

        onChange = function(old:String, cur:String) {
            if (old != cur) {
                _curFilter = this.list.filter(function(str:String) return str.startsWith(cur));
                showDropDown(true, 0, _curFilter);
            }
        }

        unfocus = function() {
            showDropDownClickFix();
            showDropDown(false);
        }

        for (option in list) {
            addOption(option);
        }

        selectedIndex = 0;
        showDropDown(false);
    }

    function showDropDownClickFix() {
        if(FlxG.mouse.justPressed) {
            for (item in _items) {
                if(item != null && item.active && item.visible)
                    item.update(0);
            }
        }
    }
    
    function paginateList(list:Array<String>):Array<String> {
        var start:Int = currentPage * pageSize;
        var end:Int = Std.int(Math.min(start + pageSize, list.length));
        return list.slice(start, end);
    }

    public function nextPage() {
        if ((currentPage + 1) * pageSize < list.length) {
            currentPage++;
            showDropDown(true, 0, _curFilter);
        }
    }

    public function previousPage() {
        if (currentPage > 0) {
            currentPage--;
            showDropDown(true, 0, _curFilter);
        }
    }

    public function showDropDown(vis:Bool = true, scroll:Int = 0, onlyAllowed:Array<String> = null) {
        if (!vis) {
            text = selectedLabel;
            _curFilter = null;
        }

        var paginatedList = paginateList(onlyAllowed != null ? onlyAllowed : list);
        curScroll = Std.int(Math.max(0, Math.min(paginatedList.length - 1, scroll)));
        
        if (vis) {
            var n:Int = 0;
            for (item in _items) {
                if (paginatedList.contains(item.label)) {
                    item.active = item.visible = (n >= curScroll);
                    n++;
                } else {
                    item.active = item.visible = false;
                }
            }

            var txtY:Float = behindText.y + behindText.height + 1;
            for (num => item in _items) {
                if (!item.visible) continue;
                item.x = behindText.x;
                item.y = txtY;
                txtY += item.height;
                item.forceNextUpdate = true;
            }

            bg.scale.y = txtY - behindText.y + 2;
            bg.updateHitbox();
        } else {
            for (item in _items) {
                item.active = item.visible = false;
            }
            bg.scale.y = 20;
            bg.updateHitbox();
        }
    }
    
    override function update(elapsed:Float) {
        var lastFocus = PsychUIInputText.focusOn;
		super.update(elapsed);
		if(FlxG.mouse.justPressed)
		{
			if(FlxG.mouse.overlaps(button, camera))
			{
				button.animation.play('pressed', true);
				if(lastFocus != this)
					PsychUIInputText.focusOn = this;
				else if(PsychUIInputText.focusOn == this)
					PsychUIInputText.focusOn = null;
			}
		}
		else if(FlxG.mouse.released && button.animation.curAnim != null && button.animation.curAnim.name != 'normal') button.animation.play('normal', true);

		if(lastFocus != PsychUIInputText.focusOn)
		{
			showDropDown(PsychUIInputText.focusOn == this);
		}
		else if(PsychUIInputText.focusOn == this)
		{
			var wheel:Int = FlxG.mouse.wheel;
			if(FlxG.keys.pressed.UP) wheel++;
			if(FlxG.keys.pressed.DOWN) wheel--;
			if(wheel != 0) showDropDown(true, curScroll - wheel, _curFilter);
		}

        if (FlxG.keys.justPressed.RIGHT) nextPage();
        if (FlxG.keys.justPressed.LEFT) previousPage();
    }

	function set_selectedIndex(v:Int) {
		var globalIndex = (currentPage * pageSize) + v;
		selectedIndex = globalIndex;
		
		if (selectedIndex < 0 || selectedIndex >= list.length) selectedIndex = -1;
		@:bypassAccessor selectedLabel = list[selectedIndex];
		text = (selectedLabel != null) ? selectedLabel : '';
		
		return selectedIndex;
	}

	function set_selectedLabel(v:String) {
		var id:Int = list.indexOf(v);
		if(id >= 0) {
			currentPage = Math.floor(id / pageSize); // Jump to the page where it is located
			showDropDown(true); // Refresh the dropdown
			@:bypassAccessor selectedIndex = id;
			selectedLabel = v;
			text = selectedLabel;
		} else {
			@:bypassAccessor selectedIndex = -1;
			selectedLabel = null;
			text = '';
		}
		return selectedLabel;
	}


	function set_list(v:Array<String>) {
		var selected:String = selectedLabel;
		showDropDown(false);

		for (item in _items) {
			item.kill();
		}

		_items = [];
		list = [];
		currentPage = 0; // Reset pagination
		
		for (option in v) {
			addOption(option);
		}

		if (selectedLabel != null) {
			set_selectedLabel(selected);
		}
		return v;
	}

	function addOption(option:String) {
		@:bypassAccessor list.push(option);
		var curID:Int = list.length - 1;
		
		var item:PsychUIDropDownItem = cast recycle(PsychUIDropDownItem, () -> new PsychUIDropDownItem(1, 1, this._itemWidth), true);
		item.cameras = cameras;
		item.label = option;
		item.visible = item.active = false;
		
		// Update onClick with correct index resolution
		item.onClick = function() {
			// Ensure the clicked index matches the paginated view
			var paginatedIndex = (currentPage * pageSize) + _items.indexOf(item);
			clickedOn(paginatedIndex, option);
		};
		
		item.forceNextUpdate = true;
		_items.push(item);
		insert(1, item);

		// If the new item is part of the current page, show it
		var start:Int = currentPage * pageSize;
		var end:Int = Std.int(Math.min(start + pageSize, list.length));
		if (curID >= start && curID < end) {
			item.visible = item.active = true;
		}
	}

	function clickedOn(num:Int, label:String) {
		var globalIndex = (currentPage * pageSize) + num;
		selectedIndex = globalIndex;

		showDropDown(false);
		if (onSelect != null) onSelect(globalIndex, label);
		if (broadcastDropDownEvent) PsychUIEventHandler.event(CLICK_EVENT, this);
	}
}

class PsychUIDropDownItem extends FlxSpriteGroup
{
	public var hoverStyle:UIStyleData = {
		bgColor: 0xFF0066FF,
		textColor: FlxColor.WHITE,
		bgAlpha: 1
	};
	public var normalStyle:UIStyleData = {
		bgColor: FlxColor.WHITE,
		textColor: FlxColor.BLACK,
		bgAlpha: 1
	};

	public var bg:FlxSprite;
	public var text:FlxText;
	public function new(x:Float = 0, y:Float = 0, width:Float = 100)
	{
		super(x, y);

		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		bg.setGraphicSize(width, 20);
		bg.updateHitbox();
		add(bg);

		text = new FlxText(0, 0, width, 8);
		text.color = FlxColor.BLACK;
		add(text);
	}

	public var onClick:Void->Void;
	public var forceNextUpdate:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.mouse.justMoved || FlxG.mouse.justPressed || forceNextUpdate)
		{
			var overlapped:Bool = (FlxG.mouse.overlaps(bg, camera));

			var style = overlapped ? hoverStyle : normalStyle;
			bg.color = style.bgColor;
			text.color = style.textColor;
			bg.alpha = style.bgAlpha;
			forceNextUpdate = false;

			if(overlapped && FlxG.mouse.justPressed)
				onClick();
		}
		
		text.x = bg.x;
		text.y = bg.y + bg.height/2 - text.height/2;
	}

	public var label(default, set):String;
	function set_label(v:String)
	{
		label = v;
		text.text = v;
		bg.scale.y = text.height + 6;
		bg.updateHitbox();
		return v;
	}
}