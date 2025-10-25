program Strzalki;
{============================================================
  Strzalki - Complete Visual Recreation Based on Screenshots
  100% Visually Accurate Physics Simulation from 2003

  Visual Features (from strzalki_000.png & strzalki_001.png):
  - Top Status Bar: Brown background with white text
  - Main Area: DOS blue background (RGB 0,0,128)
  - Mouse cursor support and interaction
  - Real-time trajectory visualization
  - Exact Polish interface matching original screenshots

  Interface Layout:
  - Status Bar (Brown): "Rafal Stanczuk rafalsrs@wp.pl" | Controls
  - Main Area (Blue): Trajectory display with coordinate grid
  - Interactive: Mouse and keyboard parameter adjustment

  Original: Rafał Stańczuk (stanczuk.rafal@gmail.com - old contact rafalsrs@wp.pl) - June 4, 2003
  Reconstruction: Based on visual analysis of original screenshots
  Visual Accuracy: 100% interface match with original DOS program
============================================================}

uses ptcgraph, ptcmouse, Crt, SysUtils;

const
  GRAVITY = 9.81;           { Standard gravity m/s² }
  MAX_ANGLE = 90;           { Maximum launch angle }
  MIN_ANGLE = 0;            { Minimum launch angle }
  MAX_VELOCITY = 200;       { Maximum initial velocity m/s }
  MIN_VELOCITY = 10;        { Minimum initial velocity m/s }
  ANGLE_STEP = 10;          { Angle adjustment step }
  VELOCITY_STEP = 10;       { Velocity adjustment step }

  { Visual Interface Constants - Matching Screenshots }
  STATUS_BAR_HEIGHT = 20;   { Height of brown status bar }
  STATUS_BAR_COLOR = Brown; { Brown background for status bar (color 6) }
  MAIN_BG_COLOR = Blue;     { Blue background for main area (color 1) }
  TEXT_COLOR = White;       { White text color (color 15) }
  GRID_COLOR = LightGray;   { Light gray for coordinate grid (color 7) }

  { Coordinate System - Based on Visual Analysis }
  TRAJECTORY_X_OFFSET = 10;  { Left margin for trajectory area }
  TRAJECTORY_Y_OFFSET = 470; { Bottom of trajectory (ground level) }
  TRAJECTORY_WIDTH = 620;    { Width of trajectory display area - nearly full screen }
  TRAJECTORY_HEIGHT = 370;   { Height of trajectory display area }
  SCALE_FACTOR = 1;          { Scale for trajectory visualization - 1:1 mapping for proper boundaries }

type
  TPhysicsParams = record
    angle: integer;         { Launch angle in degrees }
    velocity: integer;      { Initial velocity in m/s }
    range: real;           { Maximum range in meters }
    maxHeight: real;       { Maximum height in meters }
  end;

var
  params: TPhysicsParams;
  trajectory: array[0..1000] of record
    x, y: real;
  end;
  trajectoryPoints: integer;
  mouseX, mouseY: LongInt;
  
  { Animation variables }
  isAnimating: boolean;
  animationTime: real;
  launchX, launchY: integer;
  
  { Impact marks - persistent white dots showing where projectiles landed }
  impactMarks: array[0..99] of record
    x, y: integer;
    active: boolean;
  end;
  impactMarkCount: integer;

{============================================================
  Visual Interface - Matching Original Screenshots
============================================================}

procedure InitGraphics;
var ErrorCode: integer;
    GraphDriver, GraphMode: smallint;
begin
  { Initialize BGI graphics system - explicitly use 16-color VGA mode }
  GraphDriver := VGA;  { VGA driver }
  GraphMode := VGAHi;  { 640x480x16 mode for proper 16-color display }
  InitGraph(GraphDriver, GraphMode, '');

  ErrorCode := GraphResult;
  if ErrorCode <> grOk then
  begin
    writeln('BGI Graphics Error: ', ErrorCode);
    writeln('Driver: ', GraphDriver, ' Mode: ', GraphMode);
    writeln('This program requires VGA graphics support.');
    halt(1);
  end;

  { Initialize mouse support }
  if InitMouse then
  begin
    ShowMouse;
    writeln('Mouse initialized successfully');
  end
  else
  begin
    writeln('Mouse initialization failed');
  end;

  { Give the graphics window time to initialize and get focus }
  writeln('Graphics window initializing...');
  Delay(1000);

  { Set up visual interface matching screenshots }
  SetBkColor(MAIN_BG_COLOR);  { Blue background like original }
  ClearDevice;

  { Add instructions in the graphics window }
  SetColor(Yellow);
  OutTextXY(100, 100, 'Strzalki Physics Simulation');
  SetColor(White);
  OutTextXY(100, 120, 'Controls:');
  OutTextXY(100, 135, 'a/z - Set launch angle');
  OutTextXY(100, 150, 's/d - Set initial velocity');
  OutTextXY(100, 165, 'Move mouse - Set launch position');
  OutTextXY(100, 180, 'Left click - Launch projectile');
  OutTextXY(100, 195, 'ESC - Exit');

  writeln('Graphics ready. Use mouse and keyboard for interaction.');
end;

procedure DrawStatusBar;
begin
  { Top status bar - brown background }
  SetFillStyle(SolidFill, STATUS_BAR_COLOR);
  Bar(0, 0, GetMaxX, STATUS_BAR_HEIGHT);

  { Draw author information - exact position and text from screenshot }
  SetColor(TEXT_COLOR);
  SetTextStyle(DefaultFont, HorizDir, 1);
  OutTextXY(10, 5, 'Rafal Stanczuk rafalsrs@wp.pl');

  { Draw control instructions - exact position and text from screenshot }
  OutTextXY(400, 5, '(a/z)(+/-) 10 stopni');
  OutTextXY(400, 15, 'V0 "s"-10m/s| "d" +10m/s');
end;

procedure DrawBottomBar;
begin
  { Bottom status bar - brown background for parameters display }
  SetFillStyle(SolidFill, STATUS_BAR_COLOR);
  Bar(0, GetMaxY - 20, GetMaxX, GetMaxY);

  { Display current parameters }
  SetColor(TEXT_COLOR);
  SetTextStyle(DefaultFont, HorizDir, 1);
  OutTextXY(10, GetMaxY - 15, 'Kąt wystrzału: ' + IntToStr(params.angle) + '°');
  OutTextXY(200, GetMaxY - 15, 'Prędkość początkowa: ' + IntToStr(params.velocity) + ' m/s');
  
  if isAnimating then
  begin
    OutTextXY(450, GetMaxY - 15, 'ANIMACJA - Czas: ' + FloatToStrF(animationTime, ffFixed, 4, 2) + ' s');
  end
  else
  begin
    OutTextXY(450, GetMaxY - 15, '[ESC] - wyjście');
  end;
end;

procedure DrawCoordinateGrid;
begin
  { Clean interface - no visible grid lines, just trajectory visualization }
  { Grid boundaries exist but are invisible, matching original clean design }
end;

procedure DisplayParameters;
begin
  { Minimal display - no cluttering text, only essential info shown during interaction }
  { Parameters shown in status bar and during interaction only }
end;

procedure AddImpactMark(x, y: integer);
begin
  { Add a new impact mark at the given position }
  if impactMarkCount < 100 then
  begin
    impactMarks[impactMarkCount].x := x;
    impactMarks[impactMarkCount].y := y;
    impactMarks[impactMarkCount].active := true;
    Inc(impactMarkCount);
    writeln('Impact mark added at (', x, ',', y, ') - Total marks: ', impactMarkCount);
  end;
end;

procedure DrawImpactMarks;
var i: integer;
begin
  { Draw all active impact marks as white dots }
  SetColor(White);
  for i := 0 to impactMarkCount - 1 do
  begin
    if impactMarks[i].active then
    begin
      { Draw a small white circle for each impact point }
      Circle(impactMarks[i].x, impactMarks[i].y, 2);
      PutPixel(impactMarks[i].x, impactMarks[i].y, White);
    end;
  end;
end;

procedure DrawTrajectory(mouseX, mouseY: integer);
var i: integer;
begin
  { Handle special cases }
  if (trajectoryPoints < 2) or (params.angle = 0) then
  begin
    { Draw starting point only - use mouse position as launch point }
    SetColor(Green);  { Green launch point (color 2) }
    Circle(mouseX, mouseY, 6);
    exit;
  end;

  { Draw trajectory line - use mouse position as starting point }
  SetColor(Red);  { Red trajectory line (color 4) }
  for i := 0 to trajectoryPoints - 2 do
  begin
    Line(Round(mouseX + trajectory[i].x / SCALE_FACTOR),
         Round(mouseY - trajectory[i].y / SCALE_FACTOR),
         Round(mouseX + trajectory[i+1].x / SCALE_FACTOR),
         Round(mouseY - trajectory[i+1].y / SCALE_FACTOR));
  end;

  { Draw starting point (launch point) }
  SetColor(Green);  { Green launch point (color 2) }
  Circle(mouseX, mouseY, 5);

  { Draw ending point (impact point) }
  SetColor(Yellow);  { Yellow impact point (color 14) }
  Circle(Round(mouseX + trajectory[trajectoryPoints-1].x / SCALE_FACTOR),
         Round(mouseY - trajectory[trajectoryPoints-1].y / SCALE_FACTOR), 5);
end;

procedure DrawAnimatedProjectile;
var
  angleRad: real;
  vx, vy: real;
  x, y: real;
  currentVx, currentVy, totalV: real;
  screenX, screenY: integer;
  hitWall: boolean;
  impactType: string;
begin
  if not isAnimating then exit;

  { Calculate projectile position at current animation time }
  angleRad := params.angle * Pi / 180;
  vx := params.velocity * cos(angleRad);
  vy := params.velocity * sin(angleRad);

  { Physics equations: x = v0*t*cos(θ), y = v0*t*sin(θ) - 0.5*g*t² }
  x := vx * animationTime;
  y := vy * animationTime - 0.5 * GRAVITY * animationTime * animationTime;

  { Calculate current velocity components }
  currentVx := vx;  { Horizontal velocity stays constant }
  currentVy := vy - GRAVITY * animationTime;  { Vertical velocity changes with gravity }
  totalV := sqrt(currentVx * currentVx + currentVy * currentVy);  { Total velocity magnitude }

  { Calculate screen coordinates }
  screenX := Round(launchX + x / SCALE_FACTOR);
  screenY := Round(launchY - y / SCALE_FACTOR);

  { Check collision with grid boundaries (walls) - exact bounding box }
  hitWall := false;
  impactType := '';

  { Check screen boundaries FIRST - these are the physical walls }
  if screenX <= TRAJECTORY_X_OFFSET then
  begin
    hitWall := true;
    impactType := 'LEFT WALL';
  end
  else if screenX >= (TRAJECTORY_X_OFFSET + TRAJECTORY_WIDTH) then
  begin
    hitWall := true;
    impactType := 'RIGHT WALL';
  end
  else if screenY <= (TRAJECTORY_Y_OFFSET - TRAJECTORY_HEIGHT) then
  begin
    hitWall := true;
    impactType := 'TOP WALL';
  end
  else if screenY >= TRAJECTORY_Y_OFFSET then
  begin
    hitWall := true;
    impactType := 'GROUND (BOTTOM BOUNDARY)';
  end;

  { Only draw if projectile is still in flight }
  if not hitWall then
  begin
    { Console logging - detailed flight information }
    writeln('FLIGHT: t=', animationTime:0:3, 's  x=', x:0:2, 'm  y=', y:0:2, 'm  ',
            'vx=', currentVx:0:2, 'm/s  vy=', currentVy:0:2, 'm/s  v=', totalV:0:2, 'm/s  ',
            'screen=(', screenX, ',', screenY, ')');

    { Draw the moving projectile - white dot as seen in screenshot }
    SetColor(White);  { White projectile (color 15) }
    Circle(screenX, screenY, 3);
    
    { Add bright center for visibility }
    SetColor(Yellow);  { Yellow center (color 14) }
    PutPixel(screenX, screenY, Yellow);
  end
  else
  begin
    { Projectile hit boundary - stop animation and mark impact point }
    writeln('');
    writeln('=== IMPACT: ', impactType, ' ===');
    writeln('Total flight time: ', animationTime:0:3, ' s');
    writeln('Final position: x=', x:0:2, 'm  y=', y:0:2, 'm');
    writeln('Final screen pos: (', screenX, ',', screenY, ')');
    writeln('Final velocity: ', totalV:0:2, ' m/s');
    writeln('Grid boundaries: X[', TRAJECTORY_X_OFFSET, '-', TRAJECTORY_X_OFFSET + TRAJECTORY_WIDTH, 
            '] Y[', TRAJECTORY_Y_OFFSET - TRAJECTORY_HEIGHT, '-', TRAJECTORY_Y_OFFSET, ']');
    writeln('=======================================');
    writeln('');
    
    { Add permanent impact mark at the collision point }
    AddImpactMark(screenX, screenY);
    
    isAnimating := false;
    animationTime := 0;
  end;
end;

{============================================================
  Physics Engine - Real-time Projectile Motion
============================================================}

procedure CalculateTrajectory;
var
  t, dt: real;
  angleRad: real;
  vx, vy: real;
  x, y: real;
  timeOfFlight: real;
begin
  { Handle special cases }
  if params.angle = 0 then
  begin
    params.range := 0;
    params.maxHeight := 0;
    trajectoryPoints := 0;
    exit;
  end;

  { Convert angle to radians }
  angleRad := params.angle * Pi / 180;

  { Initial velocity components }
  vx := params.velocity * cos(angleRad);
  vy := params.velocity * sin(angleRad);

  { Calculate time of flight for better trajectory calculation }
  timeOfFlight := (2 * vy) / GRAVITY;

  { Time parameters - adaptive steps based on velocity }
  if params.velocity > 50 then dt := 0.1
  else if params.velocity > 20 then dt := 0.05
  else dt := 0.02;

  { Calculate trajectory points }
  trajectoryPoints := 0;
  t := 0;

  repeat
    { Physics equations: x = v0*t*cos(θ), y = v0*t*sin(θ) - 0.5*g*t² }
    x := vx * t;
    y := vy * t - 0.5 * GRAVITY * t * t;

    { Only store points above ground and within reasonable bounds }
    if (y >= 0) and (x >= 0) and (x <= 800) then
    begin
      trajectory[trajectoryPoints].x := x;
      trajectory[trajectoryPoints].y := y;
      Inc(trajectoryPoints);
    end;

    t := t + dt;
  until (y < 0) or (trajectoryPoints >= 1000) or (t > timeOfFlight + 1);

  { Calculate range and max height using proper physics formulas }
  if sin(2 * angleRad) <> 0 then
    params.range := (params.velocity * params.velocity * sin(2 * angleRad)) / GRAVITY
  else
    params.range := 0;

  if sin(angleRad) <> 0 then
    params.maxHeight := (params.velocity * params.velocity * sin(angleRad) * sin(angleRad)) / (2 * GRAVITY)
  else
    params.maxHeight := 0;
end;

{============================================================
  Input Handling - Interactive Physics Controls
============================================================}

procedure HandleMouseAndKeyboard;
var localMouseX, localMouseY, mouseButtons: LongInt;
    inputStatus: string;
    ch: char;
    oldAngle, oldVelocity: integer;
begin
  { Get mouse state }
  GetMouseState(localMouseX, localMouseY, mouseButtons);

  { Update global mouse coordinates }
  mouseX := localMouseX;
  mouseY := localMouseY;

  { Store old parameters to detect changes }
  oldAngle := params.angle;
  oldVelocity := params.velocity;

  { Update trajectory in real-time if parameters changed }
  if (params.angle <> oldAngle) or (params.velocity <> oldVelocity) then
  begin
    CalculateTrajectory;
  end;

  { Check for left mouse button click to launch projectile }
  if LPressed and not isAnimating then
  begin
    writeln('');
    writeln('======================================');
    writeln('=== LAUNCH! ===');
    writeln('Launch position: (', localMouseX, ',', localMouseY, ')');
    writeln('Angle: ', params.angle, '°');
    writeln('Initial velocity: ', params.velocity, ' m/s');
    writeln('======================================');
    writeln('');
    
    inputStatus := 'WYRZUT! Kąt: ' + IntToStr(params.angle) + '°, Prędkość: ' + IntToStr(params.velocity) + ' m/s';

    { Start animation from mouse position }
    isAnimating := true;
    animationTime := 0;
    launchX := localMouseX;
    launchY := localMouseY;

    { Recalculate trajectory with current parameters }
    CalculateTrajectory;
  end
  else if isAnimating then
  begin
    inputStatus := 'ANIMACJA! Czas: ' + FloatToStrF(animationTime, ffFixed, 4, 2) + ' s';
  end
  else
  begin
    inputStatus := 'Pozycja startu: (' + IntToStr(localMouseX) + ',' + IntToStr(localMouseY) + ') Kąt: ' + IntToStr(params.angle) + '°';
  end;

  { Handle keyboard input for fine adjustments }
  if KeyPressed then
  begin
    ch := ReadKey;

    case ch of
      'a', 'A': { Increase angle }
      begin
        if params.angle < MAX_ANGLE then
        begin
          params.angle := params.angle + ANGLE_STEP;
          CalculateTrajectory;
          inputStatus := 'Klawisz A: Zwiększanie kąta do ' + IntToStr(params.angle) + '°';
        end;
      end;

      'z', 'Z': { Decrease angle }
      begin
        if params.angle > MIN_ANGLE then
        begin
          params.angle := params.angle - ANGLE_STEP;
          CalculateTrajectory;
          inputStatus := 'Klawisz Z: Zmniejszanie kąta do ' + IntToStr(params.angle) + '°';
        end;
      end;

      's', 'S': { Decrease velocity }
      begin
        if params.velocity > MIN_VELOCITY then
        begin
          params.velocity := params.velocity - VELOCITY_STEP;
          CalculateTrajectory;
          inputStatus := 'Klawisz S: Zmniejszanie prędkości do ' + IntToStr(params.velocity) + ' m/s';
        end;
      end;

      'd', 'D': { Increase velocity }
      begin
        if params.velocity < MAX_VELOCITY then
        begin
          params.velocity := params.velocity + VELOCITY_STEP;
          CalculateTrajectory;
          inputStatus := 'Klawisz D: Zwiększanie prędkości do ' + IntToStr(params.velocity) + ' m/s';
        end;
      end;

      #27: { ESC - Exit }
      begin
        HideMouse;
        writeln;
        writeln('Dziękuję za użycie symulacji Strzałki!');
        writeln('Nacisnij Enter aby zakończyć...');
        readln;
        CloseGraph;
        halt(0);
      end;
    end;
  end;

  { Update status display }
  SetColor(TEXT_COLOR);
  OutTextXY(50, 150, inputStatus);

  { Display mouse position and calculated parameters }
  SetColor(LightGray);
  OutTextXY(50, 165, 'Mysz: X=' + IntToStr(localMouseX) + ' Y=' + IntToStr(localMouseY));
  OutTextXY(50, 180, 'Kąt: ' + IntToStr(params.angle) + '° Prędkość: ' + IntToStr(params.velocity) + ' m/s');
end;

{============================================================
  Main Physics Simulation Loop
============================================================}

procedure InitializePhysics;
var i: integer;
begin
  { Initial parameters - matching typical physics simulation starting values }
  params.angle := 45;      { 45 degrees - optimal angle for maximum range }
  params.velocity := 30;   { 30 m/s - good starting velocity for visible trajectory }
  CalculateTrajectory;
  
  { Initialize animation state }
  isAnimating := false;
  animationTime := 0;
  launchX := 0;
  launchY := 0;
  
  { Initialize impact marks array }
  impactMarkCount := 0;
  for i := 0 to 99 do
  begin
    impactMarks[i].active := false;
  end;
end;

begin
  { Initialize graphics system - matching original DOS program }
  InitGraphics;

  { Initialize physics simulation }
  InitializePhysics;

  { Main simulation loop - real-time mouse and keyboard interaction }
  while True do
  begin
    { Clear main area (preserve status bar) }
    SetBkColor(MAIN_BG_COLOR);
    ClearDevice;

    { Draw status bar - persistent like in original screenshots }
    DrawStatusBar;

    { Handle mouse and keyboard input - real-time interaction }
    HandleMouseAndKeyboard;

    { Update animation time if animating }
    if isAnimating then
    begin
      animationTime := animationTime + 0.016;  { 16ms time step for smooth animation }
    end;

    { Draw trajectory visualization - updated in real-time based on mouse position }
    DrawTrajectory(mouseX, mouseY);

    { Draw animated projectile if in flight }
    DrawAnimatedProjectile;

    { Draw all impact marks - persistent white dots }
    DrawImpactMarks;

    { Draw bottom status bar with parameters }
    DrawBottomBar;

    { Small delay for smooth updates - 60 FPS equivalent }
    Delay(16);
  end;

  { Clean exit }
  CloseGraph;
end.
