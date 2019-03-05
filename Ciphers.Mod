MODULE Ciphers;
IMPORT SYSTEM, Kernel, Oberon;

TYPE
  Cipher* = POINTER TO CipherDesc;
  CipherDesc* = RECORD
    value*: INTEGER;
    next: Cipher
  END;

PROCEDURE New*(C: Cipher; v: INTEGER) : Cipher;
BEGIN
  IF C = NIL THEN NEW(C) END;
  IF C # NIL THEN
    C.value := v;
    C.next := NIL
  END
  RETURN C 
END New;

PROCEDURE Get*(C: Cipher; x: INTEGER): INTEGER;
  VAR r,i: INTEGER; C1:Cipher;
BEGIN i:=0;r:=0;
  C1:=C; WHILE C1 # NIL DO 
    IF i = x THEN r := C1.value END;
    C1:=C1.next;
    INC(i)
  END
  RETURN r 
END Get;

PROCEDURE Clear*(C: Cipher);
BEGIN
  C.value:=0;
  C.next:=NIL
END Clear;

BEGIN
END Ciphers.
