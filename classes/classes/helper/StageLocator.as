package classes.helper {
	import flash.display.Stage;

/**
 * Helper class to deal with the CoC class GUI dependency.
 * 
 * Source:
 * https://forums.adobe.com/message/4235833#4235833
 */
	public class StageLocator {
		//public static var instance:StageLocator;
		private static var _stage:Stage;
		
		public function StageLocator ($stage:Stage) {
			//instance = this;
			_stage = $stage;
		}
		public static function get stage():Stage { return _stage; }
	}
}