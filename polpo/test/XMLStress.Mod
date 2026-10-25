MODULE XMLStress;  (* hostile and mutated XML inputs for the parser of ooc-xml *)

(* XMLStress.Limits writes the 53 inputs of voc's tests/voc/check-limits.py (deep nesting, wide
   content models, entity expansion, 16 MB inputs, long outputs) into files of the current
   directory and checks that the parser rejects each with the diagnostic of its limit.

   XMLStress.Fuzz checks truncations and byte mutations of seven small documents, after the plan
   of voc's tests/voc/check-fuzz.py, in five modes (plain, namespaces, validation, canonical,
   protocol): each must be accepted or rejected. The mutations come from a fixed seed (the
   minimal standard generator of Park and Miller), so every run checks the same inputs. *)

IMPORT Files, out, M := Msg, Mem := IOMemory, X := XMLCheck0;

CONST
  MB = 1024 * 1024;
  Max = 512;  (* longest document of the fuzzer *)

VAR
  checks, failed: LONGINT;
  f: Files.File; R: Files.Rider;
  xs: ARRAY 4096 OF CHAR;  (* 4096 times x *)
  seed: LONGINT;
  docs: ARRAY 7, Max OF CHAR; docLen: ARRAY 7 OF LONGINT;
  text: ARRAY Max OF CHAR; len: LONGINT;

(* writing a test file *)

PROCEDURE Open(name: ARRAY OF CHAR);
BEGIN f := Files.New(name); Files.Set(R, f, 0)
END Open;

PROCEDURE Close;
BEGIN Files.Register(f); Files.Close(f); f := NIL
END Close;

PROCEDURE Delete(name: ARRAY OF CHAR);
VAR res: INTEGER;
BEGIN Files.Delete(name, res)
END Delete;

PROCEDURE W(s: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN i := 0; WHILE s[i] # 0X DO Files.Write(R, s[i]); INC(i) END
END W;

PROCEDURE Rep(s: ARRAY OF CHAR; n: LONGINT);
BEGIN WHILE n > 0 DO W(s); DEC(n) END
END Rep;

PROCEDURE Int(n: LONGINT);
VAR d: ARRAY 12 OF CHAR; i: LONGINT;
BEGIN
  i := 0; REPEAT d[i] := CHR(n MOD 10 + ORD("0")); n := n DIV 10; INC(i) UNTIL n = 0;
  WHILE i > 0 DO DEC(i); Files.Write(R, d[i]) END
END Int;

(* n times x *)
PROCEDURE Xs(n: LONGINT);
BEGIN
  WHILE n >= LEN(xs) DO Files.WriteBytes(R, xs, LEN(xs)); DEC(n, LEN(xs)) END;
  IF n > 0 THEN Files.WriteBytes(R, xs, n) END
END Xs;

(* s, then i, then t, for i from 0 to n-1, with sep between *)
PROCEDURE Join(s, t, sep: ARRAY OF CHAR; n: LONGINT);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < n DO IF i > 0 THEN W(sep) END; W(s); Int(i); W(t); INC(i) END
END Join;

(* entities e0 to e(depth-1), each made of fanout references to the one before *)
PROCEDURE Expansion(depth, fanout: LONGINT);
VAR i, k: LONGINT;
BEGIN
  W('<!DOCTYPE r [<!ENTITY e0 "x">'); i := 1;
  WHILE i < depth DO
    W("<!ENTITY e"); Int(i); W(' "'); k := 0;
    WHILE k < fanout DO W("&e"); Int(i - 1); W(";"); INC(k) END;
    W('">'); INC(i)
  END;
  W("]><r/>")
END Expansion;

(* checking *)

PROCEDURE Flags(s: ARRAY OF CHAR): SET;
VAR k: LONGINT; set: SET;
BEGIN
  set := {}; k := 0;
  WHILE s[k] # 0X DO
    CASE s[k] OF
      "e": INCL(set, X.external) | "n": INCL(set, X.namespaces) | "v": INCL(set, X.validate)
    | "c": INCL(set, X.canonical) | "s": INCL(set, X.second) | "p": INCL(set, X.protocol)
    ELSE
    END;
    INC(k)
  END;
  RETURN set
END Flags;

(* does the output of ch contain s *)
PROCEDURE Contains(ch: Mem.Channel; s: ARRAY OF CHAR): BOOLEAN;
VAR i, k, n: LONGINT;
BEGIN
  IF ch = NIL THEN RETURN FALSE END;
  n := ch.Length(); i := 0;
  WHILE i < n DO
    k := 0; WHILE (s[k] # 0X) & (i + k < n) & (ch.file.data[i + k] = s[k]) DO INC(k) END;
    IF s[k] = 0X THEN RETURN TRUE END;
    INC(i)
  END;
  RETURN FALSE
END Contains;

(* the file name must be rejected with flags, its errors containing diag *)
PROCEDURE Limit(name, flags, diag: ARRAY OF CHAR);
VAR r: INTEGER; output: Mem.Channel; msg: M.Msg; k: LONGINT;
BEGIN
  INC(checks);
  r := X.Check(name, Flags(flags), output, msg);
  IF (r # X.rejected) OR ~Contains(output, diag) THEN
    INC(failed); out.String("FAIL "); out.String(name); out.String(" "); out.String(flags);
    out.String(": result "); out.Int(r, 0); out.String(", expected 1 with "); out.String(diag); out.Ln;
    IF output # NIL THEN
      k := 0; WHILE (k < output.Length()) & (k < 400) DO out.Char(output.file.data[k]); INC(k) END; out.Ln
    END
  END;
  IF output # NIL THEN output.Close END
END Limit;

(* the 15 inputs checked with each of the three flags *)
PROCEDURE Base(i: LONGINT);
VAR c: ARRAY 2 OF CHAR;
BEGIN
  CASE i OF
    0: Rep("<r>", 10000); Rep("</r>", 10000)
  | 1: W("<!DOCTYPE r [<!ELEMENT r "); Rep("(", 10000); W("r"); Rep(")", 10000); W(">]><r/>")
  | 2: W("<!DOCTYPE r [<!ELEMENT r ("); Join("r", "", ",", 10000); W(")>]><r/>")
  | 3: Expansion(12, 10)
  | 4: Expansion(10000, 1)
  | 5: W('<r a="'); Xs(MB + 1); W('"/>')
  | 6: W("<r>"); Xs(16 * MB); W("</r>")
  | 7: W("<"); Xs(16 * MB); W("/>")
  | 8: W("<r "); Join("a", '=""', " ", 100000); W("/>")
  | 9: W("<r>"); Rep("<s/>", 100000); W("</r>")
  | 10: W("<r>"); c[0] := 01X; c[1] := 0X; Rep(c, 200000); W("</r>")
  | 11: W("<r>"); Rep("&#xZ;", 200000); W("</r>")
  | 12: W('<!DOCTYPE r SYSTEM "external.dtd"><r/>')
  | 13: W('<!DOCTYPE r SYSTEM "parameters.dtd"><r/>')
  | 14: W('<!DOCTYPE r SYSTEM "internalize.dtd"><r/>')
  END
END Base;

PROCEDURE BaseName(i: LONGINT; VAR name, flags, diag: ARRAY OF CHAR);
BEGIN
  flags[0] := 0X;
  CASE i OF
    0: COPY("zq_elements", name); COPY("nesting", diag)
  | 1: COPY("zq_model-depth", name); COPY("nesting", diag)
  | 2: COPY("zq_model-width", name); COPY("content-model", diag)
  | 3: COPY("zq_unused-entities", name); COPY("limit exceeded", diag)
  | 4: COPY("zq_entity-chain", name); COPY("limit exceeded", diag)
  | 5: COPY("zq_attribute", name); COPY("attribute value", diag)
  | 6: COPY("zq_input", name); COPY("input byte", diag)
  | 7: COPY("zq_long-name", name); COPY("input byte", diag)
  | 8: COPY("zq_many-attributes", name); COPY("limit exceeded", diag)
  | 9: COPY("zq_siblings", name); COPY("processing work", diag)
  | 10: COPY("zq_invalid-controls", name); COPY("processing work", diag)
  | 11: COPY("zq_invalid-charrefs", name); COPY("processing work", diag)
  | 12: COPY("zq_conditional-depth", name); COPY("e", flags); COPY("nesting", diag)
  | 13: COPY("zq_parameter-expansion", name); COPY("e", flags); COPY("limit exceeded", diag)
  | 14: COPY("zq_internalize", name); COPY("e", flags); COPY("input byte", diag)
  END
END BaseName;

PROCEDURE Append(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
VAR i, k: LONGINT;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  k := 0; WHILE (t[k] # 0X) & (i < LEN(s) - 1) DO s[i] := t[k]; INC(i); INC(k) END;
  s[i] := 0X
END Append;

PROCEDURE Extra(i: LONGINT; VAR name, flags, diag: ARRAY OF CHAR);
VAR k: LONGINT;
BEGIN
  COPY("processing work", diag);
  CASE i OF
    0: COPY("zq_validation-idrefs", name); COPY("v", flags);
      W('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a IDREFS #IMPLIED>]><r a="');
      Join("id", "", " ", 10000); W('"/>')
  | 1: COPY("zq_validation-enumeration", name); COPY("v", flags);
      W("<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a ("); Join("t", "", "|", 10000); W(") #IMPLIED>]><r/>")
  | 2: COPY("zq_validation-closure", name); COPY("v", flags);
      W("<!DOCTYPE r [<!ELEMENT r ("); Join("a", "?", "|", 200); W(")>]><r/>")
  | 3: COPY("zq_validation-aggregate", name); COPY("v", flags);
      W("<!DOCTYPE r ["); k := 0;
      WHILE k < 100 DO W("<!ELEMENT e"); Int(k); W(" ("); Join("a", "?", "|", 40); W(")>"); INC(k) END;
      W("<!ELEMENT r EMPTY>]><r/>")
  | 4: COPY("zq_namespace-search", name); COPY("n", flags); k := 0;
      WHILE k < 100 DO W("<r xmlns:p"); Int(k); W('="urn:p'); Int(k); W('">'); INC(k) END;
      W("<r "); Join("p0:a", '=""', " ", 300); W("/>"); Rep("</r>", 100)
  | 5: COPY("zq_canonical-notations", name); COPY("s", flags);
      W("<!DOCTYPE r ["); k := 0;
      WHILE k < 3000 DO W("<!NOTATION n"); Int(k); W(' SYSTEM "n'); Int(k); W('">'); INC(k) END;
      W("]><r/>")
  | 6: COPY("zq_canonical-output", name); COPY("c", flags); COPY("output byte", diag);
      W("<r>"); Rep(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>", 4 * MB DIV 64); W("</r>")
  | 7: COPY("zq_protocol-output", name); COPY("p", flags); COPY("output byte", diag);
      W("<r>"); Rep(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>", 4 * MB DIV 64); W("</r>")
  END
END Extra;

(* the files the external DTDs of the inputs 12 to 14 refer to *)
PROCEDURE Externals;
VAR i: LONGINT;
BEGIN
  Open("external.dtd"); Rep("<![INCLUDE[", 10000); Rep("]]>", 10000); Close;
  Open("parameters.dtd"); W('<!ENTITY % p0 "x">'); i := 1;
  WHILE i < 30 DO W("<!ENTITY % p"); Int(i); W(' "'); W("%p"); Int(i - 1); W(";%p"); Int(i - 1); W(';">'); INC(i) END;
  Close;
  Open("large.ent"); Xs(16 * MB); Close;
  Open("internalize.dtd"); W('<!ENTITY % p SYSTEM "large.ent"><!ENTITY e "%p;">'); Close
END Externals;

PROCEDURE Limits*;
VAR i, k: LONGINT; name, file, flags, diag, fl: ARRAY 64 OF CHAR;
BEGIN
  checks := 0; failed := 0; Externals; i := 0;
  WHILE i < 15 DO
    BaseName(i, name, flags, diag); COPY(name, file); Append(file, ".xml");
    Open(file); Base(i); Close;
    k := 0;
    WHILE k < 3 DO
      COPY(flags, fl); IF k = 1 THEN Append(fl, "n") ELSIF k = 2 THEN Append(fl, "v") END;
      Limit(file, fl, diag); INC(k)
    END;
    INC(i)
  END;
  i := 0;
  WHILE i < 8 DO
    Open("zq_extra.xml"); Extra(i, name, flags, diag); Close;
    COPY("zq_extra.xml", file); Limit(file, flags, diag); INC(i)
  END;
  i := 0;
  WHILE i < 15 DO BaseName(i, name, flags, diag); Append(name, ".xml"); Delete(name); INC(i) END;
  Delete("zq_extra.xml"); Delete("external.dtd"); Delete("parameters.dtd"); Delete("large.ent");
  Delete("internalize.dtd");
  out.String("XMLStress.Limits: "); out.Int(checks, 0); out.String(" checks, ");
  out.Int(failed, 0); out.String(" failed"); out.Ln
END Limits;

(* fuzzing *)

(* the next number of the minimal standard generator (Park and Miller), Schrage's method *)
PROCEDURE Next(): LONGINT;
CONST a = 16807; m = 2147483647; q = 127773; r = 2836;
VAR hi, lo: LONGINT;
BEGIN
  hi := seed DIV q; lo := seed MOD q;
  seed := a * lo - r * hi;
  IF seed <= 0 THEN seed := seed + m END;
  RETURN seed
END Next;

(* a number from 0 to n-1 *)
PROCEDURE Below(n: LONGINT): LONGINT;
BEGIN RETURN Next() MOD n
END Below;

PROCEDURE Doc(i: LONGINT; s: ARRAY OF CHAR);
VAR k: LONGINT;
BEGIN
  k := 0; WHILE s[k] # 0X DO docs[i, k] := s[k]; INC(k) END;
  docLen[i] := k
END Doc;

PROCEDURE Docs;
VAR s: ARRAY 64 OF CHAR;
BEGIN
  Doc(0, "<r/>");
  Doc(1, '<?xml version="1.0"?><r a="x">text<!--comment--><?pi x?></r>');
  Doc(2, '<!DOCTYPE r [<!ELEMENT r (s*)><!ELEMENT s EMPTY><!ATTLIST s a ID #IMPLIED>]><r><s a="x"/></r>');
  Doc(3, '<!DOCTYPE r [<!ENTITY a "text"><!ENTITY b "&a;&a;">]><r a="&b;">&b;</r>');
  Doc(4, '<r xmlns="urn:test" xmlns:p="urn:p" p:a="x"><p:s/><![CDATA[a<b]]></r>');
  (* <U+0531 a="U+1F642">&#x1F642;&#13;U+0531</U+0531> in UTF-8 *)
  s := '<__ a="____">&#x1F642;&#13;__</__>';
  s[1] := 0D4X; s[2] := 0B1X; s[7] := 0F0X; s[8] := 09FX; s[9] := 099X; s[10] := 082X;
  s[27] := 0D4X; s[28] := 0B1X; s[31] := 0D4X; s[32] := 0B1X;
  Doc(5, s);
  Doc(6, '<!DOCTYPE r [<!NOTATION n SYSTEM "n"><!ENTITY u SYSTEM "u" NDATA n>]><r/>')
END Docs;

(* check text[0..len) in the five modes: accepted or rejected, nothing else *)
PROCEDURE Fuzz1;
VAR i: LONGINT; k, r: INTEGER; name: ARRAY 16 OF CHAR; fl: ARRAY 2 OF CHAR; modes: ARRAY 8 OF CHAR;
  output: Mem.Channel; msg: M.Msg;
BEGIN
  modes := "-nvcp"; Open("zq_fuzz.xml"); i := 0; WHILE i < len DO Files.Write(R, text[i]); INC(i) END; Close;
  k := 0;
  WHILE k < 5 DO
    INC(checks); name := "zq_fuzz.xml"; fl[0] := modes[k]; fl[1] := 0X;
    r := X.Check(name, Flags(fl), output, msg);
    IF (r # X.accepted) & (r # X.rejected) THEN
      INC(failed); out.String("FAIL mode "); out.String(fl); out.String(", result "); out.Int(r, 0);
      out.String(", input:"); i := 0;
      WHILE i < len DO out.Char(" "); out.Hex(ORD(text[i]), 2); INC(i) END; out.Ln
    END;
    IF output # NIL THEN output.Close END;
    INC(k)
  END
END Fuzz1;

PROCEDURE Fuzz*;
VAR i, n, k, start, end, cnt, j: LONGINT; rest: ARRAY Max OF CHAR; restLen: LONGINT;
  alpha: ARRAY 40 OF CHAR; alphaLen: LONGINT;
BEGIN
  checks := 0; failed := 0; seed := 20261025; Docs;
  alpha := '<>!?[]()/&;="%-:abc012 '; alphaLen := 0; WHILE alpha[alphaLen] # 0X DO INC(alphaLen) END;
  alpha[alphaLen] := 27X; INC(alphaLen);  (* ' *)
  alpha[alphaLen] := 09X; alpha[alphaLen + 1] := 0DX; alpha[alphaLen + 2] := 0AX;
  alpha[alphaLen + 3] := 0X; alpha[alphaLen + 4] := 01X; alpha[alphaLen + 5] := 80X;
  alpha[alphaLen + 6] := 0FFX; INC(alphaLen, 7);
  len := 0; Fuzz1;
  text[0] := 0X; len := 1; Fuzz1;
  text[0] := 0FFX; text[1] := 0FEX; len := 2; Fuzz1;
  text[0] := 0FEX; text[1] := 0FFX; len := 2; Fuzz1;
  text[0] := 0EFX; text[1] := 0BBX; text[2] := 0BFX; len := 3; Fuzz1;
  i := 0;
  WHILE i < 7 DO  (* every prefix of every document *)
    n := 1;
    WHILE n <= docLen[i] DO
      k := 0; WHILE k < n DO text[k] := docs[i, k]; INC(k) END; len := n; Fuzz1; INC(n)
    END;
    INC(i)
  END;
  j := 0;
  WHILE j < 160 DO  (* mutations: up to 8 stretches of a document replaced by random bytes *)
    i := Below(7); len := docLen[i];
    k := 0; WHILE k < len DO text[k] := docs[i, k]; INC(k) END;
    cnt := 1 + Below(8);
    WHILE cnt > 0 DO
      start := Below(len + 1); end := start + Below(12); IF end > len THEN end := len END;
      restLen := len - end; k := 0; WHILE k < restLen DO rest[k] := text[end + k]; INC(k) END;
      n := Below(12); IF start + n + restLen > Max THEN n := Max - start - restLen END;
      k := 0; WHILE k < n DO text[start + k] := alpha[Below(alphaLen)]; INC(k) END;
      k := 0; WHILE k < restLen DO text[start + n + k] := rest[k]; INC(k) END;
      len := start + n + restLen; DEC(cnt)
    END;
    Fuzz1; INC(j)
  END;
  Delete("zq_fuzz.xml");
  out.String("XMLStress.Fuzz: "); out.Int(checks, 0); out.String(" checks, ");
  out.Int(failed, 0); out.String(" failed"); out.Ln
END Fuzz;

BEGIN
  xs := ""; seed := 1;
  WHILE seed <= LEN(xs) DO xs[seed - 1] := "x"; INC(seed) END
END XMLStress.
