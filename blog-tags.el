;;; blog-tags.el --- Tag pages for the blog  -*- lexical-binding: t; -*-

;;; Commentary:

;; Makes the tag cloud page and one page for each tag from the
;; #+FILETAGS of the posts, and the tag links on post pages.  The tag
;; pages are org files in a generated directory, and publish.el
;; publishes them as other pages.
;;
;; Write tags as #+FILETAGS: :tag1:tag2:.  The export reads only this
;; form; with spaces, "tag1 tag2" is one tag.

;;; Code:

(require 'ox-publish)
(require 'ox-html)
(require 'subr-x)
(require 'url-util)

(defun blog-tags--date (post)
  "Return the date of POST, a (FILE . PROJECT) pair."
  (org-publish-find-date (car post) (cdr post)))

(defun blog-tags-collect (posts)
  "Return an alist (TAG . TAG-POSTS) for POSTS, sorted by tag name.
POSTS is a list of (FILE . PROJECT).  TAG-POSTS are newest first."
  (let ((table (make-hash-table :test #'equal)))
    (dolist (post posts)
      (dolist (tag (org-publish-find-property (car post) :filetags (cdr post)))
        (push post (gethash tag table))))
    (sort (mapcar (lambda (tag)
                    (cons tag (sort (gethash tag table)
                                    (lambda (a b)
                                      (time-less-p (blog-tags--date b) (blog-tags--date a))))))
                  (hash-table-keys table))
          (lambda (a b) (string< (car a) (car b))))))

(defun blog-tags--link (tag &optional attributes)
  "Return an HTML link to the page of TAG, with extra ATTRIBUTES."
  (format "<a href=\"/tags/%s/\"%s>%s</a>"
          (url-hexify-string tag)
          (or attributes "")
          (org-html-encode-plain-text tag)))

(defun blog-tags--font-size (count max-count)
  "Return the font size in em of a tag with COUNT posts.
The size grows from the smallest size (one post) to the largest
size (MAX-COUNT posts)."
  (let ((smallest 0.9) (largest 1.25))
    (if (<= max-count 1)
        smallest
      (+ smallest (* (- largest smallest) (/ (float (1- count)) (1- max-count)))))))

(defun blog-tags-cloud-html (tags &optional with-counts)
  "Return the HTML list of the tag cloud for TAGS from `blog-tags-collect'.
See `blog-tags--font-size' for the size of each tag.  With
WITH-COUNTS, show the number of posts after each tag."
  (let ((max-count (apply #'max 1 (mapcar (lambda (tag) (length (cdr tag))) tags))))
    (concat
     "<ul class=\"tag-cloud\">\n"
     (mapconcat (lambda (tag)
                  (let ((count (length (cdr tag))))
                    (format "<li>%s%s</li>"
                            (blog-tags--link
                             (car tag)
                             (format " style=\"font-size: %.2fem\" title=\"%d post%s\""
                                     (blog-tags--font-size count max-count)
                                     count (if (= count 1) "" "s")))
                            (if with-counts (format " <span class=\"tag-count\">(%d)</span>" count) ""))))
                tags "\n")
     "\n</ul>\n")))

(defun blog-tags-cloud (tags)
  "Return the org text of the tag cloud page for TAGS."
  (concat "#+TITLE: Tags\n\n#+begin_export html\n"
          (blog-tags-cloud-html tags t)
          "#+end_export\n"))

(defun blog-tags-sidebar (tags &optional open)
  "Return the HTML of the sidebar block with the tag cloud for TAGS.
The tag cloud is collapsed, or open with OPEN; the summary toggles it."
  (concat (format "<details class=\"sidebar-tags\"%s>\n" (if open " open" ""))
          "<summary class=\"sidebar-title\">Tags</summary>\n"
          (blog-tags-cloud-html tags)
          "</details>\n"))

(defun blog-tags-page (tag posts format-page format-entry)
  "Return the org text of the page for TAG with POSTS.
FORMAT-PAGE and FORMAT-ENTRY are functions with the arguments of
the :sitemap-function and :sitemap-format-entry project properties."
  (funcall format-page
           (format "Tag: %s" tag)
           (cons 'unordered
                 (mapcar (lambda (post) (list (funcall format-entry (car post) 'list (cdr post))))
                         posts))))

(defun blog-tags--write-file (file text)
  "Write TEXT to FILE and make its directory if necessary."
  (make-directory (file-name-directory file) t)
  (with-temp-file file
    (insert text)))

(defun blog-tags-write (dir tags format-page format-entry)
  "Write the org files of the tag pages for TAGS to DIR.
DIR/index.org is the tag cloud, and DIR/TAG/index.org lists the posts
of TAG (see `blog-tags-page' for FORMAT-PAGE and FORMAT-ENTRY).  DIR
is deleted first, so pages of removed tags do not stay."
  (when (file-directory-p dir)
    (delete-directory dir t))
  (blog-tags--write-file (expand-file-name "index.org" dir) (blog-tags-cloud tags))
  (dolist (tag tags)
    (blog-tags--write-file (expand-file-name "index.org" (expand-file-name (car tag) dir))
                           (blog-tags-page (car tag) (cdr tag) format-page format-entry))))

(defun blog-tags-links (tags)
  "Return an HTML line with links to the pages of TAGS, or \"\" without TAGS."
  (if tags
      (format "<p class=\"post-tags\">Tags: %s</p>\n"
              (mapconcat #'blog-tags--link tags " "))
    ""))

(provide 'blog-tags)
;;; blog-tags.el ends here
