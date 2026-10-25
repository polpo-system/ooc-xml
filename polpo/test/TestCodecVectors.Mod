(* the 114 codec vectors of ooc-libxml's src/TestCodecs.Mod, each decoded or encoded twice, with
   the whole output buffer and with a bounded one; written from src/TestCodecs.Mod by
   tests/voc/check-codecs.py *)
MODULE TestCodecVectors;
IMPORT Out, UC := XMLUnicodeCodec, XMLUnicodeCodecImportAll;
VAR count: LONGINT;

PROCEDURE Hex(ch: CHAR): LONGINT;
BEGIN
  IF (ch >= "0") & (ch <= "9") THEN RETURN ORD(ch)-ORD("0") END;
  RETURN ORD(CAP(ch))-ORD("A")+10
END Hex;

PROCEDURE Check(encoding, source, expected: ARRAY OF CHAR; encode, bom: BOOLEAN; errors: LONGINT);
  VAR input, output, reference: ARRAY 256 OF CHAR;
    units, decoded, wanted: ARRAY 256 OF UC.Char;
    codec: UC.Codec; factory: UC.Factory;
    sourceLength, expectedLength, n, i, start, done, written, limit, window, pass: LONGINT;

  PROCEDURE Parse(text: ARRAY OF CHAR; width: LONGINT; source: BOOLEAN): LONGINT;
    VAR i, digits, value, n: LONGINT;
  BEGIN
    i := 0; digits := 0; value := 0; n := 0;
    WHILE text[i] # 0X DO
      IF text[i] # " " THEN
        value := value*16+Hex(text[i]); INC(digits);
        IF digits = width THEN
          IF source THEN
            IF encode THEN units[n] := value ELSE input[n] := CHR(value) END
          ELSE
            IF encode THEN reference[n] := CHR(value) ELSE wanted[n] := value END
          END;
          INC(n); value := 0; digits := 0
        END
      END;
      INC(i)
    END;
    ASSERT(digits = 0, 201); RETURN n
  END Parse;

BEGIN
  factory := UC.GetFactory(encoding); ASSERT(factory # NIL, 202);
  IF encode THEN sourceLength := Parse(source, 4, TRUE); expectedLength := Parse(expected, 2, FALSE)
  ELSE sourceLength := Parse(source, 2, TRUE); expectedLength := Parse(expected, 4, FALSE)
  END;
  FOR pass := 0 TO 1 DO
    start := 0; written := 0;
    IF encode THEN
      codec := factory.NewCodec();
      IF bom THEN codec.EncodeBOM(output, 0, LEN(output), written) END;
      window := UC.maxUTF8EncodingLength
    ELSE
      IF bom THEN codec := factory.NewCodecBOM(input, 0, sourceLength, start)
      ELSE codec := factory.NewCodec()
      END;
      window := UC.maxUCS2EncodingLength
    END;
    IF pass = 0 THEN window := 128 END;
    WHILE start < sourceLength DO
      limit := written+window;
      IF encode THEN
        codec.Encode(units, start, sourceLength, output, written, limit, done, n)
      ELSE
        codec.Decode(input, start, sourceLength, decoded, written, limit, done, n)
      END;
      ASSERT((done > start) & (done <= sourceLength) & (n > written) & (n <= limit), 203);
      start := done; written := n
    END;
    IF (written # expectedLength) OR (codec.invalidChars # errors) THEN
      Out.String(encoding); Out.String(" vector "); Out.Int(count, 0); Out.String(": ");
      Out.String(source); Out.Ln
    END;
    ASSERT((written = expectedLength) & (codec.invalidChars = errors), 204);
    FOR i := 0 TO expectedLength-1 DO
      IF encode THEN ASSERT(output[i] = reference[i], 205)
      ELSE ASSERT(decoded[i] = wanted[i], 206)
      END
    END
  END;
  INC(count)
END Check;

BEGIN
  count := 0;
  Check("LATIN1", "0020", "20", TRUE, FALSE, 0);
  Check("LATIN1", "0000", "00", TRUE, FALSE, 0);
  Check("LATIN1", "00FF", "FF", TRUE, FALSE, 0);
  Check("LATIN1", "0000 00FF", "00 FF", TRUE, FALSE, 0);
  Check("LATIN1", "0000 00FF", "00 FF", TRUE, TRUE, 0);
  Check("LATIN1", "0100", "3F", TRUE, FALSE, 1);
  Check("LATIN1", "1000 FFFF", "3F3F", TRUE, FALSE, 2);
  Check("LATIN1", "1000 0020 FFFF", "3F 20 3F", TRUE, FALSE, 2);
  Check("LATIN1", "D800 DC00 0020", "3F 20", TRUE, FALSE, 1);
  Check("LATIN1", "0020 D800 DC00", "20 3F", TRUE, FALSE, 1);
  Check("LATIN1", "0020 D800 D800 0020", "20 3F 3F 20", TRUE, FALSE, 2);
  Check("LATIN1", "0020 D800 D800", "20 3F 3F", TRUE, FALSE, 2);
  Check("LATIN1", "0020 DC00 D800", "20 3F 3F", TRUE, FALSE, 2);
  Check("LATIN1", "0020 0100", "20 3F", TRUE, FALSE, 1);
  Check("LATIN1", "0020 D800", "20 3F", TRUE, FALSE, 1);
  Check("LATIN1", "0020 DC00", "20 3F", TRUE, FALSE, 1);
  Check("LATIN1", "20", "0020", FALSE, FALSE, 0);
  Check("LATIN1", "00", "0000", FALSE, FALSE, 0);
  Check("LATIN1", "FF", "00FF", FALSE, FALSE, 0);
  Check("LATIN1", "FF", "00FF", FALSE, TRUE, 0);
  Check("ASCII", "0020", "20", TRUE, FALSE, 0);
  Check("ASCII", "0000", "00", TRUE, FALSE, 0);
  Check("ASCII", "007F", "7F", TRUE, FALSE, 0);
  Check("ASCII", "0000 007F", "00 7F", TRUE, FALSE, 0);
  Check("ASCII", "0080", "3F", TRUE, FALSE, 1);
  Check("ASCII", "1000 FFFF", "3F 3F", TRUE, FALSE, 2);
  Check("ASCII", "1000 0020 FFFF", "3F 20 3F", TRUE, FALSE, 2);
  Check("ASCII", "D800 DC00 0020", "3F 20", TRUE, FALSE, 1);
  Check("ASCII", "0020 D800 DC00", "20 3F", TRUE, FALSE, 1);
  Check("ASCII", "0020 D800 D800 0020", "20 3F 3F 20", TRUE, FALSE, 2);
  Check("ASCII", "0020 D800 D800", "20 3F 3F", TRUE, FALSE, 2);
  Check("ASCII", "0020 DC00 D800", "20 3F 3F", TRUE, FALSE, 2);
  Check("ASCII", "0020 0100", "20 3F", TRUE, FALSE, 1);
  Check("ASCII", "0020 D800", "20 3F", TRUE, FALSE, 1);
  Check("ASCII", "0020 DC00", "20 3F", TRUE, FALSE, 1);
  Check("ASCII", "20", "0020", FALSE, FALSE, 0);
  Check("ASCII", "00", "0000", FALSE, FALSE, 0);
  Check("ASCII", "7F", "007F", FALSE, FALSE, 0);
  Check("ASCII", "80", "FFFD", FALSE, FALSE, 1);
  Check("ASCII", "80 20 FF", "FFFD 0020 FFFD", FALSE, FALSE, 2);
  Check("UTF-16BE", "D808 DF45 003D 0052 0061", "D808 DF45 003D 0052 0061", TRUE, FALSE, 0);
  Check("UTF-16LE", "D808 DF45 003D 0052 0061", "08D8 45DF 3D00 5200 6100", TRUE, FALSE, 0);
  Check("UTF-16LE", "D808 0020", "3F00 2000", TRUE, FALSE, 1);
  Check("UTF-16LE", "D808 E000", "3F00 00E0", TRUE, FALSE, 1);
  Check("UTF-16LE", "D808 D808", "3F00 3F00", TRUE, FALSE, 2);
  Check("UTF-16LE", "DC08 D808", "3F00 3F00", TRUE, FALSE, 2);
  Check("UTF-16LE", "DC08", "3F00", TRUE, FALSE, 1);
  Check("UTF-16LE", "FFFE", "3F00", TRUE, FALSE, 1);
  Check("UTF-16LE", "FFFF", "3F00", TRUE, FALSE, 1);
  Check("UTF-16BE", "D808 0020", "003F 0020", TRUE, FALSE, 1);
  Check("UTF-16BE", "D808 E000", "003F E000", TRUE, FALSE, 1);
  Check("UTF-16BE", "D808 D808", "003F 003F", TRUE, FALSE, 2);
  Check("UTF-16BE", "DC08 D808", "003F 003F", TRUE, FALSE, 2);
  Check("UTF-16BE", "DC08", "003F", TRUE, FALSE, 1);
  Check("UTF-16LE", "D808 DF45 003D 0052 0061", "08D8 45DF 3D00 5200 6100", TRUE, TRUE, 0);
  Check("UTF-16", "D808 DF45 003D 0052 0061", "FEFF D808 DF45 003D 0052 0061", TRUE, TRUE, 0);
  Check("UTF-16BE", "D808 DF45 003D 0052 0061", "D808 DF45 003D 0052 0061", FALSE, FALSE, 0);
  Check("UTF-16LE", "08D8 DF", "FFFD", FALSE, FALSE, 1);
  Check("UTF-16BE", "D808 DF", "FFFD", FALSE, FALSE, 1);
  Check("UTF-16LE", "2000 D0", "0020 FFFD", FALSE, FALSE, 1);
  Check("UTF-16BE", "2000 D9", "2000 FFFD", FALSE, FALSE, 1);
  Check("UTF-16LE", "00DC", "FFFD", FALSE, FALSE, 1);
  Check("UTF-16BE", "DC00", "FFFD", FALSE, FALSE, 1);
  Check("UTF-16BE", "FFFE", "FFFD", FALSE, FALSE, 1);
  Check("UTF-16BE", "FFFF", "FFFD", FALSE, FALSE, 1);
  Check("UTF-16LE", "08D8 45DF 3D00 5200 6100", "D808 DF45 003D 0052 0061", FALSE, FALSE, 0);
  Check("UTF-16LE", "08D8 45DF 3D00 5200 6100", "D808 DF45 003D 0052 0061", FALSE, TRUE, 0);
  Check("UTF-16", "D808 DF45 003D 0052 0061", "D808 DF45 003D 0052 0061", FALSE, FALSE, 0);
  Check("UTF-16", "FEFF D808 DF45 003D 0052 0061", "FEFF D808 DF45 003D 0052 0061", FALSE, FALSE, 0);
  Check("UTF-16", "FEFF D808 DF45 003D 0052 0061", "D808 DF45 003D 0052 0061", FALSE, TRUE, 0);
  Check("UTF-16", "FFFE 08D8 45DF 3D00 5200 6100", "D808 DF45 003D 0052 0061", FALSE, TRUE, 0);
  Check("UTF-8", "0041 2262 0391 002E", "41 E2 89 A2 CE 91 2E", TRUE, FALSE, 0);
  Check("UTF-8", "D55C AD6D C5B4", "ED 95 9C EA B5 AD EC 96 B4", TRUE, FALSE, 0);
  Check("UTF-8", "65E5 672C 8A9E", "E6 97 A5 E6 9C AC E8 AA 9E", TRUE, FALSE, 0);
  Check("UTF-8", "D800 DC00 007F", "F0 90 80 80 7F", TRUE, FALSE, 0);
  Check("UTF-8", "DBFF DFFD 007F", "F4 8F BF BD 7F", TRUE, FALSE, 0);
  Check("UTF-8", "0020 0800 0020", "20 E0 A0 80 20", TRUE, FALSE, 0);
  Check("UTF-8", "0020 0800", "20 E0 A0 80", TRUE, FALSE, 0);
  Check("UTF-8", "0020 FFFD 0020", "20 EF BF BD 20", TRUE, FALSE, 0);
  Check("UTF-8", "0020 FFFD", "20 EF BF BD", TRUE, FALSE, 0);
  Check("UTF-8", "0020 D800 0020", "20 3F 20", TRUE, FALSE, 1);
  Check("UTF-8", "0020 DC00 0020", "20 3F 20", TRUE, FALSE, 1);
  Check("UTF-8", "0020 D800", "20 3F", TRUE, FALSE, 1);
  Check("UTF-8", "D800", "3F", TRUE, FALSE, 1);
  Check("UTF-8", "FFFE", "3F", TRUE, FALSE, 1);
  Check("UTF-8", "FFFF", "3F", TRUE, FALSE, 1);
  Check("UTF-8", "41 E2 89 A2 CE 91 2E", "0041 2262 0391 002E", FALSE, FALSE, 0);
  Check("UTF-8", "ED 95 9C EA B5 AD EC 96 B4", "D55C AD6D C5B4", FALSE, FALSE, 0);
  Check("UTF-8", "E6 97 A5 E6 9C AC E8 AA 9E", "65E5 672C 8A9E", FALSE, FALSE, 0);
  Check("UTF-8", "F0 90 80 80 7F", "D800 DC00 007F", FALSE, FALSE, 0);
  Check("UTF-8", "F4 8F BF BD 7F", "DBFF DFFD 007F", FALSE, FALSE, 0);
  Check("UTF-8", "20 E0 A0 80 20", "0020 0800 0020", FALSE, FALSE, 0);
  Check("UTF-8", "20 E0 A0 80", "0020 0800", FALSE, FALSE, 0);
  Check("UTF-8", "20 EF BF BD 20", "0020 FFFD 0020", FALSE, FALSE, 0);
  Check("UTF-8", "20 EF BF BD", "0020 FFFD", FALSE, FALSE, 0);
  Check("UTF-8", "20 80 80 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 80 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 D0 C0 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 C0 80 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 FE 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 FF 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 ED A0 80 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 ED BF BF 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 E0 9F BF 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 F0 8F BF BF 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 F8 87 BF BF BF 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 FC 83 BF BF BF BF 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 E0 C0 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "20 E0 00 20", "0020 FFFD 0020", FALSE, FALSE, 1);
  Check("UTF-8", "41 E2 89", "0041 FFFD", FALSE, FALSE, 1);
  Check("UTF-8", "41 E2", "0041 FFFD", FALSE, FALSE, 1);
  Check("UTF-8", "F4 8F BF", "FFFD", FALSE, FALSE, 1);
  Check("UTF-8", "EF BF BE", "FFFD", FALSE, FALSE, 1);
  Check("UTF-8", "EF BF BF", "FFFD", FALSE, FALSE, 1);
  Out.Int(count, 0); Out.String(" original codec vectors passed (full and bounded output)"); Out.Ln
END TestCodecVectors.
