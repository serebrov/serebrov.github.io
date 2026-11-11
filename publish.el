;;; publish.el --- Export the blog from org to static HTML  -*- lexical-binding: t; -*-

;;; Commentary:

;; Sources are in posts/, shared CSS and JS are in static/, and the site
;; goes to public/.  Build from the shell with `make build', or load this
;; file in Emacs and run M-x blog-publish.
;;
;; Code blocks are colored at build time by htmlize, with the Emacs major
;; mode of each language.  Install htmlize from MELPA before the build.
;;
;; The build does not evaluate code blocks.  For a block with ":exports both",
;; the results that are already in the org file are exported as they are.

;;; Code:

(require 'ox-publish)
(require 'ox-html)
(require 'package)

(unless (require 'htmlize nil t)
  (package-initialize)
  (require 'htmlize))

(eval-and-compile
  (defconst blog-root
    (file-name-directory
     (or load-file-name (bound-and-true-p byte-compile-current-file) buffer-file-name))
    "Directory that contains this file."))

(require 'blog-tags (expand-file-name "blog-tags" blog-root))
(require 'blog-feeds (expand-file-name "blog-feeds" blog-root))

(defun blog-path (name)
  "Return NAME expanded against `blog-root'."
  (expand-file-name name blog-root))

(defconst blog-html-head
  (concat "<link rel=\"stylesheet\" href=\"/static/org_css/normalize.css\">\n"
          "<link rel=\"stylesheet\" href=\"/static/org_css/htmlize.css\">\n"
          "<link rel=\"stylesheet\" href=\"/static/org_css/org.css\">\n"
          "<link rel=\"stylesheet\" href=\"/static/blog.css\">\n"
          "<script defer src=\"/static/blog.js\"></script>")
  "The <head> tags that every page shares.
The paths are absolute because the site is at the root of its domain
and pages are in more than one directory.")

(defun blog-read-layout (name)
  "Return the HTML of layout/NAME.
The export reads the file for each page, so changes to it show
after the next rebuild without a reload of this file."
  (with-temp-buffer
    (insert-file-contents (blog-path (concat "layout/" name)))
    (buffer-string)))

(defun blog-page-section (file)
  "Return the menu section of the page made from FILE.
The value is \"posts\", \"archive\", \"tags\", or \"search\"."
  (cond ((or (file-in-directory-p file (blog-path "posts/archive"))
             (string= (file-name-nondirectory file) "archive.org"))
         "archive")
        ((file-in-directory-p file (blog-path "tags")) "tags")
        ((string= (file-name-nondirectory file) "search.org") "search")
        (t "posts")))

(defconst blog-post-list-pages '("index.org" "archive.org")
  "Source files of the post lists, relative to `blog-root'.")

(defconst blog-section-pages (append blog-post-list-pages '("tags/index.org" "search.org"))
  "Source files of the pages that the menu links go to, relative to `blog-root'.")

(defun blog-page-file (info)
  "Return the source file of the page that INFO describes, relative to `blog-root'."
  (file-relative-name (plist-get info :input-file) blog-root))

(defun blog-header (info)
  "Return the site header for the page that INFO describes.
The menu link with the data-section of the page gets aria-current:
\"page\" on the pages that the menu links go to, and \"true\" on other
pages of the section (posts and pages of single tags)."
  (let* ((file (plist-get info :input-file))
         (section (format "data-section=\"%s\"" (blog-page-section file)))
         (current (if (member (blog-page-file info) blog-section-pages)
                      "page"
                    "true")))
    (string-replace section
                    (format "%s aria-current=\"%s\"" section current)
                    (blog-read-layout "header.html"))))

(defun blog-footer (_info)
  "Return the site footer."
  (blog-read-layout "footer.html"))

(defun blog-video-export (path _desc backend _info)
  "Export a video:PATH link as an HTML5 video element when BACKEND is HTML."
  (when (org-export-derived-backend-p backend 'html)
    (format "<video controls preload=\"metadata\" src=\"%s\"></video>" path)))

(org-link-set-parameters "video" :export #'blog-video-export)

(defun blog-lazy-images (output backend _info)
  "Add lazy loading to all images in OUTPUT when BACKEND is HTML."
  (when (org-export-derived-backend-p backend 'html)
    (string-replace "<img " "<img loading=\"lazy\" " output)))

(defun blog-slug (title)
  "Return an HTML id made from TITLE, for example \"code-blocks\"."
  (let ((slug (string-trim (replace-regexp-in-string "[^a-z0-9]+" "-" (downcase title))
                           "-" "-")))
    (if (string-empty-p slug) "section" slug)))

(defun blog-add-heading-ids (_backend)
  "Give each heading without a CUSTOM_ID an id made from its title.
Org makes random ids otherwise, and links to sections break on each
build.  This runs on the export copy of the buffer, not on the file."
  (let ((used (make-hash-table :test #'equal)))
    (org-map-entries
     (lambda ()
       (unless (org-entry-get nil "CUSTOM_ID")
         (let* ((slug (blog-slug (org-link-display-format (org-get-heading t t t t))))
                (count (puthash slug (1+ (gethash slug used 0)) used)))
           (org-entry-put nil "CUSTOM_ID"
                          (if (= count 1) slug (format "%s-%d" slug count)))))))))

(defun blog-add-transclusions (_backend)
  "Insert the content of each #+transclude: keyword.
This runs on the export copy of the buffer, not on the file."
  (when (require 'org-transclusion nil t)
    (let ((inhibit-read-only t))
      (org-transclusion-add-all))))

(defun blog-post-entry (file project html-dir)
  "Return the post list line for the post FILE of PROJECT.
The line is a description list item: the post title is the term, and
the date and #+DESCRIPTION are the definition.  HTML-DIR is the path
from the list page to the post pages, for example \"html/\"."
  (let ((date (format-time-string "%F" (org-publish-find-date file project)))
        (description (org-publish-find-property file :description project 'html)))
    (format "[[file:%s%s][%s]] :: @@html:<time datetime=\"%s\">%s</time>@@ %s"
            html-dir
            (file-name-with-extension (file-name-nondirectory file) "html")
            (org-publish-find-title file project)
            date date
            (string-replace "\n" " " (or description "")))))

(defun blog-sitemap-entry (entry _style project)
  "Return the index page line for the post ENTRY of PROJECT.
The index pages are at the site root, and the posts are in html/."
  (blog-post-entry entry project "html/"))

(defun blog-tag-entry (file _style project)
  "Return the tag page line for the post FILE of PROJECT.
The tag pages are in tags/TAG/, and the posts are in html/."
  (blog-post-entry file project "../../html/"))

(defun blog-sitemap (title list)
  "Return the org text of an index page with TITLE and the post LIST.
LIST is flat, (unordered (ENTRY) ...), because the post projects are
not recursive.  `org-publish-sitemap-default' is not used, because its
`org-list-to-org' call removes the HTML snippets of `blog-sitemap-entry'."
  (concat "#+TITLE: " title "\n\n"
          "#+ATTR_HTML: :class post-list\n"
          (mapconcat (lambda (item) (concat "- " (car item))) (cdr list) "\n")
          "\n"))

(defun blog-post-files (projects)
  "Return a (FILE . PROJECT) pair for each post of the post PROJECTS."
  (mapcan (lambda (name)
            (let ((project (assoc name projects)))
              (mapcar (lambda (file) (cons file project))
                      (directory-files (plist-get (cdr project) :base-directory)
                                       t "\\`[^.].*\\.org\\'"))))
          '("blog-posts" "blog-archive")))

(defun blog-write-tag-pages (project-plist)
  "Write the org files of the tag pages to tags/ before the tags project.
The tags are the :blog-tags property of PROJECT-PLIST."
  (blog-tags-write (blog-path "tags") (plist-get project-plist :blog-tags)
                   #'blog-sitemap #'blog-tag-entry))

(defun blog-add-post-tags (body backend info)
  "Add links to the tag pages at the end of BODY of a post.
INFO is the export plist, BACKEND is the export backend."
  (when (and (org-export-derived-backend-p backend 'html)
             (file-in-directory-p (plist-get info :input-file) (blog-path "posts")))
    (concat body (blog-tags-links (plist-get info :filetags)))))

(defun blog-sidebar-toc (output)
  "Return a copy of the table of contents in OUTPUT for the sidebar, or \"\".
The copy has no ids, so the ids on the page stay unique.  The page
keeps its own table of contents for narrow screens (see blog.css)."
  (if (string-match "<nav id=\"table-of-contents\"\\(?:.\\|\n\\)*?</nav>" output)
      (string-replace "<nav " "<nav class=\"sidebar-toc\" "
                      (replace-regexp-in-string " id=\"[^\"]*\"" "" (match-string 0 output)))
    ""))

(defun blog-add-sidebar (output backend info)
  "Add the sidebar after the <main> element of OUTPUT.
The sidebar has the table of contents of the page and the tag cloud
for the :blog-tags property of INFO.  The post lists (/ and
/archive.html) also have a search box, and their tag cloud is open.
The /tags/ page has no sidebar, because its content is the same tag
cloud."
  (let ((tags (plist-get info :blog-tags))
        (page (blog-page-file info)))
    (when (and tags
               (org-export-derived-backend-p backend 'html)
               (not (string= page "tags/index.org")))
      (let ((post-list (member page blog-post-list-pages)))
        (string-replace "</main>"
                        (concat "</main>\n<div class=\"sidebar\">\n"
                                (if post-list (blog-read-layout "sidebar-search.html") "")
                                (blog-sidebar-toc output) "\n"
                                (blog-tags-sidebar tags post-list) "</div>")
                        output)))))

(defun blog-page-options (tags)
  "Return the export options that all pages share.
TAGS from `blog-tags-collect' are for the tag pages and the sidebar,
nil for no sidebar."
  `(:base-extension "org"
    :publishing-function org-html-publish-to-html
    ;; to allow things_like_this without making them subscript.
    ;; we can still use `things_{like_this}`
    :with-sub-superscript {}
    :with-toc t
    :section-numbers nil
    :headline-levels 6
    :html-doctype "html5"
    :html-html5-fancy t
    :html-head-include-default-style nil
    :html-head-include-scripts nil
    :html-head ,blog-html-head
    :html-preamble blog-header
    :html-postamble blog-footer
    :html-divs ((preamble "header" "preamble")
                (content "main" "content")
                (postamble "footer" "postamble"))
    :html-validation-link nil
    :blog-tags ,tags))

(defun blog-projects (&optional tags)
  "Return the `org-publish-project-alist' for the blog.
Posts and archive posts go to one flat directory, public/html/, so that
the URLs are /html/<file name>.html, the same as on the old Hugo site.
TAGS from `blog-tags-collect' are for the tag pages and the sidebar;
without TAGS, the projects only give the post files."
  (let ((page-options (blog-page-options tags)))
    `(("blog-posts"
       :base-directory ,(blog-path "posts")
       :publishing-directory ,(blog-path "public/html")
       :auto-sitemap t
       :sitemap-filename "../index.org"
       :sitemap-title "Posts"
       :sitemap-sort-files anti-chronologically
       :sitemap-format-entry blog-sitemap-entry
       :sitemap-function blog-sitemap
       ,@page-options)
      ("blog-archive"
       :base-directory ,(blog-path "posts/archive")
       :publishing-directory ,(blog-path "public/html")
       :auto-sitemap t
       :sitemap-filename "../../archive.org"
       :sitemap-title "Archive"
       :sitemap-sort-files anti-chronologically
       :sitemap-format-entry blog-sitemap-entry
       :sitemap-function blog-sitemap
       ,@page-options)
      ("blog-index"
       :base-directory ,blog-root
       :exclude "."
       :include ("index.org" "archive.org" "404.org" "search.org")
       :publishing-directory ,(blog-path "public")
       ,@page-options)
      ("blog-tags"
       :base-directory ,(blog-path "tags")
       :recursive t
       :publishing-directory ,(blog-path "public/tags")
       :preparation-function blog-write-tag-pages
       ,@page-options)
      ("blog-media"
       :base-directory ,(blog-path "posts")
       :base-extension "png\\|jpe?g\\|gif\\|svg\\|webp\\|mp4\\|webm"
       :publishing-directory ,(blog-path "public/html")
       :publishing-function org-publish-attachment
       :recursive t)
      ("blog-files"
       :base-directory ,(blog-path "posts/files")
       :base-extension any
       :publishing-directory ,(blog-path "public/html/files")
       :publishing-function org-publish-attachment
       :recursive t)
      ("blog-static"
       :base-directory ,(blog-path "static")
       :base-extension "css\\|js\\|woff2"
       :publishing-directory ,(blog-path "public/static")
       :publishing-function org-publish-attachment
       :recursive t)
      ("blog-root-files"  ; favicons and robots.txt must be at the site root
       :base-directory ,(blog-path "static")
       :base-extension "ico\\|png\\|txt"
       :publishing-directory ,(blog-path "public")
       :publishing-function org-publish-attachment)
      ("blog" :components ("blog-posts" "blog-archive" "blog-index" "blog-tags"
                           "blog-media" "blog-files" "blog-static" "blog-root-files")))))

(defconst blog-build-stamp ".cache/build-stamp"
  "File that the build touches after it publishes, relative to `blog-root'.")

(defun blog-templates-changed-p ()
  "Return non-nil if a file that all pages use is newer than the last build.
These files are layout/*.html, publish.el, and blog-tags.el.  Without
a build stamp, the value is t."
  (let ((stamp (blog-path blog-build-stamp)))
    (seq-some (lambda (file) (file-newer-than-file-p file stamp))
              (append (directory-files (blog-path "layout") t "\\.html\\'")
                      (mapcar #'blog-path '("publish.el" "blog-tags.el"))))))

(defun blog-publish (&optional force)
  "Publish the blog to public/.  With FORCE, export all files again.
All files are also exported again when `blog-templates-changed-p'."
  (interactive "P")
  (let* ((force (or force (blog-templates-changed-p)))
         (org-publish-timestamp-directory (blog-path ".cache/"))
         (tags (blog-tags-collect (blog-post-files (blog-projects))))
         (org-publish-project-alist (blog-projects tags))
         (org-html-htmlize-output-type 'css)
         (org-export-use-babel nil)
         (org-export-before-parsing-functions
          (append '(blog-add-transclusions blog-add-heading-ids)
                  org-export-before-parsing-functions))
         (org-export-filter-body-functions
          (cons #'blog-add-post-tags org-export-filter-body-functions))
         (org-export-filter-final-output-functions
          (append '(blog-lazy-images blog-add-sidebar) org-export-filter-final-output-functions))
         (make-backup-files nil))
    (org-publish "blog" force)
    (blog-feeds-write (blog-post-files org-publish-project-alist) (blog-path "public"))
    (write-region "" nil (blog-path blog-build-stamp) nil 'silent)))

(provide 'publish)
;;; publish.el ends here
