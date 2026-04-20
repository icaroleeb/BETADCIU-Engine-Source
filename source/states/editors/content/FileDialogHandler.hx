package states.editors.content;

import haxe.Exception;
import haxe.io.Bytes;
import sys.io.File;
import lime.ui.FileDialog;
import flash.net.FileFilter;

import flixel.FlxG;
import flixel.FlxBasic;

// Currently only supports OPEN, OPEN_DIRECTORY and SAVE
class FileDialogHandler extends FlxBasic
{
	public function new()
	{
		super();
	}

	// callbacks
	public var onComplete:Void->Void;
	public var onCancel:Void->Void;
	public var onError:Void->Void;

	public var data:String;
	public var path:String;
	public var completed:Bool = true;

	public function save(?fileName:String = '', ?dataToSave:String = '', ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if (!completed)
			throw new Exception('You must finish previous operation before starting a new one.');

		_startUp(onComplete, onCancel, onError);

		FileDialog.saveFile(FlxG.stage.window, 'Save', (file, filter) ->
		{
			if (file != null && file.length > 0)
			{
				sys.io.File.saveBytes(file, haxe.io.Bytes.ofString(dataToSave));
				this.path = file;
				this.completed = true;
				trace('Saved file to: $path');
				if (this.onComplete != null) this.onComplete();
			}
			else
			{
				this.completed = true;
				if (this.onCancel != null) this.onCancel();
			}
		}, null, fileName);
	}

	public function open(?defaultName:String = null, ?title:String = null, ?filters:Array<FileFilter> = null, ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if (!completed)
			throw new Exception('You must finish previous operation before starting a new one.');

		_startUp(onComplete, onCancel, onError);

		var filterTypes:Array<lime.ui.FileDialogFilter> = null;
		if (filters != null)
			filterTypes = filters.map(f -> new lime.ui.FileDialogFilter(f.extension, f.description));

		FileDialog.openFile(FlxG.stage.window, title, (files, filter) ->
		{
			if (files != null && files.length > 0)
			{
				this.path = files[0];
				this.data = File.getContent(this.path);
				this.completed = true;
				trace('Loaded file from: $path');
				if (this.onComplete != null) this.onComplete();
			}
			else
			{
				this.completed = true;
				if (this.onCancel != null) this.onCancel();
			}
		}, filterTypes, defaultName);
	}

	public function openDirectory(?title:String = null, ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if (!completed)
			throw new Exception('You must finish previous operation before starting a new one.');

		_startUp(onComplete, onCancel, onError);

		FileDialog.openDirectory(FlxG.stage.window, title, (files) ->
		{
			if (files != null && files.length > 0)
			{
				this.path = files[0];
				this.completed = true;
				trace('Loaded directory: $path');
				if (this.onComplete != null) this.onComplete();
			}
			else
			{
				this.completed = true;
				if (this.onCancel != null) this.onCancel();
			}
		}, null, false);
	}

	function _startUp(onComplete:Void->Void, onCancel:Void->Void, onError:Void->Void)
	{
		this.onComplete = onComplete;
		this.onCancel = onCancel;
		this.onError = onError;
		this.completed = false;
		this.data = null;
		this.path = null;
	}

	override function destroy()
	{
		onComplete = null;
		onCancel = null;
		onError = null;
		data = null;
		path = null;
		completed = true;
		super.destroy();
	}
}
