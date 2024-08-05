#!/usr/bin/env -S just -f

_:
	@just --list

gleam := "gleam"
port := ""

[confirm]
sync-upstream:
	git switch upstream
	git pull --ff-only --no-rebase https://github.com/gleam-lang/language-tour.git main
	git remote | xargs -I R git push R upstream
	git switch -

clean:
	{{gleam}} clean
	rm -rf ./docs
	rm -rf ./wasm-compiler

serve:
	cd docs && python3 -m http.server {{port}}

download-compiler:
	./bin/download-compiler

build:
	{{gleam}} run --target javascript

test:
	{{gleam}} deps download
	{{gleam}} format --check src test
	{{gleam}} test
	{{gleam}} run

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
