package {
	import classes.HelperSuit;
	import classes.InternalsSuit;
	import classes.PlayerTest;
	import classes.ScenesSuit;
	import classes.ItemsSuit;

	import classes.CreatureTest;
	import classes.CoCTest;
	import classes.CharSpecialTest;
	import classes.CharCreationTest;
	import classes.MonsterTest;
	import classes.VaginaClassTest;
	import classes.CockTest;
	import classes.SavesTest;
	import classes.PlayerEventsTest;
	import classes.PlayerEventsVaginaLoosenessRecoveryTest;
	import classes.MenusSuit;

[Suite]
[RunWith("org.flexunit.runners.Suite")]
	public class ClassesSuit
	{
		 public var helperSuit:HelperSuit;
		 public var scenesSuit:ScenesSuit;
		 public var itemsSuit:ItemsSuit;
		
		 public var coCTest:CoCTest;
		 public var charSpecialTest:CharSpecialTest;
		 public var charCreationTest:CharCreationTest; 
		 public var monsterTest:MonsterTest;
		 public var creaturTest:CreatureTest;
		 public var playerTest:PlayerTest;
		 public var vaginaClass:VaginaClassTest;
		 public var cockTest:CockTest;
		 public var savesTest:SavesTest;
		 public var playerEventsTest:PlayerEventsTest;
		 public var playerEventsVaginaLoosenessRecoveryTest:PlayerEventsVaginaLoosenessRecoveryTest;
		 public var internalsSuit:InternalsSuit;
		 public var menusSuit:MenusSuit;
	}
}
