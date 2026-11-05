;;; blog-feeds.el --- RSS feed and sitemap for the blog  -*- lexical-binding: t; -*-

;;; Commentary:

;; Writes public/index.xml (RSS 2.0) and public/sitemap.xml.  The feed
;; has the same URL and the same <guid> values as the feed of the old
;; Hugo site, so feed readers do not show old posts as new.

;;; Code:

(require 'ox-publish)
(require 'seq)
(require 'xml)

(defconst blog-feeds-site-url "https://serebrov.github.io/"
  "The root URL of the site, with the final slash.")

(defconst blog-feeds-title "vim, git, aws and other three-letter words"
  "The title of the feed.")

(defconst blog-feeds-size 20
  "The number of newest posts in the feed.")

(defun blog-feeds--post-url (file)
  "Return the URL of the page made from the post FILE."
  (concat blog-feeds-site-url "html/"
          (file-name-with-extension (file-name-nondirectory file) "html")))

(defun blog-feeds--item (post)
  "Return the RSS <item> for POST, a (FILE . PROJECT) pair."
  (let* ((file (car post))
         (project (cdr post))
         (url (blog-feeds--post-url file))
         (system-time-locale "C"))
    (format "<item><title>%s</title><link>%s</link><guid>%s</guid><pubDate>%s</pubDate><description>%s</description></item>"
            (xml-escape-string (org-publish-find-title file project))
            url url
            (format-time-string "%a, %d %b %Y %H:%M:%S %z" (org-publish-find-date file project))
            (xml-escape-string
             (or (org-publish-find-property file :description project 'html) "")))))

(defun blog-feeds-rss (posts)
  "Return the RSS feed for the newest posts of POSTS.
POSTS is a list of (FILE . PROJECT)."
  (let ((newest (seq-take (seq-sort-by (lambda (post)
                                         (float-time (org-publish-find-date (car post) (cdr post))))
                                       #'> posts)
                          blog-feeds-size)))
    (concat "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
            "<rss version=\"2.0\"><channel>\n"
            (format "<title>%s</title><link>%s</link><description>%s</description>\n"
                    blog-feeds-title blog-feeds-site-url blog-feeds-title)
            (mapconcat #'blog-feeds--item newest "\n")
            "\n</channel></rss>\n")))

(defun blog-feeds-sitemap (public-dir)
  "Return the sitemap of all HTML pages in PUBLIC-DIR.
The URL of an index.html page is the URL of its directory."
  (concat "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
          "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
          (mapconcat (lambda (file)
                       (format "<url><loc>%s%s</loc></url>"
                               blog-feeds-site-url
                               (string-remove-suffix "index.html"
                                                     (file-relative-name file public-dir))))
                     (directory-files-recursively public-dir "\\.html\\'")
                     "\n")
          "\n</urlset>\n"))

(defun blog-feeds-write (posts public-dir)
  "Write index.xml for POSTS and sitemap.xml to PUBLIC-DIR."
  (let ((coding-system-for-write 'utf-8))
    (write-region (blog-feeds-rss posts) nil (expand-file-name "index.xml" public-dir))
    (write-region (blog-feeds-sitemap public-dir) nil (expand-file-name "sitemap.xml" public-dir))))

(provide 'blog-feeds)
;;; blog-feeds.el ends here
