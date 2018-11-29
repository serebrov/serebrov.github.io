DEST := .
NOTES := $(wildcard content/*.md)
NOTES_HTML := $(patsubst content/%.md, $(DEST)/html/%.html, $(NOTES))
NOTES_HTML := $(sort $(NOTES_HTML))
NOTES_META := $(NOTES_HTML:.html=.json)

.DEFAULT: all
all: $(NOTES_HTML) $(NOTES_META) $(WWW_BS_FONTS) $(DEST)/index.html $(DEST)/sitemap.xml

#Order only dependency on dir (dir only will be created if it does not exist)
$(DEST)/html/%.html: content/%.md build/templates/layout.hbs build/templates/post.hbs build/templates/disqus.hbs build/scripts/handlebars | $(DEST)/html
	mkdir -p $(@D)
	build/scripts/handlebars $< > $@

$(DEST)/html/%.json: content/%.md build/scripts/frontmatter
	mkdir -p $(@D)
	build/scripts/frontmatter $< > $@

reverse = $(if $(1),$(call reverse,$(wordlist 2,$(words $(1)),$(1)))) $(firstword $(1))

$(DEST)/index.html: $(NOTES_HTML) $(NOTES_META) build/templates/layout.hbs build/templates/index.hbs
	build/scripts/index -t build/templates/index.hbs -o index.html $(call reverse,$(NOTES_HTML)) > $@

$(DEST)/sitemap.xml: $(NOTES_HTML) build/templates/sitemap.hbs
	build/scripts/index -t build/templates/sitemap.hbs -o sitemap.xml $(call reverse,$(NOTES_HTML)) > $@

.PHONY: clean serve

clean:
	rm $(DEST)/html/*.html
	rm -rf $(DEST)/css
	rm -rf $(DEST)/fonts

serve:
	node node_modules/bootlint/src/cli.js $(NOTES_HTML)
	node server.js

# serve:
# 	node node_modules/bootlint/src/cli.js $(NOTES_HTML)
# 	python -m SimpleHTTPServer 8081

$(DEST):
	mkdir $@

$(DEST)/html: | $(DEST)
	mkdir $@

$(DEST)/css: | $(DEST)
	mkdir $@

$(DEST)/fonts: | $(DEST)
	mkdir $@
