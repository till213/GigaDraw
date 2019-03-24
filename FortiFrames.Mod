MODULE FortiFrames;
IMPORT OliObjects, Display, Viewers, Input, Fonts, Texts, Oberon, MenuViewers;
TYPE
	Frame* = POINTER TO FrameDesc;
	FrameDesc* = RECORD (Display.FrameDesc)
		graphic*: OliObjects.Graphic;
		Xg*, Yg*: INTEGER;	(* math. origin rel. to upper left corner of viewer *)
		X1*, Y1*: INTEGER;	(* X1 = X + W, Y1 = Y + H *)
		x*, y*: INTEGER	(* math. origin rel. to screen origin *)
	END;
	DrawMsg* = RECORD (OliObjects.Message) 
		f*: Frame; 
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
		f*: Frame;
		dx*: INTEGER;
		dy*: INTEGER;
		id*: INTEGER
	END;
	
	markDesc = RECORD	(* Markers, beziehen sich auf Grafik (nicht auf Frame) und bezeichen math. Koord *)
		x*,y*: INTEGER;	(* sind also auch in allen Viewers der Grafik sichtbar! *)
		set*: BOOLEAN
	END;

VAR 
	mark0*, mark1*: markDesc;	(* Markers global -> nur 1 Fokus fuer alle Grafiken *)
	markedG*: OliObjects.Graphic;	(* welche (der evt. versch. offenen) Grafiken traegt den Fokus (Markers) *)

PROCEDURE PinsideBox(x, y, bx, by, bX, bY: INTEGER): BOOLEAN;
VAR
	inside: BOOLEAN;
BEGIN
	IF (bx <= x) & (by <= y) & (x <= bX) & (y <= bY) THEN 
		inside := TRUE
	ELSE
		inside := FALSE
	END
	RETURN inside
END PinsideBox;
	
PROCEDURE FlipMark(x, y: INTEGER); (* zeichnet / loescht Fokus-Kreuz *)
BEGIN
	Display.ReplConst(Display.white, x-7, y, 15, 1, 2); Display.ReplConst(Display.white, x, y-7, 1, 15, 2)
END FlipMark;

PROCEDURE InsertObject*(g: OliObjects.Graphic; o: OliObjects.Object);
VAR	
	(* Dummy: INTEGER; *)	(* Dummy: Workaround um Compiler Bug *)
	rsMsg: RestoreSelMsg; roMsg: RestoreObjMsg; rmMsg: RestoreMarksMsg;
BEGIN
	(* zuvor selektierte Objekte unselektieren *)
	rsMsg.mode := OliObjects.normal; rsMsg.graphic := markedG; Viewers.Broadcast(rsMsg);
	OliObjects.DeselectAll(g); 
	(* neues Objekt (selektiert) in Model einfuegen und zeichnen *)
	OliObjects.AddObject(g, o);
	roMsg.obj := o; roMsg.mode := OliObjects.draw; roMsg.graphic := markedG; Viewers.Broadcast(roMsg);
	Viewers.Broadcast(rmMsg)	(* Markers sind u.U. neu: mark1 am Ende einer neuen Linie *)
END InsertObject;

PROCEDURE SetMarkX*(id: INTEGER; x: INTEGER);
BEGIN
	IF id = 0 THEN
		mark0.x := x
	ELSE
		mark1.x := x
	END
END SetMarkX;

PROCEDURE SetMarkY*(id: INTEGER; y: INTEGER);
BEGIN
	IF id = 0 THEN
		mark0.y := y
	ELSE
		mark1.y := y
	END
END SetMarkY;


PROCEDURE SetMarkEnabled*(id: INTEGER; enable: BOOLEAN);
BEGIN
	IF id = 0 THEN
		mark0.set := enable
	ELSE
		mark1.set := enable
	END
END SetMarkEnabled;

PROCEDURE Restore*(F: Frame);
VAR
	dMsg: DrawMsg; 
	x, y: INTEGER;	(* ticks Koordinaten *)
	rmMsg: RestoreMarksMsg;
BEGIN
	F.X1 := F.X + F.W; F.Y1 := F.Y + F.H;
	F.x := F.X+F.Xg; F.y := F.Y1+F.Yg;
	Oberon.RemoveMarks(F.X, F.Y, F.W, F.H);
	
Display.ReplConst(Display.black, F.X, F.Y, F.W, F.H, 0); (* Frame 'einschwaerzen' *)
	y:= F.Yg MOD 16 + F.Y1 - 16;
	WHILE (y >= F.Y) DO	(* male ticks *)
		x:= F.Xg MOD 16 + F.X;
		WHILE (x < F.X1) DO
			Display.Dot(Display.white, x, y, 0); INC(x, 16)
		END; DEC(y, 16)
	END;
	IF mark0.set & (markedG = F.graphic) & PinsideBox(mark0.x+F.x, mark0.y+F.y, F.X, F.Y, F.X1, F.Y1) THEN
		FlipMark(mark0.x+F.x, mark0.y+F.y) END;	(* Marker 0 *)
	IF mark1.set & (markedG = F.graphic) & PinsideBox(mark1.x+F.x, mark1.y+F.y, F.X, F.Y, F.X1, F.Y1) THEN
		FlipMark(mark1.x+F.x, mark1.y+F.y) END;	(* Marker 1 *)
	IF (0 <= F.Xg) & (F.Xg <= F.X1-F.X) THEN Display.ReplConst(Display.white, F.X+F.Xg, F.Y, 1, F.Y1-F.Y, 2) END; (* Y-axis *)
	IF (0 >= F.Yg) & (F.Yg >= F.Y-F.Y1) THEN Display.ReplConst(Display.white, F.X, F.Y1+F.Yg, F.X1-F.X , 1, 2) END; (* X-axis *)
	dMsg.f := F; dMsg.mode := OliObjects.draw; OliObjects.BroadcastAll(F.graphic, dMsg)
END Restore;

PROCEDURE Edit(F: Frame; x0, y0: INTEGER; k0: SET);
VAR 
	x1, y1: INTEGER;	(* x0, y0 bei klick  -   x1, y1 bei loslassen *)
	k1, k2: SET;	(* k0: Taste bei klick  -  k1: Tasten bis loslassen *)
	dx, dy: INTEGER;
	v0, v1: Viewers.Viewer;
	rmMsg: RestoreMarksMsg; rsMsg: RestoreSelMsg; roMsg: RestoreObjMsg; rMsg: RestoreMsg;
	obj: OliObjects.Object;
BEGIN
	k1 := k0;
	REPEAT	(* warte bis Maus losgelasen, registriere solange zusaetzliche Klicks (Interklicks) *)
		Input.Mouse(k2, x1, y1); k1 := k1+k2;
		DEC(x1, (x1-F.x) MOD 4); DEC(y1, (y1-F.y) MOD 4);
		(*Oberon.DrawCursor(Oberon.Mouse, Oberon.Arrow, x1, y1) *)
		Oberon.DrawMouseArrow(x1, y1)
	UNTIL k2 = {};
	(* Oberon.FadeMouse(Oberon.Mouse); *)
	Oberon.FadeMouse();
	
	IF k0 = {2} THEN
		IF k1 = {2} THEN	
			(* left only: setze 1. Marker *)
			Viewers.Broadcast(rmMsg);	(* allf. alte Markers entfernen *)
			mark0.set := TRUE; mark1.set := FALSE; markedG := F.graphic;
			mark0.x := x1-F.x; mark0.y := y1-F.y;
			Viewers.Broadcast(rmMsg)	(* nun neue Markers zeichnen *)
		ELSIF k1 = {1, 2} THEN
			(* left, middle: setze 2. Marker, falls 1. gesetzt und innerhalb gl. Grafik (muss aber nicht in gl. Viewer sein *)
			IF mark0.set  & (markedG = F.graphic) THEN
				Viewers.Broadcast(rmMsg);	(* allf. alten  2. Marker entfernen *)
				mark1.set := TRUE; mark1.x := x1-F.x; mark1.y := y1-F.y;
				Viewers.Broadcast(rmMsg)	(* nun neuen 2. Marker zeichnen *)
			END
		END
	ELSIF k0 = {1} THEN
		IF k1 = {1} THEN
			(* middle only: verschiebt sel. Objekte *)
			rsMsg.mode := OliObjects.erase; rsMsg.graphic := F.graphic; Viewers.Broadcast(rsMsg);
			OliObjects.Move(F.graphic, x1-x0, y1-y0);
			rsMsg.mode := OliObjects.draw;  rsMsg.graphic := F.graphic; Viewers.Broadcast(rsMsg)	
		ELSIF k1 = {1, 2} THEN
			(* middle, left: kopiert sel. Objekte (auch in andere Viewers / Grafiken !) *)
			v0 := Viewers.This(x0, y0); v1 := Viewers.This(x1, y1);
			IF v0 = v1 THEN	(* kopiere in gleichen Viewer *)
				rsMsg.mode := OliObjects.normal; rsMsg.graphic := F.graphic; Viewers.Broadcast(rsMsg);
				OliObjects.Copy(F.graphic, F.graphic, x1-x0, y1-y0)
			ELSE	(* kopiere in anderen Viewer *)
				IF v1.dsc.next IS Frame THEN
					dx := (x1-v1.dsc.next(Frame).x)-(x0-v0.dsc.next(Frame).x);
					dy := (y1-v1.dsc.next(Frame).y)-(y0-v0.dsc.next(Frame).y);
					rsMsg.mode := OliObjects.normal; rsMsg.graphic := F.graphic; Viewers.Broadcast(rsMsg);
					OliObjects.Copy(v0.dsc.next(Frame).graphic, v1.dsc.next(Frame).graphic, dx, dy)
				END 
			END;
			rsMsg.mode := OliObjects.draw;
			IF v0 = v1 THEN  rsMsg.graphic := F.graphic ELSE rsMsg.graphic := v1.dsc.next(Frame).graphic END;
			Viewers.Broadcast(rsMsg)
		ELSIF k1 = {0, 1} THEN
			(* middle, right: Bewege sichtbaren Ausschnitt *)
			INC(F.Xg, x1-x0); INC(F.Yg, y1-y0); Restore(F)
		END
	ELSIF k0 = {0} THEN
		IF k1 = {0} THEN
			(* right only: Selektiere Objekte in Bereich - resp. MarkSingle /DeselectAll, wenn bloss Punkt angeklickt *)
			IF (x0 # x1) OR (y0 # y1) THEN
				rsMsg.mode := OliObjects.normal; rsMsg.graphic := F.graphic; Viewers.Broadcast(rsMsg); 
				OliObjects.SelectArea(F.graphic, x0-F.x, y0-F.y, x1-F.x, y1-F.y);
				rsMsg.mode := OliObjects.select; rsMsg.graphic := F.graphic; Viewers.Broadcast(rsMsg)
			ELSE
				obj := OliObjects.ThisObject(F.graphic, x0-F.x, y0-F.y);
				IF obj # NIL THEN 
					OliObjects.SelectObject(obj);
					roMsg.obj := obj; roMsg.mode := OliObjects.select; roMsg.graphic := F.graphic; Viewers.Broadcast(roMsg)
				ELSE 
					rsMsg.mode := OliObjects.normal; rsMsg.graphic := F.graphic; Viewers.Broadcast(rsMsg); 
					OliObjects.DeselectAll(F.graphic) 
				END
			END
		END
	END
END Edit;

PROCEDURE Handle(frame: Display.Frame; VAR msg: Display.FrameMsg);
VAR
	x, y: INTEGER;
	F, clone: Frame;
	dMsg: DrawMsg;
	opmMsg: OPacMoveMsg;
	restoreObjMsg: RestoreObjMsg;
BEGIN
	
	(* A bold assumption; but it compiles for now :) *)
	F:= frame(Frame);
	CASE msg OF 
		Oberon.InputMsg:
		(*WITH msg: Oberon.InputMsg DO*)
			IF msg.id = Oberon.track THEN
				x := msg.X - (msg.X - F.x) MOD 4; y := msg.Y - (msg.Y - F.y) MOD 4;	(* Mouse moves "MOD 4" *)
				IF msg.keys # {} THEN Edit(F, x, y, msg.keys)
				ELSE Oberon.DrawMouseArrow(x, y)
				END
			END
		(*END*)
	| 	Oberon.ControlMsg:
		(*WITH msg: Oberon.ControlMsg DO *)
			IF msg.id = Oberon.neutralize THEN
				Oberon.RemoveMarks(F.X, F.Y, F.W, F.H);
				OliObjects.DeselectAll(F.graphic); markedG := NIL;
				mark0.set := FALSE; mark1.set := FALSE; 
				Restore(F);
			END
		(*END*)
	|	Oberon.CopyMsg:
		(*WITH msg: Oberon.CopyMsg DO*)
			Oberon.RemoveMarks(F.X, F.Y, F.W, F.H);
			NEW(clone);  clone^ := F^;  msg.F := clone
		(*END*)
	|	MenuViewers.ModifyMsg:
		(*WITH msg: MenuViewers.ModifyMsg DO*)
			F.Y := msg.Y; F.H := msg.H;
			Restore(F)
		(*END*)
	|	RestoreObjMsg:
		(*WITH msg: RestoreObjMsg DO*)
			IF F.graphic = msg.graphic THEN
				dMsg.f := F; dMsg.mode := msg.mode;
				msg.obj.do.handle(msg.obj, dMsg);
			END
		(*END*)
	|	RestoreSelMsg:
		(*WITH msg: RestoreSelMsg DO*)
			IF F.graphic = msg.graphic THEN
				dMsg.f := F; dMsg.mode := msg.mode; 
				OliObjects.BroadcastSelected(F.graphic, dMsg)
			END
		(*END*)
	|	RestoreMarksMsg:
		(*WITH msg: RestoreMarksMsg DO*)
			IF mark0.set & (markedG = F.graphic) & PinsideBox(mark0.x+F.x, mark0.y+F.y, F.X, F.Y, F.X1, F.Y1) THEN
				FlipMark(mark0.x+F.x, mark0.y+F.y) END;
			IF mark1.set & (markedG = F.graphic) & PinsideBox(mark1.x+F.x, mark1.y+F.y, F.X, F.Y, F.X1, F.Y1) THEN
				FlipMark(mark1.x+F.x, mark1.y+F.y) END;
		(*END*)
	|	RestoreMsg:
		Restore(F)
	|	FPacMoveMsg:	(* kopiere Daten um und informiere Objecte in F *)
		(*WITH msg: FPacMoveMsg DO*)
			opmMsg.f:= F;
			opmMsg.dx:= msg(FPacMoveMsg).dx;
			opmMsg.dy:= msg(FPacMoveMsg).dy;
			opmMsg.id:= msg(FPacMoveMsg).id;
			OliObjects.BroadcastAll(F.graphic, opmMsg)
		(*END*)
	END
	(* Verstehe andere Meldungen nicht *)

END Handle;

PROCEDURE NewFrame*(F: Frame);
BEGIN
	F.handle := Handle;
	F.graphic := OliObjects.NewGraphic()
END NewFrame;

BEGIN
	mark0.set := FALSE; mark1.set := FALSE; markedG := NIL
END FortiFrames.
