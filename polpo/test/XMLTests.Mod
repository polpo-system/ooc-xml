MODULE XMLTests;  (* loksh XMLTests.Run: the test programs of voc's xml port *)

(* Each test module checks its part in its body and writes a line when all its checks passed; an
   assertion that fails stops it with a trap. Importing them runs the bodies, in this order, when
   XMLTests is loaded. *)

IMPORT TestUnicodeCodecs, TestCodecVectors, TestUnicodeMessages, TestMemoryBuffers,
  TestDTDResolver, TestParser, TestNamespaces, TestValidation, TestWriter, TestBasic,
  TestProtocol, TestEntityPolicy, TestLimits, out;

PROCEDURE Run*;
BEGIN
  out.String("XMLTests: 13 test modules passed"); out.Ln
END Run;

END XMLTests.
