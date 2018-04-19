/**
 * Coded by aimozg on 10.07.2017.
 */
package coc.view {
import classes.internals.LoggerFactory;

import coc.view.charview.CaseBlock;
import coc.view.charview.CharViewSprite;
import coc.view.charview.IfBlock;
import coc.view.charview.LayerPart;
import coc.view.charview.ModelPart;
import coc.view.charview.Palette;
import coc.view.charview.PartList;
import coc.view.charview.SwitchPart;

import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Point;
import flash.geom.Rectangle;

import mx.logging.ILogger;

public class CharView extends Sprite {
	private static const LOGGER:ILogger = LoggerFactory.getLogger(CharView);
	private var loading:Boolean;
	private var sprites:Object = {}; // spritesheet/spritemap -> CharViewSprite
	private var composite:CompositeImage;
	private var ss_total:int;
	private var ss_loaded:int;
	private var file_total:int;
	private var file_loaded:int;
	private var _originX:int;
	private var _originY:int;
	private var _width:uint;
	private var _height:uint;
	private var scale:Number;
	private var pendingRedraw:Boolean;
	private var loaderLocation:String;
	private var parts:ModelPart;
	private var _palette:Palette;

	public function get palette():Palette {
		return _palette;
	}
	public function CharView() {
		clearAll();
	}
	/**
	 * @param location "external" or "internal"
	 */
	public function reload(location:String = "external"):void {
		loaderLocation = location;
		if (loading) return;
		try {
			loading = true;
			clearAll();
			if (loaderLocation == "external") LOGGER.info("loading XML res/model.xml");
			CoCLoader.loadText("res/model.xml", function (success:Boolean, result:String, e:Event):void {
				if (success) {
					init(XML(result));
				} else {
					LOGGER.warn("XML file not found: " + e);
					loading = false;
				}
			}, loaderLocation);
		} catch (e:Error) {
			loading = false;
			LOGGER.error(e.message+"\n" + e.getStackTrace());
		}
	}
	private function clearAll():void {
		this.sprites       = {};
		this.composite     = null;
		this.ss_total      = 0;
		this.ss_loaded     = 0;
		this.file_total    = 0;
		this.file_loaded   = 0;
		this._width        = 1;
		this._height       = 1;
		this.scale         = 1;
		this.pendingRedraw = false;
		this.parts         = new PartList([]);
	}
	private function init(xml:XML):void {
		_width    = xml.@width;
		_height   = xml.@height;
		_originX  = xml.@originX || 0;
		_originY  = xml.@originY || 0;
		composite = new CompositeImage(_width, _height);
		ss_loaded = 0;
		ss_total  = -1;
		/**/
		var _parts:/*ModelPart*/Array = [];
		loadPalette(xml);
		var item:XML;
		for each(item in xml.logic.*) {
			_parts.push(loadPart(item));
		}
		this.parts = new PartList(_parts);
		var n:int  = 0;
		for each(item in xml.spritesheet) {
			n++;
			loadSpritesheet(xml, item);
		}
		for each(item in xml.spritemap) {
			n++;
			loadSpritemap(xml, item);
		}
		ss_total = n;
		if (n == 0) loadLayers(xml);
		var g:Graphics = graphics;
		g.clear();
		g.beginFill(0, 0);
		g.drawRect(0, 0, _width, _height);
		g.endFill();
		scale       = parseFloat(xml.@scale);
		this.scaleX = scale;
		this.scaleY = scale;
		loading     = false;
		if (pendingRedraw) redraw();
	}
	private function loadPalette(xml:XML):void {
		_palette                 = new Palette();
		var commonLookups:Object = {};
		for each (var color:XML in xml.palette.common.color) {
			commonLookups[color.@name.toString()] = color.text().toString();
		}
		_palette.addLookups("common", commonLookups);
		for each (var prop:XML in xml.palette.property) {
			var lookups:Object = {};
			for each (color in prop.color) {
				lookups[color.@name.toString()] = color.text().toString();
			}
			var propname:String = prop.@name.toString();
			_palette.addLookups(propname, lookups);
			_palette.addPaletteProperty(
					propname,
					prop.@src.toString(),
					Color.convertColor(prop.@default.toString()),
					[propname, "common"]);
		}
		for each (var key:XML in xml.colorkeys.key) {
			var src:uint    = Color.convertColor(key.@src.toString());
			var base:String = key.@base.toString();
			var tf:String   = key.@transform.toString() || "";
			_palette.addKeyColor(src, base, tf);
		}
	}
	public function lookupColorValue(propname:String, colorname:String):uint {
		return _palette.lookupColor(propname, colorname);
	}
	private function loadLayers(xml:XML):void {
		file_loaded = 0;
		var item:XML;
		var n:int   = 0;
		file_total  = -1;
		for each(item in xml.layers..layer) {
			var lpfx:String = item.@name + "/";
			for (var sname:String in sprites) {
				if (sname.indexOf(lpfx) == 0) {
					var sprite:CharViewSprite = sprites[sname];
					composite.addLayer(sname, sprite.bmp,
							sprite.dx - _originX, sprite.dy - _originY, false);
				}
			}
		}
		file_total = n;
		if (pendingRedraw) redraw();
	}
	private var _character:Object = {};
	public function setCharacter(value:Object):void {
		_character = value;
	}
	public function redraw():void {
		if (file_total == 0 && ss_total == 0 && !loading) {
			reload();
		}
		pendingRedraw = true;
		if (ss_loaded != ss_total || file_loaded != file_total || (ss_total + file_total) == 0) {
			return;
		}
		pendingRedraw = false;


		// Mark visible layers
		composite.hideAll();
		parts.display(_character);

		var keyColors:Object = _palette.calcKeyColors(_character);
		var bd:BitmapData    = composite.draw(keyColors);
		var g:Graphics       = graphics;
		g.clear();
		g.beginBitmapFill(bd);
		g.drawRect(0, 0, _width, _height);
		g.endFill();
		this.scaleX = scale;
		this.scaleY = scale;
	}
	private function loadPart(x:XML):ModelPart {
		var item:XML;
		switch (x.localName()) {
			case 'show':
				return new LayerPart(composite, x.@part, true);
			case 'hide':
				return new LayerPart(composite, x.@part, false);
			case 'if':
				var thenBlock:/*ModelPart*/Array = [];
				for each(item in x.*) {
					thenBlock.push(loadPart(item));
				}
				return new IfBlock(x.@test.toString(), thenBlock);
			case 'switch':
				var hasval:Boolean           = x.attribute("value").length() > 0;
				var cases:/*CaseBlock*/Array = [];
				for each(var xcase:XML in x.elements("case")) {
					var caseItems:/*ModelPart*/Array = [];
					for each(item in xcase.*) {
						caseItems.push(loadPart(item));
					}
					var hasval2:Boolean = hasval && xcase.attribute("value").length() > 0;
					var hasval3:Boolean = hasval && xcase.attribute("values").length() > 0;
					var hastest:Boolean = xcase.attribute("test").length() > 0;
					cases.push(new CaseBlock(
							hastest ? xcase.@test.toString() : null,
							hasval3 ? '[' + xcase.@values.toString() + ']' :
									hasval2 ? '[' + xcase.@value.toString() + ']' : null,
							caseItems));
				}
				var defBlock:/*ModelPart*/Array = [];
				for each (item in x.elements("default").*) {
					defBlock.push(loadPart(item));
				}
				return new SwitchPart(hasval ? x.@value.toString() : null, cases, defBlock);
			default:
				throw new Error("Expected <layer>, <if>, or <switch>, got " + x.localName());
		}
	}
	private function loadSpritemap(xml:XML, sm:XML):void {
		const filename:String = sm.@file;
		var path:String       = xml.@dir + filename;
		if (loaderLocation == "external") LOGGER.info('loading spritemap ' + path);
		CoCLoader.loadImage(path, function (success:Boolean, result:BitmapData, e:Event):void {
			if (!success) {
				LOGGER.warn("Spritemap file not found: " + e);
				ss_loaded++;
				if (pendingRedraw) redraw();
				return;
			}
			for each (var cell:XML in sm.cell) {
				var rect:/*String*/Array = cell.@rect.toString().match(/^(\d+),(\d+),(\d+),(\d+)$/);
				var x:int                = rect ? int(rect[1]) : cell.@x;
				var y:int                = rect ? int(rect[2]) : cell.@y;
				var w:int                = rect ? int(rect[3]) : cell.@w;
				var h:int                = rect ? int(rect[4]) : cell.@h;
				var f:String             = cell.@name;
				var dx:int               = cell.@dx;
				var dy:int               = cell.@dy;
				var bd:BitmapData        = new BitmapData(w, h, true, 0);
				bd.copyPixels(result, new Rectangle(x, y, w, h), new Point(0, 0));
				sprites[f] = new CharViewSprite(bd, dx, dy);
			}
			ss_loaded++;
			if (ss_loaded == ss_total) loadLayers(xml);
		}, loaderLocation);
	}
	private function loadSpritesheet(xml:XML, ss:XML):void {
		const filename:String = ss.@file;
		const cellwidth:int   = ss.@cellwidth;
		const cellheight:int  = ss.@cellheight;
		var path:String       = xml.@dir + filename;
		if (loaderLocation == "external") LOGGER.info('loading spritesheet ' + path);
		CoCLoader.loadImage(path, function (success:Boolean, result:BitmapData, e:Event):void {
			if (!success) {
				LOGGER.warn("Spritesheet file not found: " + e);
				ss_loaded++;
				if (pendingRedraw) redraw();
				return;
			}
			var y:int = 0;
			for each (var row:XML in ss.row) {
				var x:int                 = 0;
				var files:/*String*/Array = row.text().toString().split(",");
				for each (var f:String in files) {
					if (f) {
						var bd:BitmapData = new BitmapData(cellwidth, cellheight, true, 0);
						bd.copyPixels(result, new Rectangle(x, y, cellwidth, cellheight), new Point(0, 0));
						sprites[f] = new CharViewSprite(bd, 0, 0);
					}
					x += cellwidth;
				}
				y += cellheight;
			}
			ss_loaded++;
			if (ss_loaded == ss_total) loadLayers(xml);
		}, loaderLocation);
	}

}
}

