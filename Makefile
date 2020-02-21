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
	curl -LfSs http://www.paulgraham.com/articles.html | adieu -pe '$$("td font a").filter( (_,v) => /\.html$$/.test(v.attribs.href)).map( (_,v) => v.attribs.href).get().join`\n`' | sed '$$d' > $@

$(out)/index.mk: $(out)/index.txt
	sed 's|^|$(out)/raw/|g' $< | xargs $(MAKE) no-recursion=1
	touch $@

$(out)/%.html: $(out)/raw/%.html
	iconv -f windows-1252 -t utf8 $< | $(src)/essay > $@
	-tidy -miq --show-warnings no $@

mkdir = @mkdir -p $(dir $@)
.DELETE_ON_ERROR:
