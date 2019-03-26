(* 
   The FortiFrames render the graphic area with all OliObjects.

   Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber 
*)
MODULE FortiFrames;

IMPORT OliObjects, Display, Viewers, Input, Fonts, Texts, Oberon, MenuViewers;

CONST
    (* First marker ID *)
	Marker0* = 0;
	(* Second marker ID *)
	Marker1* = 1;
	(* Size of the grid *)
	GridSize = 16;

	RightMouseButton = 0;
	MiddleMouseButton = 1;
	LeftMouseButton = 2;

TYPE
	FortiFrame* = POINTER TO FortiFrameDesc;
	FortiFrameDesc* = RECORD (Display.FrameDesc)
		graphic*: OliObjects.Graphic;
		Xg*, Yg*: INTEGER;	(* math. origin rel. to upper left corner of viewer *)
		X1*, Y1*: INTEGER;	(* X1 = X + W, Y1 = Y + H *)
		x*, y*: INTEGER	(* math. origin rel. to screen origin *)
	END;
	DrawMsg* = RECORD (OliObjects.Message) 
		f*: FortiFrame; 
		mode*: INTEGER
	END;
	RestoreObjMsg* = RECORD (Display.FrameMsg)
		obj*: OliObjects.Object;
		mode*: INTEGER;
		graphic*: OliObjects.Graphic
	END;
	RestoreSelMsg* = RECORD (Display.FrameMsg)
		mode*: INTEGER;
		graphic*: OliObjects.Graphic
	END;
	RestoreMarksMsg* = RECORD (Display.FrameMsg) END;
	RestoreMsg = RECORD (Display.FrameMsg) END;

	(* Messages fuer einzelne Objekte, die in irgendeinem Frame sitzen: *)

	(* PacMan Bewegungsmeldung: *)
	FPacMoveMsg* = RECORD (Display.FrameMsg)	(* diese Message geht an Frames... *)
		dx*: INTEGER;
		dy*: INTEGER;
		id*: INTEGER;	(* welcher PacMan soll sich bewegen? *)
	END;

	OPacMoveMsg* = RECORD (OliObjects.Message)	(* ...und diese Meldung geht an Objecte innerhalb Frame *)
		f*: FortiFrame;
		dx*: INTEGER;
		dy*: INTEGER;
		id*: INTEGER
	END;
	
	markDesc = RECORD	(* Markers, beziehen sich auf Grafik (nicht auf Frame) und bezeichen math. Koord *)
		x*, y*: INTEGER;	(* sind also auch in allen Viewers der Grafik sichtbar! *)
		set*: BOOLEAN
	END;

VAR 
	mark0*, mark1*: markDesc;	(* Markers global -> nur 1 Fokus fuer alle Grafiken *)
	markedG*: OliObjects.Graphic;	(* welche (der evt. versch. offenen) Grafiken traegt den Fokus (Markers) *)

PROCEDURE PinsideBox(x, y, bx1, by1, bx2, by2: INTEGER): BOOLEAN;
VAR
BEGIN
	RETURN (bx1 <= x) & (by1 <= y) & (x <= bx2) & (y <= by2)
END PinsideBox;
	
(* Flips the marker at x/y *)
PROCEDURE FlipMark(x, y: INTEGER); 
BEGIN
	Display.ReplConst(Display.white, x - 7, y,     15, 1,  Display.invert);
	Display.ReplConst(Display.white, x,     y - 7, 1,  15, Display.invert)
END FlipMark;

PROCEDURE InsertObject*(graphic: OliObjects.Graphic; object: OliObjects.Object);
VAR	
	rsMsg: RestoreSelMsg;
	roMsg: RestoreObjMsg; 
	rmMsg: RestoreMarksMsg;
BEGIN
	(* zuvor selektierte Objekte unselektieren *)
	rsMsg.mode := OliObjects.Normal; 
	rsMsg.graphic := markedG; 
	Viewers.Broadcast(rsMsg);
	OliObjects.DeselectAll(graphic); 
	(* neues Objekt (selektiert) in Model einfuegen und zeichnen *)
	OliObjects.AddObject(graphic, object);
	roMsg.obj := object;
	roMsg.mode := OliObjects.Draw;
	roMsg.graphic := markedG; 
	Viewers.Broadcast(roMsg);
	Viewers.Broadcast(rmMsg)	(* Markers sind u.U. neu: mark1 am Ende einer neuen Linie *)
END InsertObject;

PROCEDURE SetMarkX*(marker: INTEGER; x: INTEGER);
BEGIN
	IF marker = Marker0 THEN
		mark0.x := x
	ELSE
		mark1.x := x
	END
END SetMarkX;

PROCEDURE SetMarkY*(marker: INTEGER; y: INTEGER);
BEGIN
	IF marker = Marker0 THEN
		mark0.y := y
	ELSE
		mark1.y := y
	END
END SetMarkY;

PROCEDURE SetMarkEnabled*(marker: INTEGER; enable: BOOLEAN);
BEGIN
	IF marker = Marker0 THEN
		mark0.set := enable
	ELSE
		mark1.set := enable
	END
END SetMarkEnabled;

PROCEDURE Restore*(frame: FortiFrame);
VAR
	drawMsg: DrawMsg; 
	x, y: INTEGER;	(* ticks Koordinaten *)
	rmMsg: RestoreMarksMsg;
BEGIN

	frame.X1 := frame.X + frame.W; 
	frame.Y1 := frame.Y + frame.H;
	frame.x := frame.X + frame.Xg; 
	frame.y := frame.Y1 + frame.Yg;
	Oberon.RemoveMarks(frame.X, frame.Y, frame.W, frame.H);
	
	(* Black background *)
	Display.ReplConst(Display.black, frame.X, frame.Y, frame.W, frame.H, Display.replace);
	y := frame.Yg MOD 16 + frame.Y1 - 16;
	(* Draw the ticks *)
	WHILE (y >= frame.Y) DO	
		x := frame.Xg MOD 16 + frame.X;
		WHILE (x < frame.X1) DO
			Display.Dot(Display.white, x, y, Display.replace);
			INC(x, GridSize)
		END; 
		DEC(y, GridSize)
	END;

	(* Marker 0 *)
	IF mark0.set & (markedG = frame.graphic) & PinsideBox(mark0.x + frame.x, mark0.y +frame.y, frame.X, frame.Y, frame.X1, frame.Y1) THEN
		FlipMark(mark0.x + frame.x, mark0.y + frame.y) 
	END;
	(* Marker 1 *)	
	IF mark1.set & (markedG = frame.graphic) & PinsideBox(mark1.x + frame.x, mark1.y + frame.y, frame.X, frame.Y, frame.X1, frame.Y1) THEN
		FlipMark(mark1.x + frame.x, mark1.y + frame.y)
	END;

	(* Y-axis *)
	IF (0 <= frame.Xg) & (frame.Xg <= frame.X1 - frame.X) THEN 
		Display.ReplConst(Display.white, frame.X + frame.Xg, frame.Y, 1, frame.Y1 - frame.Y, 2)
	END; 
	(* X-axis *)
	IF (0 >= frame.Yg) & (frame.Yg >= frame.Y - frame.Y1) THEN 
		Display.ReplConst(Display.white, frame.X, frame.Y1 + frame.Yg, frame.X1 - frame.X , 1, 2) 
	END; 

	drawMsg.f := frame; 
	drawMsg.mode := OliObjects.Draw; 
	OliObjects.BroadcastAll(frame.graphic, drawMsg)

END Restore;

PROCEDURE Edit(frame: FortiFrame; x0, y0: INTEGER; k0: SET);
VAR 
	x1, y1: INTEGER;	(* x0, y0 bei klick  -   x1, y1 bei loslassen *)
	k1, k2: SET;	(* k0: Taste bei klick  -  k1: Tasten bei loslassen *)
	dx, dy: INTEGER;
	v0, v1: Viewers.Viewer;
	rmMsg: RestoreMarksMsg; 
	rsMsg: RestoreSelMsg; 
	roMsg: RestoreObjMsg; 
	rMsg: RestoreMsg;
	obj: OliObjects.Object;
BEGIN

	k1 := k0;
	REPEAT	(* warte bis Maus losgelasen, registriere solange zusaetzliche Klicks (Interklicks) *)
		Input.Mouse(k2, x1, y1); 
		k1 := k1 + k2;
		DEC(x1, (x1 - frame.x) MOD 4); 
		DEC(y1, (y1 - frame.y) MOD 4);
		Oberon.DrawMouseArrow(x1, y1)
	UNTIL k2 = {};
	Oberon.FadeMouse();
	
	IF k0 = {LeftMouseButton} THEN
		IF k1 = {LeftMouseButton} THEN	
			(* left only: setze 1. Marker *)
			Viewers.Broadcast(rmMsg);	(* allframe. alte Markers entfernen *)
			mark0.set := TRUE;
			mark1.set := FALSE; 
			markedG := frame.graphic;
			mark0.x := x1 - frame.x;
			mark0.y := y1 - frame.y;
			Viewers.Broadcast(rmMsg)	(* nun neue Markers zeichnen *)
		ELSIF k1 = {LeftMouseButton, MiddleMouseButton} THEN
			(* left, middle: setze 2. Marker, falls 1. gesetzt und innerhalb gl. Grafik (muss aber nicht in gl. Viewer sein *)
			IF mark0.set & (markedG = frame.graphic) THEN
				Viewers.Broadcast(rmMsg);	(* allframe. alten 2. Marker entfernen *)
				mark1.set := TRUE; 
				mark1.x := x1 - frame.x;
				mark1.y := y1 - frame.y;
				Viewers.Broadcast(rmMsg)	(* nun neuen 2. Marker zeichnen *)
			END
		END
	ELSIF k0 = {MiddleMouseButton} THEN
		IF k1 = {MiddleMouseButton} THEN
			(* middle only: verschiebt sel. Objekte *)
			rsMsg.mode := OliObjects.Erase; 
			rsMsg.graphic := frame.graphic; 
			Viewers.Broadcast(rsMsg);
			OliObjects.Move(frame.graphic, x1 - x0, y1 - y0);
			rsMsg.mode := OliObjects.Draw;
			rsMsg.graphic := frame.graphic; 
			Viewers.Broadcast(rsMsg)	
		ELSIF k1 = {MiddleMouseButton, LeftMouseButton} THEN
			(* middle, left: kopiert sel. Objekte (auch in andere Viewers / Grafiken !) *)
			v0 := Viewers.This(x0, y0); 
			v1 := Viewers.This(x1, y1);
			IF v0 = v1 THEN	(* kopiere in gleichen Viewer *)
				rsMsg.mode := OliObjects.Normal; 
				rsMsg.graphic := frame.graphic; 
				Viewers.Broadcast(rsMsg);
				OliObjects.Copy(frame.graphic, frame.graphic, x1 - x0, y1 - y0)
			ELSIF v1.dsc.next IS FortiFrame THEN
				(* kopiere in anderen Viewer *)
				dx := (x1 - v1.dsc.next(FortiFrame).x) - (x0-v0.dsc.next(FortiFrame).x);
				dy := (y1 - v1.dsc.next(FortiFrame).y) - (y0-v0.dsc.next(FortiFrame).y);
				rsMsg.mode := OliObjects.Normal; rsMsg.graphic := frame.graphic; Viewers.Broadcast(rsMsg);
				OliObjects.Copy(v0.dsc.next(FortiFrame).graphic, v1.dsc.next(FortiFrame).graphic, dx, dy)
			END;
			rsMsg.mode := OliObjects.Draw;
			IF v0 = v1 THEN  
				rsMsg.graphic := frame.graphic 
			ELSE 
				rsMsg.graphic := v1.dsc.next(FortiFrame).graphic 
			END;
			Viewers.Broadcast(rsMsg)
		ELSIF k1 = {RightMouseButton, MiddleMouseButton} THEN
			(* middle, right: Bewege sichtbaren Ausschnitt *)
			INC(frame.Xg, x1 - x0); 
			INC(frame.Yg, y1 - y0); 
			Restore(frame)
		END
	ELSIF k0 = {RightMouseButton} THEN
		IF k1 = {RightMouseButton} THEN
			(* right only: Selektiere Objekte in Bereich - resp. MarkSingle /DeselectAll, wenn bloss Punkt angeklickt *)
			IF (x0 # x1) OR (y0 # y1) THEN
				rsMsg.mode := OliObjects.Normal; 
				rsMsg.graphic := frame.graphic; 
				Viewers.Broadcast(rsMsg); 
				OliObjects.SelectArea(frame.graphic, x0 - frame.x, y0 - frame.y, x1 - frame.x, y1 - frame.y);
				rsMsg.mode := OliObjects.Select; 
				rsMsg.graphic := frame.graphic; 
				Viewers.Broadcast(rsMsg)
			ELSE
				obj := OliObjects.ThisObject(frame.graphic, x0 - frame.x, y0 - frame.y);
				IF obj # NIL THEN 
					OliObjects.SelectObject(obj);
					roMsg.obj := obj; 
					roMsg.mode := OliObjects.Select; 
					roMsg.graphic := frame.graphic;
					Viewers.Broadcast(roMsg)
				ELSE 
					rsMsg.mode := OliObjects.Normal; 
					rsMsg.graphic := frame.graphic; 
					Viewers.Broadcast(rsMsg); 
					OliObjects.DeselectAll(frame.graphic) 
				END
			END
		END
	END
END Edit;

PROCEDURE Handle(frame: Display.Frame; VAR msg: Display.FrameMsg);
VAR
	x, y: INTEGER;
	clone: FortiFrame;
	drawMsg: DrawMsg;
	opmMsg: OPacMoveMsg;
	restoreObjMsg: RestoreObjMsg;
BEGIN
	
	CASE frame OF FortiFrame:

		CASE msg OF Oberon.InputMsg:
			IF msg.id = Oberon.track THEN
				x := msg.X - (msg.X - frame.x) MOD 4; y := msg.Y - (msg.Y - frame.y) MOD 4;	(* Mouse moves "MOD 4" *)
				IF msg.keys # {} THEN Edit(frame, x, y, msg.keys)
				ELSE Oberon.DrawMouseArrow(x, y)
				END
			END
		| Oberon.ControlMsg:
			IF msg.id = Oberon.neutralize THEN
				Oberon.RemoveMarks(frame.X, frame.Y, frame.W, frame.H);
				OliObjects.DeselectAll(frame.graphic);
				markedG := NIL;
				mark0.set := FALSE;
				mark1.set := FALSE; 
				Restore(frame);
			END
		| Oberon.CopyMsg:
			Oberon.RemoveMarks(frame.X, frame.Y, frame.W, frame.H);
			NEW(clone);
			clone^ := frame^;
			msg.F := clone
		| MenuViewers.ModifyMsg:
			frame.Y := msg.Y; frame.H := msg.H;
			Restore(frame)
		| RestoreObjMsg:
			IF frame.graphic = msg.graphic THEN
				drawMsg.f := frame;
				drawMsg.mode := msg.mode;
				msg.obj.do.handle(msg.obj, drawMsg);
			END
		| RestoreSelMsg:
			IF frame.graphic = msg.graphic THEN
				drawMsg.f := frame;
				drawMsg.mode := msg.mode; 
				OliObjects.BroadcastSelected(frame.graphic, drawMsg)
			END
		| RestoreMarksMsg:
			IF mark0.set & (markedG = frame.graphic) & PinsideBox(mark0.x + frame.x, mark0.y + frame.y, frame.X, frame.Y, frame.X1, frame.Y1) THEN
				FlipMark(mark0.x + frame.x, mark0.y + frame.y)
			END;
			IF mark1.set & (markedG = frame.graphic) & PinsideBox(mark1.x + frame.x, mark1.y + frame.y, frame.X, frame.Y, frame.X1, frame.Y1) THEN
				FlipMark(mark1.x + frame.x, mark1.y + frame.y)
			END;
		| RestoreMsg:
			Restore(frame)
		| FPacMoveMsg:	
			(* kopiere Daten um und informiere Objecte in F *)
			opmMsg.f:= frame;
			opmMsg.dx := msg(FPacMoveMsg).dx;
			opmMsg.dy := msg(FPacMoveMsg).dy;
			opmMsg.id := msg(FPacMoveMsg).id;
			OliObjects.BroadcastAll(frame.graphic, opmMsg)
		END
	END

END Handle;

PROCEDURE NewFrame*(frame: FortiFrame);
BEGIN
	frame.handle := Handle;
	frame.graphic := OliObjects.NewGraphic()
END NewFrame;

BEGIN
	mark0.set := FALSE; 
	mark1.set := FALSE; 
	markedG := NIL
END FortiFrames.
