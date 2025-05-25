;;; mini-echo-segments.el --- Collection of mini echo segments -*- lexical-binding: t -*-

;; This file is not a part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; This file is not a part of GNU Emacs.

;;; Commentary:

;; Most segments are ported from other mode line package.
;; SEE https://github.com/seagle0128/doom-modeline/blob/master/doom-modeline-segments.el

;;; Code:

(eval-when-compile
  (require 'let-alist)
  (require 'eieio))

(require 'pcase)
(require 'cl-lib)
(require 'seq)
(require 'subr-x)

(defvar mini-echo-ellipsis)
(defvar meow--indicator)
(defvar evil-state)
(defvar evil-visual-beginning)
(defvar evil-visual-end)
(defvar evil-this-macro)
(defvar flymake-suppress-zero-counters)
(defvar flymake-mode-line-exception)
(defvar dired-actual-switches)
(defvar magit-blob-mode)
(defvar magit-blame-mode-lighter)
(defvar display-time-string)
(defvar lsp-bridge-mode-lighter)
(defvar eglot-mode-line-format)
(defvar eglot--mode-line-format)
(defvar envrc--status)
(defvar flycheck-last-status-change)
(defvar flycheck-current-errors)
(defvar repeat-in-progress)
(defvar battery-mode-line-string)
(defvar envrc-lighter)
(defvar keycast-mode-line-format)
(defvar text-scale-mode-lighter)
(defvar mise-lighter)
(defvar mise--status)
(defvar ibuffer-display-maybe-show-predicates)
(defvar popper-group-function)
(defvar popper-buried-popup-alist)
(defvar wgrep-prepared)
(defvar wgrep-sibling-buffer)
(defvar current-input-method-title)
(defvar profiler-report-profile)
(defvar profiler-report-order)
(defvar profiler-report-reversed)
(defvar xwidget-webkit--loading-p)
(defvar project-mode-line-format)
(defvar treesit-explore-mode)
(defvar treesit-inspect-mode)
(defvar treesit--inspect-name)
(defvar org-src--source-type)
(defvar org-src--babel-info)

(declare-function profiler-profile-type "profiler")
(declare-function profiler-profile-diff-p "profiler")
(declare-function eieio-oset "eieio-core")
(declare-function xwidget-webkit-current-session "xwidget")
(declare-function xwidget-webkit-estimated-load-progress "xwidget")
(declare-function xwidget-webkit-title "xwidget")
(declare-function org-src-edit-buffer-p "org-src")
(declare-function projectile-project-root "ext:projectile")
(declare-function ffip-project-root "ext:ffip")
(declare-function keycast--format "ext:keycast")
(declare-function keycast--update "ext:keycast")
(declare-function evil-emacs-state-p "ext:evil-states" t t)
(declare-function evil-insert-state-p "ext:evil-states" t t)
(declare-function evil-motion-state-p "ext:evil-states" t t)
(declare-function evil-normal-state-p "ext:evil-states" t t)
(declare-function evil-operator-state-p "ext:evil-states" t t)
(declare-function evil-replace-state-p "ext:evil-states" t t)
(declare-function evil-visual-state-p "ext:evil-states" t t)
(declare-function evil-state-property "ext:evil-common")
(declare-function lsp-workspaces "ext:lsp-mode")
(declare-function flycheck-count-errors "ext:flycheck")
(declare-function elfeed-search--count-unread "ext:elfeed")

(defcustom mini-echo-buffer-status-style 'sign
  "Style used to display buffer status in mini echo."
  :type '(choice (const :tag "Change extra sign after buffer name" sign)
                 (const :tag "Change color of buffer name" color)
                 (const :tag "Change both color and sign" both))
  :group 'mini-echo)

(defcustom mini-echo-vcs-max-length 15
  "Max length limit of vcs segment string."
  :type '(choice (number
                  (const :tag "no limit for vcs" nil)))
  :package-version '(mini-echo . "0.5.2")
  :group 'mini-echo)

(defcustom mini-echo-project-detection 'project
  "How to detect the project root in mini echo.
nil means to use `default-directory'.
`auto' means to detect the following options in order."
  :type '(choice (const :tag "Find File in Project" ffip)
                 (const :tag "Projectile" projectile)
                 (const :tag "Built-in Project" project)
                 function)
  :group 'mini-echo)

(defcustom mini-echo-mise-show-always t
  "If nil, do not show mise section when `mise--status' is global or none.
Otherwise, show mise section always."
  :type 'boolean
  :group 'mini-echo)

;; faces
(defface mini-echo-green
  '((t (:foreground "green")))
  "Face for mini-echo segment with green color."
  :group 'mini-echo)

(defface mini-echo-yellow
  '((t (:foreground "yellow")))
  "Face for mini-echo segment with yellow color."
  :group 'mini-echo)

(defface mini-echo-blue
  '((t (:foreground "blue")))
  "Face for mini-echo segment with blue color."
  :group 'mini-echo)

(defface mini-echo-red
  '((t (:foreground "red")))
  "Face for mini-echo segment with red color."
  :group 'mini-echo)

(defface mini-echo-magenta
  '((t (:foreground "magenta")))
  "Face for mini-echo segment with magenta color."
  :group 'mini-echo)

(defface mini-echo-cyan
  '((t (:foreground "cyan")))
  "Face for mini-echo segment with cyan color."
  :group 'mini-echo)

(defface mini-echo-gray
  '((t (:foreground "gray")))
  "Face for mini-echo segment with gray color."
  :group 'mini-echo)

(defface mini-echo-green-bold
  '((t (:inherit (bold mini-echo-green))))
  "Face for mini-echo segment with bold green color."
  :group 'mini-echo)

(defface mini-echo-yellow-bold
  '((t (:inherit (bold mini-echo-yellow))))
  "Face for mini-echo segment with bold yellow color."
  :group 'mini-echo)

(defface mini-echo-blue-bold
  '((t (:inherit (bold mini-echo-blue))))
  "Face for mini-echo segment with bold blue color."
  :group 'mini-echo)

(defface mini-echo-red-bold
  '((t (:inherit (bold mini-echo-red))))
  "Face for mini-echo segment with bold red color."
  :group 'mini-echo)

(defface mini-echo-cyan-bold
  '((t (:inherit (bold mini-echo-cyan))))
  "Face for mini-echo segment with bold cyan color."
  :group 'mini-echo)

(defface mini-echo-magenta-bold
  '((t (:inherit (bold mini-echo-magenta))))
  "Face for mini-echo segment with bold magenta color."
  :group 'mini-echo)

(defface mini-echo-gray-bold
  '((t (:inherit (bold mini-echo-gray))))
  "Face for mini-echo segment with bold gray color."
  :group 'mini-echo)

(defface mini-echo-major-mode
  '((t (:inherit bold)))
  "Face for mini-echo segment of major mode."
  :group 'mini-echo)

(defface mini-echo-buffer-size
  '((t (:inherit default)))
  "Face for mini-echo segment of buffer size."
  :group 'mini-echo)

(defface mini-echo-buffer-position
  '((t (:inherit mini-echo-magenta)))
  "Face for mini-echo segment of buffer position."
  :group 'mini-echo)

(defface mini-echo-char-info
  '((t (:inherit mini-echo-magenta)))
  "Face for mini-echo segment of char info."
  :group 'mini-echo)

(defface mini-echo-remote-host
  '((t (:inherit mini-echo-red)))
  "Face for mini-echo segment of remote host."
  :group 'mini-echo)

(defface mini-echo-word-count
  '((t (:inherit mini-echo-yellow)))
  "Face for mini-echo segment of word count."
  :group 'mini-echo)

(defface mini-echo-last-command
  '((t (:inherit (mini-echo-blue bold))))
  "Face for mini-echo segment of last command."
  :group 'mini-echo)

(defface mini-echo-project
  '((t (:inherit mini-echo-blue)))
  "Face for mini-echo segment of project directory."
  :group 'mini-echo)

(defface mini-echo-blob-revision
  '((t (:inherit mini-echo-red)))
  "Face for mini-echo segment of blob revision."
  :group 'mini-echo)

(defface mini-echo-special-minor
  '((t (:inherit mini-echo-magenta-bold)))
  "Face for mini-echo segment of special minor mode."
  :group 'mini-echo)

(defface mini-echo-status-local
  '((t (:inherit (mini-echo-yellow bold))))
  "Face for mini-echo segment to show status in local buffer."
  :group 'mini-echo)

(defface mini-echo-status-global
  '((t (:inherit (mini-echo-cyan bold))))
  "Face for mini-echo segment to show status in global."
  :group 'mini-echo)

(defface mini-echo-selection-info
  '((t (:inherit mini-echo-status-local)))
  "Face for mini-echo segment of selection info."
  :group 'mini-echo)

(defface mini-echo-narrow
  '((t (:inherit mini-echo-status-local)))
  "Face for mini-echo segment of narrow status."
  :group 'mini-echo)

(defface mini-echo-macro
  '((t (:inherit mini-echo-status-global)))
  "Face for mini-echo segment of macro status."
  :group 'mini-echo)

(defface mini-echo-input-method
  '((t (:inherit mini-echo-status-local)))
  "Face for mini-echo segment of input method."
  :group 'mini-echo)

(defface mini-echo-process
  '((t (:inherit mini-echo-status-global)))
  "Face for mini-echo segment of process."
  :group 'mini-echo)

(defface mini-echo-repeat
  '((t (:inherit mini-echo-status-global)))
  "Face for mini-echo segment of `repeat-mode' status."
  :group 'mini-echo)

(defface mini-echo-profiler
  '((t (:inherit mini-echo-status-global)))
  "Face for mini-echo segment of profiler status."
  :group 'mini-echo)

(defface mini-echo-evil-normal-state
  '((t (:inherit mini-echo-blue)))
  "Face for mini-echo segment of evil normal state."
  :group 'mini-echo)

(defface mini-echo-evil-insert-state
  '((t (:inherit mini-echo-green)))
  "Face for mini-echo segment of evil insert state."
  :group 'mini-echo)

(defface mini-echo-evil-visual-state
  '((t (:inherit mini-echo-yellow)))
  "Face for mini-echo segment of evil visual state."
  :group 'mini-echo)

(defface mini-echo-evil-emacs-state
  '((t (:inherit mini-echo-magenta)))
  "Face for mini-echo segment of evil Emacs state."
  :group 'mini-echo)

(defface mini-echo-evil-motion-state
  '((t (:inherit mini-echo-gray)))
  "Face for mini-echo segment of evil motion state."
  :group 'mini-echo)

(defface mini-echo-evil-operator-state
  '((t (:inherit mini-echo-cyan)))
  "Face for mini-echo segment of evil operator state."
  :group 'mini-echo)

(defface mini-echo-evil-replace-state
  '((t (:inherit mini-echo-red)))
  "Face for mini-echo segment of evil replace state."
  :group 'mini-echo)

(defface mini-echo-lsp
  '((t (:inherit mini-echo-green)))
  "Face for mini-echo segment of lsp."
  :group 'mini-echo)

(defvar mini-echo-segment-alist nil)

;;; Utils

(cl-defstruct mini-echo-segment
  name &key fetch activate setup update update-hook update-advice)

;;;###autoload
(defmacro mini-echo-define-segment (name docstring &rest props)
  "Define a mini echo segment NAME with DOCSTRING and PROPS."
  (declare (indent defun) (doc-string 2))
  (if (plistp props)
      (cl-destructuring-bind (&key setup fetch update update-hook update-advice)
          props
        (pcase-let* ((`(,fetch-func ,update-func ,setup-func)
                      (mapcar
                       (lambda (s)
                         (intern (concat "mini-echo-segment--"
                                         (format "%s-%s" s name))))
                       '("fetch" "update" "setup"))))
          `(progn
             (let ((segment (make-mini-echo-segment :name ,name)))
               ;; push segment into mini echo alist
               (setf (alist-get ,name mini-echo-segment-alist nil nil #'string=) segment)
               (with-slots ((to-fetch fetch) (to-update update)
                            (to-hook update-hook) (to-advice update-advice)
                            (to-setup setup))
                   segment
                 ;; fetch
                 (defun ,fetch-func () ,docstring ,fetch)
                 (setf to-fetch ',fetch-func)
                 ;; update
                 (when (consp ',update)
                   (defun ,update-func (&rest _args)
                     (when (bound-and-true-p mini-echo-mode)
                       ,update))
                   (setf to-update ',update-func
                         to-hook ,update-hook
                         to-advice ,update-advice))
                 ;; setup
                 (and (or ,update-hook ,update-advice (consp ',setup))
                      (defun ,setup-func ()
                        ,setup
                        (dolist (h ,update-hook)
                          (add-hook h ',update-func))
                        (dolist (v ,update-advice)
                          (advice-add (car v) (cdr v) ',update-func)))
                      (setf to-setup ',setup-func)))
               segment))))
    (message "mini-echo-define-segment: %s properties error!" name)))

(defun mini-echo-segment--extract (construct &optional force)
  "Return a string with only property of face based on CONSTRUCT.
CONSTRUCT is mode line data structure ,when CONSTRUCT is not a string or
optional arg FORCE is non-nil, call `format-mode-line' always."
  (when-let* ((str (or (and (stringp construct) (null force) construct)
                       (copy-sequence (format-mode-line construct)))))
    ;; NOTE remove all text properties except face
    (remove-list-of-text-properties 0 (length str)
                                    '(help-echo mouse-face keymap local-map
                                                flymake--diagnostic-type display)
                                    str)
    (string-trim str)))

(defun mini-echo-segment--print (string &optional face max-length)
  "Return a STRING after trimmed with FACE property if it has.
If optional arg MAX-LENGTH is a number, return truncated string or combined
with ellipsis."
  (when-let* ((str (and (stringp string) (string-trim string))))
    (when (and max-length (> (length str) max-length))
      (if-let* ((suffix mini-echo-ellipsis)
                (len (length suffix)))
          (progn
            (when-let* ((suffix-face (get-text-property (- (length str) 1) 'face str)))
              (put-text-property 0 len 'face suffix-face suffix))
            (setq str (concat (substring str 0 (- max-length len)) suffix)))
        (setq str (substring str 0 max-length))))
    (if face (propertize str 'face face) str)))

;;; Built-in segments

(mini-echo-define-segment "major-mode"
  "Return major mode info of current buffer."
  :fetch
  (when (bound-and-true-p mode-name)
    (mini-echo-segment--print
     (substring-no-properties
      (pcase major-mode
        ('dired-mode "Dired")
        (_ (mini-echo-segment--extract mode-name))))
     'mini-echo-major-mode)))

(mini-echo-define-segment "buffer-position"
  "Return the cursor position of current buffer."
  :fetch
  (when-let* ((format mode-line-position-column-line-format)
              (pos (mini-echo-segment--extract format 'force)))
    (mini-echo-segment--print (string-replace "Bottom" "Bot" pos)
                              'mini-echo-buffer-position)))

(mini-echo-define-segment "char-info"
  "Return the char information of point in current buffer."
  :fetch
  (when-let* ((pos (point))
              (char (char-after pos))
              (charset (if (and (not enable-multibyte-characters) (>= char 128))
                           'eight-bit
                         (or (get-text-property pos 'charset)
                             (char-charset char))))
              (char-description (if (< char 128)
                                    (single-key-description char)
                                  (string (if (not enable-multibyte-characters)
                                              (decode-char 'eight-bit char)
                                            char)))))
    (mini-echo-segment--print
     (format "\"%s\",%s,(%d,#o%o,#x%x)" char-description charset char char char)
     'mini-echo-char-info)))

(mini-echo-define-segment "buffer-size"
  "Return the size of current buffer."
  :fetch
  (mini-echo-segment--print (mini-echo-segment--extract "%I" 'force)
                            'mini-echo-buffer-size))

(defvar-local mini-echo--project-root nil)
(defun mini-echo-update-project-root ()
  "Update and return current project root path if exists."
  (setq mini-echo--project-root
        (or (pcase mini-echo-project-detection
              ('ffip (and (fboundp 'ffip-project-root)
                          (let ((inhibit-message t))
                            (ffip-project-root))))
              ('projectile (and (bound-and-true-p projectile-mode)
                                (projectile-project-root)))
              ('project (when-let* (((fboundp 'project-current))
                                    (project (project-current)))
                          (expand-file-name
                           (if (fboundp 'project-root)
                               (project-root project)
                             (car (with-no-warnings
                                    (project-roots project)))))))
              (_ (funcall mini-echo-project-detection)))
            "")))

(mini-echo-define-segment "project"
  "Display the project name of current buffer."
  :update-advice '((vc-refresh-state . :after))
  :fetch
  (if (bound-and-true-p project-mode-line)
      (mini-echo-segment--extract project-mode-line-format)
    (when-let* ((project (or mini-echo--project-root
                             (mini-echo-update-project-root)))
                ((not (string-empty-p project))))
      (mini-echo-segment--print (file-name-nondirectory (directory-file-name project))
                                'mini-echo-project)))
  :update (mini-echo-update-project-root))

(defun mini-echo-buffer-read-only ()
  "Return read only info of current buffer."
  (when buffer-read-only (propertize "%" 'face 'mini-echo-yellow-bold)))

(defun mini-echo-buffer-status ()
  "Display the visited file status of current buffer."
  (let* ((file-name (buffer-file-name))
         (file-exist (and file-name (file-exists-p file-name)))
         (file-remote (and file-name (file-remote-p file-name))))
    (cond
     ;; for buffers which files are modified outside Emacs
     ((and file-exist (not file-remote) (not (verify-visited-file-modtime)))
      (cons "!" 'mini-echo-yellow-bold))
     ((and file-exist (buffer-modified-p))
      (cons "*" 'mini-echo-green-bold))
     ((and buffer-file-name (not file-exist) (not file-remote))
      (cons "?" 'mini-echo-red-bold))
     (t (cons " " nil)))))

(defun mini-echo-buffer-name ()
  "Return current buffer name."
  (let ((uniquify-buffer-name-style 'forward))
    (buffer-name)))

(defun mini-echo-buffer-name-with-status ()
  "Return last part of buffer name with status."
  ;; NOTE only highlight the last part of buffer-name due to `uniquify-buffer-name-style'
  (pcase-let* ((name-end (file-name-nondirectory (mini-echo-buffer-name)))
               (`(,sign . ,face) (mini-echo-buffer-status)))
    (pcase mini-echo-buffer-status-style
      ('sign (concat name-end (propertize sign 'face face)))
      ('color (propertize name-end 'face face))
      ('both (propertize (concat name-end sign) 'face face)))))

(mini-echo-define-segment "buffer-name"
  "Return name of current buffer."
  :fetch
  (concat
   (mini-echo-buffer-read-only)
   (file-name-directory (mini-echo-buffer-name))
   (mini-echo-buffer-name-with-status)))

(mini-echo-define-segment "shrink-path"
  "Return shrink path of current buffer in project or parent dir."
  :update-advice '((vc-refresh-state . :after))
  :fetch
  (concat
   (mini-echo-buffer-read-only)
   (let* ((filepath (buffer-file-name))
          (project (or mini-echo--project-root
                       (mini-echo-update-project-root)))
          (dir (thread-last default-directory
                            (or (and (not (string-empty-p project)) project))
                            (directory-file-name)
                            (file-name-nondirectory))))
     (cond
      ((not filepath) "")
      ((string-empty-p project) (propertize (concat dir "/") 'face 'shadow))
      ((string-prefix-p project filepath)
       (let* ((parts (butlast (split-string (string-remove-prefix project filepath) "/")))
              (suffix (if (<= (length parts) 4)
                          (string-join
                           `("" ,@(mapcar
                                   (lambda (s) (substring s 0 1)) parts) "")
                           "/")
                        "/../")))
         (concat (propertize dir 'face 'mini-echo-project)
                 (propertize suffix 'face 'shadow))))
      (t "")))
   (mini-echo-buffer-name-with-status))
  :update (mini-echo-update-project-root))

(mini-echo-define-segment "dired"
  "Return dired info of current buffer."
  :fetch
  (when (eq major-mode 'dired-mode)
    (save-match-data
      (let* ((switches dired-actual-switches)
             (sort-by
              (and (string-match
                    (concat
                     "--sort="
                     (regexp-opt '("size" "time" "version" "extension" "width") t))
                    switches)
                   (match-string 1 switches)))
             (time-kind
              (and (string-match
                    (concat
                     "--time=" (regexp-opt '("atime" "ctime" "mtime" "birth") t))
                    switches)
                   (match-string 1 switches)))
             (sort-item (if sort-by
                            (if (string= sort-by "time")
                                (or time-kind "mtime")
                              sort-by)
                          "name"))
             (sign (if (string-match-p "--reverse" switches) "\u2191" "\u2193")))
        (format "%s%s"
                (propertize sort-item 'face 'dired-symlink)
                (propertize sign 'face 'dired-warning))))))

(mini-echo-define-segment "remote-host"
  "Return the hostname of remote buffer."
  :fetch
  (when default-directory
    (when-let* ((host (file-remote-p default-directory 'host)))
      (mini-echo-segment--print (concat "@" host) 'mini-echo-remote-host))))

(mini-echo-define-segment "process"
  "Return current process info."
  :fetch
  (when-let* (((bound-and-true-p mode-line-process))
              (str (mini-echo-segment--extract mode-line-process 'force))
              ((not (string-empty-p str))))
    (pcase major-mode
      ('ibuffer-mode
       (let ((sign (if (string-match-p "\\[rev]" str) "\u2193" "\u2191"))
             (auto-p (if (string-match-p "Auto" str) "auto" ""))
             (sort-item (cadr (split-string str "[ ]"))))
         (format "%s|%s|%s"
                 (propertize auto-p 'face 'mini-echo-gray-bold)
                 (propertize (if ibuffer-display-maybe-show-predicates "show" "hide")
                             'face 'mini-echo-green-bold)
                 (concat (propertize sort-item 'face 'mini-echo-blue-bold)
                         (propertize sign 'face 'mini-echo-yellow-bold)))))
      ((guard (derived-mode-p 'sh-base-mode)) nil)
      ('rg-mode (car (split-string str " ")))
      (_ (mini-echo-segment--print str nil nil)))))

(mini-echo-define-segment "time"
  "Return current time."
  :setup (display-time-mode 1)
  :fetch (mini-echo-segment--extract display-time-string))

(mini-echo-define-segment "battery"
  "Return the battery status.
Display format is inherited from `battery-mode-line-format'."
  :setup (display-battery-mode 1)
  :fetch
  (when (bound-and-true-p battery-mode-line-string)
    (mini-echo-segment--extract battery-mode-line-string)))

(mini-echo-define-segment "profiler"
  "Return current profiler status"
  :fetch
  (when (or (profiler-cpu-running-p)
            (profiler-memory-running-p))
    (mini-echo-segment--print "Profiler" 'mini-echo-profiler)))

(mini-echo-define-segment "profiler-report"
  "Return info of profiler report."
  :fetch
  (when (eq major-mode 'profiler-report-mode)
    (let* ((profile profiler-report-profile)
           (type (symbol-name (profiler-profile-type profile)))
           (diff (if (profiler-profile-diff-p profile) "diff" "no-diff"))
           (order (symbol-name profiler-report-order))
           (direction (if profiler-report-reversed "reversed" "forward")))
      (format "%s|%s|%s [%s]"
              (propertize order 'face 'mini-echo-yellow)
              (propertize direction 'face 'mini-echo-red)
              (propertize diff 'face 'mini-echo-gray)
              (propertize type 'face 'mini-echo-blue-bold)))))

(mini-echo-define-segment "macro"
  "Indicator of macro being recorded or executed."
  :fetch
  (when defining-kbd-macro
    (let ((str (if (bound-and-true-p evil-this-macro)
                   (format "@%s" (char-to-string evil-this-macro))
                 "Def")))
      (mini-echo-segment--print str 'mini-echo-macro))))

(mini-echo-define-segment "input-method"
  "Indicator that shows current input method if it is active."
  :fetch
  (when (stringp current-input-method-title)
    (mini-echo-segment--print current-input-method-title 'mini-echo-input-method)))

(mini-echo-define-segment "narrow"
  "Indicator of narrow status of current buffer."
  :fetch
  (mini-echo-segment--print (mini-echo-segment--extract "%n" t) 'mini-echo-narrow))

(defvar mini-echo--repeat nil)
(mini-echo-define-segment "repeat"
  "Indicator of whether repeating transient map is active."
  :update-advice '((repeat-post-hook . :after))
  :fetch
  (when mini-echo--repeat
    (mini-echo-segment--print "REPEAT" 'mini-echo-repeat))
  :update
  (setq mini-echo--repeat (and repeat-mode repeat-in-progress)))

(mini-echo-define-segment "flymake"
  "Return flymake diagnostics of current buffer."
  :fetch
  (when (bound-and-true-p flymake-mode)
    (concat
     (when-let* ((ind (mini-echo-segment--extract flymake-mode-line-exception))
                 ((not (string-empty-p ind))))
       (string-replace "Wait"
                       (propertize "*" 'face 'compilation-mode-line-run)
                       (substring ind 1)))
     (let ((flymake-suppress-zero-counters nil))
       (string-join (mapcar #'mini-echo-segment--extract
                            '(flymake-mode-line-error-counter
                              flymake-mode-line-warning-counter
                              flymake-mode-line-note-counter))
                    "/")))))

(defsubst mini-echo-column (pos)
  "Get the column of the position `POS'."
  (save-excursion (goto-char pos)
                  (current-column)))

(mini-echo-define-segment "selection-info"
  "Return current selection in current buffer."
  :fetch
  (when (or mark-active (and (bound-and-true-p evil-local-mode)
                             (eq evil-state 'visual)))
    (pcase-let* ((`(,beg . ,end)
                  (if (and (bound-and-true-p evil-local-mode) (eq evil-state 'visual))
                      (cons evil-visual-beginning evil-visual-end)
                    (cons (region-beginning) (region-end)))))
      (let* ((lines (count-lines beg (min end (point-max))))
             (str (cond ((or (bound-and-true-p rectangle-mark-mode)
                             (and (bound-and-true-p evil-visual-selection)
                                  (eq 'block evil-visual-selection)))
                         (let ((cols (abs (- (mini-echo-column end)
                                             (mini-echo-column beg)))))
                           (format "%dx%dB" lines cols)))
                        ((and (bound-and-true-p evil-visual-selection)
                              (eq evil-visual-selection 'line))
                         (format "%dL" lines))
                        ((> lines 1)
                         (format "%dC,%dL" (- end beg) lines))
                        (t
                         (format "%dC" (- end beg))))))
        (mini-echo-segment--print str 'mini-echo-selection-info)))))

(mini-echo-define-segment "word-count"
  "Return word count info of current buffer."
  :fetch
  (mini-echo-segment--print (format " %dW" (count-words (point-min) (point-max)))
                            'mini-echo-word-count))

(mini-echo-define-segment "last-command"
  "Return last command info."
  :fetch
  (when (bound-and-true-p last-command)
    (mini-echo-segment--print (symbol-name last-command)
                              'mini-echo-last-command)))

(mini-echo-define-segment "vcs"
  "Return vcs info of current buffer.
Segment appearance depends on var `vc-display-status' and faces like
`vc-state-base' and related `vc-**-state'."
  :fetch
  (when (bound-and-true-p vc-mode)
    (mini-echo-segment--print (mini-echo-segment--extract vc-mode)
                              nil mini-echo-vcs-max-length)))

(mini-echo-define-segment "text-scale"
  "Return info of `text-scale-mode' of current buffer."
  :fetch
  (unless (string= "+0" text-scale-mode-lighter)
    (mini-echo-segment--print text-scale-mode-lighter 'mini-echo-cyan)))

;; TODO add more info like zoom level, history depth, etc
(mini-echo-define-segment "xwidget"
  "Return info of `xwidget-webkit-mdoe' buffers."
  :fetch
  (when (eq major-mode 'xwidget-webkit-mode)
    (let* ((session (xwidget-webkit-current-session))
           (title (xwidget-webkit-title session))
           (progress (and xwidget-webkit--loading-p
                          (format " [%d%%%%]"
                                  (* 100
                                     (xwidget-webkit-estimated-load-progress
                                      session))))))
      (format "%s %s"
              (propertize (or progress "") 'face 'mini-echo-yellow-bold)
              (propertize title 'face 'mini-echo-green-bold)))))

(mini-echo-define-segment "org-src"
  "Return info of `org-src-edit-buffer'."
  :fetch
  (when (org-src-edit-buffer-p)
    (let* ((type (symbol-name org-src--source-type))
           (lang (car org-src--babel-info))
           (name (buffer-name)))
      (save-match-data
        (when (string-match "\\*Org Src \\([^[]*\\)\\[ .* \\]\\*" name)
          (setq name (match-string 1 name))))
      (format "%s|%s|%s %s"
              (propertize lang 'face 'mini-echo-blue)
              (propertize type 'face 'mini-echo-yellow)
              (propertize name 'face 'mini-echo-red)
              (propertize " ORG-SRC" 'face 'mini-echo-special-minor)))))

;;; Third-party segments

;; TODO support timemachine file

;; Add more info e.g. steps between blob and head
(mini-echo-define-segment "magit-blob"
  "Return info of `magit-blob' file."
  :fetch
  (when (bound-and-true-p magit-blob-mode)
    (save-match-data
      (let ((str (buffer-name)))
        (when (string-match "\\(.+\\)\\.~\\(.+\\)~" str)
          (concat
           (file-name-nondirectory (match-string 1 str))
           (propertize (concat "@" (substring (match-string 2 str) 0 7))
                       'face 'mini-echo-blob-revision)
           (propertize " Blob" 'face 'mini-echo-special-minor)))))))

(mini-echo-define-segment "flycheck"
  "Return flycheck diagnostics of current buffer."
  :fetch
  (when (bound-and-true-p flycheck-mode)
    (concat
     (when-let* ((ind (pcase flycheck-last-status-change
                        ((and n (guard (memq n '(not-checked no-checker suspicious)))) "?")
                        ((and n (guard (memq n '(errord interrupted)))) "!")
                        ('running "*")
                        ('finished nil))))
       (propertize ind 'face 'compilation-mode-line-run))
     (let* ((errors (flycheck-count-errors flycheck-current-errors)))
       (setq errors (push (cons 'success (alist-get 'info errors)) errors))
       (mapconcat
        (lambda (s)
          (propertize (number-to-string (or (alist-get s errors) 0)) 'face s))
        '(error warning success)
        "/")))))

(mini-echo-define-segment "meow"
  "Return the meow status of current buffer."
  :fetch
  (when (bound-and-true-p meow--indicator)
    (mini-echo-segment--extract meow--indicator)))

(mini-echo-define-segment "evil"
  "Display evil status of current buffer."
  :fetch
  (when (bound-and-true-p evil-local-mode)
    (mini-echo-segment--print
     (let ((tag (evil-state-property evil-state :tag t)))
       (if (stringp tag) tag (funcall tag)))
     (cond
      ((evil-normal-state-p)   'mini-echo-evil-normal-state)
      ((evil-emacs-state-p)    'mini-echo-evil-emacs-state)
      ((evil-insert-state-p)   'mini-echo-evil-insert-state)
      ((evil-motion-state-p)   'mini-echo-evil-motion-state)
      ((evil-visual-state-p)   'mini-echo-evil-visual-state)
      ((evil-operator-state-p) 'mini-echo-evil-operator-state)
      ((evil-replace-state-p)  'mini-echo-evil-replace-state)
      (t 'mini-echo-evil-normal-state)))))

(mini-echo-define-segment "keycast"
  "Display keycast info."
  :update-hook '(post-command-hook)
  :setup (require 'keycast)
  :fetch (keycast--format keycast-mode-line-format)
  :update (keycast--update))

(defvar-local mini-echo--lsp-mode nil)
(mini-echo-define-segment "lsp-mode"
  "Return LSP-mode server state."
  :update-hook '(lsp-before-initialize-hook
                 lsp-after-initialize-hook
                 lsp-after-uninitialized-functions
                 lsp-before-open-hook
                 lsp-after-open-hook)
  :fetch
  (when (bound-and-true-p lsp-mode)
    mini-echo--lsp-mode)
  :update
  (setq mini-echo--lsp-mode
        (let* ((workspaces (lsp-workspaces)))
          (mini-echo-segment--print "LSP" (if workspaces 'mini-echo-lsp 'warning)))))

(mini-echo-define-segment "lsp-bridge"
  "Return lsp-bridge server state"
  :fetch
  (when (bound-and-true-p lsp-bridge-mode)
    (mini-echo-segment--print lsp-bridge-mode-lighter 'mini-echo-lsp)))

(mini-echo-define-segment "eglot"
  "Return eglot server state"
  :fetch
  (when (bound-and-true-p eglot--managed-mode)
    (mini-echo-segment--extract
     (if (boundp 'eglot-mode-line-format)
         eglot-mode-line-format
       eglot--mode-line-format))))

(mini-echo-define-segment "envrc"
  "Return envrc status of current buffer."
  :fetch
  (when (and (bound-and-true-p envrc-mode)
             (not (eq envrc--status 'none)))
    (let ((orig (mini-echo-segment--extract envrc-lighter)))
      (string-replace "[" "/" (substring orig 0 7)))))

(mini-echo-define-segment "mise"
  "Return mise status of current buffer."
  :fetch
  (when (and (bound-and-true-p mise-mode)
             (or mini-echo-mise-show-always
                 (not (memq mise--status '(none global)))))
    (let ((orig (mini-echo-segment--extract mise-lighter)))
      (string-replace "[" "/" (substring orig 0 6)))))

(mini-echo-define-segment "elfeed"
  "Return elfeed unread feeds count."
  :fetch
  (when-let* ((buf (get-buffer "*elfeed-search*")))
    (with-current-buffer buf
      (when-let* ((str (elfeed-search--count-unread))
                  ((string-match "\\`\\([1-9][0-9]*\\)/.*" str)))
        (concat "elfeed["
                (propertize (match-string 1 str) 'face
                            'elfeed-search-unread-count-face)
                "]")))))

;; TODO show diff-mode switches
;; (mini-echo-define-segment "diff"
;;   "Return info of diff buffers."
;;   :fetch
;;   (when (eq major-mode 'diff-mode)
;;     (propertize "Diff" 'face 'mini-echo-cyan)))

(mini-echo-define-segment "atomic-chrome"
  "Return info of atomic chrome edit buffers."
  :fetch
  (when (bound-and-true-p atomic-chrome-edit-mode)
    (concat (mini-echo-segment--print (buffer-name) nil 25)
            (propertize " Atomic" 'face 'mini-echo-special-minor))))

(mini-echo-define-segment "blame"
  "Return info of blame buffers."
  :fetch
  (when (bound-and-true-p magit-blame-mode)
    (if (string-empty-p magit-blame-mode-lighter)
        (propertize "Blame" 'face 'mini-echo-special-minor)
      (mini-echo-segment--print magit-blame-mode-lighter 'mini-echo-special-minor))))

(mini-echo-define-segment "helpful"
  "Return info of helpful buffers."
  :fetch
  (when (eq major-mode 'helpful-mode)
    (let ((str (buffer-name)))
      (save-match-data
        (if (string-match "\\`\\*helpful \\(.*\\): \\(.*\\)\\*\\'" str)
            (format "*%s* [%s]"
                    (propertize (match-string 2 str) 'face 'mini-echo-green)
                    (propertize (match-string 1 str) 'face 'mini-echo-gray))
          (propertize "lambda" 'face 'mini-echo-green))))))

(mini-echo-define-segment "treesit-inspect"
  "Return treesit node info at point."
  :fetch
  (when (or (bound-and-true-p treesit-inspect-mode)
            (bound-and-true-p treesit-explore-mode))
    (let ((face (if treesit-explore-mode 'mini-echo-yellow-bold 'mini-echo-yellow))
          (node (and treesit-inspect-mode (string-trim treesit--inspect-name))))
      (format "%s%s"
              (if (null node) ""
                (concat node (propertize "::" 'face 'font-lock-doc-face)))
              (propertize "TS" 'face face)))))

(mini-echo-define-segment "treesit-explorer-tree"
  "Return info of treesit explore tree buffers."
  :fetch
  (when (eq major-mode 'treesit--explorer-tree-mode)
    (let ((str (buffer-name)))
      (save-match-data
        (when (string-match "\\`\\*tree-sitter explorer for \\(.*\\)\\*\\'" str)
          (propertize (match-string 1 str) 'face 'mini-echo-green))))))

(mini-echo-define-segment "popper"
  "Return info of popper buffers."
  :fetch
  (when (and (fboundp 'popper-display-control-p)
             (popper-display-control-p (current-buffer)))
    (string-join
     (thread-last
       popper-buried-popup-alist
       (alist-get (and popper-group-function (funcall popper-group-function)))
       (mapcar #'cdr)
       (cons (current-buffer))
       (mapcar #'buffer-name)
       (seq-uniq)
       (seq-sort #'string-lessp)
       (seq-filter #'identity)
       (reverse)
       (mapcar
        (lambda (x)
          (mini-echo-segment--print
           x (if (string= x (buffer-name))
                 'mini-echo-yellow-bold
               'mini-echo-gray)
           25))))
     (propertize "|" 'face 'font-lock-doc-face))))

(mini-echo-define-segment "wgrep"
  "Return info of wgrep-able buffers."
  :fetch
  (when (and (bound-and-true-p wgrep-prepared)
             wgrep-sibling-buffer)
    (propertize "Wgrep" 'face 'mini-echo-special-minor)))

;; TODO add more segments

(provide 'mini-echo-segments)
;;; mini-echo-segments.el ends here.
