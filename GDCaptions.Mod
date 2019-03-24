MODULE Captions;
(* Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber *)

(* implementiert Captions - die Captionkoordinaten sind "mathematisch", bei einer DrawMsg rechnen die Captions *)
(* diese Koordinaten selbstaendig in Screenkoordinaten um *)

(* w und h sind immer positiv (dies vereinfacht die Berechnungen in SelectableLine() *)

IMPORT OliObjects, FortiFrames, Texts, TextFrames, Fonts, Display, Viewers, Oberon;

CONST
	tol = 2;	(* Toleranz: 2 Pixel darf man danebenklicken *)
	
TYPE
	Caption = POINTER TO CaptionDesc;
	CaptionDesc = RECORD(OliObjects.ObjectDesc)
		pos: LONGINT;	(* Position im globalen Text *)
		len: LONGINT;	(* Laenge des Captions *)
		yoffset: INTEGER;	(* maximaler yoffset des Fonts *)
	END;
	
	CaptionMethod = OliObjects.Method;

VAR
	captionmethod: CaptionMethod;	(* globale Variable, da Methoden fix sind *)
	T: Texts.Text;	(* globaler Text: hier hinein werden alle Captions gespeichert *)

PROCEDURE WriteWordClipped(pos, len: LONGINT; f: FortiFrames.Frame; u, v, w, h: INTEGER);
(* Schreibt ein Wort aus globalem Text T an Screenkoordinaten u, v *)
VAR
	R: Texts.Reader;
	ch: CHAR;
	dx, x1, y1, w1, h1: INTEGER;
	pat: Display.Pattern;
	
BEGIN
	IF (u + w >= f.X) & (u < f.X1 ) & (v + h >= f.Y) & (v < f.Y1) THEN	(* Caption ist (zumindest teilweise) sichtbar *)
		Texts.OpenReader(R, T, pos);
		Texts.Read(R, ch);
		DEC(len);
		WHILE (len >=  0) DO
			Display.GetChar(R.fnt.raster, ch, dx, x1, y1, w1, h1, pat);
			Display.CopyPatternC(f, R.col, pat, u + x1, v + y1, Display.replace);
			INC(u, dx);
			Texts.Read(R, ch);
			DEC(len)
		END
	END
END WriteWordClipped;

PROCEDURE CopyCaption(from, to: OliObjects.Object);
(* kopiert eine Caption: from ist die OriginalCaption MyCaption, to ist eine vorgaengig mit MyCaption.do.new() erschaffene Caption *)

VAR

BEGIN
	WITH from: Caption DO
		WITH to: Caption DO
			to^:= from^;	(* Basistypenfelder werden kopiert *)
			(* erweiterte Attribute: *)
			to.pos:= from.pos;
			to.len:= from.len;
			to.yoffset:= from.yoffset
		END
	END
END CopyCaption;

PROCEDURE SelectableCaption(caption: OliObjects.Object; x, y: INTEGER): BOOLEAN;
(* entscheidet, ob ein Mausklick mit Toleranz tol die Caption selektiert *)

VAR

BEGIN
	WITH caption: Caption DO
		IF (x >= caption.x - tol) & (x <= caption.x + caption.w + tol) & (y >= caption.y - tol + caption.yoffset) & (y <= caption.y + caption.h + tol + caption.yoffset) THEN
			RETURN TRUE
		ELSE
			RETURN FALSE
		END
	END
END SelectableCaption;

PROCEDURE HandleCaption(caption: OliObjects.Object; VAR msg: OliObjects.Message);
(* interpretiert die Messages, welche von FortiFrames aus kommen *)
(* im Moment wird nur die DrawMsg interpretiert *)

VAR
	u, v, w, h: INTEGER;	(* Screen-Koordinaten *)
	
BEGIN
	IF msg IS FortiFrames.DrawMsg THEN
		WITH msg: FortiFrames.DrawMsg DO
			WITH caption: Caption DO
				u:= caption.x + msg.f.x;	(* Screenkoordinaten berechnen *)
				v:= caption.y + msg.f.y;
				w:= caption.w;
				h:= caption.h;
				
				CASE msg.mode OF
					OliObjects.draw:	IF caption.selected THEN
													WriteWordClipped(caption.pos, caption.len, msg.f, u, v, w, h);
													Display.ReplConstC(msg.f, Display.white, u, v + caption.yoffset, w, h, Display.invert);
												ELSE
													WriteWordClipped(caption.pos, caption.len, msg.f, u, v, w, h);
												END;
					|	OliObjects.select:	Display.ReplConstC(msg.f, Display.white, u, v + caption.yoffset, w, h, Display.invert);
					|	OliObjects.normal:	Display.ReplConstC(msg.f, Display.white, u, v + caption.yoffset, w, h, Display.invert);
					|	OliObjects.erase:	Display.ReplConstC(msg.f, Display.black, u, v + caption.yoffset, w, h, Display.replace);	(* einfach eine schwarze Box drueber malen *) 
				END
			END
		END
	END	(* Ignoriere andere Messages *)
END HandleCaption;
					
PROCEDURE NewCaption(): OliObjects.Object;
(* retourniert eine neue Linie und initialisiert Methoden-Rekord *)

VAR
	caption: Caption;
	
BEGIN
	NEW(caption);
	caption.do:= captionmethod;
	RETURN caption
END NewCaption;

(* --- User Prozeduren ----------------------------------------------- *)

PROCEDURE MakeCaption*();
(* Kopiert einen markierten Text als Caption in markierten Frame.*)
(* Eine Caption wird an Position von mark0 gemalt, wobei mark0 anschliessend verschwindet. *)

VAR
	caption: Caption;
	w, h: INTEGER;
	color: SHORTINT;	(* jeder Buchstabe kann eigene Farbe haben *)
	R: Texts.Reader;
	W: Texts.Writer;
	font: Fonts.Font;
	dx, x1, y1, w1, h1: INTEGER;
	pat: Display.Pattern;	
	len, read: INTEGER;	(* Laenge der Caption *)
	ch: CHAR;
	beg, end, time: LONGINT;	(* die Selektion *)
	seltext: Texts.Text;
	yoffset: INTEGER;	(* offset fuer Selektionsrechteck *)
	rmMsg: FortiFrames.RestoreMarksMsg;

BEGIN
	IF ~(FortiFrames.mark0.set) THEN
		(* eventuell noch eine Fehlermeldung ausgeben *)
		RETURN
	END;
	seltext:= NIL;	(* wurde keine Selektion getaetigt, so bleibt dieser Wert auf NIL *)
	Oberon.GetSelection(seltext, beg, end, time);
	IF (seltext = NIL) THEN
		(* Fehlertext *)
		RETURN
	END;
	Texts.OpenReader(R, seltext, beg);
	Texts.OpenWriter(W);
	w:= 0;
	h:= 0;
	read:= 0;
	len:= SHORT(end - beg);
	
	Texts.Read(R, ch);
	INC(read);
	font:= R.fnt;
	Texts.SetFont(W, font);
	color:= R.col;
	Texts.SetColor(W, color);
	Display.GetChar(font.raster, ch, dx, x1, y1, w1, h1, pat);
	INC(w, dx);
	h:= R.fnt.height;
	yoffset:= font.minY;
	Texts.Write(W, ch);
	
	WHILE (read < len) DO
		Texts.Read(R, ch);
		INC(read);
		IF (R.fnt # font) THEN	(* aendere Font *)
			font:= R.fnt;
			Texts.SetFont(W, font);
			IF (font.minY < yoffset) THEN	(* aktualisiere yoffset *)
				yoffset:= font.minY
			END;
			IF (font.height > h) THEN	(* Aktualisiere Hoehe *)
				h:= font.height
			END
		END;
		IF (color # R.col) THEN	(* aendere Farbe *)
			color:= R.col;
			Texts.SetColor(W, color)
		END;
		Display.GetChar(font.raster, ch, dx, x1, y1, w1, h1, pat);
		INC(w, dx);
		Texts.Write(W, ch);
	END;

	NEW(caption);
	caption.w:= w;
	caption.h:= h;
	caption.x:= FortiFrames.mark0.x;
	caption.y:= FortiFrames.mark0.y;
	caption.col:= color;	(* Farbe vom letzten Buchstaben - eigentlich ueberfluessig, da Color schon im Text selbst gespeichert ist *)
	caption.selected:= TRUE;	(* Linie soll normal gemalt werden *)
	caption.do:= captionmethod;
	(* erweiterte Felder werden initialisiert *)
	caption.pos:= T.len;	(* Text wird am Schluss angehaengt *)
	caption.len:= len;
	caption.yoffset:= yoffset;
	Texts.Append(T, W.buf);
	
	Viewers.Broadcast(rmMsg);	(* alte Markierungen loeschen *)
	FortiFrames.mark0.set:= FALSE;	(* mark0 soll verschwinden *)
	FortiFrames.mark1.set:= FALSE;	(* mark1 soll verschwinden *)
	(* die folgene Prozedur kuemmert sich um das Einfuegen und Benachrichtigen aller Frames *)
	(* ausserdem werden dort alle anderen Objekte vorher deselektiert *)
	FortiFrames.InsertObject(FortiFrames.markedG, caption)
END MakeCaption;

BEGIN
	NEW(T);
	T:= TextFrames.Text("global");	(* Oeffnen des globalen Textes *)
	(* der Methodenrekord wird einmal initialisiert und ist somit fix *)
	NEW(captionmethod);
	captionmethod.new:= NewCaption;
	captionmethod.copy:= CopyCaption;
	captionmethod.selectable:= SelectableCaption;
	captionmethod.handle:= HandleCaption;
END Captions.


System.Free Captions GigaDraw FortiFrames OliObjects~
Captions.TestText
