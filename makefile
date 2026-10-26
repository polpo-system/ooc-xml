VOC ?= voc
OFLAGS ?= -O2 -s -F
BUILD ?= build/voc
ROOT := $(CURDIR)
MODULES := XMLUnicodeCodec XMLUnicodeCodecUTF8 XMLUnicodeCodecUTF16 \
	XMLUnicodeCodecASCII XMLUnicodeCodecLatin1 XMLUnicodeCodecImportAll \
	XMLLimits XMLInputBuffer XMLUnicodeBuffer XMLDTD XMLEntityResolver \
	XMLError XMLLocator XMLBuilder XMLParser XMLBuilderNamespaces XMLStream \
	XMLRegexp XMLBuilderValidation XMLWriter XMLBuilderCanonical XMLBuilderParserProtocol \
	XMLBasicElement XMLBasicParser XMLBasicDataType XMLCheck \
	TestUnicodeCodecs TestCodecVectors TestUnicodeMessages TestMemoryBuffers TestDTDResolver TestParser \
	TestNamespaces TestStream TestValidation TestWriter TestBasic TestProtocol TestEntityPolicy TestLimits

.PHONY: all codecs codec-vectors buffers resolver parser namespaces validation writer basic xmlcheck conformance limits fuzz test clean
all: basic

$(BUILD):
	mkdir -p "$(BUILD)"

# Shared ooc modules are supplied by VOC.
codecs: | $(BUILD)
	cd "$(BUILD)" && $(VOC) $(OFLAGS) \
		"$(ROOT)/src/XML/UnicodeCodec.Mod" \
		"$(ROOT)/src/XML/UnicodeCodec/ASCII.Mod" \
		"$(ROOT)/src/XML/UnicodeCodec/Latin1.Mod" \
		"$(ROOT)/src/XML/UnicodeCodec/UTF8.Mod" \
		"$(ROOT)/src/XML/UnicodeCodec/UTF16.Mod" \
		"$(ROOT)/src/XML/UnicodeCodec/ImportAll.Mod"

buffers: codecs
	cd "$(BUILD)" && $(VOC) $(OFLAGS) \
		"$(ROOT)/src/XML/Limits.Mod" \
		"$(ROOT)/src/XML/InputBuffer.Mod" \
		"$(ROOT)/src/XML/UnicodeBuffer.Mod"

codec-vectors: codecs
	python3 tests/voc/check-codecs.py --build "$(BUILD)" --voc "$(VOC)" --flags "$(OFLAGS)"

resolver: buffers
	cd "$(BUILD)" && $(VOC) $(OFLAGS) \
		"$(ROOT)/src/XML/DTD.Mod" \
		"$(ROOT)/src/XML/EntityResolver.Mod"

parser: resolver
	cd "$(BUILD)" && $(VOC) $(OFLAGS) \
		"$(ROOT)/src/XML/Error.Mod" \
		"$(ROOT)/src/XML/Locator.Mod" \
		"$(ROOT)/src/XML/Builder.Mod" \
		"$(ROOT)/src/XML/Parser.Mod"

namespaces: parser
	cd "$(BUILD)" && $(VOC) $(OFLAGS) "$(ROOT)/src/XML/Builder/Namespaces.Mod"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) "$(ROOT)/src/XML/Stream.Mod"

validation: namespaces
	cd "$(BUILD)" && $(VOC) $(OFLAGS) \
		"$(ROOT)/src/XML/Regexp.Mod" \
		"$(ROOT)/src/XML/Builder/Validation.Mod"

writer: validation
	cd "$(BUILD)" && $(VOC) $(OFLAGS) \
		"$(ROOT)/src/XML/Writer.Mod" \
		"$(ROOT)/src/XML/Builder/Canonical.Mod" \
		"$(ROOT)/src/XML/Builder/ParserProtocol.Mod"

basic: writer
	cd "$(BUILD)" && $(VOC) $(OFLAGS) \
		"$(ROOT)/src/XML/Basic/Element.Mod" \
		"$(ROOT)/src/XML/Basic/DataType.Mod" \
		"$(ROOT)/src/XML/Basic/Parser.Mod"

test: basic codec-vectors
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestUnicodeCodecs.Mod"
	"$(BUILD)/TestUnicodeCodecs"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestUnicodeMessages.Mod"
	"$(BUILD)/TestUnicodeMessages"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestMemoryBuffers.Mod"
	"$(BUILD)/TestMemoryBuffers"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestDTDResolver.Mod"
	"$(BUILD)/TestDTDResolver"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestParser.Mod"
	"$(BUILD)/TestParser"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestNamespaces.Mod"
	"$(BUILD)/TestNamespaces"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestStream.Mod"
	timeout 20 "$(BUILD)/TestStream"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestValidation.Mod"
	"$(BUILD)/TestValidation"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestWriter.Mod"
	"$(BUILD)/TestWriter"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestBasic.Mod"
	"$(BUILD)/TestBasic"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestProtocol.Mod"
	"$(BUILD)/TestProtocol"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestEntityPolicy.Mod"
	"$(BUILD)/TestEntityPolicy"
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tests/voc/TestLimits.Mod"
	timeout 20 "$(BUILD)/TestLimits"

xmlcheck: writer
	cd "$(BUILD)" && $(VOC) $(OFLAGS) -m "$(ROOT)/tools/XMLCheck.Mod"

conformance: xmlcheck
	python3 tests/voc/check-xmltest.py "$(BUILD)/XMLCheck" --work "$(BUILD)/conformance"
	python3 tests/voc/check-validation.py "$(BUILD)/XMLCheck" --work "$(BUILD)/conformance"
	python3 tests/voc/check-canonical.py "$(BUILD)/XMLCheck" --work "$(BUILD)/conformance"
	python3 tests/voc/check-protocol.py "$(BUILD)/XMLCheck" --work "$(BUILD)/conformance"
	python3 tests/voc/check-misc.py "$(BUILD)/XMLCheck" --work "$(BUILD)/conformance"

limits: xmlcheck
	python3 tests/voc/check-limits.py "$(BUILD)/XMLCheck" --work "$(BUILD)/limits"

fuzz: xmlcheck
	python3 tests/voc/check-fuzz.py "$(BUILD)/XMLCheck" --work "$(BUILD)/fuzz"

clean:
	rm -f $(foreach module,$(MODULES),$(foreach ext,c h o sym,"$(BUILD)/$(module).$(ext)")) \
		"$(BUILD)/TestUnicodeCodecs" "$(BUILD)/TestCodecVectors" "$(BUILD)/TestUnicodeMessages" \
		"$(BUILD)/TestMemoryBuffers" "$(BUILD)/TestDTDResolver" "$(BUILD)/TestParser" \
		"$(BUILD)/TestNamespaces" "$(BUILD)/TestStream" "$(BUILD)/TestValidation" "$(BUILD)/TestWriter" \
		"$(BUILD)/TestBasic" "$(BUILD)/TestProtocol" "$(BUILD)/TestEntityPolicy" "$(BUILD)/TestLimits" \
		"$(BUILD)/XMLCheck"
