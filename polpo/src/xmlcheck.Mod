MODULE xmlcheck;  (** checks XML documents with the parser of ooc-xml *)

IMPORT Texts, out, M := Msg, Mem := IOMemory, X := XMLCheck0;

CONST Max = 1024;

PROCEDURE Ln(s: ARRAY OF CHAR);
BEGIN out.String(s); out.Ln
END Ln;

PROCEDURE Help*;
BEGIN
  Ln("xmlcheck: checks XML documents (ooc-libxml of Michael van Acken)");
  Ln("  xmlcheck.Check [options] file ...   parses each file; says accepted, or lists its errors");
  Ln("options (before the files):");
  Ln("  /external     follows references to external entities and the external DTD");
  Ln("  /namespaces   checks namespaces and qualified names");
  Ln("  /validate     validates against the DTD (also /external)");
  Ln("  /canonical    writes the document in the first canonical form (James Clark's)");
  Ln("  /second       writes the second canonical form (with notations)");
  Ln("  /protocol     writes the callbacks of the parser as XML");
  Ln("  The last three write UTF-8; only one of them, and /namespaces only with /protocol.");
  Ln("examples:");
  Ln("  xmlcheck.Check doc.xml");
  Ln("  xmlcheck.Check /validate /namespaces doc.xml");
  Ln("  xmlcheck.Check /canonical doc.xml")
END Help;

(* write the bytes of ch, LF as out.Ln *)
PROCEDURE Write(ch: Mem.Channel);
VAR i, n: LONGINT; c: CHAR;
BEGIN
  n := ch.Length(); i := 0;
  WHILE i < n DO
    c := ch.file.data[i];
    IF c = 0AX THEN out.Ln ELSE out.Char(c) END;
    INC(i)
  END
END Write;

(** xmlcheck.Check [options] file ... *)
PROCEDURE Check*;
VAR A: Texts.Reader; s: ARRAY Max OF CHAR; text: ARRAY 256 OF CHAR;
  flags: SET; files, r: INTEGER; output: Mem.Channel; msg: M.Msg; bad: BOOLEAN;
BEGIN
  Texts.OpenArgs(A); flags := {}; files := 0; bad := FALSE;
  WHILE ~bad & Texts.Arg(A, s) DO
    IF s[0] = "/" THEN
      IF s = "/external" THEN INCL(flags, X.external)
      ELSIF s = "/namespaces" THEN INCL(flags, X.namespaces)
      ELSIF s = "/validate" THEN INCL(flags, X.validate)
      ELSIF s = "/canonical" THEN INCL(flags, X.canonical)
      ELSIF s = "/second" THEN INCL(flags, X.second)
      ELSIF s = "/protocol" THEN INCL(flags, X.protocol)
      ELSE out.String("xmlcheck: unknown option "); Ln(s); bad := TRUE
      END
    ELSE
      INC(files);
      r := X.Check(s, flags, output, msg);
      IF (r = X.accepted) & (output # NIL) THEN Write(output)
      ELSIF r = X.accepted THEN out.String(s); Ln(": accepted")
      ELSIF r = X.rejected THEN out.String(s); Ln(": rejected"); Write(output)
      ELSE
        out.String(s); out.String(": ");
        IF msg # NIL THEN msg.GetText(text); Ln(text) ELSE Ln("cannot be checked with these options") END
      END;
      IF output # NIL THEN output.Close END
    END
  END;
  IF ~bad & (files = 0) THEN
    Ln("usage: xmlcheck.Check [/external] [/namespaces] [/validate] [/canonical|/second|/protocol] file ...");
    Ln("  checks the XML files; xmlcheck.Help explains the options")
  END
END Check;

END xmlcheck.
