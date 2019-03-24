MODULE Random;
(* WS 98/99, Oliver Knoll *)

IMPORT Out;

PROCEDURE rnd*(VAR r: INTEGER);
(* erzeugt Pseudo-Zufallszahlen 0 <= r <= 8192 *)

BEGIN
	r:= 125 * r MOD 8192;
END rnd;

PROCEDURE rndn*(VAR r: INTEGER): REAL;
(* erzeugt Pseudo-Zufallszahlen 0 <= rn <= 1 *)

BEGIN
	r:= 125 * r MOD 8192;
	RETURN r / 8192.0;
END rndn;

PROCEDURE Test*();
VAR
	i: INTEGER;
	r1, r2: INTEGER;

BEGIN
	r1:= 1;
	r2:= 1;
	FOR i:= 0 TO 100 DO
		rnd(r1);
		Out.Int(r1, 5);
		Out.Real(rndn(r2), 12);
		Out.Ln()
	END
END Test;

BEGIN
END Random.

Compiler.Compile */s
System.Free Random~

Random.Test
