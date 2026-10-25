MODULE XMLConformance;  (* runs the XML conformance cases of a list with XMLCheck0 *)

(* XMLConformance.Run list ... reads the cases of each list, one per line:

     code flags file [reference]

   code is the expected result of XMLCheck0.Check (0 accepted, 1 rejected), flags a word of the
   letters e (external), n (namespaces), v (validate), c (canonical), s (second), p (protocol), or
   "-" for none; the output of an accepted case is compared with the bytes of the reference
   file. Lines starting with # are comments. Paths are relative to the current directory. *)

IMPORT Files, Texts, out, IntStr, Str := oocStrings, M := Msg, Mem := IOMemory, X := XMLCheck0;

CONST Max = 512;

VAR checks, failed: LONGINT;

PROCEDURE Fail(VAR line: ARRAY OF CHAR; why: ARRAY OF CHAR);
BEGIN
  INC(failed); out.String("FAIL "); out.String(line); out.String(": "); out.String(why); out.Ln
END Fail;

(* does the output of ch have the bytes of the file ref; why says where they differ *)
PROCEDURE Same(ch: Mem.Channel; VAR ref: ARRAY OF CHAR; VAR why: ARRAY OF CHAR): BOOLEAN;
VAR f: Files.File; R: Files.Rider; n, len, i: LONGINT; c: CHAR; s: ARRAY 16 OF CHAR;
BEGIN
  f := Files.Old(ref);
  IF f = NIL THEN COPY("no reference file", why); RETURN FALSE END;
  len := Files.Length(f);
  IF ch = NIL THEN n := 0 ELSE n := ch.Length() END;
  Files.Set(R, f, 0); i := 0;
  WHILE (i < len) & (i < n) DO
    Files.Read(R, c);
    IF c # ch.file.data[i] THEN
      COPY("bytes differ at ", why); IntStr.IntToStr(i, s); Str.Append(s, why); RETURN FALSE
    END;
    INC(i)
  END;
  IF len # n THEN
    COPY("lengths differ, output ", why); IntStr.IntToStr(n, s); Str.Append(s, why);
    Str.Append(", reference ", why); IntStr.IntToStr(len, s); Str.Append(s, why);
    RETURN FALSE
  END;
  RETURN TRUE
END Same;

(* the next word of line from i on; FALSE at the end *)
PROCEDURE Word(VAR line: ARRAY OF CHAR; VAR i: LONGINT; VAR w: ARRAY OF CHAR): BOOLEAN;
VAR k: LONGINT;
BEGIN
  WHILE (line[i] = " ") OR (line[i] = 09X) DO INC(i) END;
  k := 0;
  WHILE (line[i] # 0X) & (line[i] # " ") & (line[i] # 09X) DO
    IF k < LEN(w) - 1 THEN w[k] := line[i]; INC(k) END;
    INC(i)
  END;
  w[k] := 0X;
  RETURN k > 0
END Word;

PROCEDURE Case(VAR line: ARRAY OF CHAR);
VAR i, k: LONGINT; code, flags, file, ref, why: ARRAY Max OF CHAR; set: SET; r: INTEGER;
  output: Mem.Channel; msg: M.Msg; text: ARRAY 256 OF CHAR;
BEGIN
  i := 0;
  IF ~Word(line, i, code) OR (code[0] = "#") THEN RETURN END;
  IF ~Word(line, i, flags) OR ~Word(line, i, file) THEN INC(checks); Fail(line, "incomplete line"); RETURN END;
  IF ~Word(line, i, ref) THEN ref := "" END;
  INC(checks);
  set := {}; k := 0;
  WHILE flags[k] # 0X DO
    CASE flags[k] OF
      "e": INCL(set, X.external)
    | "n": INCL(set, X.namespaces)
    | "v": INCL(set, X.validate)
    | "c": INCL(set, X.canonical)
    | "s": INCL(set, X.second)
    | "p": INCL(set, X.protocol)
    ELSE
    END;
    INC(k)
  END;
  r := X.Check(file, set, output, msg);
  IF r # ORD(code[0]) - ORD("0") THEN
    COPY("result ", why); text[0] := CHR(ORD("0") + r); text[1] := 0X; Str.Append(text, why);
    IF msg # NIL THEN msg.GetText(text); Str.Append(", ", why); Str.Append(text, why) END;
    Fail(line, why);
    IF (r = X.rejected) & (output # NIL) THEN
      k := 0; WHILE (k < output.Length()) & (k < 400) DO out.Char(output.file.data[k]); INC(k) END; out.Ln
    END
  ELSIF (r = X.accepted) & (ref # "") & ~Same(output, ref, why) THEN Fail(line, why)
  END;
  IF output # NIL THEN output.Close END
END Case;

PROCEDURE RunList(VAR name: ARRAY OF CHAR);
VAR f: Files.File; R: Files.Rider; line: ARRAY 2 * Max OF CHAR; c: CHAR; n: LONGINT;
BEGIN
  checks := 0; failed := 0;
  f := Files.Old(name);
  IF f = NIL THEN out.String("FAIL no list "); out.String(name); out.Ln; RETURN END;
  Files.Set(R, f, 0); Files.Read(R, c);
  WHILE ~R.eof DO
    n := 0;
    WHILE ~R.eof & (c # 0AX) & (c # 0DX) DO
      IF n < LEN(line) - 1 THEN line[n] := c; INC(n) END;
      Files.Read(R, c)
    END;
    line[n] := 0X;
    IF n > 0 THEN Case(line) END;
    IF ~R.eof THEN Files.Read(R, c) END
  END;
  out.String("XMLConformance "); out.String(name); out.String(": ");
  out.Int(checks, 0); out.String(" checks, "); out.Int(failed, 0); out.String(" failed"); out.Ln
END RunList;

(* XMLConformance.Run list ... *)
PROCEDURE Run*;
VAR A: Texts.Reader; name: ARRAY Max OF CHAR; any: BOOLEAN;
BEGIN
  Texts.OpenArgs(A); any := FALSE;
  WHILE Texts.Arg(A, name) DO any := TRUE; RunList(name) END;
  IF ~any THEN out.String("usage: XMLConformance.Run list ..."); out.Ln END
END Run;

END XMLConformance.
