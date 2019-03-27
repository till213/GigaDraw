(* 
   A Pacman which is controllable via the arrow keys.

   Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber 
*)
MODULE PacMan;

IMPORT Display, Viewers, Files, Oberon, SYSTEM, OliObjects, FortiFrames;

CONST
	(* Tolerance in pixels for selection *)
	Tolerance = 2;
	NofAnimationFrames = 8;
	PacManWidth* = 16;
	PacManHeight* = 16;

TYPE
	(* Bitmap animation data *)
	PacManData* = RECORD
		anim*: ARRAY NofAnimationFrames OF INTEGER;
		w*, h*: BYTE	(* Breite, Hoehe *)
	END; 

	PacMan* = POINTER TO PacManDesc;
	PacManDesc* = RECORD(OliObjects.ObjectDesc)
		id*: BYTE;
		currentAnimationFrame*: BYTE	(* momentanes Animationsframe *)
	END;

VAR
	pacManMethod: OliObjects.Method;
	(* PacMan ID *)
	id: INTEGER;
	pacManData: PacManData;
	i, j: INTEGER;

PROCEDURE CopyPacMan(from, to: OliObjects.Object);
(* kopiert einen PacMan: from ist der OriginalPacMan MyPacMan, to ist ein vorgaengig mit MyPacMan.do.new() erschaffener PacMan *)
VAR
	
BEGIN
	to(PacMan)^:= from(PacMan)^
END CopyPacMan;

PROCEDURE SelectablePacMan(pacMan: OliObjects.Object; x, y: INTEGER): BOOLEAN;
(* entscheidet, ob ein Mausklick mit Toleranceeranz Tolerance den PacMan selektiert *)
VAR
BEGIN
	RETURN (x >= pacMan.x - Tolerance) & (x <= pacMan.x + pacMan.w + Tolerance) & (y >= pacMan.y - Tolerance) & (y <= pacMan.y + pacMan.h + Tolerance) 
END SelectablePacMan;

(* interpretiert die Messages, welche von FortiFrames  aus kommen *)
(* im Moment wird nur die DrawMsg und OPacMoveMsg interpretiert *)
PROCEDURE HandlePacMan(pacMan: OliObjects.Object; VAR msg: OliObjects.Message);
VAR
	u, v, w, h: INTEGER;	(* Screen-Koordinaten *)
BEGIN

	CASE msg OF FortiFrames.DrawMsg:

		CASE pacMan OF PacMan:
			u := pacMan.x + msg.f.x;	(* Screenkoordinaten berechnen *)
			v := pacMan.y + msg.f.y;
			w := pacMan.w;
			h := pacMan.h;
			
			IF msg.mode = OliObjects.Draw THEN
				IF pacMan.selected THEN
					Display.CopyPattern(pacMan.col, pacManData.anim[pacMan.currentAnimationFrame], u, v, Display.paint);
					Display.ReplConst(Display.white, u, v, w, h, Display.invert)
				ELSE
					Display.CopyPattern(pacMan.col, pacManData.anim[pacMan.currentAnimationFrame], u, v, Display.paint);
				END;
			ELSIF msg.mode = OliObjects.Select THEN 
				Display.ReplConst(Display.white, u, v, w, h, Display.invert)
			ELSIF msg.mode = OliObjects.Normal THEN 
				Display.ReplConst(Display.white, u, v, w, h, Display.invert)
			ELSIF msg.mode = OliObjects.Erase THEN 
				Display.ReplConst(Display.black, u, v, w, h, Display.paint)
			END
		END

	| FortiFrames.OPacMoveMsg:

		CASE pacMan OF PacMan:
			IF pacMan.id = msg.id THEN	(* dieser PacMan ist gemeint: bewege ihn *)
				u := pacMan.x + msg.f.x;	(* Screenkoordinaten berechnen *)
				v := pacMan.y + msg.f.y;
				w := pacMan.w;
				h := pacMan.h;

				(* loesche alte Position: *)
				Display.CopyPattern(Display.black, pacManData.anim[pacMan.currentAnimationFrame], u, v, Display.invert);
				INC(pacMan.x, (msg.dx));	(* Koordinaten updaten *)
				INC(pacMan.y, (msg.dy));
				INC(u, (msg.dx));
				INC(v, (msg.dy));
				pacMan.currentAnimationFrame := (pacMan.currentAnimationFrame + 1) MOD 2;	(* Animationsframe um 1 weiterschalten *)
				
				(* neue Position malen: *)
				Display.CopyPattern(pacMan.col, pacManData.anim[pacMan.currentAnimationFrame], u, v, Display.paint)
			END	(* dieser PacMan *)
		END

	END	(* Ignoriere andere Messages *)

END HandlePacMan;
					
(* Creates a new PacMan instance *)
PROCEDURE NewPacMan*(): OliObjects.Object;
VAR
	pacMan: PacMan;
BEGIN

	NEW(pacMan);
	pacMan.id := id;
	INC(id);	(* naechste zu vergebene ID aktualisieren *)
	pacMan.currentAnimationFrame := 0;
	pacMan.do := pacManMethod;
	pacMan.col := OliObjects.color;
	pacMan.selected := FALSE;	(* PacMan soll nicht selektiert werden *)

	RETURN pacMan

END NewPacMan;

(* --- User Prozeduren ----------------------------------------------- *)

PROCEDURE MakePacMan*();
VAR
	pacMan: OliObjects.Object;
	restoreMarksMsg: FortiFrames.RestoreMarksMsg;
	i: INTEGER;
BEGIN

	IF FortiFrames.mark0.set THEN
		
		pacMan := NewPacMan();
		
		pacMan.x := FortiFrames.mark0.x;
		pacMan.y := FortiFrames.mark0.y;
		pacMan.w := PacManWidth;
		pacMan.h := PacManHeight;
		
		Viewers.Broadcast(restoreMarksMsg);	(* alte Markierungen werden geloescht *)
		FortiFrames.SetMarkEnabled(FortiFrames.Marker0, FALSE);
			
		(* die folgene Prozedur kuemmert sich um das Einfuegen und Benachrichtigen aller Frames *)
		(* ausserdem werden dort alle anderen Objekte vorher deselektiert *)
		FortiFrames.InsertObject(FortiFrames.markedG, pacMan)

	END

END MakePacMan;

BEGIN
	(* der Methodenrekord wird einmal initialisiert und ist somit fix *)
	NEW(pacManMethod);
	pacManMethod.new:= NewPacMan;
	pacManMethod.copy:= CopyPacMan;
	pacManMethod.selectable:= SelectablePacMan;
	pacManMethod.handle:= HandlePacMan;
	id := 0;

	(* bitmap data *)
	pacManData.anim[0] := SYSTEM.ADR($0F0F 0A0FE01F F03FF87F FCE7FEE7 FEFFFEFF FEFFFEFF FEFFFE7F FC3FF81F F00FE000 00$);
	pacManData.anim[1] := SYSTEM.ADR($0F0F 0A0FE01F F039F879 FC3FFE1F FE0FFE07 FE0FFE1F FE3FFE7F FC3FF81F F00FE000 00$);
	
	pacManData.w := PacManWidth;
	pacManData.h := PacManHeight;
	
END PacMan.
