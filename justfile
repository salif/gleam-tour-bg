#!/usr/bin/env -S just -f

_:
	@just --list

[confirm]
sync-upstream:
	git switch upstream
	git pull --ff-only --no-rebase https://github.com/gleam-lang/language-tour.git main
	git remote | xargs -I R git push R upstream
	git switch -

download-compiler:
	./bin/download-compiler

build:
	gleam run

test:
	gleam deps download
	gleam format --check src test
	gleam test
	gleam run

[confirm]
[doc('Publish to GitHub Pages')]
gh-pages:
	git switch gh-pages
	git rebase main
	just build
	git add ./docs
	git commit -m "Sync"
	git push --force-with-lease
	git switch -
