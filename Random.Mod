MODULE Random;
(* WS 98/99, Oliver Knoll *)

IMPORT Texts, Oberon;

PROCEDURE rnd*(VAR r: INTEGER);
(* erzeugt Pseudo-Zufallszahlen 0 <= r <= 8192 *)

BEGIN
	r:= 125 * r MOD 8192;
END rnd;

PROCEDURE rndn*(VAR r: INTEGER): REAL;
(* erzeugt Pseudo-Zufallszahlen 0 <= rn <= 1 *)

BEGIN
	r:= 125 * r MOD 8192;
	RETURN FLT(r) / 8192.0
END rndn;

PROCEDURE Test*();
VAR
	i: INTEGER;
	r1, r2: INTEGER;
	W: Texts.Writer;
BEGIN
	Texts.OpenWriter(W);
	r1:= 1;
	r2:= 1;
	FOR i:= 0 TO 100 DO
		rnd(r1);
		Texts.WriteInt(W, r1, 5);
		Texts.WriteReal(W, rndn(r2), 12);
		Texts.WriteLn(W)
	END;
	Texts.Append(Oberon.Log, W.buf)
END Test;

BEGIN
END Random.

Random.Test
ORP.Compile */s
System.Free Random~

Random.Test
