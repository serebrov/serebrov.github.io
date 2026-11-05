# Build and preview the blog. See README.org.

EMACS ?= emacs
PORT ?= 8008
PUBLISH = $(EMACS) --batch -Q -l publish.el

.PHONY: build rebuild search serve clean

build:  ## Export the changed posts to public/
	$(PUBLISH) --eval '(blog-publish)'

rebuild:  ## Export all posts to public/ again
	$(PUBLISH) --eval '(blog-publish t)'

search:  ## Make the search index in public/pagefind/ (needs Node.js)
	npx -y pagefind@1.6.0

serve: build search  ## Build, then serve public/ on http://localhost:$(PORT)
	python3 -m http.server $(PORT) -d public

clean:  ## Remove the build output and the export cache
	rm -rf public .cache index.org archive.org archive.html tags
