.PHONY: build run bundle dmg clean

build:
	swift build -c release

run:
	-pkill -x PomodoroLockScreen
	swift run PomodoroLockScreen

bundle: build
	./scripts/bundle-app.sh

dmg: bundle
	./scripts/build-dmg.sh

clean:
	rm -rf .build dist
