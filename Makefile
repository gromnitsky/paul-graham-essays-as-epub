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
	curl -LfSs http://www.paulgraham.com/articles.html | adieu -pe '$$("td font img").map( (_,v) => $$(v).prev()).filter( (_,v) => /\.html$$/.test($$(v).attr("href"))).map( (_,v) => $$(v).attr("href") + "\t" + $$(v).text() ).get().join("\n")' > $@

$(out)/index.mk: $(out)/index.txt
	awk -F"\t" '{print "$(out)/raw/" $$1}' $< | xargs $(MAKE) no-recursion=1
	touch $@

$(out)/%.html: $(out)/raw/%.html
	iconv -f windows-1252 -t utf8 $< | $(src)/essay > $@
	-tidy -miq --show-warnings no $@

.PHONY: epub mobi
epub: $(out)/book.epub
mobi: $(out)/book.mobi

$(out)/book.epub: $(out)/index.html
	ebook-convert $< $@ -m $(src)/meta.xml --page-breaks-before='//*[@class="title"]' --level1-toc '//*[@class="title"]'

$(out)/index.html: $(essays.dest)
	erb -r date $(src)/index.erb < $(out)/index.txt > $@

$(out)/%.mobi: $(out)/%.epub
	cd $(dir $@) && kindlegen $(notdir $<) -o $(notdir $@)

mkdir = @mkdir -p $(dir $@)
.DELETE_ON_ERROR:
