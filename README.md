# ooc XML for VOC

This is a VOC port of Michael van Acken's **ooc-libxml**, the native
Oberon XML library for oo2c 1.x.

The original CVS history is the ancestry of this repository. The unmodified
CVS trunk and vendor branch are preserved as `upstream-cvs` and
`upstream-cvs-MAIN`; the original release tags are retained. VOC work belongs
on `main`, in commits following that import.

See [history/README.md](history/README.md) for the source archive, conversion
settings, revision map and verification results. The original oo2c build
instructions remain in [README](README).

## Porting scope

The target is VOC's **Oberon-2 (`-O2`)** type model. In particular, Unicode
characters must not be narrowed to its 8-bit `CHAR`, and native addresses
must not be stored in `LONGINT`.

### Building and using the library

The Unicode codecs, XML buffers, DTD data model, entity resolver, XML
parser, namespace builder, DTD validator, XML writer, canonical-output builder,
basic element interfaces and parser-protocol builder build with VOC:

```sh
make test
```

This requires VOC with the
[shared ooc and URI support](https://github.com/vishapoberon/compiler/commit/8e8edff2896e139e57b0f1e38ec57f2fa7d38765)
installed, including `LongStrings.Equal8`.
Use VOC commit `32cc3131` or later for long integer-attribute scans and the
isolated build's local-object selection.
These provide `oocUnicode`, `LongStrings`, Unicode-safe `Msg`, `Channel`,
`IOMemory`, `URIParser` and the file/memory URI schemes.
Their sources and unit tests live in VOC's `src/ports/ooc/` and confidence
tests. Rebuild VOC and its dependent modules together when updating this
package.

`XMLParser` reports document, element, attribute, text and DTD events through
`XMLBuilder`. Applications extend that builder to consume the events.
Wrap an application builder with `XMLBuilderNamespaces.New(builder)` and set
`parser.enforceQNames := TRUE` to receive namespace URIs and local names.
For DTD validation, wrap the resulting builder with
`XMLBuilderValidation.New(builder)` and set `parser.validating := TRUE`.
Enable external references when the document uses an external DTD.
`XMLWriter` generates XML with optional indentation and encoding declarations.
See [writing XML](doc/WritingXML.md) for its interfaces and output checks.
`XMLStream` accepts arbitrary UTF-8 byte chunks, retaining one bounded child
element and its opening stream's namespace context. It returns exact byte
consumption at each header/stanza/close boundary, supporting XMPP stream
restarts. See [incremental element streams](doc/Streaming.md).
The [basic element interfaces](doc/BasicElements.md) construct application
objects through element factories and typed attribute helpers.
`XMLUnicodeCodecImportAll` registers the bundled ASCII, Latin-1,
UTF-8 and UTF-16 encodings at startup. The codec source paths are unchanged so
the changes remain easy to compare with CVS.

`oocUnicode.LONGCHAR` is the shared type for UTF-16 code units. VOC and
standard Oberon-2 have no built-in `LONGCHAR`, so this alias uses `LONGINT`
storage for values in the original 0..65535 range. Supplementary characters
use surrogate pairs. `XMLUnicodeCodec.Char` uses this same type, and encoders
reject out-of-range values.

`LongStrings` supplies UTF-16 code-unit copying, editing, searching and
comparison. `Msg` preserves Unicode message attributes through `GetLText`.
Both are supplied by VOC's ooc package. Their original source baselines and
transfer provenance are recorded in
[history/oo2c-support.md](history/oo2c-support.md).

VOC's `Channel` uses this message interface. `IOMemory` provides
seekable, growable memory files. `XMLInputBuffer` reads bytes, and
`XMLUnicodeBuffer` decodes input and encodes buffered output. They support
short reads, partial writes, UTF-8/UTF-16 BOM handling and bounded operations.

The XML tests cover ASCII, Latin-1, Armenian, supplementary characters,
both UTF-16 byte orders, malformed/truncated input, buffer boundaries,
Unicode diagnostics, streaming boundaries, flush/retry behavior and lengths
above 32767. String-edit and message-framework unit tests run in VOC.
DTD tests cover declaration lookup, predefined entities, attribute values
and content-model classification. Resolver tests cover relative system
identifiers, UTF-8 percent escapes, surrogate pairs, malformed UTF-16 and
40,000-code-unit identifiers.
Parser tests cover callbacks, internal and parameter entities, default
attributes, Unicode names, character references, malformed documents and
70,000-unit text streamed through short reads. Namespace tests cover scope,
default declarations, implicit `xml` bindings, Unicode, DTD defaults,
duplicate expanded attribute names and reserved bindings. Validation tests
cover content models, required/fixed attributes, IDs and references, notations,
64 nested elements and long Unicode attribute lists. Writer tests cover
UTF-8/UTF-16 round trips, escaping, long names/URIs, indentation and partial
channel writes. Basic-element tests cover factory lookup, typed values,
application checks, locators, stack growth and long Unicode buffers. Protocol
tests reparse callback traces, including malformed input and namespace events.
The fourteen integration programs, including all 114 original codec vectors,
pass with GCC and Clang in
C23 mode, TCC and Clang ASan/UBSan.

The bundled James Clark XML test archive supplies the first well-formedness
corpus. The fixture runner requires Python 3.12 or newer. Run it with:

```sh
make BUILD=../compiler/build/ports/ooc/2 conformance
```

All 360 included XML cases and 24 original namespace fixtures pass, also under
ASan/UBSan. The runner records the upstream exclusion of `valid/sa/065.xml`,
whose entity replacement is malformed.
The same target checks 1,808 DTD-validation cases from the bundled James Clark,
IBM, Sun and OASIS archives. Historical fixture exclusions and corrected
expectations are recorded explicitly; see [conformance coverage](doc/Conformance.md).
The target also compares 339 canonical outputs byte-for-byte with the
reference files, including two explicitly recorded Sun output corrections.
The original local XML and bulk suites add 126 checks, including 98 canonical
output comparisons. Fourteen original parser/namespace protocol snapshots
match byte-for-byte; 16 negative protocol cases return XML diagnostics.
The conformance target now runs 2,687 checks.

`make xmlcheck` builds `XMLCheck`, a file well-formedness checker. Use
`XMLCheck --namespaces file.xml` to enable namespace checks. Its default
disables external references; `XMLCheck --external file.xml` enables them for
trusted local fixtures. Exit codes are 0 for successful parsing, 1 for XML
diagnostics and 2 for usage or opening errors.
`XMLCheck --validate file.xml` enables DTD validation and external references;
combine it with `--namespaces` to check namespace constraints too. Use trusted
input while the broader security review is incomplete.
`XMLCheck --canonical --external file.xml` writes the first canonical form
to standard output. `--second` selects the form that includes sorted notation
declarations. These output modes consume qualified names directly.
`XMLCheck --protocol file.xml` records parser callbacks as XML, including
locators, DTD declarations and text. It supports `--namespaces` and `--validate`.

VOC's ooc package supplies URI parsing, relative resolution and file/memory
channels. XML's `XMLEntityResolver` converts Unicode system identifiers to
these URI objects. The shared ooc tests replay all 77 original URI fixtures;
the XML tests cover every original XML regression-driver group.
`XMLCheck` applies default input, nesting, entity-expansion, value-length and
work budgets. Library applications can supply an `XMLLimits` budget through
the parser's `NewReaderLimited`, `NewChannelLimited`, `NewURILimited` and
`NewFileLimited` constructors, and `XMLBasicParser.ParseLimited` supports the
same budget. Built-in validation, namespace and output builders share it.
`make limits` runs 53 adversarial checks with process time and memory ceilings;
`make fuzz` adds 2,655 reproducible truncation and mutation checks.
Broader security testing remains unfinished;
use trusted XML.
The [input policy and security review](doc/Security.md) records the external-read
guard, resource-budget API, regression coverage and remaining resource work.

### Testing with a VOC source build

The ooc package can be built and tested in a VOC checkout using an installed
VOC compiler and matching runtime libraries. XML can then use that package's
Oberon-2 build directory directly. For a sibling VOC checkout:

```sh
make -C ../compiler/src/ports/ooc test
make BUILD=../compiler/build/ports/ooc/2 test conformance limits fuzz
```

The shared build directory contains the matching `.sym`, `.h` and `.o`
files. The XML build forces local symbol generation so its programs link the
rebuilt modules. A normal `make test` uses the installed shared VOC library.

[Port status and dependencies](doc/PortStatus.md) lists what is present and
what still needs adapting.

The tested XML modules and regression suites are integrated into VOC's
[`src/ports/xml/`, commit 1ef83249](https://github.com/vishapoberon/compiler/tree/1ef8324993beddb547a5b9d164519bb8d8341bb1/src/ports/xml).
VOC's conventional and modular model-2 library manifests include all 24 XML
modules. The integrated package passes the same four-compiler/sanitizer matrix;
its modular tests also pass all 222 bundled ABI/load checks and XML consumer
programs. Reusable support remains in VOC's existing ooc package.
From the VOC repository root, run:

```sh
make -C src/ports/xml test conformance limits fuzz
```

The standalone repository retains the CVS history and original source layout.
The upstream `configure` and `Makefile.in` describe the original oo2c build.

Original copyright and per-file licence notices apply. Most parser modules
are LGPL-2.0-or-later; [COPYING](COPYING) supplies the GNU LGPL 2.1 text.
Test data and bundled third-party test archives retain
their own notices.
