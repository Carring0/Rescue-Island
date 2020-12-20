
program Rescue_Island;

{$ifdef MSWINDOWS} {$apptype GUI} {$endif}


uses Classes, SysUtils, StrUtils, Dialogs,
  CastleWindow,CastleUtils, CastleUIControls, CastleGLImages, CastleFilesUtils,
  CastleKeysMouse, CastleVectors, CastleViewport, CastleSoundEngine, CastleTimeUtils, CastleColors,
  CastleRectangles, CastleFonts, CastleGLUtils, Generics.Defaults, CastleUIState,
  Generics.Collections,Math, CastleOnScreenMenu, CastleControls, CastleDownload; //CastleControl, CastleControls,


type
  TPlayerHud = class(TCastleUserInterface)
     procedure Render; override;
  end;


type
   TPlayer = class
   private
   type TPersonalia = class
   Gender: string; // m or w
   FirstName, LastName, FullName: string;
   Known: Boolean; // if you haven't talked to this character you won't know it's name
   Age: Integer;
   end;
   var Personalia: TPersonalia;

   private
   type TCharacter = class
   GreetingLine: string;
   AnswerLine: string;
   Action: string;
   Stamina: Integer; // uithoudingsvermogen
   Health: Integer; // gezondheidsniveau
   Strength: Integer; // kracht
   end;
   var Character: TCharacter;

   private
   type TAppearance = class
   Outfit: string; // kleding
   end;
   var Appearance: TAppearance;

   public
   WalkSprite, WalkLeftSprite, WalkNWSprite, WalkBackSprite, WalkNESprite, WalkRightSprite, WalkSESprite, WalkFrontSprite, WalkSWSprite: TSprite;
   StandSprite, StandLeftSprite, StandRightSprite, StandFrontSprite, StandBackSprite, StandSWSprite, StandSESprite, StandNWSprite, StandNESprite: TSprite;
   CurrentSprite, DatabaseSprite, TurnSprite, CloseUpSprite, CloseUpSilentSprite, CloseUpSmallTalkSprite, CloseUpBigTalkSprite: TSprite;
   Spritescreen, TurnSpriteScreen, CloseUpScreen, CloseUpSilent, CloseUpSmallTalk, CloseUpBigTalk: string;
   SpriteScr: array[1..24] of string;
   Location, DestinationLocation: string; // for setting game location of Player or Non-Playing Character (NPC)
   X, Y: Integer;
   NR: Integer;
   Selected, TalkSelected: boolean;
   XMoveLeft, XMoveRight: boolean;
   FollowPlayer: boolean;
   Center: float;
   WalkLeft, WalkRight, WalkFront, WalkBack, WalkSW, WalkSE, WalkNW, WalkNE: integer;  // animation sequence
   StandAnimation, WalkAnimation, TurnAnimation, CloseUpAnimation, CloseUpSilentAnimation, CloseUpSmallTalkAnimation, CloseUpBigTalkAnimation, StandLeft, StandRight, StandFront, StandBack, StandSW, StandSE, StandNW, StandNE: integer; // animation sequence
   MoveLeft, MoveRight, MoveDown, MoveUp, MoveSW, MoveSE, MoveNW, MoveNE : boolean; // switches
   WalkLeftLoaded, WalkRightLoaded, StandLeftLoaded, StandRightLoaded, StandSWLoaded, StandSELoaded, StandFrontLoaded, StandBackLoaded: boolean;
   Stand, Walk, ApproachFromRight, ApproachFromLeft, CloseUp: boolean;
   MoveToMouse, MoveToPlayer: boolean;// MoveToNPC: boolean;
   DestX, DestY: float;
   DestinationLocationX, DestinationLocationY : Integer;
   Talkedto: String;
   Left: boolean;
   Zone: TFloatRectangle;
   function Rect: TFloatRectangle;
   //  function CloseUpRect: TFloatRectangle;
   constructor Create;
   destructor Destroy; override;
   //procedure Update(const SecondsPassed: TFloatTime);
   end;

 type
    TLocation = class
    public
    Name: String;
    BackGround: TDrawableImage;
    ShortDescription: String;
    LongDescription: String;
    LimitTop, LimitDown, LimitLeft, LimitRight: single;
    ExitRight, ExitLeft, ExitTop, ExitDown: array[1..10] of string; // location exits
    ExitRX, ExitLX, ExitTY, ExitDY: integer;
    Entrance: string;
    NPC_Presence: boolean;  // if NPC sprites are present on location: perform certain routines, otherwise not
    NPC_Total: integer; //  total number of NPC characters on location
    // private
    type TNPC = class
    NR: Integer;
    end;
    var NPC: TNPC;

    constructor Create;
    destructor Destroy; override;
  end;


 type
    TMouse = class
    public
    MouseImages: TSprite;
    CurrentSprite : TSprite;
    Action: array[0..9] of Integer;
    NR: Integer;
    function Rect: TFloatRectangle;
    constructor Create;
    destructor Destroy; override;
 end;

 type
    TEventHandler = class
    class procedure FollowPlayerClick(Sender: TObject);
    class procedure StayOnLocationClick(Sender: TObject);
    class procedure GoToLocationClick(Sender: TObject);
    class procedure AskForInformationClick(Sender: TObject);
    class procedure CancelOrdersClick(Sender: TObject);
    class procedure CancelLocationsClick (Sender: TObject);
    class procedure GoToWestbeachNPCClick(Sender: TObject);
    class procedure GoToPassagebeachNPCClick(Sender: TObject);
    class procedure GoToEastbeachNPCClick(Sender: TObject);
    class procedure StartTalkNPCClick(Sender: TObject);
    class procedure CheckKnowledgeNPCClick(Sender: TObject);
    class procedure QuitTalkNPCClick (Sender: TObject);
    class procedure CrewmemberListNPCClick (Sender: TObject);
    class procedure CrewmemberLocationClick (Sender: TObject);
    class procedure CrewmemberProfessionClick (Sender: Tobject);
    class procedure CrewmemberInformationClick (Sender: TObject);
 end;



type
  TNPCList = specialize TObjectList<TPlayer>;

  TSpriteList = specialize TObjectList<TPlayer>;

  type
  TSpriteComparer = specialize TComparer<TPlayer>;


 var
  Window: TCastleWindowbase;
  ControlThatDeterminesMouseCursor: TCastleUserInterface;
  Location: Tlocation;
  GameMouse: TMouse;
  Player: TPlayer;
  CloseUpFrame: TDrawableImage;
  OnScreenOrderMenu, OnScreenLocationMenu, OnScreenConversationMenu, OnScreenCrewmemberMenu, OnScreenCrewmemberInfoMenu: TCastleOnScreenMenu;
  TalkTextLabel: TCastleLabel;
  PlayerHud: TPlayerHud;
  ReadString, SearchString: string;
  StartPos, EndPos: Integer;
  Text: TTextReader;
  GameStart: boolean;
  DBfile: string;

  // NPC stuff
  NPC: array[1..30] of TPlayer;
  NPCinfo: array[1..10] of TPlayer;
  NPCAmount: Integer; // total number of NPC sprites in game database

  Count:Integer;

 // Locations: string = 'castle-data:/Locations/';
  Characters: string = 'castle-data:/Characters/';   // location of the graphics

  Box: array[1..30] of TPlayer;
   //Buffer: TSoundBuffer;
  // let op dat bij het volgende de truetype library freetype-6.dll in de game dir staat!!
  MyTextureFont: TTextureFont;   // gebruikt om tekst op scherm te printen
  MyBigTextureFont: TTextureFont;
  TextLine1, TextLine2, TextLine3, TextLine4, TextLine5: string;
  LabelText: string;
  rgb1, rgb2, rgb3: Single;

  Const SWidth = 180 * 2;  // Sprite Width
  Const SHeight = 315 * 2;  // Sprite Height


  var InitialDBfile: Textfile;
  var ProgressDBfile: Textfile;


  constructor TPlayer.Create;
  begin
    inherited;
    Personalia := TPersonalia.Create;
    Character :=  TCharacter.Create;
    Appearance := TAppearance.Create;
  end;

  constructor TLocation.Create;
  begin
    inherited;
    NPC := TNPC.Create;
  end;

  constructor TMouse.Create;
  begin
    inherited;
  end;

  destructor TMouse.Destroy;
  begin
    FreeAndNil (MouseImages);
    inherited;
  end;

  destructor TPlayer.Destroy;
  begin
    inherited;
  end;

  destructor TLocation.Destroy;
  begin
    FreeAndNil (BackGround);
  end;

 function CompareSprites(constref Left, Right: TPlayer): Integer;
 begin
   Result := Sign(Right.CurrentSprite.Y - Left.CurrentSprite.Y);
 end;

function TPlayer.Rect: TFloatRectangle;
var
  ScaleSprite: Single;
begin
  Assert(CurrentSprite <> nil);
  ScaleSprite := MapRange(Self.CurrentSprite.Y, 0, 500, 1.0, 0.5);
  Result := FloatRectangle(Self.CurrentSprite.X, Self.CurrentSprite.Y, Self.CurrentSprite.FrameWidth * ScaleSprite, Self.CurrentSprite.FrameHeight * ScaleSprite);
end;

function TMouse.Rect: TFloatRectangle;
var
 ScaleSprite: Single;
begin
  ScaleSprite := MapRange(Self.CurrentSprite.Y, 0, 500, 1.0, 1.0);
  Result := FloatRectangle(Self.CurrentSprite.X, Self.CurrentSprite.Y, Self.CurrentSprite.FrameWidth * ScaleSprite, Self.CurrentSprite.FrameHeight * ScaleSprite)
end;

Procedure ShowCustomMouse;
begin
  ControlThatDeterminesMouseCursor.Cursor := mcNone;
  GameMouse.CurrentSprite.DrawingWidth:= 50;
  GameMouse.CurrentSprite.DrawingHeight:= 50;
end;

Procedure ShowWindowsMouse;
begin
  ControlThatDeterminesMouseCursor.Cursor := mcStandard;
  GameMouse.CurrentSprite.DrawingWidth:= 0;
  GameMouse.CurrentSprite.DrawingHeight:= 0;
end;


Procedure NPC_StandLeft;
begin
  NPC[Location.NPC.NR].StandLeftSprite:= TSprite.CreateFrameSize (Characters + NPC[Location.NPC.NR].Personalia.FullName + '/' + NPC[Location.NPC.NR].Appearance.Outfit + '/' + NPC[Location.NPC.NR].Personalia.FirstName + 'StandLeft.png', 60, 10, SWidth, SHeight, true, true);
  NPC[Location.NPC.NR].StandLeftSprite.FramesPerSecond:= 15;
  NPC[Location.NPC.NR].StandAnimation := NPC[Location.NPC.NR].StandLeftSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
  24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
  22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
end;

Procedure NPC_StandRight;
begin
  NPC[Location.NPC.NR].StandRightSprite:= TSprite.CreateFrameSize (Characters + NPC[Location.NPC.NR].Personalia.FullName + '/' + NPC[Location.NPC.NR].Appearance.Outfit + '/' + NPC[Location.NPC.NR].Personalia.FirstName + 'StandRight.png', 60, 10, SWidth, SHeight, true, true);
  NPC[Location.NPC.NR].StandRightSprite.FramesPerSecond:= 15;
  NPC[Location.NPC.NR].StandAnimation := NPC[Location.NPC.NR].StandRightSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
  24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
  22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
end;

Procedure NPC_StandFront;
begin
  NPC[Location.NPC.NR].StandfrontSprite:= TSprite.CreateFrameSize (Characters + NPC[Location.NPC.NR].Personalia.FullName + '/' + NPC[Location.NPC.NR].Appearance.Outfit + '/' + NPC[Location.NPC.NR].Personalia.FirstName + 'StandFront.png', 60, 10, SWidth, SHeight, true, true);
  NPC[Location.NPC.NR].StandFrontSprite.FramesPerSecond:= 15;
  NPC[Location.NPC.NR].StandAnimation := NPC[Location.NPC.NR].StandFrontSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
  24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
  22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
end;

Procedure NPC_StandSW;
begin
  NPC[Location.NPC.NR].StandSWSprite:= TSprite.CreateFrameSize (Characters + NPC[Location.NPC.NR].Personalia.FullName + '/' + NPC[Location.NPC.NR].Appearance.Outfit + '/' + NPC[Location.NPC.NR].Personalia.FirstName + 'StandSW.png' , 60, 10, SWidth, SHeight, true, true);
  NPC[Location.NPC.NR].StandSWSprite.FramesPerSecond:= 15;
  NPC[Location.NPC.NR].StandAnimation := NPC[Location.NPC.NR].StandSWSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
  24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,60, 61, 62, 63,
  64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 88, 87, 86, 85, 84, 83, 82, 81, 80, 79, 78, 77, 76, 75, 74, 73, 72, 71, 70, 69, 68, 67, 66, 65, 64, 63, 62, 60, 59,
  58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
  22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
end;

Procedure NPC_StandSE;
begin
  NPC[Location.NPC.NR].StandSESprite:= TSprite.CreateFrameSize (Characters + NPC[Location.NPC.NR].Personalia.FullName + '/' + NPC[Location.NPC.NR].Appearance.Outfit + '/' + NPC[Location.NPC.NR].Personalia.FirstName + 'StandSE.png' , 60, 10, SWidth, SHeight, true, true);
  NPC[Location.NPC.NR].StandSESprite.FramesPerSecond:= 15;
  NPC[Location.NPC.NR].StandAnimation := NPC[Location.NPC.NR].StandSESprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
  24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,60, 61, 62, 63,
  64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 88, 87, 86, 85, 84, 83, 82, 81, 80, 79, 78, 77, 76, 75, 74, 73, 72, 71, 70, 69, 68, 67, 66, 65, 64, 63, 62, 60, 59,
  58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
  22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
end;

Procedure NPC_WalkLeft;
begin
  NPC[Location.NPC.NR].WalkLeftSprite := TSprite.CreateFrameSize (Characters + NPC[Location.NPC.NR].Personalia.FullName + '/' + NPC[Location.NPC.NR].Appearance.Outfit + '/' + NPC[Location.NPC.NR].Personalia.FirstName + 'WalkLeft.png', 60, 10, SWidth, SHeight, true, true);
  NPC[Location.NPC.NR].WalkLeftSprite.FramesPerSecond:= 45;
  NPC[Location.NPC.NR].WalkAnimation := NPC[Location.NPC.NR].WalkLeftSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
  31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);
end;

Procedure NPC_WalkRight;
begin
  NPC[Location.NPC.NR].WalkRightSprite := TSprite.CreateFrameSize (Characters + NPC[Location.NPC.NR].Personalia.FullName + '/' + NPC[Location.NPC.NR].Appearance.Outfit + '/' + NPC[Location.NPC.NR].Personalia.FirstName + 'WalkRight.png', 60, 10, SWidth, SHeight, true, true);
  NPC[Location.NPC.NR].WalkRightSprite.FramesPerSecond:= 45;
  NPC[Location.NPC.NR].WalkAnimation := NPC[Location.NPC.NR].WalkRightSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
  31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);
end;

Procedure NPC_Turn;
begin
  NPC[Location.NPC.NR].TurnSprite := TSprite.CreateFrameSize (Characters + NPC[Location.NPC.NR].Personalia.FullName + '/' + NPC[Location.NPC.NR].Appearance.Outfit + '/' + NPC[Location.NPC.NR].Personalia.FirstName + NPC[Location.NPC.NR].TurnSpritescreen, 60, 10, SWidth, SHeight, true, false); // no loop
  NPC[Location.NPC.NR].TurnSprite.FramesPerSecond:= 60;
  NPC[Location.NPC.NR].TurnAnimation := NPC[Location.NPC.NR].TurnSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
  31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);
end;
Procedure NPC_CloseUpSilent;
begin
  NPC[Location.NPC.NR].CloseupSprite:= TSprite.CreateFrameSize (Characters + NPC[Location.NPC.NR].Personalia.FullName + '/' + NPC[Location.NPC.NR].Appearance.Outfit + '/' + NPC[Location.NPC.NR].Personalia.FirstName + NPC[Location.NPC.NR].CloseUpScreen, 120, 10, 350, 350, true, true);
  NPC[Location.NPC.NR].CloseupSprite.FramesPerSecond:= 30;
  NPC[Location.NPC.NR].CloseupAnimation := NPC[Location.NPC.NR].CloseupSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
   31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70,
   71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108,
   109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 118, 117, 116, 115, 114, 113, 112, 111, 110, 109, 108, 107, 106, 105, 104, 103, 102, 101, 100, 99, 98, 97, 96, 95,
   94, 93, 92, 91, 90, 89, 88, 87, 86, 85, 84, 83, 82, 81, 80, 79, 78, 77, 76, 75, 74, 73, 72, 71, 70, 69, 68, 67, 66, 65, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54,
   53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 38, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13,
   12, 11, 10, 9, 8, 7, 6, 5,4, 3, 2, 1]);
end;
Procedure NPC_CloseUpSmallTalk;
begin
  NPC[Location.NPC.NR].CloseupSprite:= TSprite.CreateFrameSize (Characters + NPC[Location.NPC.NR].Personalia.FullName + '/' + NPC[Location.NPC.NR].Appearance.Outfit + '/' + NPC[Location.NPC.NR].Personalia.FirstName + NPC[Location.NPC.NR].CloseUpScreen, 120, 10, 350, 350, true, false);
  NPC[Location.NPC.NR].CloseupSprite.FramesPerSecond:= 30;
  NPC[Location.NPC.NR].CloseupAnimation := NPC[Location.NPC.NR].CloseupSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
  31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70,
  71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108,
  109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119]);
end;

Procedure NPC_CloseUpBigTalk;
begin
  NPC[Location.NPC.NR].CloseupSprite:= TSprite.CreateFrameSize (Characters + NPC[Location.NPC.NR].Personalia.FullName + '/' + NPC[Location.NPC.NR].Appearance.Outfit + '/' + NPC[Location.NPC.NR].Personalia.FirstName + NPC[Location.NPC.NR].CloseUpScreen, 120, 10, 350, 350, true, false);
  NPC[Location.NPC.NR].CloseupSprite.FramesPerSecond:= 30;
  NPC[Location.NPC.NR].CloseupAnimation := NPC[Location.NPC.NR].CloseupSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
   31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70,
   71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108,
   109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119]);
end;

Procedure PlayerStopMove;
begin
  with Player do
  begin
    MoveLeft := False;
    MoveRight := False;
    MoveUp := False;
    MoveDown := False;
    MoveSW := False;
    MoveSE := False;
    MoveNW := False;
    MoveNE := False;
  end;
end;

Procedure NPCStopMove;
begin
  with NPC[Location.NPC.NR] do
  begin
    MoveLeft := False;
    MoveRight := False;
    MoveUp := False;
    MoveDown := False;
    MoveSW := False;
    MoveSE := False;
    MoveNW := False;
    MoveNE := False;
  end;
end;

Procedure PlayerGoLeft;
begin
  with Player do
  begin
    WalkLeftSprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkLeftSprite;
    WalkLeftSprite.SwitchToAnimation(WalkLeft);
    WalkLeftSprite.Play;
    MoveLeft := True;
    Stand := False;
  end;
end;

Procedure PlayerGoRight;
begin
  with Player do
  begin
    WalkRightSprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkRightSprite;
    WalkRightSprite.SwitchToAnimation(WalkRight);
    WalkRightSprite.Play;
    MoveRight := True;
    Stand := False;
  end;
end;

Procedure PlayerGoUp;
begin
  with Player do
  begin
    WalkBackSprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkBackSprite;
    WalkBackSprite.SwitchToAnimation(WalkBack);
    WalkBackSprite.Play;
    MoveUp := True;
    Stand := False;
  end;
end;

Procedure PlayerGoDown;
begin
  with Player do
  begin
    WalkFrontSprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkFrontSprite;
    WalkFrontSprite.SwitchToAnimation(WalkFront);
    WalkFrontSprite.Play;
    MoveDown := True;
    Stand := False;
  end;
end;

Procedure PlayerGoSW;
begin
  with Player do
  begin
    WalkSWSprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkSWSprite;
    WalkSWSprite.SwitchToAnimation(WalkSW);
    WalkSWSprite.Play;
    MoveSW := True;
    Stand := False;
    end;
end;

Procedure PlayerGoSE;
begin
  with Player do
  begin
    WalkSESprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkSESprite;
    WalkSESprite.SwitchToAnimation(WalkSE);
    WalkSESprite.Play;
    MoveSE := True;
    Stand := False;
  end;
end;

Procedure PlayerGoNE;
begin
  with Player do
  begin
    WalkNESprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkNESprite;
    WalkNESprite.SwitchToAnimation(WalkNE);
    WalkNESprite.Play;
    MoveNE := True;
    Stand := False;
  end;
end;

Procedure PlayerGoNW;
begin
  with Player do
  begin
    WalkNWSprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkNWSprite;
    WalkSprite.SwitchToAnimation(WalkNW);
    WalkNWSprite.Play;
    MoveNW := True;
    Stand := False;
  end;
end;

Procedure PlayerStandBack;
begin
  with Player do
  begin
    StandBackSprite.Position := CurrentSprite.Position;
    CurrentSprite := StandBackSprite;
    StandBackSprite.SwitchToAnimation(StandBack);
    StandBackSprite.Play;
    PlayerStopMove;
    Stand := True;
  end;
end;

Procedure PlayerStandFront;
begin
  with Player do
  begin
    StandFrontSprite.Position := CurrentSprite.Position;
    CurrentSprite := StandFrontSprite;
    StandFrontSprite.SwitchToAnimation(StandFront);
    StandFrontSprite.Play;
    PlayerStopMove;
    Stand := True;
  end;
end;

Procedure PlayerStandLeft;
begin
  with Player do
  begin
    StandLeftSprite.Position := CurrentSprite.Position;
    CurrentSprite := StandLeftSprite;
    StandLeftSprite.SwitchToAnimation(StandLeft);
    StandLeftSprite.Play;
    PlayerStopMove;
    Stand := True;
  end;
end;

Procedure PlayerStandRight;
begin
  with Player do
  begin
    StandRightSprite.Position := CurrentSprite.Position;
    CurrentSprite := StandRightSprite;
    StandRightSprite.SwitchToAnimation(StandRight);
    StandRightSprite.Play;
    PlayerStopMove;
    Stand := True;
  end;
end;

Procedure PlayerStandSW;
begin
  with Player do
  begin
    StandSWSprite.Position := CurrentSprite.Position;
    CurrentSprite := StandSWSprite;
    StandSWSprite.SwitchToAnimation(StandSW);
    StandSWSprite.Play;
    PlayerStopMove;
    Stand := True;
  end;
end;

Procedure PlayerStandSE;
begin
  with Player do
  begin
    StandSESprite.Position := CurrentSprite.Position;
    CurrentSprite := StandSESprite;
    StandSESprite.SwitchToAnimation(StandSE);
    StandSESprite.Play;
    PlayerStopMove;
    Stand := True;
  end;
end;

Procedure PlayerStandNW;
begin
  with Player do
  begin
    StandNWSprite.Position := CurrentSprite.Position;
    CurrentSprite := StandNWSprite;
    StandNWSprite.SwitchToAnimation(StandNW);
    StandNWSprite.Play;
    PlayerStopMove;
    Stand := True;
  end;
end;

Procedure PlayerStandNE;
begin
  with Player do
  begin
    StandNESprite.Position := CurrentSprite.Position;
    CurrentSprite := StandNESprite;
    StandNESprite.SwitchToAnimation(StandNE);
    StandNESprite.Play;
    PlayerStopMove;
    Stand := True;
  end;
end;

Procedure NPCGoLeft;
begin
  with NPC[Location.NPC.NR] do
  begin
    if WalkLeftLoaded = False then
    begin
      NPC_WalkLeft; // load animation sequence
      WalkLeftLoaded := True;
    end;
    SpriteScreen := 'WalkLeft.png';
    WalkLeftSprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkLeftSprite;
    WalkLeftSprite.SwitchToAnimation(WalkLeft);
    WalkLeftSprite.Play;
    MoveLeft := True;
    Stand := False;
  end;
end;

Procedure NPCGoRight;
begin
  with NPC[Location.NPC.NR] do
  begin
    if WalkRightLoaded = False then
    begin
      NPC_WalkRight; // load animation sequence
      WalkRightLoaded := True;
    end;
    SpriteScreen := 'WalkRight.png';
    WalkRightSprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkRightSprite;
    WalkRightSprite.SwitchToAnimation(WalkRight);
    WalkRightSprite.Play;
    MoveRight := True;
    Stand := False;
  end;
end;

Procedure NPCGoUp;
begin
  with NPC[Location.NPC.NR] do
  begin
    WalkBackSprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkBackSprite;
    WalkBackSprite.SwitchToAnimation(WalkBack);
    WalkBackSprite.Play;
    MoveUp := True;
    Stand := False;
  end;
end;

Procedure NPCGoDown;
begin
  with NPC[Location.NPC.NR] do
  begin
    WalkFrontSprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkFrontSprite;
    WalkFrontSprite.SwitchToAnimation(WalkFront);
    WalkFrontSprite.Play;
    MoveDown := True;
    Stand := False;
  end;
end;

Procedure NPCGoSW;
begin
  with NPC[Location.NPC.NR] do
  begin
    WalkSWSprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkSWSprite;
    WalkSWSprite.SwitchToAnimation(WalkSW);
    WalkSWSprite.Play;
    MoveSW := True;
    Stand := False;
  end;
end;

Procedure NPCGoSE;
begin
  with NPC[Location.NPC.NR] do
  begin
    WalkSESprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkSESprite;
    WalkSESprite.SwitchToAnimation(WalkSE);
    WalkSESprite.Play;
    MoveSE := True;
    Stand := False;
  end;
end;

Procedure NPCGoNE;
begin
  with NPC[Location.NPC.NR] do
  begin
    WalkNESprite.Position := CurrentSprite.Position;
     CurrentSprite := WalkNESprite;
     WalkNESprite.SwitchToAnimation(WalkNE);
     WalkNESprite.Play;
     MoveNE := True;
     Stand := False;
   end;
end;

Procedure NPCGoNW;
begin
  with NPC[Location.NPC.NR] do
  begin
    WalkNWSprite.Position := CurrentSprite.Position;
    CurrentSprite := WalkNWSprite;
    WalkSprite.SwitchToAnimation(WalkNW);
    WalkNWSprite.Play;
    MoveNW := True;
    Stand := False;
  end;
end;

Procedure NPCStandBack;
begin
  with NPC[Location.NPC.NR] do
  begin
    StandBackSprite.Position := CurrentSprite.Position;
    CurrentSprite := StandBackSprite;
    StandBackSprite.SwitchToAnimation(StandBack);
    StandBackSprite.Play;
    NPCStopMove;
    Stand := True;
  end;
end;

Procedure NPCStandFront;
begin
  with NPC[Location.NPC.NR] do
  begin
    if StandFrontLoaded = False then
    begin
      NPC_StandFront; // load animation sequence
      StandFrontLoaded := True;
    end;
    StandFrontSprite.Position := CurrentSprite.Position;
    CurrentSprite := StandFrontSprite;
    StandFrontSprite.SwitchToAnimation(StandFront);
    StandFrontSprite.Play;
    NPCStopMove;
    Stand := True;
  end;
end;

Procedure NPCStandLeft;
begin
  with NPC[Location.NPC.NR] do
  begin
    if StandLeftLoaded = False then // only load the first time to prevent reloading
    begin
      NPC_StandLeft;
      StandLeftLoaded := True;
    end;
    SpriteScreen := 'StandLeft.png';
    StandLeftSprite.Position := CurrentSprite.Position;
    CurrentSprite := StandLeftSprite;
    StandLeftSprite.SwitchToAnimation(StandLeft);
    StandLeftSprite.Play;
    NPCStopMove;
    Stand := True;
  end;
end;

Procedure NPCStandRight;
begin
  with NPC[Location.NPC.NR] do
  begin
    if StandRightLoaded = False then
    begin
      NPC_StandRight;
      StandRightLoaded := True;
    end;
    SpriteScreen := 'StandRight.png';
    StandRightSprite.Position := CurrentSprite.Position;
    CurrentSprite := StandRightSprite;
    StandRightSprite.SwitchToAnimation(StandRight);
    StandRightSprite.Play;
    NPCStopMove;
    Stand := True;
  end;
end;

Procedure NPCStandSW;
begin
  with NPC[Location.NPC.NR] do
  begin
    if StandSWLoaded = False then
    begin
      NPC_StandSW;
      StandSWLoaded := True;
    end;

    StandSWSprite.Position := CurrentSprite.Position;
    CurrentSprite := StandSWSprite;
    StandSWSprite.SwitchToAnimation(StandSW);
    StandSWSprite.Play;
    NPCStopMove;
    Stand := True;
  end;
end;

Procedure NPCStandSE;
begin
  with NPC[Location.NPC.NR] do
  begin
    if StandSELoaded = False then
    begin
      NPC_StandSE;
      StandSELoaded := True;
    end;

    StandSESprite.Position := CurrentSprite.Position;
    CurrentSprite := StandSESprite;
    StandSESprite.SwitchToAnimation(StandSE);
    StandSESprite.Play;
    NPCStopMove;
    Stand := True;
  end;
end;

Procedure NPCStandNW;
begin
  with NPC[Location.NPC.NR] do
  begin
    StandNWSprite.Position := CurrentSprite.Position;
    CurrentSprite := StandNWSprite;
    StandNWSprite.SwitchToAnimation(StandNW);
    StandNWSprite.Play;
    NPCStopMove;
    Stand := True;
  end;
end;

Procedure NPCStandNE;
begin
  with NPC[Location.NPC.NR] do
  begin
    StandNESprite.Position := CurrentSprite.Position;
    CurrentSprite := StandNESprite;
    StandNESprite.SwitchToAnimation(StandNE);
    StandNESprite.Play;
    NPCStopMove;
    Stand := True;
  end;
end;

 Procedure Create_InitialNPC_DBase;
   var
     NPCList: TNPCList;
     NewNPC: TPlayer;
     begin
       NPCList := TNPCList.Create(true);
          try
            NewNPC := TPlayer.Create;
            with NewNPC do
            begin
              NR := 1;
              Personalia.FirstName:= 'Piet';
              Personalia.LastName := 'Jansen';
              Personalia.FullName := NewNPC.Personalia.FirstName + ' ' + NewNPC.Personalia.LastName;
              Personalia.Gender:= 'm';
              Appearance.Outfit:= 'Action';
              Location := 'Westbeach';
              X := 220;
              Y := 20;
              DestinationLocation := 'None';
              DestinationLocationX := 0;
              DestinationLocationY := 0;
              SpriteScreen := 'StandSE.png';
              Character.Action := 'Idle';
              Character.GreetingLine := 'Hm. Good day sir.';
              Character.AnswerLine:= 'Dinner will be ready soon sir.';
            end;
            NPCList.Add(NewNPC);

            NewNPC := TPlayer.Create;
            with NewNPC do
            begin
              NR := 2;
              Personalia.FirstName:= 'Sandra';
              Personalia.LastName:= 'Selini';
              Personalia.FullName := NewNPC.Personalia.FirstName + ' ' + NewNPC.Personalia.LastName;
              Personalia.Gender:= 'f';
              Appearance.Outfit:= 'Duty';
              Location := 'Passagebeach';
              X := 600;
              Y := 0;
              DestinationLocation := 'None';
              DestinationLocationX := 0;
              DestinationLocationY := 0;
              SpriteScreen := 'StandSW.png';
              Character.Action := 'Idle';
              Character.GreetingLine := 'Good day commander';
              Character.AnswerLine := 'Well, I am looking for the doctor.';
            end;
            NPCList.Add(NewNPC);

            NewNPC := TPlayer.Create;
            with NewNPC do
            begin
              NR := 3;
              Personalia.FirstName:= 'Clarence';
              Personalia.LastName:= 'Hottingen';
              Personalia.FullName := NewNPC.Personalia.FirstName + ' ' + NewNPC.Personalia.LastName;
              Personalia.Gender:= 'm';
              Appearance.Outfit:= 'Action';
              Location := 'Eastbeach';
              X := 800;
              Y := 0;
              DestinationLocation := 'None';
              DestinationLocationX := 0;
              DestinationLocationY := 0;
              SpriteScreen := 'StandSW.png';
              Character.Action := 'Idle';
              Character.GreetingLine := 'At your orders sir!';
              Character.AnswerLine := 'No sign of any enemy on the island sir.';
            end;
            NPCList.Add(NewNPC);
            NewNPC := TPlayer.Create;
            with NewNPC do
            begin
              NR := 4;
              Personalia.FirstName:= 'Yoko';
              Personalia.LastName:= 'Masako';
              Personalia.FullName := NewNPC.Personalia.FirstName + ' ' + NewNPC.Personalia.LastName;
              Personalia.Gender:= 'f';
              Appearance.Outfit:= 'Action';
              Location := 'Westbeach';
              X := 1000;
              Y := 150;
              DestinationLocation := 'None';
              DestinationLocationX := 0;
              DestinationLocationY := 0;
              SpriteScreen := 'StandSE.png';
              Character.Action := 'Idle';
              Character.GreetingLine := 'Sir?';
              Character.AnswerLine := 'Yoko terrible speaking English I know sir!';
            end;
            NPCList.Add(NewNPC);
            NewNPC := TPlayer.Create;
            with NewNPC do
            begin
              NR := 5;
              Personalia.FirstName:= 'Kyley';
              Personalia.LastName:= 'Carring';
              Personalia.FullName := NewNPC.Personalia.FirstName + ' ' + NewNPC.Personalia.LastName;
              Personalia.Gender:= 'f';
              Appearance.Outfit:= 'Duty';
              Location := 'Eastbeach';
              X := 1000;
              Y := 50;
              DestinationLocation := 'None';
              DestinationLocationX := 0;
              DestinationLocationY := 0;
              SpriteScreen := 'StandSW.png';
              Character.Action := 'Idle';
              Character.GreetingLine := 'Hi John.';
              Character.AnswerLine := 'No dear, it is very quiet around here.';
            end;
            NPCList.Add(NewNPC);
            NewNPC := TPlayer.Create;
            with NewNPC do
            begin
              NR := 6;
              Personalia.FirstName:= 'Thari';
              Personalia.LastName:= 'Langdon';
              Personalia.FullName := NewNPC.Personalia.FirstName + ' ' + NewNPC.Personalia.LastName;
              Personalia.Gender:= 'f';
              Appearance.Outfit:= 'Action';
              Location := 'Passagebeach';
              X := 1100;
              Y := 0;
              DestinationLocation := 'None';
              DestinationLocationX := 0;
              DestinationLocationY := 0;
              SpriteScreen := 'StandSW.png';
              Character.Action := 'Idle';
              Character.GreetingLine := 'Good day sir.';
              Character.AnswerLine := 'This is a boring place, just sand around.';
            end;
            NPCList.Add(NewNPC);
            NewNPC := TPlayer.Create;
            with NewNPC do
            begin
              NR := 7;
              Personalia.FirstName:= 'Jack';
              Personalia.LastName:= 'Delaney';
              Personalia.FullName := NewNPC.Personalia.FirstName + ' ' + NewNPC.Personalia.LastName;
              Personalia.Gender:= 'm';
              Appearance.Outfit:= 'Action';
              Location := 'Westbeach';
              X := 600;
              Y := 0;
              DestinationLocation := 'None';
              DestinationLocationX := 0;
              DestinationLocationY := 0;
              SpriteScreen := 'StandSW.png';
              Character.Action := 'Idle';
              Character.GreetingLine := 'Good day sir.';
              Character.AnswerLine := 'Do you mind if I smoke?';
            end;
            NPCList.Add(NewNPC);
            NewNPC := TPlayer.Create;
            with NewNPC do
            begin
              NR := 8;
              Personalia.FirstName:= 'Jane';
              Personalia.LastName:= 'Hopkins';
              Personalia.FullName := NewNPC.Personalia.FirstName + ' ' + NewNPC.Personalia.LastName;
              Personalia.Gender:= 'f';
              Appearance.Outfit:= 'Action';
              Location := 'Passagebeach';
              X := 900;
              Y := 0;
              DestinationLocation := 'None';
              DestinationLocationX := 0;
              DestinationLocationY := 0;
              SpriteScreen := 'StandSW.png';
              Character.Action := 'Idle';
              Character.GreetingLine := 'Good day sir.';
              Character.AnswerLine := 'I want to fly the Shockwave again.';
            end;
            NPCList.Add(NewNPC);



      AssignFile(InitialDBFile, 'InitialDBfile.txt');
         try
         Rewrite(InitialDBFile);
         try
         Writeln (InitialDBFile, NPCList.Count);
         for NewNPC in NPCList do
      begin
        Writeln (InitialDBFile, NewNPC.NR);
        Writeln (InitialDBFile, NewNPC.Personalia.FirstName);
        Writeln (InitialDBFile, NewNPC.Personalia.LastName);
        Writeln (InitialDBFile, NewNPC.Personalia.FullName);
        Writeln (InitialDBFile, NewNPC.Personalia.Gender);
        Writeln (InitialDBFile, NewNPC.Appearance.Outfit);
        Writeln (InitialDBFile, NewNPC.Location);
        Writeln (InitialDBFile, NewNPC.X);
        Writeln (InitialDBFile, NewNPC.Y);
        Writeln (InitialDBFile, NewNPC.DestinationLocation);
        Writeln (InitialDBFile, NewNPC.DestinationLocationX);
        Writeln (InitialDBFile, NewNPC.DestinationLocationY);
        Writeln (InitialDBFile, NewNPC.SpriteScreen);
        Writeln (InitialDBFile, NewNPC.Character.Action);
        Writeln (InitialDBFile, NewNPC.Character.GreetingLine);
        Writeln (InitialDBFile, NewNPC.Character.AnswerLine);
    //    Writeln (InitialDBFile, '------------------------------------------');
      end;
       finally
       CloseFile(InitialDBFile);
     end;
   except
     on E: EInOutError do
     raise Exception.Create('Error writing file');
   end;
   finally FreeAndNil(NPCList);
   end;
   end;


Procedure SaveNPC_DBase;
var
  NPCList: TNPCList;
  NewNPC: TPlayer;
  begin
    NPCList := TNPCList.Create(true);
       try
       NewNPC := TPlayer.Create;
       with NewNPC do
       begin
         NR := 1;
         Personalia.FirstName:= 'Piet';
         Personalia.LastName := 'Jansen';
         Personalia.FullName := NPCinfo[1].Personalia.FirstName + ' ' + NPCinfo[1].Personalia.LastName;
         Personalia.Gender:= NPCinfo[1].Personalia.Gender;
         Appearance.Outfit:= 'Action';
         Location := NPCinfo[1].Location;
         X := NPCinfo[1].X;
         Y := 0;
         DestinationLocation := NPCinfo[1].DestinationLocation;
         DestinationLocationX := NPCinfo[1].DestinationLocationX;
         DestinationLocationY := NPCinfo[1].DestinationLocationY;
         SpriteScreen := NPCinfo[1].SpriteScreen; // 'Walkright.png';
         Character.Action := NPCinfo[1].Character.Action;
         Character.GreetingLine := 'What is it sir?';
         Character.AnswerLine:= 'My cooking is delicious!';
       end;
       NPCList.Add(NewNPC);
       NewNPC := TPlayer.Create;
       with NewNPC do
       begin
         NR := 2;
         Personalia.FirstName:= 'Sandra';
         Personalia.LastName:= 'Selini';
         Personalia.FullName := NPCinfo[2].Personalia.FirstName + ' ' + NPCinfo[2].Personalia.LastName;
         Personalia.Gender:= NPCinfo[2].Personalia.Gender;
         Appearance.Outfit:= 'Duty';
         Location := NPCinfo[2].Location;
         X := NPCinfo[2].X;
         Y := 0;
         DestinationLocation := NPCinfo[2].DestinationLocation;
         DestinationLocationX := NPCinfo[2].DestinationLocationX;
         DestinationLocationY := NPCinfo[2].DestinationLocationY;
         SpriteScreen := NPCinfo[2].SpriteScreen;
         Character.Action := NPCinfo[2].Character.Action;
         Character.GreetingLine := 'Good day again commander';
         Character.AnswerLine := 'Well, I am still looking for the doctor.';
       end;
       NPCList.Add(NewNPC);
       NewNPC := TPlayer.Create;
       with NewNPC do
       begin
         NR := 3;
         Personalia.FirstName:= 'Clarence';
         Personalia.LastName:= 'Hottingen';
         Personalia.FullName := NPCinfo[3].Personalia.FirstName + ' ' + NPCinfo[3].Personalia.LastName;
         Personalia.Gender:= NPCinfo[3].Personalia.Gender;
         Appearance.Outfit:= 'Action';
         Location := NPCinfo[3].Location;
         X := NPCinfo[3].X;
         Y := 0;
         DestinationLocation := NPCinfo[3].DestinationLocation;
         DestinationLocationX := NPCinfo[3].DestinationLocationX;
         DestinationLocationY := NPCinfo[3].DestinationLocationY;
         SpriteScreen := NPCinfo[3].SpriteScreen;
         Character.Action := NPCinfo[3].Character.Action;
         Character.GreetingLine := 'At your orders sir!';
         Character.AnswerLine := 'No sign of any enemy on the island sir.';
       end;
       NPCList.Add(NewNPC);
       NewNPC := TPlayer.Create;
       with NewNPC do
       begin
         NR := 4;
         Personalia.FirstName:= 'Yoko';
         Personalia.LastName:= 'Masako';
         Personalia.FullName := NPCinfo[4].Personalia.FirstName + ' ' + NPCinfo[4].Personalia.LastName;
         Personalia.Gender:= NPCinfo[4].Personalia.Gender;
         Appearance.Outfit:= 'Action';
         Location := NPCinfo[4].Location;
         X := NPCinfo[4].X;
         Y := 0;
         DestinationLocation := NPCinfo[4].DestinationLocation;
         DestinationLocationX := NPCinfo[4].DestinationLocationX;
         DestinationLocationY := NPCinfo[4].DestinationLocationY;
         SpriteScreen := NPCinfo[4].SpriteScreen;
         Character.Action := NPCinfo[4].Character.Action;
         Character.GreetingLine := 'Sir?';
         Character.AnswerLine := 'I love vegetables!';
       end;
       NPCList.Add(NewNPC);
       NewNPC := TPlayer.Create;
       with NewNPC do
       begin
         NR := 5;
         Personalia.FirstName:= 'Kyley';
         Personalia.LastName:= 'Carring';
         Personalia.FullName := NPCinfo[5].Personalia.FirstName + ' ' + NPCinfo[5].Personalia.LastName;
         Personalia.Gender:= NPCinfo[5].Personalia.Gender;
         Appearance.Outfit:= 'Duty';
         Location := NPCinfo[5].Location;
         X := NPCinfo[5].X;
         Y := 0;
         DestinationLocation := NPCinfo[5].DestinationLocation;
         DestinationLocationX := NPCinfo[5].DestinationLocationX;
         DestinationLocationY := NPCinfo[5].DestinationLocationY;
         SpriteScreen := NPCinfo[5].SpriteScreen;
         Character.Action := NPCinfo[5].Character.Action;
         Character.GreetingLine := 'Hi John.';
         Character.AnswerLine := 'No dear, it is very quiet around here.';
       end;
       NPCList.Add(NewNPC);
       NewNPC := TPlayer.Create;
       with NewNPC do
       begin
         NR := 6;
         Personalia.FirstName:= 'Thari';
         Personalia.LastName:= 'Langdon';
         Personalia.FullName := NPCinfo[6].Personalia.FirstName + ' ' + NPCinfo[6].Personalia.LastName;
         Personalia.Gender:= NPCinfo[6].Personalia.Gender;
         Appearance.Outfit:= 'Action';
         Location := NPCinfo[6].Location;
         X := NPCinfo[6].X;
         Y := 0;
         DestinationLocation := NPCinfo[6].DestinationLocation;
         DestinationLocationX := NPCinfo[6].DestinationLocationX;
         DestinationLocationY := NPCinfo[6].DestinationLocationY;
         SpriteScreen := NPCinfo[6].SpriteScreen;
         Character.Action := NPCinfo[6].Character.Action;
         Character.GreetingLine := 'Good day sir.';
         Character.AnswerLine := 'I would like to go home now.';
       end;
       NPCList.Add(NewNPC);
       NewNPC := TPlayer.Create;
       with NewNPC do
       begin
         NR := 7;
         Personalia.FirstName:= 'Jack';
         Personalia.LastName:= 'Delaney';
         Personalia.FullName := NPCinfo[7].Personalia.FirstName + ' ' + NPCinfo[7].Personalia.LastName;
         Personalia.Gender:= NPCinfo[7].Personalia.Gender;
         Appearance.Outfit:= 'Action';
         Location := NPCinfo[7].Location;
         X := NPCinfo[7].X;
         Y := 0;
         DestinationLocation := NPCinfo[7].DestinationLocation;
         DestinationLocationX := NPCinfo[7].DestinationLocationX;
         DestinationLocationY := NPCinfo[7].DestinationLocationY;
         SpriteScreen := NPCinfo[7].SpriteScreen;
         Character.Action := NPCinfo[7].Character.Action;
         Character.GreetingLine := 'Good day sir.';
         Character.AnswerLine := 'Do you know where Lillian is?';
       end;
       NPCList.Add(NewNPC);
       NewNPC := TPlayer.Create;
        with NewNPC do
       begin
         NR := 8;
         Personalia.FirstName:= 'Jane';
         Personalia.LastName:= 'Hopkins';
         Personalia.FullName := NewNPC.Personalia.FirstName + ' ' + NewNPC.Personalia.LastName;
         Personalia.Gender:= 'f';
         Appearance.Outfit:= 'Action';
         Location := NPCinfo[8].Location;
         X := NPCinfo[8].X;
         Y := 0;
         DestinationLocation := NPCinfo[8].DestinationLocation;
         DestinationLocationX := NPCinfo[8].DestinationLocationX;
         DestinationLocationY := NPCinfo[8].DestinationLocationY;
         SpriteScreen := NPCinfo[8].SpriteScreen;
         Character.Action := NPCinfo[8].Character.Action;
         Character.GreetingLine := 'Good day sir.';
         Character.AnswerLine := 'I want to fly the Shockwave again.';
         end;
         NPCList.Add(NewNPC);


       AssignFile(ProgressDBFile, 'ProgressDBfile.txt');
       try
         Rewrite(ProgressDBFile);
         try
           Writeln (ProgressDBFile, NPCList.Count);
           for NewNPC in NPCList do
           begin
             Writeln (ProgressDBFile, NewNPC.NR);
             Writeln (ProgressDBFile, NewNPC.Personalia.FirstName);
             Writeln (ProgressDBFile, NewNPC.Personalia.LastName);
             Writeln (ProgressDBFile, NewNPC.Personalia.FullName);
             Writeln (ProgressDBFile, NewNPC.Personalia.Gender);
             Writeln (ProgressDBFile, NewNPC.Appearance.Outfit);
             Writeln (ProgressDBFile, NewNPC.Location);
             Writeln (ProgressDBFile, NewNPC.X);
             Writeln (ProgressDBFile, NewNPC.Y);
             Writeln (ProgressDBFile, NewNPC.DestinationLocation);
             Writeln (ProgressDBFile, NewNPC.DestinationLocationX);
             Writeln (ProgressDBFile, NewNPC.DestinationLocationY);
             Writeln (ProgressDBFile, NewNPC.SpriteScreen);
             Writeln (ProgressDBfile, NewNPC.Character.Action);
             Writeln (ProgressDBFile, NewNPC.Character.GreetingLine);
             Writeln (ProgressDBFile, NewNPC.Character.AnswerLine);
           end;
           finally
           CloseFile(ProgressDBFile);
        end;
        except
        on E: EInOutError do
        raise Exception.Create('Error writing file');
        end;
      finally FreeAndNil(NPCList);
    end;
  end;


Procedure LoadNPC_Database;
var
  S: String;
  I: Integer;
begin
  if GameStart then DBfile := 'InitialDBfile.txt' else DBfile := 'ProgressDBfile.txt';
  Text := TTextReader.Create(DBfile);
  try
  S := Text.ReadLn;    // this first line in the text file indicates the total amount of NPC characters
  NPCAmount := StrToInt(S); // read all game NPC's for counting purposes in procedures
  for I := 1 to StrToInt(S) do
  begin
    S := Text.Readln;
    NPCinfo[I].NR:= StrToInt(S);
    S := Text.Readln;
    NPCinfo[I].Personalia.FirstName:= S;
    S := Text.Readln;
    NPCinfo[I].Personalia.LastName:= S;
    S := Text.Readln;
    NPCinfo[I].Personalia.FullName := S;
    S := Text.Readln;
    NPCinfo[I].Personalia.Gender := S;
    S := Text.Readln;
    NPCinfo[I].Appearance.Outfit:= S;
    S := Text.Readln;
    NPCinfo[I].Location := S;
    S := Text.Readln;
    NPCinfo[I].X := StrtoInt(S);
    S := Text.Readln;
    NPCinfo[I].Y := StrToInt(S);
    S := Text.Readln;
    NPCinfo[I].DestinationLocation := S;
    S := Text.Readln;
    NPCinfo[I].DestinationLocationX := StrToInt(S);
    S := Text.Readln;
    NPCinfo[I].DestinationLocationY := StrToInt(S);
    S := Text.Readln;
    NPCinfo[I].SpriteScreen := S;
    S := Text.Readln;
    NPCinfo[I].Character.Action := S;
    S := Text.Readln;
    NPCinfo[I].Character.GreetingLine := S;
    S := Text.Readln;
    NPCinfo[I].Character.AnswerLine := S;
  end;

finally FreeAndNil(Text) end;
end;


Procedure LoadNPC;  // load all NPC characters that are on location
var I: Integer;
begin
  Location.NPC.NR := 0;  //start with no NPC on location
  for I := 1 to NPCAmount do // check all NPC for their location
  begin
    if NPCinfo[I].Location = Location.Name then
    begin
      Location.NPC_Presence := True;
      Inc(Location.NPC.NR);

      NPC[Location.NPC.NR].NR:= NPCinfo[I].NR;
      NPC[Location.NPC.NR].Personalia.FirstName:= NPCinfo[I].Personalia.FirstName;
      NPC[Location.NPC.NR].Personalia.LastName := NPCinfo[I].Personalia.LastName;
      NPC[Location.NPC.NR].Personalia.FullName := NPCinfo[I].Personalia.FullName;
      NPC[Location.NPC.NR].Personalia.Gender := NPCinfo[I].Personalia.Gender;
      NPC[Location.NPC.NR].Appearance.Outfit:= NPCinfo[I].Appearance.Outfit;
      NPC[Location.NPC.NR].Location := NPCinfo[I].Location;
      NPC[Location.NPC.NR].X := NPCinfo[I].X;
      NPC[Location.NPC.NR].Y := NPCinfo[I].Y;
      NPC[Location.NPC.NR].DestinationLocation := NPCinfo[I].DestinationLocation;
      NPC[Location.NPC.NR].DestinationLocationX := NPCinfo[I].DestinationLocationX;
      NPC[Location.NPC.NR].DestinationLocationY := NPCinfo[I].DestinationLocationY;
      NPC[Location.NPC.NR].SpriteScreen:= NPCinfo[I].SpriteScreen;
      NPC[Location.NPC.NR].Character.Action:= NPCinfo[I].Character.Action;
      NPC[Location.NPC.NR].Character.GreetingLine:= NPCinfo[I].Character.GreetingLine;
      NPC[Location.NPC.NR].Character.AnswerLine:= NPCinfo[I].Character.AnswerLine;

      NPC[Location.NPC.NR].WalkLeftLoaded := False;
      NPC[Location.NPC.NR].StandLeftLoaded:= False;
      NPC[Location.NPC.NR].WalkRightLoaded := False;
      NPC[Location.NPC.NR].StandRightLoaded:= False;

      NPC[Location.NPC.NR].TurnSpriteScreen:= 'TurnLeftToRight.png';
      NPC_Turn;

      NPC[Location.NPC.NR].CloseUpScreen:= 'CloseUpSilent.png';
      NPC_CloseUpSilent;


      if NPC[Location.NPC.NR].SpriteScreen = 'StandSW.png' then
      begin
        NPC_StandSW; // load animation sequence
        NPC[Location.NPC.NR].CurrentSprite := NPC[Location.NPC.NR].StandSWSprite;
        Assert(NPC[Location.NPC.NR].CurrentSprite <> nil);
        NPC[Location.NPC.NR].CurrentSprite.X := NPC[Location.NPC.NR].X;
        NPC[Location.NPC.NR].CurrentSprite.Y := 0;
        NPC[Location.NPC.NR].CurrentSprite.SwitchToAnimation(NPC[Location.NPC.NR].StandSW);
        NPC[Location.NPC.NR].CurrentSprite.Play;
      end;

      if NPC[Location.NPC.NR].SpriteScreen = 'StandSE.png' then
      begin
        NPC_StandSE; // load animation sequence
        NPC[Location.NPC.NR].CurrentSprite := NPC[Location.NPC.NR].StandSESprite;
        Assert(NPC[Location.NPC.NR].CurrentSprite <> nil);
        NPC[Location.NPC.NR].CurrentSprite.X := NPC[Location.NPC.NR].X;
        NPC[Location.NPC.NR].CurrentSprite.Y := 0;
        NPC[Location.NPC.NR].CurrentSprite.SwitchToAnimation(NPC[Location.NPC.NR].StandSE);
       NPC[Location.NPC.NR].CurrentSprite.Play;
      end;

      if NPC[Location.NPC.NR].SpriteScreen = 'StandRight.png' then
      begin
        NPC_StandRight; // load animation sequence
        NPC[Location.NPC.NR].CurrentSprite := NPC[Location.NPC.NR].StandRightSprite;
        Assert(NPC[Location.NPC.NR].CurrentSprite <> nil);
        NPC[Location.NPC.NR].CurrentSprite.X := NPC[Location.NPC.NR].X;
        NPC[Location.NPC.NR].CurrentSprite.Y := 0;
        NPC[Location.NPC.NR].CurrentSprite.SwitchToAnimation(NPC[Location.NPC.NR].StandRight);
        NPC[Location.NPC.NR].CurrentSprite.Play;
      end;

      if NPC[Location.NPC.NR].SpriteScreen = 'StandLeft.png' then
      begin
        NPC_StandLeft; // load animation sequence
        NPC[Location.NPC.NR].CurrentSprite := NPC[Location.NPC.NR].StandLeftSprite;
        Assert(NPC[Location.NPC.NR].CurrentSprite <> nil);
        NPC[Location.NPC.NR].CurrentSprite.X := NPC[Location.NPC.NR].X;
        NPC[Location.NPC.NR].CurrentSprite.Y := 0;
        NPC[Location.NPC.NR].CurrentSprite.SwitchToAnimation(NPC[Location.NPC.NR].StandLeft);
        NPC[Location.NPC.NR].CurrentSprite.Play;
      end;

     if NPC[Location.NPC.NR].SpriteScreen = 'WalkRight.png' then
     begin
       NPC_WalkRight; // load animation sequence
       NPC[Location.NPC.NR].CurrentSprite := NPC[Location.NPC.NR].WalkRightSprite;
       Assert(NPC[Location.NPC.NR].CurrentSprite <> nil);
       NPC[Location.NPC.NR].CurrentSprite.X :=  NPC[Location.NPC.NR].X;
       NPC[Location.NPC.NR].CurrentSprite.Y := 0;
       NPC[Location.NPC.NR].CurrentSprite.SwitchToAnimation(NPC[Location.NPC.NR].WalkAnimation);
       NPC[Location.NPC.NR].CurrentSprite.Play;
       NPC[Location.NPC.NR].MoveRight := True;
       NPC[Location.NPC.NR].Stand := False;
     end;

     if NPC[Location.NPC.NR].SpriteScreen = 'WalkLeft.png' then
     begin
       NPC_WalkLeft; // load animation sequence
       NPC[Location.NPC.NR].CurrentSprite := NPC[Location.NPC.NR].WalkLeftSprite;
       Assert(NPC[Location.NPC.NR].CurrentSprite <> nil);
       NPC[Location.NPC.NR].CurrentSprite.X :=  NPC[Location.NPC.NR].X;
       NPC[Location.NPC.NR].CurrentSprite.Y := 0;
       NPC[Location.NPC.NR].CurrentSprite.SwitchToAnimation(NPC[Location.NPC.NR].WalkAnimation);
       NPC[Location.NPC.NR].CurrentSprite.Play;
     end;

     if NPC[Location.NPC.NR].Character.Action = 'FollowPlayer' then
     begin
      with NPC[Location.NPC.NR] do
      begin
        Selected:= True;
        NPCStandLeft;
        NPCStandRight;
        NPCGoLeft;
        NPCGoRight;
      end;
     end;

     if NPC[Location.NPC.NR].Character.Action = 'GoToLocation' then
     begin
       with NPC[Location.NPC.NR] do
       begin
         if Spritescreen = 'WalkLeft.png' then NPCGoLeft;
         if Spritescreen = 'WalkRight.png' then NPCGoRight;
       end;
     end;

     Box[Location.NPC.NR] := NPC[Location.NPC.NR];  // put all NPC on this location in a list
     Inc(Location.NPC_Total); // increment the total of NPC on location
    end;
  end;
end;

procedure Westbeach;
begin
  GameMouse.NR := 3;
  GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[GameMouse.NR]);
  with Location do
  begin
    Name := ('Westbeach');
    Background   := TDrawableImage.Create(ApplicationData('Locations/Westbeach.png'));
    LimitLeft := (0 - Player.CurrentSprite.DrawingWidth/3);
    LimitRight := 3000;
    LimitTop := 700;
    LimitDown := 0;
    ExitLeft[1] := 'None';
    ExitRight[1] := 'Passagebeach';
    ExitRight[2] := 'Eastbeach';
    ExitTop[1] := 'None';
    ExitDown[1] := 'None';
    ExitLX := Window.Left + 30;
    ExitRX := Window.Width;
    ExitDY := 0;
    ExitTY := 800;
    if Entrance = 'right' then
    begin
    Player.CurrentSprite.X := Location.ExitRX - 1;//  entrance point from right side
    end;
  end;

  LoadNPC_Database;
  GameStart := False; // make sure next time the progress database is loaded instead of the initial
  Location.NPC_Total := 0;
  LoadNPC;

end;


procedure Passagebeach;
begin
  GameMouse.NR := 3; // make sure walking is enabled
  GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[GameMouse.NR]);
  //Window.MousePosition := Vector2(100,100);
  with Location do
  begin
    Name := ('Passagebeach');
    Background   := TDrawableImage.Create(ApplicationData('Locations/Passagebeach.png'));
    LimitLeft := - 500;
    LimitRight := 3000;
    LimitTop := 700;
    LimitDown := 0;
    ExitLeft[1] := 'Westbeach';
    ExitRight[1] := 'Eastbeach';
    ExitDown[1] := 'None';
    ExitLX := Window.Left + 30;
    ExitRX := Window.Width;
    ExitDY := 0;
    ExitTY := 800;
    if Entrance = 'left' then
    begin
      Player.CurrentSprite.X := Location.ExitLX + 1 - Player.CurrentSprite.DrawingWidth; // Player enters from leftside of location
   //   Player.DestX := 200; // stop at entrance point leftside
    end;
    if Entrance = 'right' then Player.CurrentSprite.X := Location.ExitRX - 1;//  Player.CurrentSprite.DrawingWidth;
  end;

  LoadNPC_Database;
  GameStart := False; // make sure next time the progress database is loaded instead of the initial
  Location.NPC_Total := 0;
  LoadNPC;

end;


procedure Eastbeach;
begin
  GameMouse.NR := 3;
  GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[GameMouse.NR]);
  with Location do
  begin
    Name := ('Eastbeach');
    Background   := TDrawableImage.Create(ApplicationData('Locations/Eastbeach.png'));
    LimitLeft := - 500;
    LimitRight := Window.Width - (Player.CurrentSprite.DrawingWidth* 2/3);
    LimitTop := 700;
    LimitDown := 0;
    ExitLeft[1] := 'Passagebeach';
    ExitLeft[2] := 'Westbeach';
    ExitRight[1] := 'None';
    ExitDown[1] := 'None';
    ExitLX := Window.Left + 30;
    ExitRX := Window.Width;
    ExitDY := 0;
    ExitTY := 800;
    if Entrance = 'left' then
    begin
      Player.CurrentSprite.X := Location.ExitLX + 1 - Player.CurrentSprite.DrawingWidth; // Player enters from leftside of location
  //    Player.DestX := 200; // stop at entrance point leftside
    end;
  end;

  LoadNPC_Database;
  GameStart := False; // make sure next time the progress database is loaded instead of the initial
  Location.NPC_Total := 0;
  LoadNPC;

end;

//  Buffer := SoundEngine.LoadBuffer('F:\Ocean Waves.wav');
  //Buffer := SoundEngine.LoadBuffer(fx + 'seagulls.wav');
//  SoundEngine.PlaySound(Buffer);
//end;

Procedure TPlayerHud.Render;
var
 SpriteList: TSpriteList;
 M: TPlayer;
 Count: integer;
 begin
 inherited;

Location.BackGround.Color := Vector4(rgb1, rgb2, rgb3, 1);  // fade background to night
Player.CurrentSprite.Color := Vector4(rgb1, rgb2, rgb3, 1);

Location.BackGround.Draw(0, 0, 1980, 1080);

SpriteList := TSpriteList.Create(false);
try
  SpriteList.Add(Player);

  if Location.NPC_Presence then
  begin
    For Count := 1 to Location.NPC_Total do
    begin
      SpriteList.Add(Box[Count]);
      Box[Count].CurrentSprite.Color := Vector4(rgb1, rgb2, rgb3, 1);
    end;
 end;

  SpriteList.Sort(TSpriteComparer.Construct(@CompareSprites));

  for M in SpriteList do
  M.CurrentSprite.Draw(M.Rect);

  finally FreeAndNil(SpriteList);
end;


For Count := 1 to Location.NPC_Total do
begin
  Location.NPC.NR := Count;


  if NPC[Location.NPC.NR].CloseUp = True then
  begin
    NPC[Location.NPC.NR].CloseUpSprite.Draw (NPC[Location.NPC.NR].CloseUpSprite.X, NPC[Location.NPC.NR].CloseUpSprite.Y);
    CloseUpFrame.Draw(NPC[Location.NPC.NR].CloseUpSprite.X, NPC[Location.NPC.NR].CloseUpSprite.Y);
  end;
end;

GameMouse.CurrentSprite.Draw;



MyTextureFont.Print(10,400, Black, TextLine1);
//MyTextureFont.Print(800,140, Black, TextLine2);
//MyTextureFont.Print(800,100, Black, TextLine3);
//MyTextureFont.Print(600,70, Red, TextLine4);


if GameMouse.Rect.Collides(Player.Rect.Grow(-150)) then
begin
  if GameMouse.NR = 0 then // look at
  begin
    MyTextureFont.Print(Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/3, Player.CurrentSprite.Y + Player.CurrentSprite.DrawingHeight, White, Player.Personalia.FirstName);
  end;
end;

  if Location.NPC_Presence then
  begin
    for Count := 1 to Location.NPC_Total do  // count all NPC on this location
    begin
      if GameMouse.Rect.Collides(Box[Count].Rect.Grow(-150)) then
      begin
        if GameMouse.NR = 0 then // look at
        begin
          MyTextureFont.Print(Box[Count].CurrentSprite.X + Box[Count].CurrentSprite.DrawingWidth/3, Box[Count].CurrentSprite.Y + Box[Count].CurrentSprite.DrawingHeight, White, 'Look at ' + Box[Count].Personalia.FirstName);
        end;
        if GameMouse.Nr = 1 then  // order NPC
        begin
          Location.NPC.NR := Count;
          NPC[Location.NPC.NR].Selected := True;
          MyTextureFont.Print(Box[Count].CurrentSprite.X + Box[Count].CurrentSprite.DrawingWidth/3, Box[Count].CurrentSprite.Y + Box[Count].CurrentSprite.DrawingHeight, White, 'Command ' + Box[Count].Personalia.FirstName);
        end;
        if GameMouse.NR = 2 then // talk to
        begin
          Location.NPC.NR := Count;
          MyTextureFont.Print(Box[Count].CurrentSprite.X + Box[Count].CurrentSprite.DrawingWidth/3, Box[Count].CurrentSprite.Y + Box[Count].CurrentSprite.DrawingHeight, White, 'Talk to ' + Box[Count].Personalia.FirstName);
          if Player.CurrentSprite.X < Box[Count].CurrentSprite.X then Player.DestX := Box[Count].CurrentSprite.X;
          if Player.CurrentSprite.X > Box[Count].CurrentSprite.X then Player.DestX := (Box[Count].CurrentSprite.X + Box[Count].CurrentSprite.DrawingWidth);
        end;
      end;
    end;
  end;
end;

Procedure PlayerWalkToTarget;
begin
  If Player.DestY > Player.CurrentSprite.Y then
  begin
    if (Player.DestX > (Player.Center)) and (Player.DestX < Player.Center) and (Player.DestY > (Player.CurrentSprite.Y + Player.CurrentSprite.DrawingHeight/3)) then
    begin
      PlayerGoUp;
    end;
    if (Player.DestX > (Player.Center)) and (Player.DestY > (Player.CurrentSprite.Y + Player.CurrentSprite.DrawingHeight/3)) then
    begin
      PlayerGoNE;
    end;
    if (Player.DestX > (Player.Center)) and (Player.DestY > Player.CurrentSprite.Y) and (Player.DestY < Player.CurrentSprite.DrawingHeight/3) then
    begin
      PlayerGoRight;
    end;
  end;

  If Player.DestY < Player.CurrentSprite.Y then
  begin
    if (Player.DestX > Player.Center) and (Player.DestY < Player.CurrentSprite.Y) then
    begin
      PlayerGoSE;
      end;
      if (Player.DestX > Player.Center) and (Player.DestX < Player.Center) then
      begin
        PlayerGoDown;
      end;
      if (Player.DestX < Player.Center) and (Player.DestY < Player.CurrentSprite.Y) then
      begin
        PlayerGoSW;
      end;
  end;

  If (Player.DestX < Player.Center) and (Player.DestY > Player.CurrentSprite.Y) and (Player.DestY < (Player.CurrentSprite.Y + Player.CurrentSprite.DrawingHeight/3)) then
  begin
    PlayerGoLeft;
  end;
  if (Player.DestX < Player.Center) and (Player.DestY > (Player.CurrentSprite.Y + Player.CurrentSprite.DrawingHeight/3)) then
  begin
    PlayerGoNW;
  end;
end;


Procedure PlayerWalkToNPC;
begin
  if Player.DestX > (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth)then
  begin
    Player.DestX := Box[Location.NPC.NR].CurrentSprite.X;
    NPC[Location.NPC.NR].ApproachFromLeft:= True;
    NPC[Location.NPC.NR].ApproachFromRight:= False;
    PlayerGoRight;
  end;
  if Player.DestX < Player.CurrentSprite.X then
  begin
    Player.DestX := (NPC[Location.NPC.NR].CurrentSprite.X + NPC[Location.NPC.NR].CurrentSprite.DrawingWidth);
    NPC[Location.NPC.NR].ApproachFromRight:= True;
    NPC[Location.NPC.NR].ApproachFromLeft:= False;
    PlayerGoLeft;
  end;
 end;


Procedure PlayerTalkToNPC;
var I: Integer;
begin
  CloseUpFrame := TDrawableImage.Create('castle-data:CloseUpFrameTransparant.png');
  for I := 1 to Location.NPC.NR do
  begin
    if NPC[I].TalkSelected = True then
    begin

    Location.NPC.NR := I;
    if NPC[Location.NPC.NR].ApproachFromLeft = True then
    begin
      if NPC[Location.NPC.NR].SpriteScreen = 'StandSE.png'then
      begin
        with NPC[Location.NPC.NR] do
        begin
          TurnSprite.X := CurrentSprite.X;
          TurnSprite.Y := CurrentSprite.Y;
          CurrentSprite := TurnSprite;
          TurnAnimation := TurnSprite.AddAnimation([50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30,29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18]);
          CurrentSprite.SwitchToAnimation(TurnAnimation);
          CurrentSprite.Play;
          SpriteScreen := 'StandSW.png';
        end;
      end;
    end;

    if NPC[Location.NPC.NR].ApproachFromRight = True then
    begin
      if NPC[Location.NPC.NR].SpriteScreen = 'StandSW.png' then
      begin
        with NPC[Location.NPC.NR] do
        begin
          TurnSprite.X := CurrentSprite.X;
          TurnSprite.Y := CurrentSprite.Y;
          CurrentSprite := TurnSprite;
          TurnAnimation := TurnSprite.AddAnimation([20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52]);
          CurrentSprite.SwitchToAnimation(TurnAnimation);
          CurrentSprite.Play;
          SpriteScreen := 'StandSE.png';
        end;
      end;
    end;

    with NPC[Location.NPC.NR] do
    begin
      CloseUpSprite.X := CurrentSprite.X - (CurrentSprite.DrawingWidth/3);
      CloseUpSprite.Y := CurrentSprite.Y + (CurrentSprite.DrawingHeight/2);
      CloseUpSprite.SwitchToAnimation(CloseupAnimation);
      GameMouse.CurrentSprite.DrawingWidth:= 0;
      GameMouse.CurrentSprite.DrawingHeight:= 0;

      CloseUpSprite.Play;
      if TalkSelected then CloseUp := True;
    end;
  end;
 end;

   ControlThatDeterminesMouseCursor.Cursor := mcStandard; // show standard mouse cursor again for selecting options of Onscreenmenu
   OnScreenConversationMenu.Anchor(hpLeft, NPC[Location.NPC.NR].CloseUpSprite.X + NPC[Location.NPC.NR].CloseUpSprite.DrawingWidth/3);
   OnScreenConversationMenu.Anchor (vpBottom, NPC[Location.NPC.NR].CloseUpSprite.Y - NPC[Location.NPC.NR].CloseUpSprite.DrawingHeight/2);
   Window.Controls.InsertFront(OnScreenConversationMenu); // show the talk subject option menu

   TalkTextLabel.Anchor(hpLeft, NPC[Location.NPC.NR].CloseUpSprite.X); // prepare position of the NPC text label
   TalkTextLabel.Anchor(vpBottom, NPC[Location.NPC.NR].CloseUpSprite.Y);
end;

Procedure CheckNPCRight;
var I, A: integer;
begin
  if Location.NPC_Presence = true then
  begin
    for I := 1 to Location.NPC_Total do
    begin
      Location.NPC.NR := I;

      NPC[Location.NPC.NR].WalkRightLoaded:= False;
      NPC[Location.NPC.NR].StandRightLoaded := False;
      NPC[Location.NPC.NR].WalkLeftLoaded:= False;
      NPC[Location.NPC.NR].StandLeftLoaded := False;
      NPC[Location.NPC.NR].StandSWLoaded := False;
      NPC[Location.NPC.NR].StandSELoaded := False;
      NPC[Location.NPC.NR].Selected := False;


      if NPC[Location.NPC.NR].Character.Action = 'FollowPlayer' then
      begin
        NPC[Location.NPC.NR].Location:= Location.ExitRight[1];
        NPC[Location.NPC.NR].CurrentSprite.X := - 400;
        NPC[Location.NPC.NR].Spritescreen:= 'WalkRight.png';
        NPC[Location.NPC.NR].FollowPlayer := False;

        A := NPC[Location.NPC.NR].NR; // find the corresponding database nr of this Location sprite
        NPCinfo[A].Location := NPC[Location.NPC.NR].Location;
        NPCinfo[A].X := Round(NPC[Location.NPC.NR].CurrentSprite.X); // transfer temporary Sprite X coordinate to database
        NPCinfo[A].Spritescreen:= NPC[Location.NPC.NR].Spritescreen;
        NPCinfo[A].Character.Action:= NPC[Location.NPC.NR].Character.Action;
      end;

      if NPC[Location.NPC.NR].Character.Action = 'GoToLocation' then
      begin
        A := NPC[Location.NPC.NR].NR; // find the corresponding database nr of this Location sprite
        NPCinfo[A].Location := Location.ExitRight[1];
        NPCinfo[A].X := NPC[Location.NPC.NR].X; // transfer temporary Sprite X coordinate to database
        NPCinfo[A].DestinationLocation := NPC[Location.NPC.NR].DestinationLocation;
        NPCinfo[A].DestinationLocationX := NPC[Location.NPC.NR].DestinationLocationX;
        NPCinfo[A].DestinationLocationY := NPC[Location.NPC.NR].DestinationLocationY;
        NPCinfo[A].Spritescreen:= NPC[Location.NPC.NR].Spritescreen;
        NPCinfo[A].Character.Action:= NPC[Location.NPC.NR].Character.Action;
      end;

      if NPC[Location.NPC.NR].Character.Action = 'Idle' then
      begin
        A := NPC[Location.NPC.NR].NR; // find the corresponding database nr of this Location sprite
        NPCinfo[A].Location := NPC[Location.NPC.NR].Location;
        NPCinfo[A].X := Round(NPC[Location.NPC.NR].CurrentSprite.X); // transfer Sprite X coordinate to database
        NPCinfo[A].Spritescreen:= NPC[Location.NPC.NR].Spritescreen;
        NPCinfo[A].Character.Action := NPC[Location.NPC.NR].Character.Action;
      end;
     end;
     SaveNPC_DBase;
  end;
end;

Procedure CheckNPCLeft;
var I, A: integer;
begin
  if Location.NPC_Presence = true then
  begin
    for I := 1 to Location.NPC_Total do
    begin
       Location.NPC.NR := I;

       NPC[Location.NPC.NR].WalkRightLoaded:= False;
       NPC[Location.NPC.NR].StandRightLoaded := False;
       NPC[Location.NPC.NR].WalkLeftLoaded:= False;
       NPC[Location.NPC.NR].StandLeftLoaded := False;
       NPC[Location.NPC.NR].StandSWLoaded := False;
       NPC[Location.NPC.NR].StandSELoaded := False;
       NPC[Location.NPC.NR].Selected := False;

       if NPC[Location.NPC.NR].Character.Action = 'FollowPlayer' then
       begin
         NPC[Location.NPC.NR].Location:= Location.ExitLeft[1];
         NPC[Location.NPC.NR].CurrentSprite.X := 2200;
         NPC[Location.NPC.NR].Spritescreen:= 'WalkLeft.png';
         NPC[Location.NPC.NR].FollowPlayer := False;

         A := NPC[Location.NPC.NR].NR; // find the corresponding database nr of this Location sprite
         NPCinfo[A].Location := NPC[Location.NPC.NR].Location;
         NPCinfo[A].X := Round(NPC[Location.NPC.NR].CurrentSprite.X); // transfer temporary Sprite X coordinate to database
         NPCinfo[A].Spritescreen:= NPC[Location.NPC.NR].Spritescreen;
         NPCinfo[A].Character.Action:= NPC[Location.NPC.NR].Character.Action;
       end;

       if NPC[Location.NPC.NR].Character.Action = 'GoToLocation' then
       begin
         A := NPC[Location.NPC.NR].NR; // find the corresponding database nr of this location sprite
         NPCinfo[A].Location := Location.ExitLeft[1];
         NPCinfo[A].X := NPC[Location.NPC.NR].X; // transfer temporary Sprite X coordinate to database
         NPCinfo[A].DestinationLocation := NPC[Location.NPC.NR].DestinationLocation;
         NPCinfo[A].DestinationLocationX := NPC[Location.NPC.NR].DestinationLocationX;
         NPCinfo[A].DestinationLocationY := NPC[Location.NPC.NR].DestinationLocationY;
         NPCinfo[A].Spritescreen:= NPC[Location.NPC.NR].Spritescreen;
         NPCinfo[A].Character.Action:= NPC[Location.NPC.NR].Character.Action;
       end;

       if NPC[Location.NPC.NR].Character.Action = 'Idle' then
       begin
         A := NPC[Location.NPC.NR].NR; // find the corresponding database nr of this location sprite
         NPCinfo[A].Location := NPC[Location.NPC.NR].Location;
         NPCinfo[A].X := Round(NPC[Location.NPC.NR].CurrentSprite.X); // transfer Sprite X coordinate to database
         NPCinfo[A].Spritescreen:= NPC[Location.NPC.NR].Spritescreen;
         NPCinfo[A].Character.Action := NPC[Location.NPC.NR].Character.Action;
       end;
    end;
    SaveNPC_DBase;
  end;
end;


Procedure CheckExitLocation;
begin
  if Player.CurrentSprite.X >= Location.ExitRX then
  begin
    if Location.ExitRight[1] = 'Eastbeach' then
    begin
      Location.Entrance := 'left';
      CheckNPCRight;
      SaveNPC_DBase; // remember all NPC stuff
      EastBeach;
    end;
    if Location.ExitRight[1] = 'Passagebeach' then
    begin
      Location.Entrance := 'left';
      CheckNPCRight;
      SaveNPC_DBase; ; // remember all NPC stuff
      Passagebeach;
    end;
  end;

  if (Player.CurrentSprite.Position.X + Player.CurrentSprite.DrawingWidth) < Location.ExitLX then
  begin
    if Location.ExitLeft[1] = 'Westbeach' then
    begin
      Location.Entrance := 'right';
      CheckNPCLeft;
      SaveNPC_DBase; // remember all NPC stuff
      Westbeach;
    end;
    if Location.ExitLeft[1] = 'Passagebeach' then
    begin
      Location.Entrance := 'right';
      CheckNPCLeft;
      SaveNPC_DBase; // remember all NPC stuff
      Passagebeach;
    end;
  end;

  if Player.CurrentSprite.Position.X < Location.LimitLeft then
  begin
    Player.CurrentSprite.X := Location.LimitLeft;
    Player.MoveLeft := False;
    PlayerStandLeft;
  end;

  if Player.CurrentSprite.Position.X > Location.LimitRight then
  begin
    Player.CurrentSprite.X := Location.LimitRight;
    Player.MoveRight := False;
    PlayerStandRight;
  end;

  if Player.CurrentSprite.Position.Y > Location.LimitTop then
  begin
    Player.CurrentSprite.Y := Location.LimitTop;
    Player.MoveUp := False;
    PlayerStandBack;
  end;

  if Player.CurrentSprite.Position.Y < Location.LimitDown then
  begin
    Player.CurrentSprite.Y := Location.LimitDown;
    Player.MoveDown := False;
    PlayerStandFront;
  end;
end;


procedure WindowUpdate(Container: TUIContainer);
var
SecondsPassed: Single;
  I, S: Integer;
  Distance: array[1..20] of Integer; // keep a certain distance between sprites
  begin
    Distance[1] := 150;
    Distance[2] := 300;
    Distance[3] := 450;
    Distance[4] := 600;

    GameMouse.CurrentSprite.Position := Window.MousePosition;
    if Window.MousePosition.X + GameMouse.CurrentSprite.DrawingWidth >= Location.ExitRX then Window.MousePosition.X := Location.ExitRX - GameMouse.CurrentSprite.DrawingWidth - 1;

    SecondsPassed := Container.Fps.SecondsPassed;
    Player.X := round(Player.CurrentSprite.X);

  if Player.MoveLeft then Player.CurrentSprite.X := Player.CurrentSprite.X - SecondsPassed * 250;
  if Player.MoveRight then Player.CurrentSprite.X := Player.CurrentSprite.X + SecondsPassed * 250;
  if Player.MoveUp then Player.CurrentSprite.Y := Player.CurrentSprite.Y + SecondsPassed * 80;
  if Player.MoveDown then Player.CurrentSprite.Y := Player.CurrentSprite.Y - SecondsPassed * 80;

  if Player.MoveSW then
  begin
    Player.CurrentSprite.X := Player.CurrentSprite.X - 4;
    Player.CurrentSprite.Y := Player.CurrentSprite.Y - 1;
  end;

  if Player.MoveSE then
  begin
    Player.CurrentSprite.X := Player.CurrentSprite.X + 4;
    Player.CurrentSprite.Y := Player.CurrentSprite.Y - 1;
  end;

  if Player.MoveNW then
  begin
    Player.CurrentSprite.X := Player.CurrentSprite.X - 4;
    Player.CurrentSprite.Y := Player.CurrentSprite.Y + 1;
  end;

  if Player.MoveNE then
  begin
    Player.CurrentSprite.X := Player.CurrentSprite.X + 4;
    Player.CurrentSprite.Y := Player.CurrentSprite.Y + 1;
  end;

  For I := 1 to Location.NPC_Total do
  begin

   Location.NPC.NR := I;
   if NPC[Location.NPC.NR].Character.Action = 'FollowPlayer' then
   begin
     if NPC[Location.NPC.NR].CurrentSprite.X < Player.CurrentSprite.X - Distance[I] then
     begin
       if NPC[Location.NPC.NR].MoveRight = False then NPCGoRight;
     end;
     if NPC[Location.NPC.NR].CurrentSprite.X > (Player.CurrentSprite.X - Distance[I]) then
     begin
       if NPC[Location.NPC.NR].MoveRight = True then NPCStandRight;
     end;
     if NPC[Location.NPC.NR].CurrentSprite.X > Player.CurrentSprite.X + Distance[I] then
     begin
       if NPC[Location.NPC.NR].MoveLeft = False then NPCGoLeft;
     end;
     if NPC[Location.NPC.NR].CurrentSprite.X < (Player.CurrentSprite.X + Distance[I]) then
     begin
       if NPC[Location.NPC.NR].MoveLeft = True then NPCStandLeft;
     end;
   end;
 end;


CheckExitLocation;  // check if Player position exceeds Location; if so:load next Location or keep it on current location

for I := 1 to Location.NPC_Total do
begin
  Location.NPC.NR := I;
  if NPC[Location.NPC.NR].Character.Action = 'FollowPlayer' then
  begin
    if NPC[Location.NPC.NR].MoveLeft then NPC[Location.NPC.NR].CurrentSprite.X := NPC[Location.NPC.NR].CurrentSprite.X - SecondsPassed * 250;
    if NPC[Location.NPC.NR].MoveRight then NPC[Location.NPC.NR].CurrentSprite.X := NPC[Location.NPC.NR].CurrentSprite.X + SecondsPassed * 250;
  end;
end;


for I := 1 to Location.NPC_Total do  // collision detection between NPC on location
begin
  Location.NPC.NR := I;

  if NPC[Location.NPC.NR].Character.Action = 'GoToLocation' then
  begin
    for S := 1 to Location.NPC_Total do
    begin
      if NPC[Location.NPC.NR].Rect.Collides(NPC[S].Rect.Grow(-150)) then // if the moving NPC collides
      begin
        if S <> Location.NPC.NR then // ignore collision with itself
        begin
          if NPC[Location.NPC.NR].MoveLeft then NPC[Location.NPC.NR].DestinationLocationX:= Round(NPC[S].CurrentSprite.X + NPC[S].CurrentSprite.DrawingWidth/2); // place it somewhat right of the colliding sprite
          if NPC[Location.NPC.NR].MoveRight then NPC[Location.NPC.NR].DestinationLocationX:= Round(NPC[S].CurrentSprite.X - NPC[S].CurrentSprite.DrawingWidth/2); // place it somewhat left of the colliding sprite
        end;
      end;
    end;

    if NPC[Location.NPC.NR].MoveLeft then
    begin
      NPC[Location.NPC.NR].XMoveLeft:= False;
      NPC[Location.NPC.NR].CurrentSprite.X := NPC[Location.NPC.NR].CurrentSprite.X - SecondsPassed * 250;

      if NPC[Location.NPC.NR].Location = NPC[Location.NPC.NR].DestinationLocation then   // if NPC reaches the destination location
      if NPC[Location.NPC.NR].CurrentSprite.X < NPC[Location.NPC.NR].DestinationLocationX then // then if NPC passes the destination coordinates
      begin
        NPC[Location.NPC.NR].CurrentSprite.X := NPC[Location.NPC.NR].DestinationLocationX; // go to the saved coordinate
        NPCStandLeft; // stop walking
        NPC[Location.NPC.NR].Character.Action:= 'Idle'; // deselect NPC GoToLocation to prevent looping of this action
      end;

      if NPC[Location.NPC.NR].CurrentSprite.X < -400 then  // if NPC leaves the location left side
      begin
        NPC[Location.NPC.NR].MoveLeft:= False;
        NPC[Location.NPC.NR].X := 2000;
        NPC[Location.NPC.NR].XMoveLeft:= True;
      end;
    end;

    if NPC[Location.NPC.NR].XMoveLeft then
    begin
      NPC[Location.NPC.NR].X := NPC[Location.NPC.NR].X - Round(SecondsPassed * 250);
      if NPC[Location.NPC.NR].X <= - 360 then
      begin
        NPC[Location.NPC.NR].X := 2000;
        NPC[Location.NPC.NR].Location:= Location.ExitLeft[1];
      end;
    end;

    if NPC[Location.NPC.NR].MoveRight then
    begin
      NPC[Location.NPC.NR].XMoveRight:= True;
      NPC[Location.NPC.NR].CurrentSprite.X := NPC[Location.NPC.NR].CurrentSprite.X + SecondsPassed * 250;

      if NPC[Location.NPC.NR].Location = NPC[Location.NPC.NR].DestinationLocation then   // if NPC reaches the destination location
      if NPC[Location.NPC.NR].CurrentSprite.X > NPC[Location.NPC.NR].DestinationLocationX then // then if NPC passes the destination coordinates
      begin
        NPC[Location.NPC.NR].CurrentSprite.X := NPC[Location.NPC.NR].DestinationLocationX; // go to the saved coordinate
        NPCStandRight;
        NPC[Location.NPC.NR].Character.Action:= 'Idle'; // deselect NPC GoToLocation to prevent looping of this action
      end;

      if NPC[Location.NPC.NR].CurrentSprite.X > 2000 then  // if NPC leaves the location left side
      begin
        NPC[Location.NPC.NR].MoveRight:= False;
        NPC[Location.NPC.NR].X := -400;
        NPC[Location.NPC.NR].XMoveRight:= True;
      end;
    end;

    if NPC[Location.NPC.NR].XMoveRight then
    begin
      NPC[Location.NPC.NR].X := NPC[Location.NPC.NR].X + Round(SecondsPassed * 250);
      if NPC[Location.NPC.NR].X >= 2000 then
      begin
        NPC[Location.NPC.NR].X := -400;
        NPC[Location.NPC.NR].Location:= Location.ExitRight[1];
      end;
    end;
   end;
end;


  if Player.MoveToMouse then
  begin
    Player.Center:= (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/2);
    if Player.MoveRight then
    begin
      if GameMouse.NR = 6 then Player.DestX := Location.ExitRX;
      if GameMouse.NR = 2 then
      begin
        if Player.Center > Player.DestX then
        begin
          PlayerStandRight;
          PlayerTalkToNPC;
          Player.MoveToMouse := False;
        end;
      end;
      if GameMouse.NR = 3 then
      begin
        if Player.Center > Player.DestX then
        begin
          PlayerStandRight;
          Player.MoveToMouse := False;
        end;
      end;
    end;
  end;

if Player.MoveLeft then
begin
  if GameMouse.NR = 5 then Player.DestX := Location.ExitLX;
  if GameMouse.NR = 3 then
  begin
    if Player.Center < Player.DestX then
    begin
      Player.MoveToMouse := False;
      PlayerStandLeft;
    end;
  end;
  if GameMouse.NR = 2 then
  begin
    if Player.Center < Player.DestX then
    begin
      Player.MoveToMouse := False;
      PlayerStandLeft;
      PlayerTalkToNPC;
    end;
  end;
end;

if Player.MoveNE then
begin
  if Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/3 > Player.DestX then
  begin
    PlayerStopMove;
    PlayerGoUp;
  end;
end;

if Player.MoveNW then
begin
  if Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/3 < Player.DestX then
  begin
    PlayerStopMove;
    PlayerGoUp;
  end;
end;

if Player.MoveSE then
begin
  if Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/3 > Player.DestX then
  begin
    PlayerStopMove;
    PlayerGoDown;
  end;
end;

if Player.MoveSW then
begin
  if Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/3 < Player.DestX then
  begin
    Player.MoveSW := False;
    PlayerGoDown;
  end;
end;

if Player.MoveUp then
begin
  if Player.CurrentSprite.Y > Player.DestY then
  begin
    PlayerStopMove;
    Player.MoveToMouse := False;
    Player.StandBackSprite.X := Player.CurrentSprite.X;
    Player.StandBackSprite.Y := Player.CurrentSprite.Y;
    Player.CurrentSprite := Player.StandBackSprite;
    Player.StandBackSprite.SwitchToAnimation(Player.StandBack);
    Player.StandBackSprite.Play;
    Player.MoveUp := False;
  end;
end;

if Player.MoveDown then
begin
  if Player.CurrentSprite.Y < Player.DestY then
  begin
    PlayerStopMove;
    Player.MoveToMouse := False;
    Player.StandFrontSprite.X := Player.CurrentSprite.X;
    Player.StandFrontSprite.Y := Player.CurrentSprite.Y;
    Player.CurrentSprite := Player.StandFrontSprite;
    Player.StandFrontSprite.SwitchToAnimation(Player.StandFront);
    Player.StandFrontSprite.Play;
    Player.MoveDown := False;
  end;
end;

  If GameMouse.CurrentSprite.X <= Location.ExitLX then
  begin
    if GameMouse.NR = 3 then // if the current action is "walk to"
    begin
      if Location.ExitLeft[1] = 'None' then
      GameMouse.NR := 9   // if there is no exit show the no-pass sign
      else
        GameMouse.NR:= 5;  // if there is an exit show the left arrow
    end;
      GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[GameMouse.NR]);
  end;

  If GameMouse.CurrentSprite.X > 900 then //+ GameMouse.CurrentSprite.DrawingWidth >= Location.ExitRX - 100 then
  begin
    if GameMouse.NR = 3 then // if the current action is "walk to"
    begin
      if Location.ExitRight[1] = 'None' then
      GameMouse.NR := 9   // if there is no exit then show the no-pass sign
      else
        GameMouse.NR:= 6;  // if there is an exit then show the right arrow
      end;
      GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[GameMouse.NR]);
  end;

  if GameMouse.CurrentSprite.X > Location.ExitLX then
  begin
    if (GameMouse.CurrentSprite.X + GameMouse.CurrentSprite.DrawingWidth) < Location.ExitRX - 5 then
    begin
    if (GameMouse.NR = 5) or (GameMouse.NR = 6) or (GameMouse.NR = 9) then
    begin
      GameMouse.NR := 3;
      GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[GameMouse.NR]);
    end;
    end;
  end;

  Player.CurrentSprite.Update(SecondsPassed);
  if Location.NPC_Presence then
  begin
    for Count := 1 to Location.NPC_Total do
    begin
      Box[Count].CurrentSprite.Update(SecondsPassed);
      if NPC[Count].CloseUp = True then
      begin
        NPC[Count].CloseupSprite.Update(SecondsPassed);
      end;
  end;

  GameMouse.MouseImages.Update(SecondsPassed);

 end;
end;

procedure EndProg;
begin
  FreeAndNil(Location);
  FreeAndNil(Player);
  Application.Terminate;
end;

procedure WindowPress(Container: TUIContainer; const Event: TInputPressRelease);
var I: Integer;
begin
  if Event.IsKey(keyEscape) then EndProg;

// screen effects ------------------------------------------------------------------

  if Event.IsKey(keySpace)then
  begin
    rgb1 := rgb1-0.004;
    rgb2 := rgb2-0.004;
    rgb3 := rgb3-0.004;
    Location.BackGround.Color := Vector4(rgb1, rgb2, rgb3, 1);  // fade to dark
  end;

  if Event.IsKey(key0) then
  begin
    rgb1 := rgb1 + 0.003;
    rgb2 := rgb2 + 0.003;
    rgb3 := rgb3 + 0.003;
    Location.BackGround.Color := Vector4(rgb1, rgb2, rgb3, 1);  // fade in to bright
  end;

 // Player walk (only) left-right-up-down with cursor keys -------------------------

  if Event.IsKey(keyArrowLeft) then
  begin
    if Player.Stand = True then
    begin
      PlayerGoLeft;
    end
    else
      PlayerStandLeft;
  end;

  if Event.IsKey(keyArrowRight) then
  begin
    if Player.Stand = True then
    begin
      PlayerGoRight;
    end
    else
      PlayerStandRight;
  end;

  if Event.IsKey(keyArrowUp) then
  begin
    Player.DestY := Window.Height;
    if Player.Stand = True then PlayerGoUp else PlayerStandBack;
  end;

  if Event.IsKey(keyArrowDown) then
  begin
    Player.DestY := 0;
    if Player.Stand = True then PlayerGoDown else PlayerStandFront;
  end;


  // Mouse actions--------------------------------------------------------------

  if Event.IsMouseButton(buttonRight)then
  begin
    inc(GameMouse.NR);  // cycle through the options
    if GameMouse.NR = 4 then GameMouse.NR := 0;
    GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[GameMouse.NR]);
  end;

  if Event.IsMouseButton(buttonLeft)then
  begin

    if GameMouse.NR = 1 then // if "order" NPC selected, then show the option menu
    begin
      for I := 1 to Location.NPC_Total do
      begin
        if GameMouse.Rect.Collides(Box[I].Rect.Grow(-150)) then
        begin
          Location.NPC.NR := I;
          OnScreenOrderMenu.Anchor(hpLeft, Box[I].CurrentSprite.X + 50);
          OnScreenOrderMenu.Anchor(vpBottom, Box[I].CurrentSprite.Y + 180);
          Window.Controls.InsertFront(OnScreenOrderMenu); // when selected to order a NPC then show the option menu
          ShowWindowsMouse;
          Player.MoveToMouse := True;
        end;
      end;
    end;

    if GameMouse.NR = 2 then  // if "talk to NPC" selected, then move Player closer to NPC
    begin
      for I := 1 to Location.NPC_Total do
      begin
        Location.NPC.NR := I;
        if GameMouse.Rect.Collides(Box[I].Rect.Grow(-150)) then
        begin
          NPC[Location.NPC.NR].TalkSelected := True;
          if Player.Rect.Collides(Box[I].Rect.Grow(-150)) then // if the Player is already near the NPC he can start talking right away
          begin
            if Player.CurrentSprite.X < NPC[Location.NPC.NR].X then NPC[Location.NPC.NR].ApproachFromLeft := True;
            if Player.CurrentSprite.X > NPC[Location.NPC.NR].X then NPC[Location.NPC.NR].ApproachFromRight := True;
            PlayerTalkToNPC;
          end else   // if the Player is out of range of the NPC, walk to NPC first before talking
          begin
            Player.MoveToMouse := True;
            Player.DestX :=  Event.Position.X;
            Player.DestY := Event.Position.Y;
            PlayerWalkToNPC;
          end;
        end;
      end;
    end;

    if GameMouse.NR = 3 then // walk
    begin
      Player.Center:= (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/2);
      Player.MoveToMouse := True;
      Player.DestX := Event.Position.X;
      if Player.DestX >= Location.ExitRX then Player.DestX := Location.ExitRX;
      Player.DestY := Event.Position.Y;
      If Player.DestY < Location.ExitDY then Player.DestY := Location.ExitDY;

      PlayerWalkToTarget;
    end;

  if (GameMouse.NR = 5) or (GameMouse.NR = 6) then  // walk to next location arrow signs
  begin
    Player.Center:= (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/2);
    Player.MoveToMouse := True;
    Player.DestX := Event.Position.X;
    if Player.DestX >= Location.ExitRX then Player.DestX := Location.ExitRX;
    Player.DestY := Event.Position.Y;
    If Player.DestY < Location.ExitDY then Player.DestY := Location.ExitDY;
    PlayerWalkToTarget;
  end;
 end;
end;


// Onscreen menu procedures-----------------------------------------------------------------

class procedure TEventHandler.GoToLocationClick(Sender: TObject);
begin
  OnScreenLocationMenu.Anchor(hpLeft, Box[Location.NPC.NR].CurrentSprite.X + 50);
  OnScreenLocationMenu.Anchor(vpBottom, Box[Location.NPC.NR].CurrentSprite.Y + 180);
  ShowWindowsMouse;
  Window.Controls.InsertFront(OnScreenLocationMenu); // when selected to order a NPC then show the option menu
  Window.Controls.Remove(OnScreenOrderMenu);
end;

class procedure TEventHandler.GoToWestbeachNPCClick(Sender: TObject);
var I: Integer;
begin
  NPC[Location.NPC.NR].Character.Action:= 'GoToLocation';
  NPC[Location.NPC.NR].DestinationLocation:= 'Westbeach';
  NPC[Location.NPC.NR].DestinationLocationX := 800;   // test coordinate
  NPC[Location.NPC.NR].DestinationLocationY := 0;   // test coordinate

  For I := 1 to 2 do
  begin
    if Location.ExitRight[I] = 'Westbeach' then NPCGoRight;
    if Location.ExitLeft[I] = 'Westbeach' then NPCGoLeft;
  end;
  ShowCustomMouse;
  Window.Controls.Remove(OnScreenLocationMenu);
  Window.Controls.Remove(OnScreenOrderMenu);
end;

class procedure TEventHandler.GoToPassagebeachNPCClick(Sender: TObject);
var I: Integer;
begin
  NPC[Location.NPC.NR].Character.Action:= 'GoToLocation';
  NPC[Location.NPC.NR].DestinationLocation:= 'Passagebeach';
  NPC[Location.NPC.NR].DestinationLocationX := 800;   // test coordinate
  NPC[Location.NPC.NR].DestinationLocationY := 200;   // test coordinate

  For I := 1 to 2 do
  begin
    if Location.ExitRight[I] = 'Passagebeach' then NPCGoRight;
    if Location.ExitLeft[I] = 'Passagebeach' then NPCGoLeft;
  end;
  ShowCustomMouse;
  Window.Controls.Remove(OnScreenLocationMenu);
  Window.Controls.Remove(OnScreenOrderMenu);
end;

class procedure TEventHandler.GoToEastbeachNPCClick(Sender: TObject);
var I: Integer;
begin
  NPC[Location.NPC.NR].Character.Action:= 'GoToLocation';
  NPC[Location.NPC.NR].DestinationLocation:= 'Eastbeach';
  NPC[Location.NPC.NR].DestinationLocationX := 600;   // test coordinate
  NPC[Location.NPC.NR].DestinationLocationY := 200;   // test coordinate

  For I := 1 to 2 do
  begin
    if Location.ExitRight[I] = 'Eastbeach' then NPCGoRight;
    if Location.ExitLeft[I] = 'Eastbeach' then NPCGoLeft;
  end;
  ShowCustomMouse;
  Window.Controls.Remove(OnScreenLocationMenu);
  Window.Controls.Remove(OnScreenOrderMenu);
end;

class procedure TEventHandler.CancelOrdersClick (Sender: TObject);
begin
  ShowCustomMouse;
  Window.Controls.Remove(OnScreenOrderMenu);
end;

class procedure TEventHandler.CancelLocationsClick (Sender: TObject);
begin
  ShowCustomMouse;
  Window.Controls.Remove(OnScreenLocationMenu);
end;

class procedure TEventHandler.FollowPlayerClick(Sender: TObject);
begin
  NPC[Location.NPC.NR].Character.Action:= 'FollowPlayer';

  NPCStandRight; // load the necessary animation sheets
  NPCStandLeft;
  NPCGoLeft;
  NPCGoRight;
  ShowCustomMouse;
  Window.Controls.Remove(OnScreenOrderMenu);

end;

class procedure TEventHandler.StayOnLocationClick(Sender: TObject);
begin
  NPC[Location.NPC.NR].Character.Action:= 'Idle';
  ShowCustomMouse;
  Window.Controls.Remove(OnScreenOrderMenu);
end;

class procedure TEventHandler.AskForInformationClick(Sender: TObject);
begin
 // not implemented yet
end;

class procedure TEventHandler.CrewmemberListNPCClick(Sender: TObject);
var I: Integer;
begin

  For I := 1 to Location.NPC_Total do
  begin
    if NPC[I].TalkSelected = True then
    begin
      Location.NPC.NR := I;
      OnScreenCrewmemberMenu.Anchor(hpLeft, NPC[Location.NPC.NR].CloseUpSprite.X + NPC[Location.NPC.NR].CloseUpSprite.DrawingWidth/2);
      OnScreenCrewmemberMenu.Anchor(vpBottom, NPC[Location.NPC.NR].CloseUpSprite.Y - NPC[Location.NPC.NR].CloseUpSprite.DrawingHeight/2);
    end;
  Window.Controls.Remove(OnScreenConversationMenu);
  Window.Controls.InsertFront(OnScreenCrewmemberMenu);
  end;
end;

class procedure TEventHandler.CrewmemberLocationClick (Sender: TObject);
begin
  TalkTextLabel.Text.Add(LabelText);
  Window.Controls.Remove(OnScreenCrewmemberInfoMenu);
  Window.Controls.InsertFront(OnScreenConversationmenu);
end;

class procedure TEventHandler.CrewmemberProfessionClick (Sender: TObject);
begin
 // not implemented yet
end;

class procedure TEventHandler.CrewmemberInformationClick(Sender: TObject);
var I: Integer;
  HS, HH: String;
begin
  OnScreenCrewmemberInfoMenu.Anchor(hpLeft, NPC[Location.NPC.NR].CloseUpSprite.X + NPC[Location.NPC.NR].CloseUpSprite.DrawingWidth/2);
  OnScreenCrewmemberInfoMenu.Anchor(vpBottom, NPC[Location.NPC.NR].CloseUpSprite.Y - NPC[Location.NPC.NR].CloseUpSprite.DrawingHeight/2);
  SearchString := 'Clarence';

   For I := 1 to NPCAmount do // check all NPC for their current location
  begin
    if NPCinfo[I].Personalia.FirstName = SearchString then
    begin
      Window.Controls.Remove(OnScreenCrewmemberInfoMenu);
      Window.Controls.InsertFront(TalkTextLabel);
      TalkTextLabel.Text.Clear;
      if NPCinfo[I].Personalia.Gender = 'm' then HS := 'He';
      if NPCinfo[I].Personalia.Gender = 'm' then HH := 'him';
      if NPCinfo[I].Personalia.Gender = 'f' then HS := 'She';
      if NPCinfo[I].Personalia.Gender = 'f' then HH := 'her';

      OnScreenCrewmemberInfoMenu.Add('Where can I find ' + HH + '?', @TEventHandler(nil).CrewmemberLocationClick);
      Window.Controls.Remove(OnScreenConversationMenu);
      Window.Controls.Remove(OnScreenCrewmemberMenu);
      Window.Controls.InsertFront(OnScreenCrewmemberInfoMenu);

      LabelText := HS + ' is at ' + NPCinfo[I].Location;

    end;
  end;


  Window.Controls.Remove(OnScreenCrewmemberMenu);
end;


class procedure TEventHandler.StartTalkNPCClick (Sender: TObject);
var I: Integer;
begin
  For I := 1 to Location.NPC_Total do
  begin
    if NPC[I].TalkSelected = True then
    begin
      Location.NPC.NR := I;
      NPC[Location.NPC.NR].CloseUpScreen:= 'CloseUpSmallTalk.png';
      ShowWindowsMouse;
      NPC_CloseUpSmallTalk;
      PlayerTalkToNPC;

      Window.Controls.InsertFront(TalkTextLabel);
      TalkTextLabel.Text.Clear;
      TalkTextLabel.Text.Add(NPC[Location.NPC.NR].Character.GreetingLine);

  //    NPCTalkTextLabel.Caption:= 'Hello there! I am very thrilled to play in this videogame!';

//ReadString := 'Hello there! This is the first time I play in an animated videogame. It looks very exciting and I hope I make it to the end for sure.';
//ReadString := 'This is the first time I play in an animated videogame. It looks very exciting and I surely hope I make it to the end.';
//ReadString := 'I want to try this out because it is the first time I play in an animated videogame. It looks very exciting and I hope I make it to the end for sure.';
//ReadString := 'I hate to say it but there will be a lockdown within a week for at least the next four weeks.';
//ReadString := 'Remember when you were young, you shone like the sun. Shine on you crazy diamond.';
ReadString := 'one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen seventeen eightteen nineteen twenty.';

//NPCTalkTextLabel.Text.Add(LabelText);

//LastChar := AnsiLastChar(TextLine1);


TextLine1 := MidStr(ReadString, 0, Length(ReadString));
EndPos := PosEx(' ', TextLine1, 30);
TextLine1 := MidStr(ReadString, StartPos, EndPos) + LineEnding;

StartPos := EndPos + 1;
TextLine2 := MidStr(ReadString, StartPos + 1, Length(ReadString));
EndPos := PosEx(' ', TextLine2, 30);
TextLine2 := MidStr(ReadString, StartPos, EndPos) + LineEnding;

StartPos := EndPos + 1 + StartPos;
TextLine3 := MidStr(ReadString, StartPos + 1, Length(ReadString));
EndPos := PosEx(' ', TextLine3, 30);
TextLine3 := MidStr(ReadString, StartPos, EndPos) + LineEnding;

StartPos := EndPos + 1 + StartPos;
TextLine4 := MidStr(ReadString, StartPos + 1, Length(ReadString));
EndPos := PosEx(' ', TextLine4, 30);
TextLine4 := MidStr(ReadString, StartPos, EndPos) + LineEnding;

StartPos := EndPos + 1 + StartPos;
TextLine5 := MidStr(ReadString, StartPos + 1, Length(ReadString));
EndPos := PosEx(' ', TextLine5, 30);
TextLine5 := MidStr(ReadString, StartPos, EndPos) + LineEnding;



TalkTextLabel.Caption := TextLine1 + TextLine2 + TextLine3 + TextLine4 + TextLine5;


    end;
  end;
end;

class procedure TEventHandler.CheckKnowledgeNPCClick (Sender: TObject);
var I: Integer;
begin
  For I := 1 to Location.NPC_Total do
  begin
    if NPC[I].TalkSelected = True then
    begin
      Location.NPC.NR := I;
      NPC[Location.NPC.NR].CloseUpScreen:= 'CloseUpBigTalk.png';
      NPC_CloseUpBigTalk;
      PlayerTalkToNPC;

      Window.Controls.InsertFront(TalkTextLabel);
      TalkTextLabel.Text.Clear;
      TalkTextLabel.Text.Add(NPC[Location.NPC.NR].Character.AnswerLine);
    end;
  end;
end;

class procedure TEventHandler.QuitTalkNPCClick (Sender: TObject);
var I: Integer;
begin
  For I := 1 to Location.NPC_Total do
  begin
    Location.NPC.NR := I;

    NPC[Location.NPC.NR].CloseUp:= False;
    NPC[Location.NPC.NR].TalkSelected:= False;

    ShowCustomMouse;
    Window.Controls.Remove(OnScreenConversationMenu);
    Window.Controls.Remove(TalkTextLabel);

    if NPC[Location.NPC.NR].ApproachFromLeft = True then  // set Sprite to previous state
    begin
      NPCStandSW;
      NPC[Location.NPC.NR].ApproachFromleft := False;
    end;
    if NPC[Location.NPC.NR].ApproachFromRight = True then
    begin
      NPCStandSE;
      NPC[Location.NPC.NR].ApproachFromRight := False;
    end;
  end;
end;


// initialize program------------------------------------------------------------------------------------------

begin
MyTextureFont := TTextureFont.Create(Application);
MyTextureFont.Load('castle-data:/DejaVuSans.ttf', 20, true);

MyBigTextureFont := TTextureFont.Create(Application);
MyBigTextureFont.Load('castle-data:/Xerox Serif Wide Bold.ttf', 100, true);

rgb1 := 1.0;
rgb2 := 1.0;
rgb3 := 1.0;

Player:= TPlayer.Create;

Location := TLocation.Create;


GameMouse := TMouse.Create;
GameMouse.MouseImages := TSprite.CreateFrameSize('castle-data:/mouse-icons.png', 500, 100, 50, 50, true, true);

GameMouse.MouseImages.FramesPerSecond:= 1;
GameMouse.Action[0]:= GameMouse.MouseImages.AddAnimation([0]);  // look
GameMouse.Action[1]:= GameMouse.MouseImages.AddAnimation([1]);  // get
GameMouse.Action[2]:= GameMouse.MouseImages.AddAnimation([2]);  // talk
GameMouse.Action[3]:= GameMouse.MouseImages.AddAnimation([3]);  // walk
GameMouse.Action[4]:= GameMouse.MouseImages.AddAnimation([4]);  // inventory
GameMouse.Action[5]:= GameMouse.MouseImages.AddAnimation([5]); // exit left arrow
GameMouse.Action[6]:= GameMouse.MouseImages.AddAnimation([6]); // exit right arrow
GameMouse.Action[7]:= GameMouse.MouseImages.AddAnimation([7]); // exit up arrow
GameMouse.Action[8]:= GameMouse.MouseImages.AddAnimation([8]); // exit down arrow
GameMouse.Action[9]:= GameMouse.MouseImages.AddAnimation([9]); // no exit sign

GameMouse.CurrentSprite := GameMouse.MouseImages;
GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[Count]);
GameMouse.CurrentSprite.Play;


Create_InitialNPC_DBase;  // make textfile with all NPC information at start of game


For Count := 1 to 30 do
begin
NPC[Count] := TPlayer.Create;
NPCinfo[Count] := TPlayer.Create;
end;

//Player.Zone := FloatRectangle(100,100,100,100); // create a detection zone around the Player for testing


Player.Personalia.FirstName := 'John';
Player.Personalia.LastName := 'Carring';
Player.Personalia.FullName := Player.Personalia.FirstName + ' ' + Player.Personalia.LastName;
Player.Appearance.Outfit := 'Duty';


 with Player do
 begin
   SpriteScr[1] := 'WalkLeft.png';
   SpriteScr[2] := 'WalkRight.png';
   SpriteScr[3] := 'WalkFront.png';
   SpriteScr[4] := 'WalkBack.png';
   SpriteScr[5] := 'WalkNW.png';
   SpriteScr[6] := 'WalkNE.png';
   SpriteScr[7] := 'WalkSW.png';
   SpriteScr[8] := 'WalkSE.png';
   SpriteScr[9] := 'StandLeft.png';
   SpriteScr[10] := 'StandRight.png';
   SpriteScr[11] := 'StandFront.png';
   SpriteScr[12] := 'StandBack.png';
   SpriteScr[13] := 'StandNW.png';
   SpriteScr[14] := 'StandNE.png';
   SpriteScr[15] := 'StandSW.png';
   SpriteScr[16] := 'StandSE.png';
   SpriteScr[17] := 'TurnLeftToRight.png';
 end;

For Count:= 1 to 8 do
begin
  Player.WalkSprite := TSprite.CreateFrameSize (Characters + Player.Personalia.FullName + '/' + Player.Appearance.Outfit + '/' + Player.Personalia.FirstName + Player.SpriteScr[Count] ,60, 10, SWidth, SHeight, true, true);
  Player.WalkSprite.FramesPerSecond:= 45;
  Player.WalkAnimation := Player.WalkSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
  31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);

  if Count = 1 then Player.WalkLeftSprite := Player.WalkSprite;
  if Count = 2 then Player.WalkRightSprite := Player.WalkSprite;
  if Count = 3 then Player.WalkFrontSprite := Player.WalkSprite;
  if Count = 4 then Player.WalkBackSprite := Player.WalkSprite;
  if Count = 5 then Player.WalkNWSprite := Player.WalkSprite;
  if Count = 6 then Player.WalkNESprite := Player.WalkSprite;
  if Count = 7 then Player.WalkSWSprite := Player.WalkSprite;
  if Count = 8 then Player.WalkSESprite := Player.WalkSprite;
end;

For Count := 9 to 16 do
begin
  Player.StandSprite := TSprite.CreateFrameSize (Characters + Player.Personalia.FullName + '/' + Player.Appearance.Outfit + '/' + Player.Personalia.FirstName + Player.SpriteScr[Count],60, 10, SWidth, SHeight, true, true);
  Player.StandSprite.FramesPerSecond:= 15;
  Player.StandAnimation := Player.StandSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
  24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
  58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
  22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);

  if Count = 9 then Player.StandLeftSprite := Player.StandSprite;
  if Count = 10 then Player.StandRightSprite := Player.StandSprite;
  if Count = 11 then Player.StandFrontSprite := Player.StandSprite;
  if Count = 12 then Player.StandBackSprite := Player.StandSprite;
  if Count = 13 then Player.StandNWSprite := Player.StandSprite;
  if Count = 14 then Player.StandNESprite := Player.StandSprite;
  if Count = 15 then Player.StandSWSprite := Player.StandSprite;
  if Count = 16 then Player.StandSESprite := Player.StandSprite;
end;


// initial ------------------------------------------------------------------

Player.CurrentSprite := Player.StandRightSprite;
Player.Stand := True;
Player.CurrentSprite.Position := Vector2(100,0);
Player.CurrentSprite.SwitchToAnimation(Player.StandRight);
Player.CurrentSprite.Play;


Window := TCastleWindowBase.Create(Application);
Window.OnUpdate := @WindowUpdate;
Window.OnPress := @WindowPress;
Window.FullScreen := True;
Window.Open;

GameStart := true;  // load Initial DBase on first entering start location
WestBeach;   // start game on this location
//Passagebeach;
//Eastbeach;


ControlThatDeterminesMouseCursor := TCastleUserInterface.Create(Application);
ControlThatDeterminesMouseCursor.FullSize := true;
ControlThatDeterminesMouseCursor.Cursor := mcNone;


Window.Controls.InsertFront(ControlThatDeterminesMouseCursor);

OnScreenOrderMenu := TCastleOnScreenMenu.Create(Application);
OnScreenOrderMenu.Add('Follow me', @TEventHandler(nil).FollowPlayerClick);
OnScreenOrderMenu.Add('Stay here', @TEventHandler(nil).StayOnLocationClick);
OnScreenOrderMenu.Add('Go to location', @TEventHandler(nil).GoToLocationClick);
OnScreenOrderMenu.Add('Ask for information', @TEventHandler(nil).AskForInformationClick);
OnScreenOrderMenu.Add('Never mind',@TEventHandler(nil).CancelOrdersClick);

OnScreenLocationMenu := TCastleOnScreenMenu.Create(Application);
OnScreenLocationMenu.Add('Westbeach', @TEventHandler(nil).GoToWestbeachNPCClick);
OnScreenLocationMenu.Add('Passagebeach', @TEventHandler(nil).GoToPassagebeachNPCClick);
OnScreenLocationMenu.Add('Eastbeach', @TEventHandler(nil).GoToEastbeachNPCClick);
OnScreenLocationMenu.Add('Never mind', @TEventHandler(nil).CancelLocationsClick);

OnScreenConversationMenu := TCastleOnScreenMenu.Create(Application);
OnScreenConversationMenu.Add('Hi', @TEventHandler(nil).StartTalkNPCClick);
OnScreenConversationMenu.Add('Any news?', @TEventHandler(nil).CheckKnowledgeNPCClick);
OnScreenConversationMenu.Add('crew member information', @TEventHandler(nil).CrewmemberListNPCClick);
OnScreenConversationMenu.Add('Bye', @TEventHandler(nil).QuitTalkNPCClick);

OnScreenCrewmemberMenu := TCastleOnScreenMenu.Create(Application);
OnScreenCrewmemberMenu.Add('Thari', @TEventHandler(nil).CrewmemberInformationClick);
OnScreenCrewmemberMenu.Add('Clarence', @TEventHandler(nil).CrewmemberInformationClick);
OnScreenCrewmemberMenu.Add('Sandra', @TEventHandler(nil).CrewmemberInformationClick);
OnScreenCrewmemberMenu.Add('Kyley', @TEventHandler(nil).CrewmemberInformationClick);

OnScreenCrewmemberInfoMenu := TCastleOnScreenMenu.Create(Application);


TalkTextLabel := TCastleLabel.Create(Application);
TalkTextLabel.Color := White;
TalkTextLabel.Frame:= true;
TalkTextLabel.FrameColor := White;
TalkTextLabel.Outline := 2;
TalkTextLabel.OutlineHighQuality := true;
TalkTextLabel.BorderColor := Red;
TalkTextLabel.Font.OutlineColor := Black;
TalkTextLabel.FontSize := 18;
TalkTextLabel.CustomFont := MyTextureFont;


PlayerHud := TPlayerHud.Create(Application);
Window.Controls.InsertFront(PlayerHud);


Application.Run;

end.


