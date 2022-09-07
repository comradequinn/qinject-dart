VERSION=`cat pubspec.yaml | grep version: | cut -d' ' -f2`

.PHONY: example
example:
	@dart run example/main.dart

.PHONY: test
test:
	@dart test

.PHONY: changelog
# ensure commit messages follow the format 'v1.0.0' for new version commits
changelog : 
	@-rm -f CHANGELOG.md > /dev/null
	@git log | grep v${VERSION} > /dev/null || echo "## ${VERSION}" > CHANGELOG.md
	@git log --pretty="- %s" | sed '/- v[0-9]/ { s/- v/## /g; }' >> CHANGELOG.md

.PHONY: verify
verify : 
	@dart pub publish --dry-run

.PHONY: publish
publish : test verify
	@dart pub publish
