;;; org-random-todo.el --- notify of random TODO's

;; Copyright (C) 2013 Kevin Brubeck Unhammer

;; Author: Kevin Brubeck Unhammer <unhammer+dill@mm.st>
;; Version: 0.2
;; Package-Requires: ((emacs "24.3"))
;; Keywords: org todo notification

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Show a random TODO from your org-agenda-files every so often.
;; Requires org-element, which was added fairly recently to org-mode
;; (tested with org-mode version 7.9.3f and later).

;;; Code:

(require 'org-element)
(require 'cl-lib)
(require 'notifications nil 'noerror)
(unless (fboundp 'cl-mapcan) (defalias 'cl-mapcan 'mapcan))

(defvar org-random-todo-files nil
  "Files to grab TODO items from.
If nil, use `org-agenda-files'.")

(defvar org-random-todo--cache nil)

(defun org-random-todo--update-cache ()
  "Update the cache of TODO's."
  (setq org-random-todo--cache
	(cl-mapcan
	 (lambda (file)
	   (when (file-exists-p file)
	     (with-current-buffer (org-get-agenda-file-buffer file)
	       (org-element-map (org-element-parse-buffer)
				'headline
				(lambda (hl)
				  (when (and (org-element-property :todo-type hl)
					     (not (equal 'done (org-element-property :todo-type hl))))
				    (cons file
					  (concat (org-element-property :todo-keyword hl)
						  ": "
						  (org-element-property :raw-value hl)))))))))
	 (or org-random-todo-files org-agenda-files))))

(defvar org-random-todo--notification-id nil)

(defvar org-random-todo-notification-timeout 4000
  "How long to show the on-screen notification.")

;;;###autoload
(defun org-random-todo ()
  "Show a random TODO notification from your agenda files.
See `org-random-todo-files' to change what files are crawled.
Runs `org-random-todo--update-cache' if TODO's are out of date."
  (interactive)
  (unless (minibufferp)	 ; don't run if minibuffer is asking something
    (unless org-random-todo--cache
      (org-random-todo--update-cache))
    (with-temp-buffer
      (let ((todo (nth (random (length org-random-todo--cache))
		       org-random-todo--cache)))
	(message "%s: %s" (file-name-base (car todo)) (cdr todo))
	(when (and (require 'notifications nil 'noerror)
                   (notifications-get-capabilities))
          (setq org-random-todo--notification-id
                (notifications-notify :title (file-name-base (car todo))
                                      :body (cdr todo)
                                      :timeout org-random-todo-notification-timeout
                                      :replaces-id org-random-todo--notification-id)))))))

(defvar org-random-todo-how-often 600
  "Show a message every this many seconds.
This happens simply by requiring `org-random-todo', as long as
this variable is set to a number.")

(when (numberp org-random-todo-how-often)
  (run-with-timer org-random-todo-how-often
                  org-random-todo-how-often
                  'org-random-todo))


(defvar org-random-todo-cache-idletime 600
  "Update cache after being idle this many seconds.
See `org-random-todo--update-cache'; only happens if this variable is
a number.")

(when (numberp org-random-todo-cache-idletime)
  (run-with-idle-timer org-random-todo-cache-idletime
                       'on-each-idle
                       'org-random-todo--update-cache))

(provide 'org-random-todo)
;;; org-random-todo.el ends here
