{ Main "playing game" state, where most of the game logic takes place.

  Feel free to use this code as a starting point for your own projects.
  (This code is in public domain, unlike most other CGE code which
  is covered by the LGPL license variant, see the COPYING.txt file.) }
unit GameStatePlay;

interface

uses Classes,
  CastleUIState, CastleComponentSerialize, CastleUIControls, CastleControls,
  CastleKeysMouse, CastleViewport, CastleScene, CastleVectors, StrUtils, Dialogs,
  CastleWindow,CastleUtils, CastleGLImages, CastleFilesUtils,
  CastleSoundEngine, CastleTimeUtils, CastleColors,
  CastleRectangles, CastleFonts, CastleGLUtils, Generics.Defaults,
  Generics.Collections, CastleOnScreenMenu, CastleDownload, CastleSceneCore,
  CastleCameras, CastleTransform,
  CastleImages, X3DNodes;

 type
   TAvatar = class(TComponent)

   private
   type TPersonalia = class
   Gender: string;
   UnknownName, FirstName, LastName, FullName: string;
   Known: Boolean;
   Age: Integer;
   end;
   var Personalia: TPersonalia;

   private
   type TCharacter = class
   GreetingLine: string;
   AnswerLine: string;
   Action: string;
   Stamina: Integer;
   Health: Integer;
   Strength: Integer;
   end;
   var Character: TCharacter;

   private
   type TAppearance = class
   Description: string;
   Outfit: string;
   end;
   var Appearance: TAppearance;

//   WalkLeft, WalkRight, WalkFront, WalkBack, Stand: boolean;
   StandIdleAnim, WalkLeftAnim, WalkRightAnim, WalkFrontAnim, WalkBackAnim: TCastleScene;

   Directory: string;
 //  Stand: boolean;

   public

   Constructor Create;

end;


  type
    { Main "playing game" state, where most of the game logic takes place. }
    TStatePlay = class(TUIState)
    private
    Player: TAvatar;
    NPC: TAvatar;

      Mouse: TCastleScene;
      PlayerScene: TCastleTransform;
      NPCScene: TCastleTransform;

      X, Y, S: single;

      Label1: TCastleLabel;
      procedure MakeMousePhysics;
      procedure MouseCollisionEnter(const CollisionDetails: TPhysicsCollisionDetails);
      procedure PlayerScenePhysics;
      procedure CreatePlayer;
      procedure CreateNPC;

      Procedure GoFront;
      Procedure GoBack;
      Procedure GoLeft;
      Procedure GoRight;
      Procedure StandFront;
      Procedure StandLeft;
      Procedure StandBack;
      Procedure StandRight;

      procedure ReplaceNodes(ParentNode: TX3DNode; var Node: TX3DNode);

      public
      constructor Create(AOwner: TComponent); override;
      procedure Start; override;
      procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;
      function Press(const Event: TInputPressRelease): Boolean; override;
    end;


var
  StatePlay: TStatePlay;
  Stand, WalkLeft, WalkRight, WalkFront, WalkBack: boolean;

implementation

uses SysUtils, Math,
  GameStateMenu;

{ TStatePlay ----------------------------------------------------------------- }


constructor TAvatar.Create;
begin
  inherited;
  Personalia := TPersonalia.Create;
  Character :=  TCharacter.Create;
  Appearance := TAppearance.Create;
  StandIdleAnim := TCastleScene.Create(Application);
  WalkLeftAnim := TCastleScene.Create(Application);
  WalkRightAnim := TCastleScene.Create(Application);
  WalkFrontAnim := TCastleScene.Create(Application);
  WalkBackAnim := TCastleScene.Create(Application);
end;
var
  MainViewport: TCastleViewport;

Procedure TStatePlay.MouseCollisionEnter(const CollisionDetails: TPhysicsCollisionDetails);
begin
  if CollisionDetails.OtherTransform <> nil then
   begin
     if CollisionDetails.OtherTransform = PlayerScene then Label1.Caption := 'YESSS!'; // .Terminate;
   end;
end;

Procedure TStatePlay.MakeMousePhysics;
 var
  RBody: TRigidBody;
  Size: TVector3;
  Collider: TBoxCollider;
  begin
    RBody := TRigidBody.Create(Mouse);
    RBody.Dynamic:= true;
    RBody.Setup2D;
    RBody.OnCollisionEnter:= @MouseCollisionEnter;

    Collider := TBoxCollider.Create(RBody);

    Size := Mouse.LocalBoundingBox.Size;
    Size.Z := Max(0.1, Size.Z);
    Collider.Size := Size;
    Mouse.RigidBody := RBody;
end;

Procedure TStatePlay.PlayerScenePhysics;
 var
  RBody: TRigidBody;
  Size: TVector3;
  Collider: TBoxCollider;
begin
  RBody := TRigidBody.Create(PlayerScene);
  RBody.Dynamic:= true;
  RBody.Setup2D;

  Collider := TBoxCollider.Create(RBody);

  Size := PlayerScene.LocalBoundingBox.Size;
  Size.Z := Max(0.1, Size.Z);
  Collider.Size := Size;
  PlayerScene.RigidBody := RBody;
end;

procedure TStatePlay.ReplaceNodes(ParentNode: TX3DNode; var Node: TX3DNode);
var
  NewNode: TPhysicalMaterialNode;
begin
  if Node is TUnlitMaterialNode then
  begin
    NewNode := TPhysicalMaterialNode.Create;
 //   NewNode.BaseTexture := Node.EmissiveTexture;
    NewNode.NormalTexture := TImageTextureNode.Create;
    TImageTextureNode(NewNode.NormalTexture).SetUrl(['castle-data:/locations/eastbeach.png']);

    Node := NewNode;
  end;
end;


procedure StopWalk;
begin
  Stand := false;
  WalkLeft := false;
  WalkRight := false;
  WalkFront := false;
  WalkBack := false;
  StatePlay.Player.StandIdleAnim.Exists := false;
  StatePlay.Player.WalkFrontAnim.Exists := false;
  StatePlay.Player.WalkFrontAnim.Exists := false;
  StatePlay.Player.WalkBackAnim.Exists := false;
  StatePlay.Player.WalkLeftAnim.Exists := false;
  StatePlay.Player.WalkRightAnim.Exists := false;
end;

Procedure TStatePlay.GoLeft;
begin
  StopWalk;
  with StatePlay.Player.WalkLeftAnim do

  begin
   // StandIdleAnim.Exists := false;
    Exists := true;
    WalkLeft := true;
 //   Stand := false;
    PlayAnimation(Player.Personalia.FirstName + 'walkleft', true);
  end;
end;

Procedure TStatePlay.StandLeft;
begin
  StopWalk;
  with StatePlay.Player.StandIdleAnim do
  begin
    Exists := true;
    WalkLeft := false;
    Stand := true;
    PlayAnimation(Player.Personalia.FirstName + 'standleft', true); ;
  end;
end;

Procedure TStatePlay.GoRight;
begin
  StopWalk;
   with StatePlay.Player.WalkRightAnim do
  begin
 //   StandIdleAnim.Exists := false;
    Exists := true;
    WalkRight := true;
    Stand := false;
    PlayAnimation(Player.Personalia.FirstName + 'walkright', true);
  end;
end;

Procedure TStatePlay.StandRight;
begin
  StopWalk;
  with StatePlay.Player.StandIdleAnim do
  begin
    Exists := true;
    WalkRight := false;
    Stand := true;
    PlayAnimation(Player.Personalia.FirstName + 'standright', true);
  end;
end;

Procedure TStatePlay.GoBack;
begin
  StopWalk;
  with StatePlay.Player.WalkBackAnim do
  begin
    Exists := true;
    WalkBack := true;
    Stand := false;
    PlayAnimation(Player.Personalia.FirstName + 'walkback', true);
  end;
end;

Procedure TStatePlay.StandBack;
begin
  StopWalk;
  with StatePlay.Player.StandIdleAnim do
  begin
    Exists := true;
    WalkBack := false;
    Stand := true;
    PlayAnimation(Player.Personalia.FirstName + 'standback', true);
  end;
end;

Procedure TStatePlay.GoFront;
begin
  StopWalk;
  with StatePlay.Player.WalkFrontAnim do
  begin
  Exists := true;
    WalkFront := true;
    Stand := false;
    PlayAnimation(Player.Personalia.FirstName + 'walkfront', true);
  end;
end;

Procedure TStatePlay.StandFront;
begin
 StopWalk;
 with StatePlay.Player.StandIdleAnim do
 begin
 Exists := true;
  WalkFront := false;
  Stand := true;
  PlayAnimation(Player.Personalia.FirstName + 'standfront', true);
  end;
 end;


constructor TStatePlay.Create(AOwner: TComponent);
begin
  inherited;
end;


procedure TStatePlay.Start;
begin
  inherited;
   DesignUrl := 'castle-data:/westbeach-gamestateplay.castle-user-interface';
   MainViewport := DesignedComponent ('Viewport') as TCastleViewport;
   Mouse := DesignedComponent ('Mouse') as TCastleScene;
   Mouse.PlayAnimation('mouse-eye', true);
   PlayerScene := DesignedComponent ('PlayerScene') as TCastleTransform;

   Label1 := DesignedComponent ('Label1') as TCastleLabel;

   CreatePlayer;
   CreateNPC;

 //  PlayerScene.RootNode.EnumerateReplaceChildren(@ReplaceNodes);



 StandFront; // initial animation of playerscene
 S := 1;

// MakeMousePhysics;
// PlayerScenePhysics;

end;

procedure TStatePlay.CreatePlayer;
begin
  Player := TAvatar.Create;
  Player.Personalia.FirstName := lowercase('Thari');
  Player.Personalia.LastName:= lowercase('Langdon');
  Player.Personalia.FullName:= Player.Personalia.FirstName + ' ' + Player.Personalia.LastName;
  Player.Appearance.Outfit:= 'casual';

  Player.Directory := 'castle-data:/characters/' + Player.Personalia.FullName + '/' + Player.Appearance.Outfit + '/' + Player.Personalia.FirstName;

  Player.StandIdleAnim := DesignedComponent ('StandIdleAnim') as TCastleScene;
  Player.WalkLeftAnim := DesignedComponent ('WalkLeftAnim') as TCastleScene;
  Player.WalkRightAnim := DesignedComponent ('WalkRightAnim') as TCastleScene;
  Player.WalkFrontAnim := DesignedComponent ('WalkFrontAnim') as TCastleScene;
  Player.WalkBackAnim := DesignedComponent ('WalkBackAnim') as TCastleScene;

  Player.StandIdleAnim.URL:= Player.Directory + 'standidle.starling-xml';
  Player.WalkFrontAnim.URL:= Player.Directory + 'walkfront.starling-xml';
  Player.WalkBackAnim.URL:= Player.Directory + 'walkback.starling-xml';
  Player.WalkLeftAnim.URL:= Player.Directory + 'walkleft.starling-xml';
  Player.WalkRightAnim.URL:= Player.Directory + 'walkright.starling-xml';
end;

procedure TStatePlay.CreateNPC;
begin
  NPC := TAvatar.Create;
  NPC.Personalia.FirstName := lowercase('Kyley');
  NPC.Personalia.LastName:= lowercase('Carring');
  NPC.Personalia.FullName:= NPC.Personalia.FirstName + ' ' + NPC.Personalia.LastName;
  NPC.Appearance.Outfit:= 'casual';
  NPC.Directory := 'castle-data:/characters/' + NPC.Personalia.FullName + '/' + NPC.Appearance.Outfit + '/' + NPC.Personalia.FirstName;

  NPCScene := TCastleTransform.Create(Application);
  MainViewport.Items.Add(NPCScene);

  NPC.StandIdleAnim.URL:= NPC.Directory + 'standidle.starling-xml';
//  NPC.WalkFrontAnim.URL:= NPC.Directory + 'walkfront.starling-xml';
//  NPC.WalkBackAnim.URL:= NPC.Directory + 'walkback.starling-xml';
//  NPC.WalkLeftAnim.URL:= NPC.Directory + 'walkleft.starling-xml';
//  NPC.WalkRightAnim.URL:= NPC.Directory + 'walkright.starling-xml';

  NPCScene.Add(NPC.StandIdleAnim);
  NPCScene.Add(NPC.WalkFrontAnim);
  NPCScene.Add(NPC.WalkBackAnim);
  NPCScene.Add(NPC.WalkLeftAnim);
  NPCScene.Add(NPC.WalkRightAnim);

  NPCScene.Translation := Vector3(-200, 0, 2);
  NPCScene.Scale := Vector3(0.5, 0.5, 0.5);
end;


procedure TStatePlay.Update(const SecondsPassed: Single; var HandleInput: Boolean);
begin
  MainViewport.Cursor := mcNone;
  Mouse.Translation := Vector3(Mainviewport.PositionTo2DWorld(Container.MousePosition, true), 9);

 if Mouse.BoundingBox.RectangleXY.Collides(StatePlay.PlayerScene.BoundingBox.RectangleXY.Grow(-30, -20)) then Label1.Caption := Player.Personalia.FirstName else Label1.Caption := ' ';
 //if Mouse.BoundingBox.RectangleXY.Collides(StatePlay.PlayerScene.BoundingBox.RectangleXY.Grow(-30, -20)) then Label1.Caption := Player.Personalia.FirstName else Label1.Caption := ' ';


 if WalkLeft = True then
  begin
    X := X - 8;
    PlayerScene.Translation := Vector3(X, Y, 1);
  end;

 if WalkRight = True then
 begin
   X := X + 8;
   PlayerScene.Translation := Vector3(X, Y, 1);
 end;

 if WalkFront = True then
 begin
   Y := Y - 3;
   S := S + 0.005;
   PlayerScene.Translation := Vector3(X, Y, 1);
   PlayerScene.Scale := Vector3(S, S, S);
 end;

 if WalkBack = True then
 begin
   Y := Y + 3;
   S := S - 0.005;
  PlayerScene.Translation := Vector3(X, Y, 1);
  PlayerScene.Scale := Vector3(S, S, S);
 end;
end;


function TStatePlay.Press(const Event: TInputPressRelease): Boolean;
begin
  Result := inherited;
  if Result then Exit; // allow the ancestor to handle keys

  if Event.IsKey(keyArrowLeft) then
  begin
    if Stand then GoLeft else StandLeft;
  end;

  if Event.IsKey(keyArrowRight) then
  begin
    if Stand then GoRight else StandRight;
  end;

  if Event.IsKey(keyArrowUp) then
  begin
    if Stand then GoBack else StandBack;
  end;

   if Event.IsKey(keyArrowDown) then
  begin
    if Stand then GoFront else StandFront;
  end;

  if Event.IsMouseButton(buttonRight)then
  begin
   Application.Terminate;
 //   inc(GameMouse.NR);  // cycle through the options
 //   if GameMouse.NR = 4 then GameMouse.NR := 0;
 //   GameMouse.CurrentSprite.SwitchToAnimation(GameMouse.Action[GameMouse.NR]);
  end;

  if Event.IsKey(keyEscape) then
  begin
    TUIState.Current := StateMenu;
    Exit(true);
  end;
end;

end.
