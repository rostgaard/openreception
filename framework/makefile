all: pubspec.lock
	@echo Nothing to do for a library, how about 'make tests' instead?

dependencies: pubspec.lock

upgrade-packages:
	@pub upgrade

tests: pubspec.lock
	pub run test test/*.dart

tests-to-json-file:
	-pub run test test/*.dart --reporter json > test-report.json

tests-text-output:
	@dart test/tests.dart -r expanded

analyze: pubspec.lock
	@dartanalyzer --no-hints --fatal-warnings lib/*.dart
	@dartanalyzer --no-hints --fatal-warnings test/*.dart

analyze-hints: pubspec.lock
	@echo "! (dartanalyzer lib/*.dart | grep '^\[')" | bash
	@echo "! (dartanalyzer test/*.dart | grep '^\[')" | bash

analyze-all: analyze analyze-hints

pubspec.lock: pubspec.yaml
	@pub upgrade

