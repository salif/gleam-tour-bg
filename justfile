#!/usr/bin/env -S just -f

_:
	@just --list

[confirm]
sync-upstream:
	git switch upstream
	git pull --ff-only --no-rebase https://github.com/gleam-lang/language-tour.git main
	git remote | xargs -I R git push R upstream
	git switch -

build:
	gleam run
