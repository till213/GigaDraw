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

	(* Pac-Man move message which is sent to all frames *)
	FPacMoveMsg* = RECORD (Display.FrameMsg)
		dx*: INTEGER;
		dy*: INTEGER;
		id*: INTEGER; (* ID of Pacman to be moved *)
	END;

	(* Messages targeted at OliObjects within a given frame *)

	OPacMoveMsg* = RECORD (OliObjects.Message)
		f*: FortiFrame;
		dx*: INTEGER;
		dy*: INTEGER;
		id*: INTEGER
	END;
	
	(* Markers relate to the Graphic document (not to a specific frame)
	   and are hence visible in all viewer frames *)
	markDesc = RECORD
		(* World coordinates *)
		x*, y*: INTEGER;
		set*: BOOLEAN
	END;

VAR 
    (* Global markers, visible in all frames *)
	mark0*, mark1*: markDesc;
	(* The "focus" Graphic: the one having been marked last *)
	markedG*: OliObjects.Graphic;

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
	(* Deselect previously selected objects *)
	rsMsg.mode := OliObjects.Normal; 
	rsMsg.graphic := markedG; 
	Viewers.Broadcast(rsMsg);
	OliObjects.DeselectAll(graphic); 
	(* Add new object *)
	OliObjects.AddObject(graphic, object);
	roMsg.obj := object;
	roMsg.mode := OliObjects.Draw;
	roMsg.graphic := markedG; 
	Viewers.Broadcast(roMsg);
	(* Restore markers *)
	Viewers.Broadcast(rmMsg)	
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
	(* Coordinates of ticks *)
	x, y: INTEGER;
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
	(* x0, y0 upon click, x1, y1 upon release *)
	x1, y1: INTEGER;
	(* k0: mouse keys upon click  -  k1: mouse keys upon release *)	
	k1, k2: SET;	
	dx, dy: INTEGER;
	v0, v1: Viewers.Viewer;
	rmMsg: RestoreMarksMsg; 
	rsMsg: RestoreSelMsg; 
	roMsg: RestoreObjMsg; 
	rMsg: RestoreMsg;
	obj: OliObjects.Object;
BEGIN

	k1 := k0;
	(* Register inter-clicks until mouse keys k2 have all been released *)
	REPEAT	
		Input.Mouse(k2, x1, y1); 
		k1 := k1 + k2;
		DEC(x1, (x1 - frame.x) MOD 4); 
		DEC(y1, (y1 - frame.y) MOD 4);
		Oberon.DrawMouseArrow(x1, y1)
	UNTIL k2 = {};
	Oberon.FadeMouse();
	
	IF k0 = {LeftMouseButton} THEN
		IF k1 = {LeftMouseButton} THEN	
			(* Left only: place first marker *)
			(* First remove all markers *)
			Viewers.Broadcast(rmMsg);	
			mark0.set := TRUE;
			mark1.set := FALSE; 
			markedG := frame.graphic;
			mark0.x := x1 - frame.x;
			mark0.y := y1 - frame.y;
			(* Draw the new marker *)
			Viewers.Broadcast(rmMsg)
		ELSIF k1 = {LeftMouseButton, MiddleMouseButton} THEN
			(* Left, middle: place 2nd marker, if 1st marker is already set
			   in the same Graphic (but which does not have to be in the same 
			   viewer framen *)
			IF mark0.set & (markedG = frame.graphic) THEN
				Viewers.Broadcast(rmMsg);	(* Remove 2nd marker *)
				mark1.set := TRUE; 
				mark1.x := x1 - frame.x;
				mark1.y := y1 - frame.y;
				Viewers.Broadcast(rmMsg)	(* Redraw 2nd marker *)
			END
		END
	ELSIF k0 = {MiddleMouseButton} THEN
		IF k1 = {MiddleMouseButton} THEN
			(* Middle only: move selected objects *)
			rsMsg.mode := OliObjects.Erase; 
			rsMsg.graphic := frame.graphic; 
			Viewers.Broadcast(rsMsg);
			OliObjects.Move(frame.graphic, x1 - x0, y1 - y0);
			rsMsg.mode := OliObjects.Draw;
			rsMsg.graphic := frame.graphic; 
			Viewers.Broadcast(rsMsg)	
		ELSIF k1 = {MiddleMouseButton, LeftMouseButton} THEN
			(* Middle, left: copy selected objects (also into different viewers or even Graphics) *)
			v0 := Viewers.This(x0, y0); 
			v1 := Viewers.This(x1, y1);
			IF v0 = v1 THEN	
				(* Copy within same viewer *)
				rsMsg.mode := OliObjects.Normal; 
				rsMsg.graphic := frame.graphic; 
				Viewers.Broadcast(rsMsg);
				OliObjects.Copy(frame.graphic, frame.graphic, x1 - x0, y1 - y0)
			ELSIF v1.dsc.next IS FortiFrame THEN
				(* Copy into different viewer *)
				dx := (x1 - v1.dsc.next(FortiFrame).x) - (x0-v0.dsc.next(FortiFrame).x);
				dy := (y1 - v1.dsc.next(FortiFrame).y) - (y0-v0.dsc.next(FortiFrame).y);
				rsMsg.mode := OliObjects.Normal; 
				rsMsg.graphic := frame.graphic; 
				Viewers.Broadcast(rsMsg);
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
			(* Middle, right: move entire graphic document *)
			INC(frame.Xg, x1 - x0); 
			INC(frame.Yg, y1 - y0); 
			Restore(frame)
		END
	ELSIF k0 = {RightMouseButton} THEN
		IF k1 = {RightMouseButton} THEN
			(* Right only: select all objects in area; deselect all if only point area *)
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
				(* Mouse moves "MOD 4" *)
				x := msg.X - (msg.X - frame.x) MOD 4; y := msg.Y - (msg.Y - frame.y) MOD 4;
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
			(* Copy payload into message broadcast to all objects *)
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
