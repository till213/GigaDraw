(* 
   Implements captions which are created from selected text.

   Systemsoftware WS 98/99, Oliver Knoll, Raphael Huber 
*)
MODULE Captions;

IMPORT Display, OliObjects, FortiFrames, Fonts, Texts, TextFrames, Viewers, Oberon;

CONST
	SelectionTolerance = 2;
	
TYPE
	Caption = POINTER TO CaptionDesc;
	CaptionDesc = RECORD(OliObjects.ObjectDesc)
		(* Position in global text *)
		pos: LONGINT;
		(* Caption length *)
		len: LONGINT;
		(* Maximum y-offset of font *)
		yoffset: INTEGER;
	END;
	
	CaptionMethod = OliObjects.Method;

VAR
	captionMethod: CaptionMethod;
	(* Global text into which all captions are copied *)
	T: Texts.Text;	

PROCEDURE WriteWordClipped(pos, len: LONGINT; f: FortiFrames.FortiFrame; u, v, w, h: INTEGER);
(* Schreibt ein Wort aus globalem Text T an Screenkoordinaten u, v *)
VAR
	R: Texts.Reader;
	ch: CHAR;
	dx, x1, y1, w1, h1: INTEGER;
	pat: INTEGER;
BEGIN
	IF (u + w >= f.X) & (u < f.X1 ) & (v + h >= f.Y) & (v < f.Y1) THEN	(* Caption ist (zumindest teilweise) sichtbar *)
		Texts.OpenReader(R, T, pos);
		Texts.Read(R, ch);
		DEC(len);
		WHILE (len >=  0) DO
			Fonts.GetPat(R.fnt, ch, dx, x1, y1, w1, h1, pat);
			Display.CopyPattern(R.col, pat, u + x1, v + y1, Display.replace);
			INC(u, dx);
			Texts.Read(R, ch);
			DEC(len)
		END
	END
END WriteWordClipped;

PROCEDURE CopyCaption(from, to: OliObjects.Object);
VAR
BEGIN
	CASE from OF Caption:
		CASE to OF Caption:
			to^ := from^;	(* Basistypenfelder werden kopiert *)
			(* erweiterte Attribute: *)
			to.pos:= from.pos;
			to.len:= from.len;
			to.yoffset:= from.yoffset
		END
	END
END CopyCaption;

PROCEDURE SelectableCaption(caption: OliObjects.Object; x, y: INTEGER): BOOLEAN;
(* entscheidet, ob ein Mausklick mit Toleranz SelectionTolerance die Caption selektiert *)
VAR
	selectable: BOOLEAN;
BEGIN
	CASE caption OF Caption:
		IF (x >= caption.x - SelectionTolerance) & (x <= caption.x + caption.w + SelectionTolerance) & (y >= caption.y - SelectionTolerance + caption.yoffset) & (y <= caption.y + caption.h + SelectionTolerance + caption.yoffset) THEN
			selectable := TRUE
		ELSE
			selectable := FALSE
		END
	END
	RETURN selectable
END SelectableCaption;

PROCEDURE HandleCaption(caption: OliObjects.Object; VAR msg: OliObjects.Message);
(* interpretiert die Messages, welche von FortiFrames aus kommen *)
(* im Moment wird nur die DrawMsg interpretiert *)
VAR
	u, v, w, h: INTEGER;	(* Screen-Koordinaten *)
BEGIN
	IF msg IS FortiFrames.DrawMsg THEN
		CASE msg OF FortiFrames.DrawMsg:
			CASE caption OF Caption:
				u:= caption.x + msg.f.x;	(* Screenkoordinaten berechnen *)
				v:= caption.y + msg.f.y;
				w:= caption.w;
				h:= caption.h;
				
				IF msg.mode = OliObjects.Draw THEN
					IF caption.selected THEN
						WriteWordClipped(caption.pos, caption.len, msg.f, u, v, w, h);
						Display.ReplConst(Display.white, u, v + caption.yoffset, w, h, Display.invert);
					ELSE
						WriteWordClipped(caption.pos, caption.len, msg.f, u, v, w, h);
					END;
				ELSIF msg.mode = OliObjects.Select THEN
					Display.ReplConst(Display.white, u, v + caption.yoffset, w, h, Display.invert);
				ELSIF msg.mode = OliObjects.Normal THEN
					Display.ReplConst(Display.white, u, v + caption.yoffset, w, h, Display.invert);
				ELSIF msg.mode = OliObjects.Erase THEN
					Display.ReplConst(Display.black, u, v + caption.yoffset, w, h, Display.replace);	(* einfach eine schwarze Box drueber malen *) 
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
	caption.do:= captionMethod;
	RETURN caption
END NewCaption;

(* --- User Prozeduren ----------------------------------------------- *)

PROCEDURE MakeCaption*();
(* Kopiert einen markierten Text als Caption in markierten Frame.*)
(* Eine Caption wird an Position von mark0 gemalt, wobei mark0 anschliessend verschwindet. *)
VAR
	caption: Caption;
	w, h: INTEGER;
	color: INTEGER;	(* jeder Buchstabe kann eigene Farbe haben *)
	R: Texts.Reader;
	W: Texts.Writer;
	font: Fonts.Font;
	dx, x1, y1, w1, h1: INTEGER;
	pat: INTEGER;	
	len, read: INTEGER;	(* Laenge der Caption *)
	ch: CHAR;
	beg, end, time: INTEGER;	(* die Selektion *)
	seltext: Texts.Text;
	yoffset: INTEGER;	(* offset fuer Selektionsrechteck *)
	rmMsg: FortiFrames.RestoreMarksMsg;
BEGIN

	IF (FortiFrames.mark0.set) THEN
		
		seltext:= NIL;	(* wurde keine Selektion getaetigt, so bleibt dieser Wert auf NIL *)
		Oberon.GetSelection(seltext, beg, end, time);
		IF ~(seltext = NIL) THEN
			
			Texts.OpenReader(R, seltext, beg);
			Texts.OpenWriter(W);
			w:= 0;
			h:= 0;
			read:= 0;
			len:= end - beg;
			
			Texts.Read(R, ch);
			INC(read);
			font:= R.fnt;
			Texts.SetFont(W, font);
			color:= R.col;
			Texts.SetColor(W, color);
			Fonts.GetPat(font, ch, dx, x1, y1, w1, h1, pat);
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
				Fonts.GetPat(font, ch, dx, x1, y1, w1, h1, pat);
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
			caption.do:= captionMethod;
			(* erweiterte Felder werden initialisiert *)
			caption.pos:= T.len;	(* Text wird am Schluss angehaengt *)
			caption.len:= len;
			caption.yoffset:= yoffset;
			Texts.Append(T, W.buf);
			
			Viewers.Broadcast(rmMsg);	(* alte Markierungen loeschen *)
			(* FortiFrames.mark0.set:= FALSE;	(* mark0 soll verschwinden *) *)
			FortiFrames.SetMarkEnabled(0, FALSE);
			(*FortiFrames.mark1.set:= FALSE;	(* mark1 soll verschwinden *) *)
			FortiFrames.SetMarkEnabled(1, FALSE);
			(* die folgene Prozedur kuemmert sich um das Einfuegen und Benachrichtigen aller Frames *)
			(* ausserdem werden dort alle anderen Objekte vorher deselektiert *)
			FortiFrames.InsertObject(FortiFrames.markedG, caption)

		END

	END

END MakeCaption;

BEGIN
	NEW(T);
	T:= TextFrames.Text("global");	(* Oeffnen des globalen Textes *)
	(* der Methodenrekord wird einmal initialisiert und ist somit fix *)
	NEW(captionMethod);
	captionMethod.new:= NewCaption;
	captionMethod.copy:= CopyCaption;
	captionMethod.selectable:= SelectableCaption;
	captionMethod.handle:= HandleCaption;
END Captions.


System.Free Captions GigaDraw FortiFrames OliObjects~
Captions.MakeCaption
