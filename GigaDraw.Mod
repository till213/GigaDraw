MODULE GigaDraw;
(* Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber *)

(* implementiert die User-Kommandos *)

IMPORT OliObjects, FortiFrames, Viewers, Texts, Oberon, MenuViewers, TextFrames;
CONST
	menuwidth = 14;

VAR
	W: Texts.Writer;

PROCEDURE Reset*();
VAR
	v: Viewers.Viewer;

BEGIN
	v:= Oberon.Par.vwr;	(* Reset muss im Menubalken aufgerufen werden! *)
	IF v.dsc.next IS FortiFrames.Frame THEN
		v.dsc.next(FortiFrames.Frame).Xg:= 5;
		v.dsc.next(FortiFrames.Frame).Yg:= -v.dsc.next(FortiFrames.Frame).H + 5;
		FortiFrames.Restore(v.dsc.next(FortiFrames.Frame))	(* nur dieses Fenster soll restored werden *)
	END
END Reset;

PROCEDURE Open*();
VAR
	mv: MenuViewers.Viewer;
	tf: TextFrames.Frame;
	ff: FortiFrames.Frame;
	x, y: INTEGER;
	S: Texts.Scanner;

BEGIN
	Oberon.AllocateUserViewer(0, x, y);
	Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
	Texts.Scan(S);
	tf:= TextFrames.NewMenu(S.s, "System.Close System.Copy System.Grow GigaDraw.Delete GigaDraw.Reset");
	NEW(ff);
	FortiFrames.NewFrame(ff);
	mv:= MenuViewers.New(tf, ff, menuwidth, x, y);
	Viewers.Open(mv, x, y);
	ff.Xg:= 5;
	ff.Yg:= -ff.H + 5;
	FortiFrames.Restore(ff)
END Open;

PROCEDURE Delete*();
VAR
	v: Viewers.Viewer;
	rsMsg: FortiFrames.RestoreSelMsg;

BEGIN
	v:= Oberon.Par.vwr;	(* Delete muss im Menu aufgerufen werden *)
	IF v.dsc.next IS FortiFrames.Frame THEN
		rsMsg.mode:= OliObjects.erase;
		rsMsg.graphic:= v.dsc.next(FortiFrames.Frame).graphic;
		Viewers.Broadcast(rsMsg);	(* erst alle Viewers updaten ... *)
		OliObjects.DeleteSelected(v.dsc.next(FortiFrames.Frame).graphic)	(* ... dann das Modell veraendern *)
	END
END Delete;

PROCEDURE ChangeColor*();
(* aendert die globale Variable color in OliObjects *)

VAR
	S: Texts.Scanner;
	seltext: Texts.Text;	(* der selektiere Text *)
	beg, end, time: LONGINT;	(* die Selektion *)

BEGIN
	seltext:= NIL;	(* wenn keine Selektion getaetigt, bleibt dieser Wert auf NIL *)
	Oberon.GetSelection(seltext, beg, end, time);
	IF seltext # NIL THEN
		Texts.OpenScanner(S, seltext, beg);
		Texts.Scan(S);
		IF S.class = Texts.Int THEN
			OliObjects.ChangeColor(S.i)
		END
	END
END ChangeColor;

PROCEDURE LogText*(msg: ARRAY OF CHAR);
VAR
BEGIN
	Texts.WriteString(W, msg);
	Texts.Append(Oberon.Log, W.buf)
END LogText;

PROCEDURE LogInt*(i: INTEGER);
VAR
BEGIN
	Texts.WriteInt(W, i, 10);
	Texts.Append(Oberon.Log, W.buf)
END LogInt;

BEGIN
	Texts.OpenWriter(W)
END GigaDraw.


	
	