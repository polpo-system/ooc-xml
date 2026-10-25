# ooc-xml

XML for [polpo](https://github.com/polpo-system/polpo): the XML parser, DTD validator, namespace
builders, Unicode codecs and XML writer of Michael van Acken's ooc-libxml 3.2.0, written for the
Optimizing Oberon-2 Compiler (OOC).

This repository continues [voc-ooc-xml](https://github.com/norayr/voc-ooc-xml), the port of the
library to [voc](https://github.com/norayr/voc). Its history starts with the CVS history of
ooc-libxml (the branches `upstream-cvs` and `upstream-cvs-MAIN`, the original release tags; see
[history/README.md](history/README.md)), followed by the voc port, which added resource limits
for hostile input and tested the library against the XML conformance suites
([doc/voc.md](doc/voc.md)). The commits after it adapt the library to polpo.

```
portia.Install ooc-xml
```

It runs on x86 only: the library is built on type-bound procedures, which the x86 compiler of
polpo compiles with /2 and the compilers of the other ports do not have. It needs the base
packages ooc-io and ooc-uri (channels, messages, files in memory, URI references) and LongStrings
of ooc-strings.

## Using

    xmlcheck.Check [options] file ...    accepted, or the errors with line and column
    xmlcheck.Help                        the options: /external /namespaces /validate
                                         /canonical /second /protocol

`polpo/tools/XMLCheck.Tool` (installed as `tools/XMLCheck.Tool`) describes the command.

In a program, import `XMLUnicodeCodecImportAll` to register the codecs (ASCII, Latin-1, UTF-8,
UTF-16). Names and character data are `oocUnicode.LONGCHAR`, UTF-16 code units kept in a LONGINT;
characters above U+FFFF are surrogate pairs, and positions and lengths count code units.

Extend `XMLBuilder.BuilderDesc` for the callbacks of the parser and call `XMLBuilder.Init` on the
builder. Create an `XMLLimits` budget and give the builder and the budget to
`XMLParser.NewReaderLimited`, `NewChannelLimited`, `NewURILimited` or `NewFileLimited`. Set
`parser.followExternalRef` before `ParseDocument`, and look at `parser.errList` before using the
results. The constructors without limits are still there and behave as in the original.

For namespaces, wrap the builder with `XMLBuilderNamespaces.New` and set `parser.enforceQNames`.
For validation, wrap that builder with `XMLBuilderValidation.New` and set `parser.validating`
(external references are needed when the DTD is external). `polpo/src/XMLCheck0.Mod` shows all
of it on one page.

The parser has limits against hostile input, but its review is not finished: parse documents
you trust. The documents in `doc/` describe the limits (`Security.md`), the conformance cases
(`Conformance.md`), writing XML (`WritingXML.md`) and the element objects of `XMLBasicParser`
(`BasicElements.md`); their build commands are those of voc.

## What is here

    src/XML/              the library, 24 modules (src/XML/Parser.Mod is XMLParser)
    tools/XMLCheck.Mod    the checking program of voc
    tests/                the conformance suites, the local fixtures, the voc tests and runners
    polpo/src/            XMLCheck0 (XMLCheck of voc as a procedure) and the command xmlcheck
    polpo/tools/          XMLCheck.Tool
    polpo/test/           the tests for polpo
    history/              the CVS history of ooc-libxml and how it was converted
    doc/                  the documents of the voc port

The other files (the oo2c build files, src/IO, src/OS, src/URI) belong to the original library
and the voc port; polpo builds only the modules of src/XML. Its URI modules and the rest of the
OOC library it uses come with polpo (src/lib/ooc).

The changes for polpo, after the voc port:

- XMLUnicodeCodec imports OakStrings as Strings (the Strings of voc; polpo's Strings is another
  module).
- XMLBuilderValidation calls its constant invalidStandaloneAttrNormalization
  invalidStandaloneAttrNormalize: the polpo compilers take identifiers of up to 31 characters.
- In the voc tests, assertion numbers below 20 have 200 added: the x86 compiler takes numbers
  from 20 to 255.

## Tests

The tests of the voc port, with Oberon commands in place of its Python runners:

    XMLTests.Run              the 12 voc test programs and TestCodecVectors (the 114 vectors of
                              src/TestCodecs.Mod): codecs, messages, memory channels, DTD and
                              entity resolution, the parser, namespaces, validation, the writer,
                              element objects, the protocol, external entities, resource limits
    XMLConformance.Run list   the cases of the lists, 2687 in all: well-formedness of James
                              Clark's xmltest and the namespace fixtures (384), canonical output
                              of xmltest, ibm and sun (339), validation with xmltest, ibm, sun and
                              oasis (1808), the local regressions and bulk outputs (126), the
                              protocol of the callbacks (30, run in protocol/ and namespaces/)
    XMLStress.Limits          53 hostile inputs, each rejected by its limit
    XMLStress.Fuzz            2845 checks of truncated and mutated documents

The lists carry the exclusions and corrected expectations of the voc runners, each with its
reason in a comment. The tests unpack the archives with `tar.Unpack`; portia runs them all after
`portia.Install /t ooc-xml`.

## License

The library is under the GNU Lesser General Public License, version 2 or later (the notices in
the files; `COPYING` is the text of version 2.1). The test suites in the archives keep their own
notices. The files written for polpo (in `polpo/`) are under the same terms.
