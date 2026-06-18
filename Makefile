.PHONY: build run bundle clean

build:
	swift build -c release

run:
	swift run PomodoroLockScreen

bundle: build
	./scripts/bundle-app.sh

clean:
	rm -rf .build dist
