package states.editors.content;

import haxe.ui.containers.dialogs.SaveFileDialog;
import haxe.ui.backend.SaveFileDialogBase;
import haxe.ui.components.Label;
import haxe.ui.containers.windows.WindowManager;
import haxe.ui.containers.windows.Window;
import haxe.ui.components.Button;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxImageFrame;

import haxe.ui.util.Variant;
import haxe.ui.components.Image;
import haxe.ui.core.ItemRenderer;
import haxe.ui.components.CheckBox;
import haxe.ui.containers.HBox;
import haxe.ui.containers.Panel;
import haxe.ui.containers.VBox;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;

using backend.ui.ToolKitUtils;

// most of the new UI was built from Nightmare Vision's Character Editor, big props to Campbell and NMV Team

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/ui/charEditorToolBar.xml"))
class ToolBar extends MenuBar {}

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/ui/charEditorCharSettings.xml"))
class CharacterDialog extends CollapsibleDialog {}

@:xml('<panel text="Animations" tooltip="List of anims of the current character.">

    <listview id="animationList" width="150" height="200" selectedIndex="0">
        <data>

        </data>
    </listview>
</panel>')
class CharacterAnimList extends Panel {}

@:xml('
<panel id="theVBox" height="50" width="150">

    <vbox id="weener" width="100%">
        <label text="Zoom: 1x" horizontalAlign="center" verticalAlign="center" id="zoomText"/>
        <label text="Animation Frames: ()" horizontalAlign="center" verticalAlign="center" id="animationFramesText"/>
    </vbox>

</panel>
')
class MiscInfo extends Panel {}

class CharEditorUI extends flixel.group.FlxSpriteContainer
{
    public var characterDialogBox:CharacterDialog;
    public var toolBar:ToolBar;
	public var miscInfo:MiscInfo;
    public var animationList:CharacterAnimList;

    public function new()
    {
        super();

        toolBar = new ToolBar();
		add(toolBar);
		toolBar.findComponent('stageBGCheckbox', CheckBox).value = true;

		animationList = new CharacterAnimList();
		add(animationList);
		animationList.x = 20;
		animationList.y = toolBar.height + 20;

        miscInfo = new MiscInfo();
		add(miscInfo);
		miscInfo.y = toolBar.height + 20;
		miscInfo.x = (FlxG.width - miscInfo.actualComponentWidth) / 2;

        characterDialogBox = new CharacterDialog();
		add(characterDialogBox);
		characterDialogBox.showDialog(false);
		
		characterDialogBox.x = FlxG.width - characterDialogBox.actualComponentWidth - 20;
		characterDialogBox.y = toolBar.height + 20;
		
		characterDialogBox.characterTabs.selectedPage = characterDialogBox.characterTabs.getPageById('charSettings');
		
		characterDialogBox.findComponent('iconDisplay', Button).remainPressed = false;
    }

    override function destroy()
	{
		super.destroy();
	}
	
	public function setHealthIcon(frame:FlxFrame)
	{
		characterDialogBox.findComponent('iconDisplay', Button).icon = Variant.fromImageData(frame);
	}
}