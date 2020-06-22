
program Rescue_Island;

{$ifdef MSWINDOWS} {$apptype GUI} {$endif}


uses Classes, SysUtils, Dialogs,
  CastleWindow,CastleUtils, CastleUIControls, CastleGLImages, CastleFilesUtils,
  CastleKeysMouse, CastleVectors, CastleViewport, CastleSoundEngine, CastleTimeUtils, CastleColors,
  CastleRectangles, CastleFonts, CastleGLUtils, Generics.Defaults,
  Generics.Collections,Math, CastleLCLUtils, CastleControl, CastleControls, CastleOnScreenMenu;



type
   TPlayer = class
   private
   type TPersonalia = class
   Gender: char; // m or w
   FirstName, LastName, FullName: string;
   Known: Boolean; // if you haven't talked to this character you won't know his name
   Age: Integer;
   end;
   var Personalia: TPersonalia;

   private
   type TCharacter = class
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
   FirstName, LastName, FullName, Outfit: string;
   WalkLeftSprite, WalkRightSprite, WalkFrontSprite, WalkBackSprite, WalkSWSprite, WalkSESprite, WalkNWSprite, WalkNESprite: TSprite;
   StandLeftSprite, StandRightSprite, StandFrontSprite, StandBackSprite, StandSWSprite, StandSESprite, StandNWSprite, StandNESprite: TSprite;
   SitFrontSprite, StandUpFrontSprite, SitandStandUpFrontSprite,
   CurrentSprite : TSprite;
   Location: string; // for setting game location of Player or Non-Playing Character (NPC)
   X, Y: Integer;
   WalkLeft, WalkRight, WalkFront, WalkBack, WalkSW, WalkSE, WalkNW, WalkNE: integer;  // animation sequence
   StandLeft, StandRight, StandFront, StandBack, StandSW, StandSE, StandNW, StandNE: integer; // animation sequence
   MoveLeft, MoveRight, MoveDown, MoveUp, MoveSW, MoveSE, MoveNW, MoveNE : boolean; // switches
   SitFront, StandUpFront,SitAndStandUpFront: integer;
   Stand: boolean;
   MoveToMouse, MoveToNPC: boolean;
   DestX, DestY : float;
   Talkedto: String;
   Left: boolean;
   function Rect: TFloatRectangle;
   constructor Create;
   destructor Destroy; override;
   //procedure Update(const SecondsPassed: TFloatTime);
   end;

 type
    TLocation = class
    public
    Name: String;
    BackGround: TSprite;
    ShortDescription: String;
    LongDescription: String;
    ExitRight, ExitLeft, ExitTop, ExitDown: string; // location exits
    ExitRX, ExitLX, ExitTY, ExitDY: single;
    constructor Create;
    destructor Destroy; override;
 //   procedure Update(const SecondsPassed: TFloatTime);
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
  TNPCList = specialize TObjectList<TPlayer>;


  TSpriteList = specialize TObjectList<TPlayer>;

  type
  TSpriteComparer = specialize TComparer<TPlayer>;

 var
  CastleControl1: TCastleControlBase;
  Window: TCastleWindowbase;
  ControlThatDeterminesMouseCursor: TCastleUserInterface;
  Location: Tlocation;
  GameMouse: TMouse;
  Player: TPlayer;
  Personalia: TPlayer.TPersonalia;
  Character: TPlayer.TCharacter;
  Appearance: TPlayer.TAppearance;

  NPC: array[1..20] of TPlayer;

  //TNPC: TPlayer;


  // set maximum of NPC sprites
  NPCAmount: Integer; // number of NPC sprites to load on location
  Locations: string = 'castle-data:/Locations/';
  Characters: string = 'castle-data:/Characters/';   // location of the graphics
  NPCNR, NR : Integer; // tellers
  NPC_Presence: boolean;  // if a NPC sprite is present on location: perform certain routines, otherwise not
  Box: array[1..20] of TPlayer;
   //Buffer: TSoundBuffer;
  // let op dat bij het volgende de truetype library freetype-6.dll in de game dir staat!!
  MyTextureFont: TTextureFont;   // gebruikt om tekst op scherm te printen
  MyBigTextureFont: TTextureFont;
  TextLine1, TextLine2: string;
  rgb1, rgb2, rgb3: Single;

  Const SWidth = 180 * 2;  // Sprite Width
  Const SHeight = 315 * 2;  // Sprite Height


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
    FreeAndNil (WalkLeftSprite);
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
// ScaleSprite := MapRange(NPC[NR].CurrentSprite.Y, 0, 500, 1.0, 0.5);
 Result := FloatRectangle(Self.CurrentSprite.X, Self.CurrentSprite.Y, Self.CurrentSprite.FrameWidth * ScaleSprite, Self.CurrentSprite.FrameHeight * ScaleSprite);
end;

function TMouse.Rect: TFloatRectangle;
var
 ScaleSprite: Single;
begin
  ScaleSprite := MapRange(Self.CurrentSprite.Y, 0, 500, 1.0, 1.0);
  Result := FloatRectangle(Self.CurrentSprite.X, Self.CurrentSprite.Y, Self.CurrentSprite.FrameWidth * ScaleSprite, Self.CurrentSprite.FrameHeight * ScaleSprite)
end;

Procedure NPC_StandFront;
begin
  NPC[NPCNR].StandFrontSprite:= TSprite.CreateFrameSize (Characters + NPC[NPCNR].FullName + '/' + NPC[NPCNR].Outfit + '/' + NPC[NPCNR].FirstName + 'StandFront.png', 60, 10, SWidth, SHeight, true, true);
  NPC[NPCNR].StandFrontSprite.FramesPerSecond:= 15;
  NPC[NPCNR].StandFront := NPC[NPCNR].StandFrontSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
  24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
  58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
  22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
end;

Procedure NPC_StandLeft;
begin
  NPC[NPCNR].StandLeftSprite:= TSprite.CreateFrameSize (Characters + NPC[NPCNR].FullName + '/' + NPC[NPCNR].Outfit + '/' + NPC[NPCNR].FirstName + 'Standleft.png', 60, 10, SWidth, SHeight, true, true);
  NPC[NPCNR].StandLeftSprite.FramesPerSecond:= 15;
  NPC[NPCNR].StandLeft := NPC[NPCNR].StandLeftSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
  24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
  58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
  22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
end;

Procedure NPC_WalkLeft;
  begin
  NPC[NPCNR].WalkLeftSprite := TSprite.CreateFrameSize (Characters + NPC[NPCNR].FullName + '/' + NPC[NPCNR].Outfit + '/' + NPC[NPCNR].FirstName +'Walkleft.png',60, 10, SWidth, SHeight, true, true);
  NPC[NPCNR].WalkLeftSprite.FramesPerSecond:= 60;
  NPC[NPCNR].WalkLeft := NPC[NPCNR].WalkLeftSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
  31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);
end;

Procedure NPC_WalkRight;
  begin
  NPC[NPCNR].WalkRightSprite := TSprite.CreateFrameSize (Characters + NPC[NPCNR].FullName + '/' + NPC[NPCNR].Outfit + '/' + NPC[NPCNR].FirstName + 'Walkright.png',60, 10, Swidth, SHeight, true, true);
  NPC[NPCNR].WalkrightSprite.FramesPerSecond:= 60;
  NPC[NPCNR].WalkRight := NPC[NPCNR].WalkRightSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
  31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);
end;

Procedure StopMove;
begin
  Player.MoveLeft := False;
  Player.MoveRight := False;
  Player.MoveUp := False;
  Player.MoveDown := False;
  Player.MoveSW := False;
  Player.MoveSE := False;
  Player.MoveNW := False;
  Player.MoveNE := False;
end;

Procedure GoLeft;
begin
  if Player.Stand then
  begin
    Player.WalkLeftSprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
    Player.WalkLeftSprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
    Player.WalkLeftSprite.X := Player.CurrentSprite.X;
    Player.WalkLeftSprite.Y := Player.CurrentSprite.Y;
    Player.CurrentSprite := Player.WalkLeftSprite;
    Player.WalkLeftSprite.SwitchToAnimation(Player.WalkLeft);
    StopMove;
    Player.WalkLeftSprite.Play;
    Player.MoveLeft := True;
    Player.Stand := False;
  end else
  begin
    Player.StandLeftSprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
    Player.StandLeftSprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
    Player.StandLeftSprite.X := Player.CurrentSprite.X;
    Player.StandLeftSprite.Y := Player.CurrentSprite.Y;
    Player.CurrentSprite := Player.StandLeftSprite;
    Player.StandLeftSprite.SwitchToAnimation(Player.StandLeft);
    StopMove;
    Player.StandLeftSprite.Play;
    Player.Stand := True;
  end;
end;

Procedure GoRight;
begin
  if Player.Stand then
  begin
    Player.WalkRightSprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
    Player.WalkRightSprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
    Player.WalkRightSprite.X := Player.CurrentSprite.X;
    Player.WalkRightSprite.Y := Player.CurrentSprite.Y;
    Player.CurrentSprite := Player.WalkRightSprite;
    Player.WalkRightSprite.SwitchToAnimation(Player.WalkRight);
    StopMove;
    Player.WalkRightSprite.Play;
    Player.MoveRight := True;
    Player.Stand := False;
  end else
  begin
    Player.StandRightSprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
    Player.StandRightSprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
    Player.StandRightSprite.X := Player.CurrentSprite.X;
    Player.StandRightSprite.Y := Player.CurrentSprite.Y;
    Player.CurrentSprite := Player.StandRightSprite;
    Player.StandRightSprite.SwitchToAnimation(Player.StandRight);
    StopMove;
    Player.StandRightSprite.Play;
    Player.Stand := True;
  end;
end;

Procedure GoUp;
begin
  if Player.Stand then
  begin
    Player.WalkBackSprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
    Player.WalkBackSprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
    Player.WalkBackSprite.X := Player.CurrentSprite.X;
    Player.WalkBackSprite.Y := Player.CurrentSprite.Y;
    Player.CurrentSprite := Player.WalkBackSprite;
    Player.WalkBackSprite.SwitchToAnimation(Player.WalkBack);
    StopMove;
    Player.WalkBackSprite.Play;
    Player.MoveUp := True;
    Player.Stand := False;
  end else
  begin
    Player.StandBackSprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
    Player.StandBackSprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
    Player.StandBackSprite.X := Player.CurrentSprite.X;
    Player.StandBackSprite.Y := Player.CurrentSprite.Y;
    Player.CurrentSprite := Player.StandBackSprite;
    Player.StandBackSprite.SwitchToAnimation(Player.StandBack);
    StopMove;
    Player.StandBackSprite.Play;
    Player.Stand := True;
  end;
end;

Procedure GoDown;
begin
  if Player.Stand then
  begin
    Player.WalkFrontSprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
    Player.WalkFrontSprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
    Player.WalkFrontSprite.X := Player.CurrentSprite.X;
    Player.WalkFrontSprite.Y := Player.CurrentSprite.Y;
    Player.CurrentSprite := Player.WalkFrontSprite;
    Player.WalkFrontSprite.SwitchToAnimation(Player.WalkFront);
    StopMove;
    Player.WalkFrontSprite.Play;
    Player.MoveDown := True;
    Player.Stand := False;
  end else
  begin
    Player.StandFrontSprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
    Player.StandFrontSprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
    Player.StandFrontSprite.X := Player.CurrentSprite.X;
    Player.StandFrontSprite.Y := Player.CurrentSprite.Y;
    Player.CurrentSprite := Player.StandFrontSprite;
    Player.StandFrontSprite.SwitchToAnimation(Player.StandFront);
    StopMove;
    Player.StandFrontSprite.Play;
    Player.Stand := True;
  end;
end;

Procedure GoSW;
 begin
   if Player.Stand then
   begin
     Player.WalkSWSprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
     Player.WalkSWSprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
     Player.WalkSWSprite.X := Player.CurrentSprite.X;
     Player.WalkSWSprite.Y := Player.CurrentSprite.Y;
     Player.CurrentSprite := Player.WalkSWSprite;
     Player.WalkSWSprite.SwitchToAnimation(Player.WalkSW);
     StopMove;
     Player.WalkSWSprite.Play;
     Player.MoveSW := True;
     Player.Stand := False;
   end else
   begin
     Player.StandSWSprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
     Player.StandSWSprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
     Player.StandSWSprite.X := Player.CurrentSprite.X;
     Player.StandSWSprite.Y := Player.CurrentSprite.Y;
     Player.CurrentSprite := Player.StandSWSprite;
     Player.StandSWSprite.SwitchToAnimation(Player.StandSW);
     StopMove;
     Player.StandSWSprite.Play;
     Player.Stand := True;
   end;
end;

Procedure GoSE;
begin
  if Player.Stand then
  begin
    Player.WalkSESprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
    Player.WalkSESprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
    Player.WalkSESprite.X := Player.CurrentSprite.X;
    Player.WalkSESprite.Y := Player.CurrentSprite.Y;
    Player.CurrentSprite := Player.WalkSESprite;
    Player.WalkSESprite.SwitchToAnimation(Player.WalkSE);
    StopMove;
    Player.WalkSESprite.Play;
    Player.MoveSE := True;
    Player.Stand := False;
  end else
  begin
    Player.StandSESprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
    Player.StandSESprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
    Player.StandSESprite.X := Player.CurrentSprite.X;
    Player.StandSESprite.Y := Player.CurrentSprite.Y;
    Player.CurrentSprite := Player.StandSESprite;
    Player.StandSESprite.SwitchToAnimation(Player.StandSE);
    StopMove;
    Player.StandSESprite.Play;
    Player.Stand := True;
  end;
end;

Procedure GoNE;
 begin
   if Player.Stand then
   begin
     Player.WalkNESprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
     Player.WalkNESprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
     Player.WalkNESprite.X := Player.CurrentSprite.X;
     Player.WalkNESprite.Y := Player.CurrentSprite.Y;
     Player.CurrentSprite := Player.WalkNESprite;
     Player.WalkNESprite.SwitchToAnimation(Player.WalkNE);
     StopMove;
     Player.WalkNESprite.Play;
     Player.MoveNE := True;
     Player.Stand := False;
   end else
   if Player.Stand = False then
   begin
     Player.StandNESprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
     Player.StandNESprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
     Player.StandNESprite.X := Player.CurrentSprite.X;
     Player.StandNESprite.Y := Player.CurrentSprite.Y;
     Player.CurrentSprite := Player.StandNESprite;
     Player.StandNESprite.SwitchToAnimation(Player.StandNE);
     StopMove;
     Player.StandNESprite.Play;
     Player.Stand := True;
   end;
end;

 Procedure GoNW;
 begin
   if Player.Stand then
   begin
     Player.WalkNWSprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
     Player.WalkNWSprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
     Player.WalkNWSprite.X := Player.CurrentSprite.X;
     Player.WalkNWSprite.Y := Player.CurrentSprite.Y;
     Player.CurrentSprite := Player.WalkNWSprite;
     Player.WalkNWSprite.SwitchToAnimation(Player.WalkNW);
     StopMove;
     Player.WalkNWSprite.Play;
     Player.MoveNW := True;
     Player.Stand := False;
   end else
   begin
     Player.StandNWSprite.DrawingWidth:= Player.CurrentSprite.DrawingWidth;
     Player.StandNWSprite.DrawingHeight:= Player.CurrentSprite.DrawingHeight;
     Player.StandNWSprite.X := Player.CurrentSprite.X;
     Player.StandNWSprite.Y := Player.CurrentSprite.Y;
     Player.CurrentSprite := Player.StandNWSprite;
     Player.StandNWSprite.SwitchToAnimation(Player.StandNW);
     StopMove;
     Player.StandNWSprite.Play;
     Player.Stand := True;
   end;
end;

 Procedure LoadNPC;  // load all NPC characters that are on location
 begin
   NPC_Presence := True;
   With NPC[NPCNR] do  // load the NPC with the corresponding number
   begin
     NPC[NPCNR].FullName := (NPC[NPCNR].FirstName + ' '+ NPC[NPCNR].LastName);
     NPC[NPCNR].Stand := True;
     NPC_StandLeft; // load animation sequence
 //  NPC_WalkLeft; // load animation sequence
     CurrentSprite := NPC[NPCNR].StandLeftSprite;
     Assert(CurrentSprite <> nil);
     CurrentSprite.X := NPC[NPCNR].X;
     CurrentSprite.Y := 0;
     CurrentSprite.SwitchToAnimation(NPC[NPCNR].StandLeft);
     CurrentSprite.Play;
     Box[NR] := NPC[NPCNR]; // put the NPC that is on this location in a list (Box).
     Inc(NR); // then increment the number of the Box list so it can hold another NPC if procedure LoadNPC is called again
     Inc(NPCAmount); // increment the total of NPC after each added NPC
   end;
end;


procedure Westbeach;
begin
  Location.Name := ('Westbeach');
  Location.BackGround := TSprite.Create(Locations + Location.Name + '.png', 1, 1, 1, true, true);
  Location.ExitLeft := 'None';
  Location.ExitRight := 'Eastbeach';
  Location.ExitLX := 90;
  Location.ExitRX := 1470;
  NR := 1;
  NPCAmount := 0;

  For NPCNR:= 1 to 5 do  // check the initial or present location of every NPC character
  begin
     if NPC[NPCNR].Location = 'westbeach' then LoadNPC;
  end;
end;

//  Buffer := SoundEngine.LoadBuffer('F:\Ocean Waves.wav');
  //Buffer := SoundEngine.LoadBuffer(fx + 'seagulls.wav');
//  SoundEngine.PlaySound(Buffer);
//end;

procedure Eastbeach;
begin
  Location.Name := ('Eastbeach');
  Location.BackGround := TSprite.Create(Locations + Location.Name + '.png', 1, 1, 1, true, true);
  Location.ExitLeft := 'Westbeach';
  Location.ExitRight := 'None';
  Location.ExitLX := 90;
  Location.ExitRX := 1470;
  NR := 1;
  NPCAmount := 0;
  Player.CurrentSprite.X := (Location.ExitLX - Player.CurrentSprite.DrawingWidth);
  For NPCNR:= 1 to 5 do  // check the location of every NPC character
  begin
     if NPC[NPCNR].Location = 'eastbeach' then LoadNPC;
  end;
end;


 //procedure TForm1.CastleControl1Render(Sender: TObject);
Procedure WindowRender(Container: TUIContainer);
var
 SpriteList: TSpriteList;
 M: TPlayer;
   begin
// inherited;
//Location.BackGround.Color := Vector4(0.5, 0.5, 0.5, 1);  // laat het avond worden
//Location.BackGround.Color := Vector4(0.3, 0.3, 0.3, 1);
// Location.BackGround.Color := Vector4(0.2, 0.2, 0.2, 1);
// Location.BackGround.Color := Vector4(0.1, 0.1, 0.1, 1);
// Location.BackGround.Color := Vector4(0.05, 0.05, 0.05, 1);

Location.BackGround.Color := Vector4(rgb1, rgb2, rgb3, 1);  // fade background to night
Player.CurrentSprite.Color := Vector4(rgb1, rgb2, rgb3, 1);

//Player.Sprite.Color := Vector4(rgb1, rgb2, rgb3, 1);

SpriteList := TSpriteList.Create(false);
try
  SpriteList.Add(Player);

  if NPC_Presence then
  begin
    For NR := 1 to NPCAmount do
    begin
      SpriteList.Add(Box[NR]);
    end;
  end;

  SpriteList.Sort(TSpriteComparer.Construct(@CompareSprites));
  Location.BackGround.Draw(0, 0, 1920, 1080);

  for M in SpriteList do
  M.CurrentSprite.Draw(M.Rect);
  finally FreeAndNil(SpriteList) end;

//Player.CurrentSprite.Draw;

//GameMouse.CurrentSprite.Position := CastleControl1.MousePosition;
GameMouse.CurrentSprite.Position := Window.MousePosition;

GameMouse.CurrentSprite.Draw;

MyTextureFont.Print(20, 5, Yellow, TextLine1);
MyTextureFont.Print(70, 5, Red, TextLine2);
MyTextureFont.Print(300, 30, Red, 'number of NPC on location:'+ inttostr(NPCAmount));

Player.X := Round(Player.CurrentSprite.X);

MyBigTextureFont.Print(500, 1000, Blue, 'RESCUE ISLAND');


if GameMouse.Rect.Collides(Player.Rect.Grow(-150)) then
begin
  if GameMouse.NR = 0 then // look at
  begin
    MyTextureFont.Print(Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/3, Player.CurrentSprite.Y + Player.CurrentSprite.DrawingHeight, White, Player.FirstName);
  end;
end;

if NPC_Presence then
begin
for NR := 1 to NPCAmount do
begin
  if GameMouse.Rect.Collides(Box[NR].Rect.Grow(-150)) then
  begin
    if GameMouse.NR = 0 then // look at
    begin
      MyTextureFont.Print(Box[NR].CurrentSprite.X + Box[NR].CurrentSprite.DrawingWidth/3, Box[NR].CurrentSprite.Y + Box[NR].CurrentSprite.DrawingHeight, White, 'Look at ' + Box[NR].FirstName);
    end;

  if GameMouse.Nr = 1 then  // test: make selected NPC character walk left
  begin
   MyTextureFont.Print(Box[NR].CurrentSprite.X + Box[NR].CurrentSprite.DrawingWidth/3, Box[NR].CurrentSprite.Y + Box[NR].CurrentSprite.DrawingHeight, White, 'Command ' + Box[NR].FirstName);
  //   NPC_WalkLeft;
   //  GameMouse.Nr := 0; // prevents from looping / reloading the GameMouse.NR = 1 actions
  end;

  if GameMouse.NR = 2 then // talk to
//    begin
// Player.DestX := NPC[NR].X;  //Round(NPC[1].X);
//  Player.DestY := NPC[NR].Y;  // Round(NPC[1].Y);
//  if Player.X < NPC[NR].X then Player.MoveToDest := True;
//  if Player.X = NPC[NR].X then
 // begin
 // Player.MoveToDest := False;
   begin
    MyTextureFont.Print(Box[NR].CurrentSprite.X + Box[NR].CurrentSprite.DrawingWidth/3, Box[NR].CurrentSprite.Y + Box[NR].CurrentSprite.DrawingHeight, White, 'Talk to ' + Box[NR].FirstName);
    end;
  end;
 end;
end;

{if Player.Rect.Collides(NPC[1].Rect.Grow(-200))then
 begin
   Player.StandRightSprite.X := Player.CurrentSprite.X - 1;
   Player.StandRightSprite.Y := Player.CurrentSprite.Y;
   Player.CurrentSprite := Player.StandRightSprite;
   Player.StandRightSprite.SwitchToAnimation(Player.StandRight);
   Player.StandRightSprite.Play;
   Player.MoveRight := False;
   Player.DestX := Player.CurrentSprite.X;  // onthoud de eindpositie
  Player.DestY := Player.CurrentSprite.Y;
end;
}
  // 50% grootte is:
// Player.Sprite.DrawingWidth := 295;
// Player.Sprite.DrawingHeight:= 475;

  // 80% grootte is:
 // Player.Sprite.DrawingWidth := 472;
 //Player.Sprite.DrawingHeight:= 760;


//if Player.Sprite.X < 200 then

 //Player.Sprite.HorizontalFlip:= True;

 // Player.Sprite.Draw(Player.Sprite.X ,Y);
//  Player.Sprite.Move(Player.Sprite.X + 1 , 0, 0);

//Player.Sprite.VerticalFlip := True;
//Sprite.Draw(X, Y);
// Player.Sprite.DrawFlipped(R, true, false);


end;


procedure WindowUpdate(Container: TUIContainer);
var
  SecondsPassed: Single;
  begin
    SecondsPassed := Container.Fps.SecondsPassed;
    Player.X := round(Player.CurrentSprite.X);

    if Player.MoveRight then Player.CurrentSprite.X := Player.CurrentSprite.X + SecondsPassed * 280;
    if Player.MoveLeft  then Player.CurrentSprite.X := Player.CurrentSprite.X - SecondsPassed * 280;


   if Player.MoveToMouse then
   begin

     if Player.MoveRight then
     begin
       if GameMouse.NR = 6 then Player.DestX := Location.ExitRX - 100;
       if GameMouse.NR = 3 then
       begin
         if Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/2 > Player.DestX then
         begin
           Player.MoveToMouse := False;
           Player.StandRightSprite.X := Player.CurrentSprite.X;
           Player.StandRightSprite.Y := Player.CurrentSprite.Y;
           Player.CurrentSprite := Player.StandRightSprite;
           Player.StandRightSprite.SwitchToAnimation(Player.StandRight);
           Player.StandRightSprite.Play;
           Player.MoveRight := False;
         end;
       end;
     end;


     if Player.MoveLeft then
     begin
       if GameMouse.NR = 5 then Player.DestX := (Location.ExitLX + GameMouse.CurrentSprite.DrawingWidth);
       if GameMouse.NR = 3 then
       begin
         if (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/2) < Player.DestX then
         begin
           Player.MoveToMouse := False;
           Player.StandLeftSprite.X := Player.CurrentSprite.X;
           Player.StandLeftSprite.Y := Player.CurrentSprite.Y;
           Player.CurrentSprite := Player.StandLeftSprite;
           Player.StandLeftSprite.SwitchToAnimation(Player.StandLeft);
           Player.StandLeftSprite.Play;
           Player.MoveLeft := False;
         end;
       end;
     end;

     if Player.MoveNE then
     begin
       if (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/2) > Player.DestX then
       begin
         StopMove;
         Player.MoveToMouse := False;
         Player.StandNESprite.X := Player.CurrentSprite.X;
         Player.StandNESprite.Y := Player.CurrentSprite.Y;
         Player.CurrentSprite := Player.StandNESprite;
         Player.StandNESprite.SwitchToAnimation(Player.StandNE);
         Player.StandNESprite.Play;
         Player.MoveNE := False;
       end;
     end;

     if Player.MoveNW then
     begin
       if (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/2) < Player.DestX then
       begin
         StopMove;
         Player.MoveToMouse := False;
         Player.StandNWSprite.X := Player.CurrentSprite.X;
         Player.StandNWSprite.Y := Player.CurrentSprite.Y;
         Player.CurrentSprite := Player.StandNWSprite;
         Player.StandNWSprite.SwitchToAnimation(Player.StandNW);
         Player.StandNWSprite.Play;
         Player.MoveNW := False;
       end;
     end;

     if Player.MoveSE then
     begin
       if (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/2) > Player.DestX then
       begin
         StopMove;
         Player.MoveToMouse := False;
         Player.StandSESprite.X := Player.CurrentSprite.X;
         Player.StandSESprite.Y := Player.CurrentSprite.Y;
         Player.CurrentSprite := Player.StandSESprite;
         Player.StandSESprite.SwitchToAnimation(Player.StandSE);
         Player.StandSESprite.Play;
         Player.MoveSE := False;
       end;
     end;

     if Player.MoveSW then
     begin
       if (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth/3) < Player.DestX then
       begin
         StopMove;
         Player.MoveToMouse := False;
         Player.StandSWSprite.X := Player.CurrentSprite.X;
         Player.StandSWSprite.Y := Player.CurrentSprite.Y;
         Player.CurrentSprite := Player.StandSWSprite;
         Player.StandSWSprite.SwitchToAnimation(Player.StandSW);
         Player.StandSWSprite.Play;
         Player.MoveSW := False;
       end;
     end;

     if Player.MoveUp then
     begin
       if Player.CurrentSprite.Y > Player.DestY then
       begin
         StopMove;
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
         StopMove;
         Player.MoveToMouse := False;
         Player.StandFrontSprite.X := Player.CurrentSprite.X;
         Player.StandFrontSprite.Y := Player.CurrentSprite.Y;
         Player.CurrentSprite := Player.StandFrontSprite;
         Player.StandFrontSprite.SwitchToAnimation(Player.StandFront);
         Player.StandFrontSprite.Play;
         Player.MoveDown := False;
       end;
     end;
  end;
   {
   if NPC_Presence then
   begin
   For NR := 1 to NPCAmount do
     begin
       if NPC[NR].MoveLeft then NPC[NR].CurrentSprite.X := NPC[NR].CurrentSprite.X - SecondsPassed * 280;
     end;
   end;
  }

    If GameMouse.CurrentSprite.X > Location.ExitRX then
    begin
      if GameMouse.NR = 3 then
      begin
        GameMouse.NR := 6;
        GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[6]);
      end;
    end;

    If GameMouse.CurrentSprite.X < Location.ExitRX then
    begin
      if GameMouse.NR = 6 then
      begin
        GameMouse.NR:= 3;
        GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[GameMouse.NR]);
      end;
   end;

    If (GameMouse.CurrentSprite.X + GameMouse.CurrentSprite.DrawingWidth) < Location.ExitLX then
    begin
    if GameMouse.NR = 3 then
   //   begin
        GameMouse.NR:= 5;
        GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[GameMouse.NR]);
   //   end;
   end;

    If (GameMouse.CurrentSprite.X + GameMouse.CurrentSprite.DrawingWidth) > Location.ExitLX then
    begin
      if GameMouse.NR = 5 then
      begin
        GameMouse.NR:= 3;
        GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[GameMouse.NR]);
      end;
   end;


   if Player.CurrentSprite.X >= Location.ExitRX then
   begin
     if Location.ExitRight = 'Eastbeach' then Eastbeach;
   end;

   if (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth) <= Location.ExitLX - 400 then
   begin
    if Location.ExitLeft = 'Westbeach' then Westbeach;
     Player.CurrentSprite.X := 1500;
   end;

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

   if Player.MoveUp then
   begin
     Player.CurrentSprite.Y := Player.CurrentSprite.Y + 2; //SecondsPassed * 100.0;
   end;

   if Player.MoveDown then
   begin
     Player.CurrentSprite.Y := Player.CurrentSprite.Y - SecondsPassed * 100.0;
   end;


Location.BackGround.Update(SecondsPassed);
GameMouse.MouseImages.Update(SecondsPassed);

Player.CurrentSprite.Update(SecondsPassed);
 // end;
  if NPC_Presence then
  begin
    for NR := 1 to NPCAmount do
    begin
      Box[NR].CurrentSprite.Update(SecondsPassed);
    end;
  end;


end;


procedure WindowPress(Container: TUIContainer; const Event: TInputPressRelease);
begin
  if Event.IsKey(K_Escape) then Window.Close;

  if Event.IsKey(K_Space)then
  begin
    rgb1 := rgb1-0.004;
    rgb2 := rgb2-0.004;
    rgb3 := rgb3-0.004;
    Location.BackGround.Color := Vector4(rgb1, rgb2, rgb3, 1);  // laat het avond worden
  end;

  if Event.IsKey(K_0) then
  begin
    rgb1 := rgb1 + 0.003;
    rgb2 := rgb2 + 0.003;
    rgb3 := rgb3 + 0.003;
    Location.BackGround.Color := Vector4(rgb1, rgb2, rgb3, 1);  // laat het avond worden
  end;


  if Event.IsMouseButton(mbleft) then
  begin
    TextLine1 := IntToStr(Round(Event.Position.X));
    TextLine2 := IntToStr(Round(Event.Position.Y));
    Player.MoveToMouse := True;

If GameMouse.NR = 1 then
begin

end;
 //   if GameMouse.NR = 2 then  // "talk to NPC" selected, then move Player to NPC
 //  begin
  //    Player.DestX := NPC[NR].CurrentSprite.X;  //Round(NPC[1].X);
  //    Player.DestY := NPC[NR].CurrentSprite.Y;  // Round(NPC[1].Y);
 // Player.MoveToMouse := True;

 if GameMouse.NR = 5 then GameMouse.NR := 3;
 if GameMouse.NR = 6 then GameMouse.NR := 3;
 if GameMouse.NR = 3 then // walk
 begin


   if Event.IsMouseButton(mbleft) then // select walk and move to the mousesprite coordinates
   begin
     Player.MoveToMouse := True;
     Player.DestX := Event.Position.X;
     Player.DestY := Event.Position.Y;

     If Player.DestY > Player.Y then
     begin
       if (Player.DestX > Player.CurrentSprite.X) and (Player.DestX < Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth) and (Player.DestY > (Player.CurrentSprite.Y + Player.CurrentSprite.DrawingHeight/3)) then
       begin
         GoUp;
       end;
       if (Player.DestX > (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth)) and (Player.DestY > (Player.CurrentSprite.Y + Player.CurrentSprite.DrawingHeight/3)) then
       begin
         GoNE;
       end;
       if (Player.DestX > (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth)) and (Player.DestY > Player.CurrentSprite.Y) and (Player.DestY < Player.CurrentSprite.DrawingHeight/3) then
       begin
         GoRight;
       end;
     end;

     if Player.DestY < Player.CurrentSprite.Y then
     begin
       if (Player.DestX > (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth)) and (Player.DestY < Player.CurrentSprite.Y) then
       begin
         GoSE;
       end;
       if (Player.DestX > Player.CurrentSprite.X) and (Player.DestX < (Player.CurrentSprite.X + Player.CurrentSprite.DrawingWidth)) then
       begin
         GoDown;
       end;
       if (Player.DestX < Player.CurrentSprite.X) and (Player.DestY < Player.CurrentSprite.Y) then
       begin
         GoSW;
       end;
     end;

     if (Player.DestX < Player.CurrentSprite.X) and (Player.DestY > Player.CurrentSprite.Y) and (Player.DestY < (Player.CurrentSprite.Y + Player.CurrentSprite.DrawingHeight/3)) then
       begin
         GoLeft;
       end;
     if (Player.DestX < Player.CurrentSprite.X) and (Player.DestY > (Player.CurrentSprite.Y + Player.CurrentSprite.DrawingHeight/3)) then
       begin
         GoNW;
       end;
     end;
 end;


//    if GameMouse.NR = 4 then
 //   begin
  //    Player.DestX := Round(Event.Position.X);
  //    Player.DestY := Round(Event.Position.Y);
   //   Player.MoveToMouse := True;
//  end;
  end;

  if Event.IsMouseButton(mbright)then
  begin
    inc(GameMouse.NR);
    if GameMouse.NR = 4 then GameMouse.NR := 0;
    GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[GameMouse.NR]);
  end;

  if Event.IsKey(K_Left) then GoLeft;
  if Event.IsKey(K_Right) then GoRight;
  if Event.IsKey(K_Up) then GoUp;
  if Event.IsKey(K_Down) then GoDown;
end;


Procedure LoadNPC_DBase;
var
  NPCList: TNPCList;
  NewNPC: TPlayer;
begin
NPCList := TNPCList.Create(true);
   try
     NewNPC := TPlayer.Create;
     with NewNPC do
     begin
       FirstName:= 'Kyley';
       LastName:= 'Carring';
       FullName := NewNPC.FirstName + NewNPC.LastName;
       Outfit:= 'Casual';
       Location := 'westbeach';
       X := 350;
       Y := 200;
       Talkedto := 'Hi!';
     end;
     NPCList.Add(NewNPC);

     NewNPC := TPlayer.Create;
     with NewNPC do
     begin
       FirstName:= 'Thari';
       LastName:= 'Langdon';
       FullName := NewNPC.FirstName + NewNPC.LastName;
       Outfit:= 'Casual';
       Location := 'eastbeach';
       X := 700;
       Y := 200;
       Talkedto := 'Good day sir';
     end;
     NPCList.Add(NewNPC);

     NewNPC := TPlayer.Create;
     with NewNPC do
     begin
       FirstName:= 'Yoko';
       LastName:= 'Masako';
       FullName := NewNPC.FirstName + NewNPC.LastName;
       Outfit:= 'Casual';
       Location := 'eastbeach';
       X := 900;
       Y := 200;
       Talkedto := 'Sayonara!';
     end;
     NPCList.Add(NewNPC);

     NewNPC := TPlayer.Create;
     with NewNPC do
     begin
       FirstName:= 'Victor';
       LastName:= 'Bergwald';
       FullName := NewNPC.FirstName + NewNPC.LastName;
       Outfit:= 'Casual';
       Location := 'eastbeach';
       X := 1100;
       Y := 200;
       Talkedto := 'Hm?';
     end;
     NPCList.Add(NewNPC);
     finally // FreeAndNil(NPCList)
end;
end;

// initialize program

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
GameMouse.MouseImages := TSprite.CreateFrameSize('castle-data:/mouse-icons.png', 450, 100, 50, 50, true, true);

//ControlThatDeterminesMouseCursor := TCastleUserInterface.Create(Self);
//ControlThatDeterminesMouseCursor.FullSize := true;
//ControlThatDeterminesMouseCursor.Cursor := mcNone;
//CastleControl1.Controls.InsertFront(ControlThatDeterminesMouseCursor);


GameMouse.MouseImages.FramesPerSecond:= 1;
GameMouse.Action[0]:= GameMouse.MouseImages.AddAnimation([0]);  // look
GameMouse.Action[1]:= GameMouse.MouseImages.AddAnimation([1]);  // get
GameMouse.Action[2]:= GameMouse.MouseImages.AddAnimation([2]);  // talk
GameMouse.Action[3]:= GameMouse.MouseImages.AddAnimation([3]);  // walk
GameMouse.Action[4]:= GameMouse.MouseImages.AddAnimation([4]);  // inventory
GameMouse.Action[5]:= GameMouse.MouseImages.AddAnimation([5]); // exit left arrow
GameMouse.Action[6]:= GameMouse.MouseImages.AddAnimation([6]); // exit right arrow

GameMouse.CurrentSprite := GameMouse.MouseImages;
GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[NR]);
GameMouse.CurrentSprite.Play;




//NPCAmount := 4;  // plaats aantal NPC op deze locatie
For NPCNR := 1 to 5 do
begin
NPC[NPCNR] := TPlayer.Create;
end;

Player.FirstName := 'Victor';
Player.LastName := 'Bergwald';
Player.FullName := Player.FirstName + ' ' + Player.LastName;
Player.Outfit := 'Casual';

LoadNPC_DBase;
//with NPCList do     won't work here because it's a local list?
begin

end;

NPC[1].FirstName:= 'Kyley';
NPC[1].LastName:= 'Carring';
NPC[1].FullName := NPC[1].FirstName + ' '+ NPC[1].LastName;
NPC[1].Outfit:= 'Casual';
NPC[1].Location := 'westbeach';
NPC[1].X := 350;
NPC[1].Y := 200;
NPC[1].Talkedto:= 'Hi!';

NPC[2].FirstName:= 'Thari';
NPC[2].LastName:= 'Langdon';
NPC[2].FullName := NPC[2].FirstName + ' '+ NPC[2].LastName;
NPC[2].Outfit := 'Casual';
NPC[2].Location:= 'eastbeach';
NPC[2].X := 650;
NPC[2].Y := 200;
NPC[2].Talkedto:= 'What do you want from me?';

NPC[3].FirstName := 'Yoko';
NPC[3].LastName:= 'Masako';
NPC[3].FullName := NPC[3].FirstName + ' '+ NPC[3].LastName;
NPC[3].Outfit := 'Casual';
NPC[3].Location:= 'eastbeach';
NPC[3].X := 1100;
NPC[3].Y := 200;
NPC[3].Talkedto:= 'Sayonara sir!';

NPC[4].FirstName:= 'Victor';
NPC[4].LastName := 'Bergwald';
NPC[4].FullName := NPC[4].FirstName + ' '+ NPC[4].LastName;
NPC[4].Outfit := 'Casual';
NPC[4].Location:= 'westbeach';
NPC[4].X := 1000;
NPC[4].Y := 200;
NPC[4].Talkedto:= 'Outstanding!';

NPC[5].FirstName:= 'Jack';
NPC[5].LastName := 'Delaney';
NPC[5].FullName := NPC[5].FirstName + ' '+ NPC[5].LastName;
NPC[5].Outfit := 'Casual';
NPC[5].Location:= 'eastbeach';
NPC[5].X := 1200;
NPC[5].Y := 200;
NPC[5].Talkedto:= 'Allright!!';


{NPC[5].FirstName:= 'Lillian';
NPC[5].LastName := 'Vanheel';
NPC[5].FullName := NPC[5].FirstName + ' '+ NPC[5].LastName;
NPC[5].Outfit := 'Casual';
NPC[5].Location:= 'eastbeach';
NPC[5].X := 450;
NPC[5].Y := 200;
NPC[5].Talkedto:= 'This is boring!';  }


// move directions of Sprite
Player.WalkLeftSprite := TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName +'WalkLeft.png',60, 10, SWidth, SHeight, true, true);
Player.WalkLeftSprite.FramesPerSecond:= 60;
Player.WalkLeft := Player.WalkLeftSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);

Player.WalkRightSprite := TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'WalkRight.png',60, 10, Swidth, SHeight, true, true);
Player.WalkrightSprite.FramesPerSecond:= 60;
Player.WalkRight := Player.WalkRightSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);

Player.WalkFrontSprite := TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.firstName + 'WalkFront.png',60, 10, SWidth, SHeight, true, true);
Player.WalkFrontSprite.FramesPerSecond:= 60;
Player.WalkFront := Player.WalkFrontSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);

Player.WalkBackSprite := TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'WalkBack.png', 60, 10, SWidth, SHeight, true, true);
Player.WalkBackSprite.FramesPerSecond:= 60;
Player.WalkBack := Player.WalkBackSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);

Player.WalkSWSprite:= TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'WalkSW.png', 60, 10, SWidth, SHeight, true, true);
Player.WalkSWSprite.FramesPerSecond:= 60;
Player.WalkSW := Player.WalkSWSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);

Player.WalkSESprite:= TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'WalkSE.png', 60, 10, SWidth, SHeight, true, true);
Player.WalkSESprite.FramesPerSecond:= 60;
Player.WalkSE := Player.WalkSESprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);

Player.WalkNESprite:= TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'WalkNE.png', 60, 10, SWidth, SHeight, true, true);
Player.WalkNESprite.FramesPerSecond:= 60;
Player.WalkNE := Player.WalkNESprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);

Player.WalkNWSprite:= TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'WalkNW.png', 60, 10, SWidth, SHeight, true, true);
Player.WalkNWSprite.FramesPerSecond:= 60;
Player.WalkNW := Player.WalkNWSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]);


// stand directions of Sprite
Player.StandLeftSprite := TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'StandLeft.png',60, 10, SWidth, SHeight, true, true);
Player.StandLeftSprite.FramesPerSecond:= 15;
Player.StandLeft := Player.StandLeftSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);

Player.StandRightSprite := TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'StandRight.png', 60, 10, SWidth, SHeight , true, true);
Player.StandRightSprite.FramesPerSecond:= 15;
Player.StandRight := Player.StandRightSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);

Player.StandFrontSprite:= TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'StandFront.png', 60, 10, SWidth, SHeight, true, true);
Player.StandFrontSprite.FramesPerSecond:= 15;
Player.StandFront := Player.StandFrontSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);

Player.StandBackSprite := TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'StandBack.png',60, 10, SWidth, SHeight, true, true);
Player.StandBackSprite.FramesPerSecond:= 15;
Player.StandBack := Player.StandBackSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);

Player.StandSWSprite := TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'StandSW.png', 60, 10, SWidth, SHeight, true, true);
Player.StandSWSprite.FramesPerSecond:= 15;
Player.StandSW := Player.StandSWSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);

Player.StandSESprite := TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'StandSE.png', 60, 10, SWidth, SHeight, true, true);
Player.StandSESprite.FramesPerSecond:= 15;
Player.StandSE := Player.StandSESprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);

Player.StandNWSprite := TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'StandNW.png', 60, 10, SWidth, SHeight, true, true);
Player.StandNWSprite.FramesPerSecond:= 15;
Player.StandNW := Player.StandNWSprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);

Player.StandNESprite := TSprite.CreateFrameSize (Characters + Player.FullName + '/' + Player.Outfit + '/' + Player.FirstName + 'StandNE.png', 60, 10, SWidth, SHeight, true, true);
Player.StandNESprite.FramesPerSecond:= 15;
Player.StandNE := Player.StandNESprite.AddAnimation([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,
22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);



// initial
Player.CurrentSprite := Player.StandRightSprite;
Player.Stand := True;
Player.CurrentSprite.X := 100;
Player.CurrentSprite.Y := 0;
Player.CurrentSprite.SwitchToAnimation(Player.StandRight);
Player.CurrentSprite.Play;


WestBeach;   // start game on this location
//Eastbeach;


Window := TCastleWindowBase.Create(Application);
Window.OnRender := @WindowRender;
Window.OnUpdate := @WindowUpdate;
Window.OnPress := @WindowPress;
Window.Open;
Application.Run;



end.


