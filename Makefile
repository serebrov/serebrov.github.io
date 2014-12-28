DEST := .
NOTES := $(wildcard content/*.md)
NOTES_HTML := $(patsubst content/%.md, $(DEST)/html/%.html, $(NOTES))
NOTES_META := $(NOTES_HTML:.html=.json)

BS = build/vendor/bootstrap-3.3.1
# cosmo flatly lumen paper readable sandstone simplex spacelab superhero yeti
BS_THEME=.readable
BS_THEME=.yeti
BS_CSS := $(BS)/css/bootstrap$(BS_THEME).css
WWW_BS_CSS := $(DEST)/css/bootstrap$(BS_THEME).css
WWW_BS_FONTS := $(patsubst $(BS)/fonts/%, $(DEST)/fonts/%, $(wildcard $(BS)/fonts/*))
PYGMENTS_CSS = $(DEST)/css/pygments.css

.DEFAULT: all
all: $(NOTES_HTML) $(NOTES_META) $(DEST)/css/all.css $(WWW_BS_FONTS) $(DEST)/index.html

#Order only dependency on dir (dir only will be created if it does not exist)
$(DEST)/html/%.html: content/%.md build/templates/bootstrap.hbs build/templates/post.hbs build/scripts/handlebars | $(DEST)/html
	mkdir -p $(@D)
	build/scripts/handlebars $< > $@

$(DEST)/html/%.json: content/%.md build/scripts/frontmatter
	mkdir -p $(@D)
	build/scripts/frontmatter $< > $@

reverse = $(if $(1),$(call reverse,$(wordlist 2,$(words $(1)),$(1)))) $(firstword $(1))

$(DEST)/index.html: $(NOTES_HTML) $(NOTES_META) build/templates/bootstrap.hbs build/templates/index.hbs
	build/scripts/index -t build/templates/index.hbs $(call reverse,$(NOTES_HTML)) > $@

$(DEST)/css/all.css: $(BS_CSS) build/css/custom.css | $(DEST)/css
	mkdir -p $(@D)
	cat $^ > $@
	node_modules/pygmentize-bundled-cached/node_modules/pygmentize-bundled/vendor/pygments/pygmentize -S default -f html >> $@

$(DEST)/fonts/%: $(BS)/fonts/% | $(DEST)/fonts
	mkdir -p $(@D)
	cat $< > $@

.PHONY: clean serve

clean:
	rm -rf $(DEST)/html
	rm -rf $(DEST)/css
	rm -rf $(DEST)/fonts

serve:
	node node_modules/bootlint/src/cli.js $(NOTES_HTML)
	python -m SimpleHTTPServer 8081

$(DEST):
	mkdir $@

$(DEST)/html: | $(DEST)
	mkdir $@

$(DEST)/css: | $(DEST)
	mkdir $@

$(DEST)/fonts: | $(DEST)
	mkdir $@
