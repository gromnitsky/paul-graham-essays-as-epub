SHELL := bash -o pipefail
src := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
out := _out

essays.dest := $(patsubst $(out)/raw/%.html, $(out)/%.html, $(wildcard $(out)/raw/*.html))

all: $(essays.dest)

$(out)/raw/%.html:
	$(mkdir)
	curl -LfSs "http://www.paulgraham.com/$*.html" > $@

$(if $(no-recursion),,$(eval sinclude $(out)/index.mk))

# last time I saw this kind of html was ~2003; it's horrible!
$(out)/index.txt:
	$(mkdir)
	curl -LfSs http://www.paulgraham.com/articles.html | adieu -pe '$$("td font img").map( (_,v) => $$(v).prev()).filter( (_,v) => /\.html$$/.test($$(v).attr("href"))).map( (_,v) => $$(v).attr("href") + "\t" + $$(v).text() ).get().join("\n")' | grep -v lwba.html > $@

$(out)/index.mk: $(out)/index.txt
	awk -F"\t" '{print "$(out)/raw/" $$1}' $< | xargs $(MAKE) no-recursion=1
	touch $@

$(out)/%.html: $(out)/raw/%.html
	iconv -f windows-1252 -t utf8 $< | $(src)/essay > $@
	-tidy -miq --show-warnings no $@

.PHONY: epub mobi
epub: $(out)/graham,paul__essays.epub
mobi: $(out)/graham,paul__essays.mobi

$(out)/%.epub: $(out)/_toc.html; $(calibre)
$(out)/%.mobi: $(out)/_toc.html; $(calibre)

$(out)/_toc.html: $(essays.dest)
	erb -r date $(src)/toc.erb < $(out)/index.txt > $@

calibre = ebook-convert $< $@ --minimum-line-height=0 --breadth-first -m $(src)/meta.xml --page-breaks-before='//*[@class="title"]' --level1-toc '//*[@class="title"]'

mkdir = @mkdir -p $(dir $@)
.DELETE_ON_ERROR:

upload: mobi epub
	rsync -avPL --delete -e ssh $(out)/*.{epub,mobi} gromnitsky@web.sourceforge.net:/home/user-web/gromnitsky/htdocs/lit/graham,paul__essays/
