/*
   	CoC主文件 - 这是游戏开始时加载的内容。 如果你想开始了解CoC的结构，
    这是开始的地方。
    首先，我们在代码库中导入来自许多不同文件的所有类。 不改变它是明智的
    这些进口的顺序，直到更多的知道什么时候需要加载。
 */

package classes {
// BREAKING ALL THE RULES.
import classes.AssClass;
import classes.CoC_Settings;
import classes.Cock;
import classes.Creature;
import classes.GlobalFlags.kACHIEVEMENTS;
import classes.GlobalFlags.kFLAGS;
import classes.GlobalFlags.kGAMECLASS;
import classes.ImageManager;
import classes.InputManager;
import classes.ItemSlotClass;
import classes.Items.*;
import classes.Parser.Parser;
import classes.PerkClass;
import classes.PerkLib;
import classes.Player;
import classes.Scenes.*;
import classes.Scenes.Areas.*;
import classes.Scenes.Areas.Desert.*;
import classes.Scenes.Areas.Forest.*;
import classes.Scenes.Areas.HighMountains.*;
import classes.Scenes.Areas.Mountain.*;
import classes.Scenes.Areas.Swamp.*;
import classes.Scenes.Combat.Combat;
import classes.Scenes.Dungeons.DungeonMap;
import classes.Scenes.Dungeons.LethicesKeep.LethicesKeep;
import classes.Scenes.Dungeons.DeepCave.*;
import classes.Scenes.Dungeons.DesertCave.*;
import classes.Scenes.Dungeons.DungeonCore;
import classes.Scenes.Dungeons.Factory.*;
import classes.Scenes.Dungeons.HelDungeon.*;
import classes.Scenes.Explore.*;
import classes.Scenes.Monsters.*;
import classes.Scenes.Monsters.pregnancies.PlayerBunnyPregnancy;
import classes.Scenes.Monsters.pregnancies.PlayerCentaurPregnancy;
import classes.Scenes.NPCs.*;
import classes.Scenes.NPCs.pregnancies.PlayerBenoitPregnancy;
import classes.Scenes.NPCs.pregnancies.PlayerOviElixirPregnancy;
import classes.Scenes.Places.*;
import classes.Scenes.Places.TelAdre.*;
import classes.Scenes.Quests.*;
import classes.Scenes.Seasonal.*;
import classes.Scenes.Seasonal.AprilFools;
import classes.Scenes.Seasonal.Fera;
import classes.Scenes.Seasonal.Thanksgiving;
import classes.Scenes.Seasonal.Valentines;
import classes.Scenes.Seasonal.XmasBase;
import classes.StatusEffectClass;
import classes.VaginaClass;
import classes.content.*;
import classes.display.SpriteDb;
import classes.internals.*;
import classes.internals.Utils;
import classes.Time;

import coc.view.MainView;

import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.*;
import flash.net.navigateToURL;
import flash.net.registerClassAlias;
import flash.net.URLRequest;
import flash.text.*;
import flash.utils.ByteArray;

import mx.logging.Log;
import mx.logging.LogEventLevel;
import mx.logging.targets.TraceTarget;

// This file contains most of the persistent gamestate flags.

/*
   在这个游戏中关于描述的一个非常重要的事情是，很多单词都是基于隐藏的整数值。
    将这些整数与表格进行比较或直接查询以获取用于描述的特定部分的词语。 例如，
    下面的AssClass具有湿度，松弛度，丰满度和贞操的变量。 你会经常发现这样的列表
   scattered through the code:
   butt looseness
   0 - virgin
   1 - normal
   2 - loose
   3 - very loose
   4 - gaping
   5 - monstrous


    追踪描述变量的完整列表，它们的整数值如何转化为描述，以及如何调用它们
    对于任何想要使用变量扩展内容的人来说都是一项非常有用的任务。
    更复杂的是，代码有时还会有一些随机的单词列表，用于保留某些特定的内容
    文字过于无聊。
 */


// 以下所有带有Scenes的文件都会加载游戏的主要内容。

// Class based content? In my CoC?! It's more likely than you think!

// All the imports below are for Flash.

/****
 classes.CoC: The Document class of Corruption of the Champions.
 ****/

/*
这个类实例化游戏。 如果你创建一个新的地方/场所/场景，你可能需要将它添加到这里。
为include语句添加描述。 许多描述文本代码都在这些内部。
建议移动或移除引用不再需要的事物的旧评论。
 */

[SWF(width="1000", height="800", backgroundColor="0x000000", pageTitle="Corruption of Champions")]

public class CoC extends MovieClip implements GuiInput {
    {
        /*
            这是一个静态的初始化块，用来设置一个丑陋的黑客
           在任何类变量初始化之前进行日志记录。
           这样做是因为他们可以在测试过程中记录消息。
         */

        CoC.setUpLogging();
    }

    //包括功能。 所有功能
    include "../../includes/debug.as";
    include "../../includes/eventParser.as";
    include "../../includes/engineCore.as";

    //在游戏保存或加载时需要注意的任何类都可以使用saveAwareAdd将自己添加到该阵列中。
    //一旦在数组中，只要游戏需要它们将数据写入或读取到flags数组，它们就会被Saves.as通知。
    private static var _saveAwareClassList:Vector.<SaveAwareInterface> = new Vector.<SaveAwareInterface>();

    //由Saves中的saveGameObject函数调用
    public static function saveAllAwareClasses(game:CoC):void {
        for (var sac:int = 0; sac < _saveAwareClassList.length; sac++)
            _saveAwareClassList[sac].updateBeforeSave(game);
    }

    //由Saves中的loadGameObject函数调用
    public static function loadAllAwareClasses(game:CoC):void {
        for (var sac:int = 0; sac < _saveAwareClassList.length; sac++)
            _saveAwareClassList[sac].updateAfterLoad(game);
    }

    public static function saveAwareClassAdd(newEntry:SaveAwareInterface):void {
        _saveAwareClassList.push(newEntry);
    }

    //任何需要了解时间流逝的类都可以使用timeAwareAdd将它们自己添加到该数组中。
    //一旦进入阵列，他们会在每个小时过去的时候收到通知，允许他们更新行动，哺乳期，怀孕等。
    private static var _timeAwareClassList:Vector.<TimeAwareInterface> = new Vector.<TimeAwareInterface>(); //通过eventParser中的goNext函数访问
    private static var timeAwareLargeLastEntry:int = -1; //eventParser用于调用timeAwareLarge
    private var playerEvent:PlayerEvents;

    public static function timeAwareClassAdd(newEntry:TimeAwareInterface):void {
        _timeAwareClassList.push(newEntry);
    }

    private static var doCamp:Function; //露营由campInitialize设置，只能由playerMenu调用

    private static function campInitialize(passDoCamp:Function):void {
        doCamp = passDoCamp;
    }

    // /
    private var _perkLib:PerkLib = new PerkLib(); // to init the static
    private var _statusEffects:StatusEffects = new StatusEffects(); // to init the static
    public var charCreation:CharCreation = new CharCreation();
    public var playerAppearance:PlayerAppearance = new PlayerAppearance();
    public var playerInfo:PlayerInfo = new PlayerInfo();
    public var saves:Saves = new Saves(gameStateDirectGet, gameStateDirectSet);
    public var perkTree:PerkTree = new PerkTree();
    // Items/
    public var mutations:Mutations = Mutations.init();
    public var consumables:ConsumableLib = new ConsumableLib();
    public var useables:UseableLib;
    public var weapons:WeaponLib = new WeaponLib();
    public var armors:ArmorLib = new ArmorLib();
    public var undergarments:UndergarmentLib = new UndergarmentLib();
    public var jewelries:JewelryLib = new JewelryLib();
    public var shields:ShieldLib = new ShieldLib();
    public var miscItems:MiscItemLib = new MiscItemLib();
    // Scenes/
    public var achievementList:Achievements = new Achievements();
    public var camp:Camp = new Camp(campInitialize);
    public var dreams:Dreams = new Dreams();
    public var dungeons:DungeonCore;
    public var equipmentUpgrade:ItemUpgrade = new ItemUpgrade();
    public var followerInteractions:FollowerInteractions = new FollowerInteractions();
    public var inventory:Inventory = new Inventory(saves);
    public var masturbation:Masturbation = new Masturbation();
    public var pregnancyProgress:PregnancyProgression;
    public var bimboProgress:BimboProgression = new BimboProgression();

    // Scenes/Areas/
    public var commonEncounters:CommonEncounters = new CommonEncounters(); // Common dependencies go first

    public var bog:Bog;
    public var desert:Desert = new Desert();
    public var forest:Forest = new Forest();
    public var deepWoods:DeepWoods = new DeepWoods(forest);
    public var glacialRift:GlacialRift = new GlacialRift();
    public var highMountains:HighMountains;
    public var lake:Lake;
    public var mountain:Mountain;
    public var plains:Plains;
    public var swamp:Swamp;
    public var volcanicCrag:VolcanicCrag;

    public var exploration:Exploration = new Exploration(); //Goes last in order to get it working.
    // Scenes/Combat/
    public var combat:Combat = new Combat();
    // Scenes/Dungeons
    public var brigidScene:BrigidScene = new BrigidScene();
    public var lethicesKeep:LethicesKeep = new LethicesKeep();
    // Scenes/Explore/
    public var gargoyle:Gargoyle = new Gargoyle();
    public var lumi:Lumi = new Lumi();
    public var giacomoShop:Giacomo = new Giacomo();
    // Scenes/Monsters/
    public var goblinScene:GoblinScene = new GoblinScene();
    public var goblinAssassinScene:GoblinAssassinScene = new GoblinAssassinScene();
    public var goblinWarriorScene:GoblinWarriorScene = new GoblinWarriorScene();
    public var goblinShamanScene:GoblinShamanScene = new GoblinShamanScene();
    public var goblinElderScene:PriscillaScene = new PriscillaScene();
    public var impScene:ImpScene;
    public var mimicScene:MimicScene = new MimicScene();
    public var succubusScene:SuccubusScene = new SuccubusScene();
    // Scenes/NPC/
    public var amilyScene:AmilyScene;
    public var anemoneScene:AnemoneScene;
    public var arianScene:ArianScene = new ArianScene();
    public var ceraphScene:CeraphScene = new CeraphScene();
    public var ceraphFollowerScene:CeraphFollowerScene = new CeraphFollowerScene();
    public var emberScene:EmberScene;
    public var exgartuan:Exgartuan = new Exgartuan();
    public var helFollower:HelFollower = new HelFollower();
    public var helScene:HelScene = new HelScene();
    public var helSpawnScene:HelSpawnScene = new HelSpawnScene();
    public var holliScene:HolliScene = new HolliScene();
    public var isabellaScene:IsabellaScene = new IsabellaScene();
    public var isabellaFollowerScene:IsabellaFollowerScene = new IsabellaFollowerScene();
    public var izmaScene:IzmaScene;
    public var jojoScene:JojoScene;
    public var joyScene:JoyScene = new JoyScene();
    public var kihaFollower:KihaFollower = new KihaFollower();
    public var kihaScene:KihaScene = new KihaScene();
    public var latexGirl:LatexGirl = new LatexGirl();
    public var marbleScene:MarbleScene;
    public var marblePurification:MarblePurification = new MarblePurification();
    public var milkWaifu:MilkWaifu = new MilkWaifu();
    public var raphael:Raphael = new Raphael();
    public var rathazul:Rathazul = new Rathazul();
    public var sheilaScene:SheilaScene = new SheilaScene();
    public var shouldraFollower:ShouldraFollower = new ShouldraFollower();
    public var shouldraScene:ShouldraScene = new ShouldraScene();
    public var sophieBimbo:SophieBimbo = new SophieBimbo();
    public var sophieFollowerScene:SophieFollowerScene = new SophieFollowerScene();
    public var sophieScene:SophieScene = new SophieScene();
    public var urta:UrtaScene = new UrtaScene();
    public var urtaHeatRut:UrtaHeatRut = new UrtaHeatRut();
    public var urtaPregs:UrtaPregs;
    public var valeria:Valeria = new Valeria();
    public var vapula:Vapula = new Vapula();
    // Scenes/Places/
    public var bazaar:Bazaar = new Bazaar();
    public var boat:Boat = new Boat();
    public var farm:Farm = new Farm();
    public var owca:Owca = new Owca();
    public var telAdre:TelAdre;
    public var ingnam:Ingnam = new Ingnam();
    public var prison:Prison = new Prison();
    public var townRuins:TownRuins = new TownRuins();
    // Scenes/Seasonal/
    public var aprilFools:AprilFools = new AprilFools();
    public var fera:Fera = new Fera();
    public var thanksgiving:Thanksgiving = new Thanksgiving();
    public var valentines:Valentines = new Valentines();
    public var xmas:XmasBase = new XmasBase();
    // Scenes/Quests/
    public var urtaQuest:UrtaQuest = new UrtaQuest();

    public var mainMenu:MainMenu = new MainMenu();
    public var gameSettings:GameSettings = new GameSettings();
    public var debugMenu:DebugMenu = new DebugMenu();
    public var crafting:Crafting = new Crafting();

    // Force updates in Pepper Flash ahuehue
    private var _updateHack:Sprite = new Sprite();

    public var mainViewManager:MainViewManager = new MainViewManager();
    //Scenes in includes folder GONE! Huzzah!

    public var bindings:Bindings = new Bindings();
    public var output:Output = Output.init();
    public var credits:Credits = Credits.init();
    public var measurements:Measurements = Measurements.init();
    /****
     这是纯粹用于沼泽，而我们把事情清理干净。
       希望，任何你坚持这个对象的东西都可以最终被移除。
          我只用它，因为由于某种原因，Flash编译器没有看到
           某些功能，尽管它们与范围相同
           函数调用它们。
     ****/

    public var mainView:MainView;

    public var parser:Parser;

    // 所有变量：
    // 将各种全局变量声明为类变量。
    // 请注意，它们是在构造函数中设置的，而不是在这里。
    public var debug:Boolean;
    public var ver:String;
    public var version:String;
    public var versionID:uint = 0;
    public var permObjVersionID:uint = 0;
    public var mobile:Boolean;
    public var images:ImageManager;
    public var player:Player;
    public var player2:Player;
    public var monster:Monster;
    public var flags:DefaultDict;
    public var achievements:DefaultDict;
    private var _gameState:int;

    public function get gameState():int {
        return _gameState;
    }

    public var time:Time;

    public var temp:int;
    public var args:Array;
    public var funcs:Array;
    public var oldStats:*; // I *think* this is a generic object
    public var inputManager:InputManager;

    public var kFLAGS_REF:*;
    public var kACHIEVEMENTS_REF:*;

    public function clearOutput():void {
        output.clear(true);
    }

    public function rawOutputText(text:String):void {
        output.raw(text);
    }

    public function outputText(text:String):void {
        output.text(text);
    }

    public function displayHeader(string:String):void {
        output.text(output.formatHeader(string));
    }

    public function formatHeader(string:String):String {
        return output.formatHeader(string);
    }

    public function get inCombat():Boolean {
        return _gameState == 1;
    }

    public function set inCombat(value:Boolean):void {
        _gameState = (value ? 1 : 0);
    }

    public function gameStateDirectGet():int {
        return _gameState;
    }

    public function gameStateDirectSet(value:int):void {
        _gameState = value;
    }

    public function rand(max:int):int {
        return Utils.rand(max);
    }

    //System time
    public var date:Date = new Date();

    //Mod save version.
    public var modSaveVersion:Number = 15;
    public var levelCap:Number = 120;

    //dungeoneering variables (If it ain't broke, don't fix it)
    public var inDungeon:Boolean = false;
    public var dungeonLoc:int = 0;

    // To save shitting up a lot of code...
    public var inRoomedDungeon:Boolean = false;
    public var inRoomedDungeonResume:Function = null;
    public var inRoomedDungeonName:String = "";

    public var timeQ:Number = 0;
    public var campQ:Boolean = false;

    private static var traceTarget:TraceTarget;

    private static function setUpLogging():void {
        traceTarget = new TraceTarget();

        traceTarget.level = LogEventLevel.WARN;

        CONFIG::debug
        {
            traceTarget.level = LogEventLevel.DEBUG;
        }

        //Add date, time, category, and log level to the output
        traceTarget.includeDate = true;
        traceTarget.includeTime = true;
        traceTarget.includeCategory = true;
        traceTarget.includeLevel = true;

        // let the logging begin!
        Log.addTarget(traceTarget);
    }

    /**
     * Create scenes that use the new pregnancy system. This method is public to allow for simple testing.
     * @param pregnancyProgress Pregnancy progression to use for scenes, which they use to register themself
     */
    public function createScenes(pregnancyProgress:PregnancyProgression):void {
        this.dungeons = new DungeonCore(pregnancyProgress);

        this.bog = new Bog(pregnancyProgress);
        this.mountain = new Mountain(pregnancyProgress, output);
        this.highMountains = new HighMountains(pregnancyProgress, output);
        this.volcanicCrag = new VolcanicCrag(pregnancyProgress, output);
        this.swamp = new Swamp(pregnancyProgress, output);
        this.plains = new Plains(pregnancyProgress, output);
        this.telAdre = new TelAdre(pregnancyProgress);

        this.impScene = new ImpScene(pregnancyProgress, output);
        this.anemoneScene = new AnemoneScene(pregnancyProgress, output);
        this.marbleScene = new MarbleScene(pregnancyProgress, output);
        this.jojoScene = new JojoScene(pregnancyProgress, output);
        this.amilyScene = new AmilyScene(pregnancyProgress, output);
        this.izmaScene = new IzmaScene(pregnancyProgress, output);
        this.lake = new Lake(pregnancyProgress, output);

        // not assigned to a variable as it is self-registering, PregnancyProgress will keep a reference to the instance
        new PlayerCentaurPregnancy(pregnancyProgress, output);
        new PlayerBunnyPregnancy(pregnancyProgress, output, mutations);
        new PlayerBenoitPregnancy(pregnancyProgress, output);
        new PlayerOviElixirPregnancy(pregnancyProgress, output);

        this.emberScene = new EmberScene(pregnancyProgress);
        this.urtaPregs = new UrtaPregs(pregnancyProgress);
    }

    /**
     * Create the main game instance.
     * If a stage is injected it will be use instead of the one from the superclass.
     *
     * @param injectedStage if not null, it will be used instead of this.stage
     */
    public function CoC(injectedStage:Stage = null) {
        var stageToUse:Stage;

        if (injectedStage != null) {
            stageToUse = injectedStage;
        }
        else {
            stageToUse = this.stage;
        }

        // Cheatmode.
        kGAMECLASS = this;

        this.pregnancyProgress = new PregnancyProgression();
        createScenes(pregnancyProgress);

        useables = new UseableLib();

        this.kFLAGS_REF = kFLAGS;
        this.kACHIEVEMENTS_REF = kACHIEVEMENTS;
        // cheat for the parser to be able to find kFLAGS
        // If you're not the parser, DON'T USE THIS

        this.parser = new Parser(this, CoC_Settings);

        try {
            this.mainView = new MainView(/*this.model*/);
            if (CoC_Settings.charviewEnabled)
                this.mainView.charView.reload();
        }
        catch (e:Error) {
            throw Error(e.getStackTrace());
        }
        this.mainView.name = "mainView";
        this.mainView.addEventListener(Event.ADDED_TO_STAGE, Utils.curry(_postInit, stageToUse));
        stageToUse.addChild(this.mainView);
    }

    private function _postInit(stageToUse:DisplayObjectContainer, e:Event):void {
        // Hooking things to MainView.
        this.mainView.onNewGameClick = charCreation.newGameGo;
        this.mainView.onAppearanceClick = playerAppearance.appearance;
        this.mainView.onDataClick = saves.saveLoad;
        this.mainView.onLevelClick = playerInfo.levelUpGo;
        this.mainView.onPerksClick = playerInfo.displayPerks;
        this.mainView.onStatsClick = playerInfo.displayStats;
        this.mainView.onBottomButtonClick = function (i:int):void {
            output.record("<br>[" + output.button(i).labelText + "]<br>");
        };

        // Set up all the messy global stuff:

        // ******************************************************************************************

        var mainView:MainView = this.mainView;

        /**
         * Global Variables used across the whole game. I hope to whittle it down slowly.
         */

        /**
         * System Variables
         * Debug, Version, etc
         */
        debug = false; //DEBUG, used all over the place
        ver = "1.0.2_mod_1.4.13"; //Version NUMBER
        version = ver + " (<b>Weapon Upgrading!</b>)"; //Version TEXT

        //Indicates if building for mobile?
        mobile = false;

        this.images = new ImageManager(stageToUse.stage, mainView);
        this.inputManager = new InputManager(stageToUse.stage, mainView, false);
        include "../../includes/ControlBindings.as";

        //} endregion

        /**
         * Player specific variables
         * The player object and variables associated with the player
         */
        //{ region PlayerVariables

        //The Player object, used everywhere
        player = new Player();
        player2 = new Player();
        playerEvent = new PlayerEvents();

        //Used in perk selection, mainly eventParser, input and engineCore
        //tempPerk = null;

        //Create monster, used all over the place
        monster = new Monster();
        //} endregion

        /**
         * State Variables
         * They hold all the information about item states, menu states, game states, etc
         */
        //{ region StateVariables

        //User all over the place whenever items come up

        //The extreme flag state array. This needs to go. Holds information about everything, whether it be certain attacks for NPCs
        //or state information to do with the game.
        flags = new DefaultDict();
        achievements = new DefaultDict();

        /**
         * Used everywhere to establish what the current game state is
         * 0 = normal
         * 1 = in combat
         * 2 = in combat in grapple
         * 3 = at start or game over screen
         */
        _gameState = 0;

        /**
         * Display Variables
         * Variables that hold display information like number of days and all the current displayed text
         */
        //{ region DisplayVariables

        //Holds the date and time display in the bottom left
        time = new Time();

        //The string holds all the "story" text, mainly used in engineCore
        //}endregion

        // These are toggled between by the [home] key.
        mainView.textBGTranslucent.visible = true;
        mainView.textBGWhite.visible = false;
        mainView.textBGTan.visible = false;

        // *************************************************************************************
        //Workaround.
        mainViewManager.registerShiftKeys();
        exploration.configureRooms();
        lethicesKeep.configureRooms();
        dungeons.map = new DungeonMap();

        temp = 0; //Fenoxo loves his temps

        //Used to set what each action buttons displays and does.
        args = [];
        funcs = [];

        //Used for stat tracking to keep up/down arrows correct.
        oldStats = {};
        oldStats.oldStr = 0;
        oldStats.oldTou = 0;
        oldStats.oldSpe = 0;
        oldStats.oldInte = 0;
        oldStats.oldSens = 0;
        oldStats.oldLib = 0;
        oldStats.oldCor = 0;
        oldStats.oldHP = 0;
        oldStats.oldLust = 0;
        oldStats.oldFatigue = 0;
        oldStats.oldHunger = 0;

        //model.maxHP = maxHP;

        // ******************************************************************************************

        mainView.aCb.items = [{label: "TEMP", perk: new PerkClass(PerkLib.Acclimation)}];
        mainView.aCb.addEventListener(Event.SELECT, playerInfo.changeHandler);

        //Register the classes we need to be able to serialize and reconstitute so
        // they'll get reconstituted into the correct class when deserialized
        registerClassAlias("AssClass", AssClass);
        registerClassAlias("Character", Character);
        registerClassAlias("Cock", Cock);
        registerClassAlias("CockTypesEnum", CockTypesEnum);
        registerClassAlias("Enum", Enum);
        registerClassAlias("Creature", Creature);
        registerClassAlias("ItemSlotClass", ItemSlotClass);
        registerClassAlias("KeyItemClass", KeyItemClass);
        registerClassAlias("Monster", Monster);
        registerClassAlias("Player", Player);
        registerClassAlias("StatusEffectClass", StatusEffectClass);
        registerClassAlias("VaginaClass", VaginaClass);

        //Hide sprites
        mainView.hideSprite();
        //Hide up/down arrows
        mainView.statsView.hideUpDown();

        this.addFrameScript(0, this.run);
    }

    public function run():void {
        //Set up stage
        stage.focus = kGAMECLASS.mainView.mainText;
        mainView.eventTestInput.x = -10207.5;
        mainView.eventTestInput.y = -1055.1;
        mainViewManager.startUpButtons();
        saves.loadPermObject();
        mainViewManager.setTheme();
        mainView.setTextBackground(flags[kFLAGS.TEXT_BACKGROUND_STYLE]);
        //Now enter the main menu.
        mainMenu.mainMenu();

        this.stop();

        if (_updateHack) {
            _updateHack.name = "wtf";
            _updateHack.graphics.beginFill(0xFF0000, 1);
            _updateHack.graphics.drawRect(0, 0, 2, 2);
            _updateHack.graphics.endFill();

            stage.addChild(_updateHack);
            _updateHack.x = 999;
            _updateHack.y = 799;
        }
    }

    public function forceUpdate():void {
        _updateHack.x = 999;
        _updateHack.addEventListener(Event.ENTER_FRAME, moveHackUpdate);
    }

    public function moveHackUpdate(e:Event):void {
        _updateHack.x -= 84;

        if (_updateHack.x < 0) {
            _updateHack.x = 0;
            _updateHack.removeEventListener(Event.ENTER_FRAME, moveHackUpdate);
        }
    }

    public function spriteSelect(choice:Object = 0):void {
        // Inlined call from lib/src/coc/view/MainView.as
        // TODO: When flags goes away, if it goes away, replace this with the appropriate settings thing.
        if (choice <= 0 || choice == null || flags[kFLAGS.SHOW_SPRITES_FLAG] == 0) {
            mainViewManager.hideSprite();
        }
        else {
            if (choice is Class) {
                mainViewManager.showSpriteBitmap(SpriteDb.bitmapData(choice as Class));
            }
            else {
                mainViewManager.hideSprite();
            }
        }
    }

    // TODO remove once that GuiInput interface has been sorted
    public function addButton(pos:int, text:String = "", func1:Function = null, arg1:* = -9000, arg2:* = -9000, arg3:* = -9000, toolTipText:String = "", toolTipHeader:String = ""):CoCButton {
        return output.addButton(pos, text, func1, arg1, arg2, arg3, toolTipText, toolTipHeader);
    }

    // TODO remove once that GuiInput interface has been sorted
    public function menu():void {
        output.menu();
    }
}
}
