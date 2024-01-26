;;; package-generator.el --- Generate Emacs Lisp package boilerplate
;; -*- lexical-binding: t -*-

;; Author: L. S. Russell <lesliesrussell@gmail.com>
;; Version: 1.0
;; Keywords: tools, package, development
;; URL: http://example.com/package-name
;; Package-Requires: ((emacs "29.1"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;; `package-generator.el` provides a convenient way to generate boilerplate
;; code for new Emacs Lisp packages. It creates a standard directory structure
;; along with basic files like README, LICENSE, and a .el file for the package.
;; The package also initializes a git repository in the package directory.

;; Usage:
;; To generate a new package, use the interactive function `pg-generate-package`.
;; It prompts for the package name and automatically sets up the directory
;; structure and files based on customizable templates and settings.

;; Customization:
;; The following variables can be customized:
;; - `pg-author`: Default author name and email.
;; - `pg-version`: Default version number for the package.
;; - `pg-package-requires`: List of package dependencies.
;; - `pg-keywords`: List of keywords for the package.
;; - `pg-url`: URL of the package.
;; - `pg-root-dir`: Root directory for creating new packages.
;; - `pg-directory-structure`: List of directory paths to create.
;; - `pg-file-templates`: Alist of file templates for package files.

;;; Code:

;; Group definition for customization
(defgroup package-generator nil
  "Settings for the Emacs Lisp package generator."
  :group 'tools
  :prefix "pg-")

(defcustom pg-author "Your Name <email@example.com>"
  "Default author name and email."
  :type 'string
  :group 'package-generator)

(defcustom pg-version "1.0"
  "Default version number."
  :type 'string
  :group 'package-generator)

(defcustom pg-package-requires '((emacs "24.3"))
  "List of package dependencies."
  :type '(repeat (list (string :tag "Package")
                       (string :tag "Version")))
  :group 'package-generator)

(defcustom pg-keywords '("keyword1" "keyword2")
  "List of keywords for the package."
  :type '(repeat string)
  :group 'package-generator)

(defcustom pg-url "http://example.com/package-name"
  "URL of the package."
  :type 'string
  :group 'package-generator)

(defcustom pg-root-dir "~/.sandbox/"
  "Root directory for creating new packages."
  :type 'directory
  :group 'package-generator)

(defcustom pg-directory-structure '("src" "test" "docs" "examples" "resources")
  "List of directory paths to create in the new package."
  :type '(repeat string)
  :group 'package-generator)

(defcustom pg-file-templates
  '(("src" . (("package-name.el" . generate-package-el-template)
              ("package-name-pkg.el" . generate-package-pkg-template)))
    ("docs" . (("readme.org" . "<static template string for readme.org>")
               ("license.txt" . "<static template string for license.txt>")))
    ("examples" . (("demo.el" . "<this is a goddamned demo>"))))
  "Alist of subdirectories and their file-template pairs."
  :type '(alist :key-type string
                :value-type (repeat (cons (string :tag "File name")
                                          (sexp :tag "Template function symbol or static string"))))
  :group 'package-generator)

(defun pg-git-init (package-dir)
  "Initialize a new Git repository in the given PACKAGE-DIR."
  (let ((default-directory package-dir))
    (shell-command "git init")))

(defun generate-package-el-template (package-name)
  "Generate a template string for package-name.el."
  (concat ";;; " package-name ".el --- Description for " package-name "\n\n"
          ";;; Commentary:\n"
          ";; This file is part of " package-name ".\n\n"
          ";;; Code:\n\n"
          "(provide '" package-name ")\n"
          ";;; " package-name ".el ends here\n"))

(defun generate-package-pkg-template (package-name)
  "Generate the template for package-name-pkg.el using the custom variables.
Arguments:
 PACKAGE-NAME - the name of the package."
  (let ((requires-string (mapconcat (lambda (dep)
                                      (format "(%s \"%s\")" (car dep) (cadr dep)))
                                    pg-package-requires
                                    " ")))
    (format ";;; %s-pkg.el --- %s\n\n(define-package \"%s\" \"%s\"\n  \"%s\"\n  %s)\n\n;;; %s-pkg.el ends here"
            package-name (car pg-keywords)  ; Assuming the first keyword as a brief description.
            package-name pg-version (car pg-keywords) requires-string
            package-name)))

(defun pg-create-directory-structure (root-dir package-name)
  "Create the basic directory structure for a package named PACKAGE-NAME in ROOT-DIR."
  (let ((package-dir (expand-file-name package-name root-dir)))
    ;; Create the package directory
    (unless (file-directory-p package-dir)
      (make-directory package-dir t))

    ;; Create the subdirectories within the package directory
    (dolist (subdir pg-directory-structure)
      (let ((full-path (concat package-dir "/" subdir)))
        (unless (file-directory-p full-path)
          (make-directory full-path t))))))

(defun pg-create-files (package-dir package-name)
  "Create files in PACKAGE-DIR for PACKAGE-NAME based on pg-file-templates."
  (dolist (dir-template pg-file-templates)
    (let* ((subdir (car dir-template))
           (files (cdr dir-template))
           (full-subdir-path (concat package-dir "/" subdir)))
      ;; Ensure the subdirectory exists
      (unless (file-directory-p full-subdir-path)
        (make-directory full-subdir-path t))
      ;; Create each file in the subdirectory
      (dolist (file-template files)
        (let* ((file-name (replace-regexp-in-string "package-name" package-name (car file-template)))
               (template-func-or-string (cdr file-template))
               (template (if (functionp template-func-or-string)
                             (funcall template-func-or-string package-name)
                           template-func-or-string))
               (full-file-path (concat full-subdir-path "/" file-name)))
          (with-temp-file full-file-path
            (insert template)))))))

;;;###autoload
(defun pg-generate-package ()
  "Interactive function to generate a new Emacs Lisp package."
  (interactive)
  ;; Ask only for the package name
  (let ((package-name (read-string "Package name: "))
        (dir pg-root-dir))
    ;; Create directory structure
    (pg-create-directory-structure dir package-name)
    (pg-create-files (concat dir package-name) package-name)
    ;; Initialize Git repository
    (pg-git-init (concat dir package-name))))

(provide 'package-generator)
;;; package-generator.el ends here
