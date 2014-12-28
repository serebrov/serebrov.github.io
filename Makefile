DEST := .
NOTES := $(wildcard content/*.md)
NOTES_HTML := $(patsubst content/%.md, $(DEST)/html/%.html, $(NOTES))

BS = build/vendor/bootstrap-3.3.1
WWW_BS_CSS := $(patsubst $(BS)/css/%.css, $(DEST)/css/%.css, $(wildcard $(BS)/css/*.css))
WWW_BS_FONTS := $(patsubst $(BS)/fonts/%, $(DEST)/fonts/%, $(wildcard $(BS)/fonts/*))
PYGMENTS_CSS = $(DEST)/css/pygments.css

.DEFAULT: all
all: $(NOTES_HTML) $(WWW_BS_CSS) $(WWW_BS_FONTS) $(PYGMENTS_CSS)

#Order only dependency on dir (dir only will be created if it does not exist)
$(DEST)/html/%.html: content/%.md build/templates/bootstrap.hbs build/scripts/build_template | $(DEST)/html
	mkdir -p $(@D)
	scripts/build_template $< > $@

$(DEST)/index.html: $(NOTES_HTML) build/templates/bootstrap.hbs
	scripts/build_index -t templates/bootstrap.hbs $(NOTES_HTML) > $@

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
	cd www && python -m SimpleHTTPServer 8081

$(DEST):
	mkdir $@

$(DEST)/html: | $(DEST)
	mkdir $@

$(DEST)/css: | $(DEST)
	mkdir $@

$(DEST)/fonts: | $(DEST)
	mkdir $@
