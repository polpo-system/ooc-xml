# VOC port status

`make test` builds and tests the Unicode codecs, XML byte/Unicode buffers,
DTD data model, entity resolver, diagnostics, locator, builder interface and
parser, namespace builder, DTD validator, writer, canonical-output builder,
basic element interfaces and parser-protocol builder against VOC's shared ooc
support under the Oberon-2 model.

## Dependencies

Having a module with the same name is not enough: its character types,
integer widths, record extensions and method signatures must agree.

| Dependency | Status |
| --- | --- |
| `XMLParser`, `XMLBuilder`, `XMLLocator`, `XMLError` | Ported and tested with in-memory and file inputs, UTF-16 callbacks and UTF-8 diagnostics. |
| `XMLStream` | Additive bounded UTF-8 element-stream framing, namespace inheritance, exact consumption and explicit restarts; see [streaming](Streaming.md). |
| `XMLBuilderNamespaces` | Ported with scoped declarations, implicit `xml` bindings, duplicate expanded-name checks and Unicode coverage. |
| `XMLBuilderValidation`, `XMLRegexp` | Ported DTD validation and content-model matching; tested with internal/external DTDs and Unicode attributes. |
| `XMLWriter`, `XMLBuilderCanonical` | Ported XML generation and canonical forms; round-trip and reference-output tests cover Unicode, escaping, attribute sorting and notations. |
| `XMLBasicElement`, `XMLBasicParser`, `XMLBasicDataType` | Ported element factories, typed attributes and application-object construction. |
| `XMLBuilderParserProtocol` | Ported callback traces with locators; original reference snapshots match byte-for-byte. |
| `XMLDTD` | Ported data model; tests cover internal subsets, parameter entities, default attributes and validity constraints. |
| `XMLEntityResolver` | Ported Unicode system-identifier normalization and relative URI resolution; tested with supplementary characters, malformed UTF-16 and long identifiers. |
| `XMLInputBuffer`, `XMLUnicodeBuffer` | Ported and tested with short reads, BOMs, growth, compaction, repeated flushes and partial-write retries. |
| `XMLLimits` | Shared per-parse input/output, recursion, expansion, value-size, content-model and work budgets; limited constructors apply them before prefetch and built-in builders share them. |
| `IOMemory` | Transferred to VOC's ooc package. Tests cover permissions, seeking, sparse writes, truncation, growth, overlapping copies, bounds and fingerprints. |
| Unicode codec registry, ASCII, Latin-1, UTF-8, UTF-16 | Adapted to `-O2`; new Oberon tests pass with GCC/C23, Clang/C23 and TCC. |
| `oocUnicode`, `LongStrings` | Supplied by VOC's ooc package, using the shared `LONGCHAR` alias for code units and `LONGINT` for positions and lengths. |
| `Msg` | VOC's ooc module now uses the tested Unicode-safe implementation. `GetLText` preserves UTF-16; `GetText` retains the original Latin-1 conversion. |
| `Channel` | VOC's existing ooc module now uses the tested implementation, rebuilt against the Unicode-safe `Msg`. |
| `TextRider`, `BinaryRider`, `Time` | Supplied by VOC. The riders are rebuilt against the updated interfaces; text diagnostics widen their templates explicitly. |
| `Ascii`, `CharClass`, `IntStr`, `RealStr` | VOC has ports; retain only the required interfaces and test their use. |
| `Strings` | XML expects oo2c semantics. VOC also has Oakwood `Strings` and `oocStrings`; choose explicitly, not just by module name. |
| `Files` | Supplied by VOC as `oocFiles`, backed by `FilesHost` and `Platform`; the URI file scheme now uses it. |
| `StdChannels`, `Err`, `Log` | Original sources are available; not in the current VOC source tree under these names. Needed by upstream drivers/examples, not all by the parser itself. |
| `URI`, `URIParser`, file/memory/mailto schemes and component parsers | Transferred to VOC's ooc package with an unchanged baseline, adapted and tested. Optional network/form-query modules remain in the CVS import. |
| `OS:*`, `IO:PFD`, sockets and select | The imported sources include upstream C bindings. Use VOC's system interfaces for the port; file I/O and current-directory access already have Oberon interfaces. Network support remains a separate stage. |
| `ADT:ArrayList`, `ADT:Dictionary`, `ADT:Object`, `ADT:String` | Used by optional `URI:Query:WWWForm`, not directly by the XML parser. Do not import newer generic replacements unnecessarily. |

Support-module provenance is recorded in
[history/oo2c-support.md](../history/oo2c-support.md). Additional imported
support modules need the same recorded provenance and unmodified baseline.

## VOC integration boundary

VOC's XML port contains the XML-specific modules. Reusable dependencies,
including strings, diagnostics, channels, memory files and URI support, belong
in VOC's `src/ports/ooc/` package.

VOC commit `1ef8324993beddb547a5b9d164519bb8d8341bb1` integrates all 24
implementation files from standalone commit `ff8ab3d` unchanged into
`src/ports/xml/`, with flattened paths and a provenance manifest. It includes
the XML regression programs, original fixtures, archives and process-bounded
resource/mutation runners. Test attributes preserve fixture bytes and line
endings. Conventional, modular and Windows model-2 build manifests include XML.

VOC's `Msg` and `Channel` have been replaced by the tested implementations.
`LongStrings`, `IOMemory` and the shared `oocUnicode.LONGCHAR` alias also live
in VOC's ooc directory. The XML build imports these modules from VOC.
The shared package and its dependents, including `oocFiles`, `TextRider`,
`BinaryRider` and `ProgramArgs`, are rebuilt and tested together.

Use the existing Oberon `oocFiles`, `FilesHost` and `Platform` interfaces for
system access. Add portable `Platform` functions only for verified missing
operations. The upstream C adapters remain in the preserved history; they
will not be part of the VOC port's implementation.

## String and diagnostic checks

- Copies, edits and searches preserve UTF-16 code units, including Armenian
  characters and surrogate pairs. Positions count code units; bounded edits
  may split a pair, as in the original interface.
- `Long` and `Append8` widen Latin-1 octets. UTF-8 decoding uses the codecs.
- `Capitalize` preserves oo2c's ASCII and Latin-1 mapping; other code units
  remain unchanged.
- Small-buffer edit combinations are checked against independently constructed
  expected results. Capacity tests use subtraction to avoid length overflow.
- Regression tests cover insertion beyond the end, message-list transfers into
  empty and extended lists, repeated built-in placeholders, bounded narrow
  output and wide/narrow strings longer than 32767 units or octets.
- A UTF-8 round trip through the string and diagnostic interfaces checks that
  Armenian and supplementary characters survive the complete support path.

## Memory channel and buffer checks

- Memory growth copies array contents using native-width addresses. Reads and
  writes validate ranges before address calculations, and overlapping copies
  are handled explicitly.
- Byte-buffer tests retain 50000 bytes, grow buffers, compact overlapping
  ranges and distinguish embedded zero octets from the end marker. Read
  errors are recorded once, including errors delivered with partial data.
- Unicode input waits for sufficient bytes before decoding a split character.
  Tests include one-byte reads, a split character at the normal block boundary,
  empty and BOM-only input, UTF-8/UTF-16 detection, truncated sequences and
  unsupported detected encodings.
- Unicode output preserves split surrogate pairs, retries short writes and
  retains unwritten bytes after errors. Repeated flushes preserve output
  exactly. A writer returning zero progress is reported as a write error.
- Round trips exercise 40001 UTF-16 code units, supplementary characters and
  an embedded U+FEFF through UTF-8 and both UTF-16 byte orders, with retained
  and discarded input blocks.
- Channel `WriteBytes` and buffer interval-write methods pass source arrays
  by `VAR` to avoid implicit full-array copies; these sources are read-only.

## URI, DTD and resolver checks

- URI unit tests in VOC cover RFC 2396 relative-resolution examples, escaped
  dot segments, malformed escapes, cloning, 40,000-byte URIs and file/memory
  channels. Byte classification uses explicit ASCII ranges.
- All 77 original URI fixtures run in VOC's ooc package, including component
  traces and serialization, with two documented historical corrections.
- All 114 original codec hex vectors run in `make test`, checking full and
  bounded output buffers. UTF-8 invalid-continuation grouping preserves the
  original output while respecting the caller's logical input end.
- File URI construction escapes file names; channel opening rejects remote
  authorities and overlong paths. `%00` is rejected because decoded URI
  components use zero-terminated strings.
- DTD names and values use the shared UTF-16 code units. Comparisons and
  predefined entity construction widen bytes explicitly. Tests exercise
  declaration deduplication, attribute attachment, normalization and nested
  attribute-value fragments.
- Resolver normalization uses dynamically sized UTF-8 and percent-escape
  buffers. Tests include Armenian, supplementary characters, preserved
  existing escapes and output larger than the upstream 8 KiB buffer.
  Malformed UTF-16 returns a diagnostic through `Resolver.GetURI`.

## Parser checks

- Applications receive UTF-16 names, attribute values and character data.
  Locator positions count UTF-16 code units. Diagnostic output uses UTF-8,
  including when the input has no base URI.
- Unicode character tables retain the XML 1.0 Second Edition ranges.
  Sparse classifications use comparisons to fit VOC's 512-value CASE span;
  dispatch maps buffer-end markers to adjacent labels. A fingerprint checks
  name classification across all 65,536 code units against the preserved tables.
- Integration tests exercise empty/nested entities, parameter declarations,
  default attributes, whitespace normalization, supplementary character
  references, both UTF-16 byte orders and short-read streaming beyond 32767.
- Empty copied DTD character fragments allocate a terminator, avoiding VOC's
  zero-length-array trap. Attribute entity whitespace processing advances the
  cursor, and invalid-encoding diagnostics tolerate an absent base URI.
- `make conformance` extracts the bundled James Clark archive into ignored
  build storage and checks all 360 included well-formedness cases. The
  upstream exclusion of `valid/sa/065.xml` is recorded in the result file.
  All 24 original namespace fixtures also pass with `XMLCheck --namespaces`.
  Timeouts, traps and opening errors are failures, even for negative fixtures.
  Canonical-output comparisons also run in this target; see below.
- `XMLCheck` disables external references by default. The library retains its
  upstream `followExternalRef = TRUE` default; applications must set it
  explicitly. Limited constructors accept a shared `XMLLimits` budget before
  prefetch; `XMLCheck` uses the default limits. Use trusted documents while the
  broader security review is incomplete.

## Namespace checks

- The builder resolves prefixes after collecting all declarations in a start
  tag, and restores scope after an end tag. Default declarations apply to
  elements; unprefixed attributes retain no namespace.
- The implicit `xml` binding is available without a declaration. Reserved
  prefix/URI bindings, undeclared prefixes, empty prefixed declarations and
  duplicate expanded attribute names produce diagnostics.
- Buffered attributes are cleared between elements. Default namespace entries
  are skipped during prefix lookup, and fatal errors suppress further events
  to the application apart from `EndDocument`.
- Tests cover attributes declared in a DTD without an accompanying element
  declaration, Unicode names/URIs, more than 16 nested scopes and attribute
  list growth. DTD default values and explicit-value normalization also work
  for elements without `<!ELEMENT>` declarations.

## DTD validation

- `XMLBuilderValidation` checks element content, attribute syntax and
  declarations, ID uniqueness and references, notations and standalone
  constraints. `XMLRegexp` matches sequence/choice/repetition models and checks
  that each possible next name identifies one content-particle occurrence.
- Put validation before namespace processing in the callback chain. DTDs name
  qualified elements and attributes. Set `parser.validating := TRUE` and
  enable external references to read the complete DTD.
- Stack growth is checked before incrementing the nesting level. Mixed-content
  error lists grow to fit long names. Attribute-list token offsets use
  `LONGINT`; tests include 20,000 Unicode ID references and 64 nested elements.
- Character content is checked in element-only models for all documents,
  independently of the standalone declaration. `NOTATION` attributes on
  `EMPTY` elements and ambiguous content models produce diagnostics.
- `make conformance` checks 1,808 DTD-validation fixtures in addition to the
  XML and namespace well-formedness cases, also under ASan/UBSan.
  [Conformance coverage](Conformance.md) explains the four upstream exclusions
  and historical expectation corrections. Fixture sources remain unchanged.

## XML output

- `XMLWriter` accepts wide strings through `VAR` array parameters, treated as
  read-only. Latin-1 methods widen bytes explicitly. The shared Unicode
  code-unit type is used throughout the writer and element-name stack.
- Text CR and attribute TAB/LF/CR use character references to preserve values
  when parsed again. Latin-1 tag names and URI strings use dynamic storage
  instead of fixed 1,024-character buffers. Region methods check their bounds.
- Integration tests round-trip Armenian and supplementary characters through
  UTF-8 and UTF-16, including split surrogates, 70,000-unit text, 40,000-byte
  names and URIs, stack growth, numeric attributes, mixed content and indentation.
  Partial channel writes and a recoverable flush failure retain pending bytes.
- `XMLBuilderCanonical` sorts names using wide-string comparisons, quotes
  notation literals with a delimiter absent from their contents and releases
  buffered attributes after each start tag. The fixture runner compares 339
  outputs byte-for-byte, also under ASan/UBSan. It records two historical Sun
  normalization corrections without changing the archived reference files.
- [Writing XML](WritingXML.md) describes the output API and required error
  checks. Applications supply valid names and balanced tag operations.

## Basic element objects and callback traces

- `XMLBasicElement` provides root factories, child lists, growable Unicode
  strings and character-data elements. `XMLBasicParser` builds application
  objects, checks application-defined attribute/content rules and optionally
  validates against a DTD. See [Basic element objects](BasicElements.md).
- The parser installs a grown nesting stack and sets the root object's locator
  before attributes arrive. It stops application callbacks after an application
  error, including missing-child and whole-element checks. Regression tests
  cover 64 nested objects, root-relative URI attributes, invalid input,
  Unicode factory names and 70,000-unit character buffers.
- Typed integer attributes retain the entire value before conversion. Latin-1
  conversion checks representability and capacity before modifying the result;
  URI conversion reports malformed UTF-16. Shared `IntConv` now scans with
  `LONGINT` offsets (VOC commit `32cc3131`), with generic long-input tests in
  VOC's confidence suite.
- `XMLBuilderParserProtocol` writes callbacks as XML through `XMLWriter`.
  Tests reparse traces for declarations, attributes, namespaces, CDATA,
  comments, instructions, entities, missing base URIs and fatal parse errors.
  All 14 original successful protocol/namespace snapshots match byte-for-byte,
  including their locator positions; 16 negative protocol cases return XML
  diagnostics. Long-text tests exercise buffered trace output.
- The original local XML and bulk suites now run 126 checks in the conformance
  target, with 98 byte-for-byte canonical comparisons. Their sole historical
  validation correction is a declared non-deterministic content model;
  [Conformance coverage](Conformance.md) records it and reviews the original
  drivers. The full conformance/output total is 2,687.

## Input policy review

- A shared external-buffer guard enforces `followExternalRef = FALSE` even
  while recovering from malformed parameter-entity references. The review
  reproduced and fixed an external read through that path.
- Parameter-entity cycles now produce diagnostics before re-entering an
  expanding entity. Internalized external entities are checked using their own
  decoder, so malformed UTF-8 is reported correctly.
- An instrumented in-memory resource tests external DTDs, general/parameter
  entities, invalid attribute references, unused unparsed entities, recursive
  references and malformed internalized input without accessing host files.
- [Input policy and resource review](Security.md) explains the tested controls
  and resource-budget API. Cutoff tests cover early failure and shared external
   byte budgets. The `limits` target runs 53 hostile-input cases under process
   time and memory ceilings, including namespace, validation and output modes.
- Input and retained-token buffers grow geometrically. DTD namespace insertion
  is iterative, and lookup/insertion and attribute comparisons charge the
  budget. Value graphs are checked before recursive flattening. Continue using
   trusted documents while broader adversarial review remains incomplete.
- Built-in validation, regular-expression, namespace and canonical/protocol
  builders share the parser budget, including aggregate validation costs and
  encoded output bytes. Basic parsing has an additive `ParseLimited` entry
  point. Direct DTD value/namespace APIs can opt into a budget.
- The `fuzz` target runs 2,655 deterministic truncation/mutation checks across
  five parser/output modes under per-process limits.

## Verification

The thirteen XML test programs, seven shared ooc regression programs and the
77-case shared URI fixture driver pass with
GCC/C23, Clang/C23 and TCC under `-O2`. The shared ooc package is rebuilt
before each XML test run. An additional Clang build instruments the shared
package, ported XML modules and tests with AddressSanitizer and
UndefinedBehaviorSanitizer:

```sh
env CC=clang \
  CFLAGS='-std=c23 -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer' \
  ASAN_OPTIONS=detect_leaks=0:detect_stack_use_after_return=0 \
  UBSAN_OPTIONS=halt_on_error=1 \
  make -C ../compiler/src/ports/ooc BUILD="$PWD/build/sanitize" test
env CC=clang \
  CFLAGS='-std=c23 -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer' \
  ASAN_OPTIONS=detect_leaks=0:detect_stack_use_after_return=0 \
  UBSAN_OPTIONS=halt_on_error=1 \
  make BUILD=build/sanitize test conformance limits fuzz
```

ASan's alternate stack frames must be disabled so VOC's conservative garbage
collector can find live pointers on the native stack. The installed VOC
runtime is used as provided by the compiler. Set `BUILD` to a rebuilt ooc
directory when testing from source without installing VOC first; see the
source-build example in the README.
The isolated ooc build forces local symbol files, so rebuilt objects are linked
even when installed modules export identical interfaces. All conformance
and adversarial targets pass with GCC/C23, Clang/C23, TCC and the sanitizer build.
The integrated VOC package passes the same matrix. A fresh model-2 modular
build with networking disabled passes all 222 bundled ABI/load checks and
the XML parser, validation, writer and Basic consumer tests.

The existing conventional compiler binary in the development checkout still
rejects the unchanged ooc `LowReal.Mod` constant at line 87 with `err 203`,
before `make xml` reaches XML. The isolated build uses the installed compiler;
the successful modular build creates a fresh compiler. Conventional compiler
image and native-Windows validation remain VOC release tasks.

## Representation rules

- Build explicitly with `-O2`: 8-bit `SHORTINT`, 16-bit `INTEGER`, 32-bit
  `LONGINT`. Do not change the whole library to the C or V type model.
- Preserve Unicode values. The ported codec interface uses `LONGINT` storage
  through the shared `oocUnicode.LONGCHAR` alias for UTF-16 code units.
  Its definition documents the representation and valid 0..65535 range.
- Replace implicit wide-string operations with explicit string helpers.
  Record memory moves must use the actual element size after porting.
- Audit indices and lengths separately from character values. VOC's ordinary
  `Strings.Length` has an `INTEGER` result and is not a general XML document
  length operation.
- Keep native addresses in `SYSTEM.ADDRESS`, preserve native field widths,
  and check narrowing conversions at OS boundaries.

## Next stages

1. Complete VOC compiler-image and platform release validation using the
   integrated package and its shared ooc dependencies.
2. Continue the adversarial review described in [Security.md](Security.md)
   before accepting untrusted input.
