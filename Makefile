DEST := .
NOTES := $(wildcard content/*.md)
NOTES_HTML := $(patsubst content/%.md, $(DEST)/html/%.html, $(NOTES))
NOTES_META := $(NOTES_HTML:.html=.json)

BS = build/vendor/bootstrap-3.3.1
WWW_BS_CSS := $(patsubst $(BS)/css/%.css, $(DEST)/css/%.css, $(wildcard $(BS)/css/*.css))
WWW_BS_FONTS := $(patsubst $(BS)/fonts/%, $(DEST)/fonts/%, $(wildcard $(BS)/fonts/*))
PYGMENTS_CSS = $(DEST)/css/pygments.css

.DEFAULT: all
all: $(NOTES_HTML) $(NOTES_META) $(WWW_BS_CSS) $(WWW_BS_FONTS) $(PYGMENTS_CSS) $(DEST)/index.html

#Order only dependency on dir (dir only will be created if it does not exist)
$(DEST)/html/%.html: content/%.md build/templates/bootstrap.hbs build/scripts/handlebars | $(DEST)/html
	mkdir -p $(@D)
	build/scripts/handlebars $< > $@

$(DEST)/html/%.json: content/%.md
	mkdir -p $(@D)
	build/scripts/frontmatter $< > $@

$(DEST)/index.html: $(NOTES_HTML) build/templates/bootstrap.hbs build/templates/index.hbs
	build/scripts/index -t build/templates/index.hbs $(NOTES_HTML) > $@

$(DEST)/css/%.css: $(BS)/css/%.css | $(DEST)/css
	mkdir -p $(@D)
	cat $< > $@

$(PYGMENTS_CSS): 
	node_modules/pygmentize-bundled-cached/node_modules/pygmentize-bundled/vendor/pygments/pygmentize -S default -f html > $@

$(DEST)/fonts/%: $(BS)/fonts/% | $(DEST)/fonts
	mkdir -p $(@D)
	cat $< > $@

.PHONY: clean serve

clean:
	rm -rf $(DEST)/html
	rm -rf $(DEST)/css
	rm -rf $(DEST)/fonts

serve:
	python -m SimpleHTTPServer 8081

$(DEST):
	mkdir $@

$(DEST)/html: | $(DEST)
	mkdir $@

$(DEST)/css: | $(DEST)
	mkdir $@

$(DEST)/fonts: | $(DEST)
	mkdir $@
