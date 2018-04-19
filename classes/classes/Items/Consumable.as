/**
 * Created by aimozg on 09.01.14.
 */
package classes.Items
{
	import classes.Credits;
	import classes.GlobalFlags.*;
	import classes.CoC_Settings;
	import classes.Scenes.Camp;
	import classes.Scenes.Places.Prison;
	import classes.DefaultDict;
	import classes.Output;
	import classes.Player;

/**
	 * An item, that is consumed by player, and disappears after use. Direct subclasses should override "doEffect" method
	 * and NOT "useItem" method.
	 */
	public class Consumable extends Useable
	{
		protected function get mutations():Mutations { return kGAMECLASS.mutations; }
		protected function get changes():int { return mutations.changes; }
		protected function set changes(val:int):void { mutations.changes = val; }
		protected function get changeLimit():int { return mutations.changeLimit; }
		protected function set changeLimit(val:int):void { mutations.changeLimit = val; }

		protected function get output():Output { return kGAMECLASS.output; }
		protected function get credits():Credits { return kGAMECLASS.credits; }
		protected function get player():Player { return kGAMECLASS.player; }
		protected function get prison():Prison { return kGAMECLASS.prison; }
		protected function get flags():DefaultDict { return kGAMECLASS.flags; }
		protected function get camp():Camp { return kGAMECLASS.camp; }
		protected function tfChance(min:int, max:int):Boolean { return mutations.tfChance(min, max); }
		protected function doNext(eventNo:Function):void { kGAMECLASS.output.doNext(eventNo); }

		public function Consumable(id:String, shortName:String = null, longName:String = null, value:Number = 0, description:String = null) {
			super(id, shortName, longName, value, description);
		}

		override public function get description():String {
			var desc:String = _description;
			//Type
			desc += "\n\nType: Consumable ";
			if (shortName == "Wingstick") desc += "(Thrown)";
			if (shortName == "S.Hummus") desc += "(Cheat Item)";
			if (shortName == "BroBrew" || shortName == "BimboLq" || shortName == "P.Pearl") desc += "(Rare Item)";
			if (longName.indexOf("dye") >= 0) desc += "(Dye)";
			if (longName.indexOf("egg") >= 0) desc += "(Egg)";
			if (longName.indexOf("book") >= 0) desc += "(Magic Book)";
			//Value
			desc += "\nBase value: " + String(value);
			return desc;
		}
		
		/**
		 * Delegate function for legacy 'Mutations.as' code.
		 * @param	... args stat change parameters
		 */
		protected function dynStats(... args):void {
			game.dynStats.apply(null, args);
		}
		
		override public function getMaxStackSize():int {
			return 10;
		}
	}
}
