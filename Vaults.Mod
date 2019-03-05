MODULE Vaults;

  IMPORT SYSTEM, Files, Fonts, Ciphers;

  CONST 
    replace* = 0; insert* = 1; delete* = 2; unmark* = 3;  (*op-codes*)

  TYPE 
    Method* = POINTER TO MethodDesc;
    Document* = POINTER TO DocumentDesc;
    DocumentDesc* = RECORD
      x*, y*, w*, h*, d*, p*: INTEGER;
      sx*, sy*: REAL;
      sw*, sh*: INTEGER;
      selected*, marked*: BOOLEAN;
      do*: Method;
      next: Document
    END;

    Vault* = POINTER TO VaultDesc;
    Notifier* = PROCEDURE (V: Vault; op: INTEGER; beg, end: LONGINT);
    VaultDesc* = RECORD
      len*: LONGINT;
      changed*: BOOLEAN;
      flattened*: BOOLEAN;
      sel*, first: Document;
      notify*: Notifier
    END;

    Msg* = RECORD END ;
    WidMsg* = RECORD (Msg) w*: INTEGER END ;
    ColorMsg* = RECORD (Msg) col*: INTEGER END ;
    FontMsg* = RECORD (Msg) fnt*: Fonts.Font END ;
    

    bmpHeaderEntry = RECORD
        a: INTEGER;
        b: INTEGER;
        c: INTEGER;
        d: INTEGER
    END;

    jpgHeaderEntry = RECORD
        a: INTEGER;
        b: INTEGER;
        c: INTEGER;
        d: INTEGER
    END;

    pngHeaderEntry = RECORD
        a: INTEGER;
        b: INTEGER;
        c: INTEGER;
        d: INTEGER
    END;

    MethodDesc* = RECORD
(*        module*, allocator*: Name;
        new*: Modules.Command;             *)
        copy*: PROCEDURE (from, to: Document);
        draw*, change*: PROCEDURE (D: Document; VAR msg: Msg);
        selectable*: PROCEDURE (D: Document; x, y: INTEGER): BOOLEAN;
        read*: PROCEDURE (D: Document; VAR r: Files.Rider); (*; VAR c: Context); *)
        write*: PROCEDURE (D: Document; cno: INTEGER; VAR r: Files.Rider); (*; VAR c: Context);*)
        print*: PROCEDURE (D: Document; x, y: INTEGER)
      END ;

    
VAR 
 
  res*: INTEGER;
  width: INTEGER;
  new*: Document; 
  LineMethod*, CapMethod*, MacMethod* : Method;

  PROCEDURE New*(D: Document);
  BEGIN   new := D 
  END New;

  PROCEDURE Add*(V: Vault; D: Document);
  BEGIN D.marked := FALSE; D.selected := TRUE; D.next := V.first;
    V.first := D; V.sel := D; V.changed := TRUE
  END Add;

  PROCEDURE ThisDocument*(V: Vault; x, y: INTEGER): Document;
    VAR D: Document;
  BEGIN D := V.first;
    WHILE (D # NIL) & ~D.do.selectable(D, x ,y) DO D := D.next END ;
    RETURN D
  END ThisDocument;

  PROCEDURE SelectDocument*(V: Vault; D: Document);
  BEGIN
    IF D # NIL THEN D.selected := TRUE; V.sel := D END
  END SelectDocument;

  PROCEDURE SelectArea*(V: Vault; x0, y0, x1, y1: INTEGER);
    VAR D: Document; t: INTEGER;
  BEGIN D := V.first;
    IF x1 < x0 THEN t := x0; x0 := x1; x1 := t END ;
    IF y1 < y0 THEN t := y0; y0 := y1; y1 := t END ;
    WHILE D # NIL DO
      IF (x0 <= D.x) & (D.x + D.w <= x1) & (y0 <= D.y) & (D.y + D.h <= y1) THEN
        D.selected := TRUE; V.sel := D
      END ;
      D := D.next
    END ;
    IF V.sel # NIL THEN  END
  END SelectArea;

  PROCEDURE Draw*(V: Vault; VAR m: Msg);
    VAR D: Document;
  BEGIN D := V.first;
    WHILE D # NIL DO D.do.draw(D, m); D := D.next END
  END Draw;

(*
  PROCEDURE List*(V: Vault);
    VAR D: Document; tag: INTEGER;
  BEGIN D := V.first;
    WHILE D # NIL DO
      Texts.Write(XW, 9X); Texts.WriteHex(XW, ORD(D)); Texts.Write(XW, 9X);
      Texts.WriteInt(XW, D.x, 5); Texts.WriteInt(XW, D.y, 5); Texts.WriteInt(XW, D.w, 5); Texts.WriteInt(XW, D.h, 5);
      Texts.Write(XW, "/"); SYSTEM.GET(ORD(D)-8, tag); Texts.WriteHex(XW, tag);
      SYSTEM.GET(ORD(D)-4, tag); Texts.WriteHex(XW, tag); Texts.WriteLn(XW); D := D.next
    END ;
    Texts.Append(Oberon.Log, XW.buf)
  END List;
*)

  (*----------------procedures operating on selection -------------------*)

  PROCEDURE Deselect*(V: Vault);
    VAR D: Document;
  BEGIN D := V.first; V.sel := NIL; 
    WHILE D # NIL DO D.selected := FALSE; D := D.next END
  END Deselect;

  PROCEDURE DrawSel*(V: Vault; VAR m: Msg);
    VAR D: Document;
  BEGIN D := V.first;
    WHILE D # NIL DO
      IF D.selected THEN D.do.draw(D, m) END ;
      D := D.next
    END
  END DrawSel;

  PROCEDURE Change*(V: Vault; VAR m: Msg);
    VAR D: Document;
  BEGIN D := V.first; V.changed := TRUE;
    WHILE D # NIL DO
      IF D.selected THEN D.do.change(D, m) END ;
      D := D.next
    END
  END Change;



  PROCEDURE WriteFile*(V: Vault; name: ARRAY OF CHAR);
    VAR f: Files.File; w: Files.Rider; 
  BEGIN f := Files.New(name); Files.Set(w, f, 0); 
  (*  Files.Write(w, GraphFileId); InitContext(c); StoreElems(w, c, V.first);  *)
    Files.Register(f)
  END WriteFile;


  PROCEDURE SetWidth*(w: INTEGER);
  BEGIN width := w
  END SetWidth;


  PROCEDURE Open*(V: Vault; name: ARRAY OF CHAR);
    VAR tag: CHAR;
          b: BYTE;
          i: INTEGER;
      f: Files.File; r: Files.Rider; 
  BEGIN V.first := NIL; V.sel := NIL; V.changed := FALSE; f := Files.Old(name);
    IF f # NIL THEN
      Files.Set(r, f, 0);
      Files.ReadByte(r, b); i:=b;
      Files.ReadByte(r, b); i:=i+(b*100H);
     
    ELSE res := 2
    END
  END Open;



  PROCEDURE Delete*(V: Vault);
    VAR D, pred: Document;
  BEGIN V.sel := NIL; V.changed := TRUE; D := V.first;
    WHILE (D # NIL) & D.selected DO D := D.next END ;
    V.first := D;
    IF D # NIL THEN
      pred := D; D := D.next;
      WHILE D # NIL DO
        IF D.selected THEN pred.next := D.next ELSE pred := D END ;
        D := D.next
      END
    END
  END Delete;






  PROCEDURE InstallDrawMethods*(drawLine, drawCaption, drawMacro: PROCEDURE (D: Document; VAR msg: Msg));
  BEGIN LineMethod.draw := drawLine; CapMethod.draw := drawCaption; MacMethod.draw := drawMacro
  END InstallDrawMethods;

BEGIN 
END Vaults.

