.PHONY: test pkg regen
test:
	bats tests/*.bats

pkg:
	sh packaging/macos/build_pkg.sh "$$(cat VERSION)" "mavericks-signal-desktop-$$(cat VERSION).pkg"

# Regenerate the container recipe + launcher from signal-desktop.conf via the porthole sibling.
regen:
	../mavericks-porthole/bin/generate-viewer signal-desktop.conf --out .
