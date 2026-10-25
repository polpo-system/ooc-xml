MODULE XMLCheck0;  (* checks an XML document: parses it, with options; the core of xmlcheck *)

(* XMLCheck of voc (tools/XMLCheck.Mod) as a procedure for polpo, with the same
   options and results: 0 the document is accepted, 1 the parser reported errors, 2 the file
   cannot be opened or the output cannot be written. The errors, or the canonical or protocol
   output, are left in a memory channel. *)

IMPORT M := Msg, Mem := IOMemory, B := XMLBuilder,
  N := XMLBuilderNamespaces, V := XMLBuilderValidation,
  Canon := XMLBuilderCanonical, C := XMLUnicodeCodec,
  Protocol := XMLBuilderParserProtocol, Limits := XMLLimits,
  P := XMLParser, XMLUnicodeCodecImportAll;

CONST
  external* = 0;  (* follow references to external entities *)
  namespaces* = 1;  (* namespaces, qualified names enforced *)
  validate* = 2;  (* validate against the DTD (follows external references) *)
  canonical* = 3;  (* write the first canonical form *)
  second* = 4;  (* write the second canonical form *)
  protocol* = 5;  (* write the protocol of the parser's callbacks *)

  accepted* = 0; rejected* = 1; failed* = 2;

(* checks the XML file path; output: the errors (rejected), the canonical or protocol output
   (accepted with one of canonical, second, protocol), NIL otherwise; msg: why it failed *)
PROCEDURE Check* (VAR path: ARRAY OF CHAR; flags: SET; VAR output: Mem.Channel; VAR msg: M.Msg): INTEGER;
VAR p: P.Parser; res: M.Msg; out: Mem.Channel; canon: Canon.Builder; proto: Protocol.Builder;
  builder: B.Builder; format: SHORTINT;
BEGIN
  output := NIL; msg := NIL; canon := NIL; proto := NIL; out := NIL; format := 0;
  IF canonical IN flags THEN format := Canon.firstCanonicalForm
  ELSIF second IN flags THEN format := Canon.secondCanonicalForm
  END;
  IF (format # 0) & ((protocol IN flags) OR (namespaces IN flags)) THEN RETURN failed END;
  builder := B.New();
  IF (format # 0) OR (protocol IN flags) THEN
    out := Mem.Tmp("", {Mem.read, Mem.write}, res);
    IF res # NIL THEN msg := res; RETURN failed END;
    IF protocol IN flags THEN
      proto := Protocol.New(out, C.GetFactory("UTF-8")); builder := proto
    ELSE
      canon := Canon.New(out, C.GetFactory("UTF-8"), format); builder := canon
    END
  END;
  IF namespaces IN flags THEN builder := N.New(builder) END;
  IF validate IN flags THEN builder := V.New(builder); INCL(flags, external) END;
  p := P.NewFileLimited(path, NIL, NIL, NIL, builder, Limits.New(), res);
  IF p = NIL THEN msg := res; RETURN failed END;
  p.followExternalRef := external IN flags; p.enforceQNames := namespaces IN flags;
  p.validating := validate IN flags; p.ParseDocument;
  IF p.errList.msgCount # 0 THEN
    IF out # NIL THEN out.Close END;
    out := Mem.Tmp("", {Mem.read, Mem.write}, res);
    p.errList.Write(out); output := out;
    RETURN rejected
  END;
  IF canon # NIL THEN
    IF (canon.out.writer.res # NIL) OR (canon.out.codec.invalidChars # 0) THEN out.Close; RETURN failed END
  ELSIF proto # NIL THEN
    IF (proto.w.writer.res # NIL) OR (proto.w.codec.invalidChars # 0) THEN out.Close; RETURN failed END
  END;
  output := out;
  RETURN accepted
END Check;

END XMLCheck0.
