XMLCheck - checks XML documents with the parser of ooc-libxml (Michael van Acken)

  xmlcheck.Check [options] file ...    parses each file: "accepted", or its errors with line
                                       and column
  xmlcheck.Help                        the options and examples

The options come before the files:
  /external     follows references to external entities and reads the external DTD
  /namespaces   checks namespaces and qualified names
  /validate     validates against the DTD (reads external entities too)
  /canonical    writes the document in the first canonical form (James Clark's)
  /second       writes the second canonical form, with the notations
  /protocol     writes the callbacks of the parser as an XML document
Only one of the last three; /namespaces goes with /protocol, not with the canonical forms.
The output of the last three is UTF-8.

Examples:
  xmlcheck.Check doc.xml
  xmlcheck.Check /validate /namespaces doc.xml
  xmlcheck.Check /canonical doc.xml

In programs: XMLCheck0.Check(path, flags, output, msg) does the same and returns 0 (accepted),
1 (rejected, the errors in output) or 2 (the file cannot be read, msg says why). The library
itself is described in the README of the package (src/pkg/ooc-xml/README.md).
