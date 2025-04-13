# mini-echo.el

[![License GPL 3](https://img.shields.io/badge/license-GPL_3-green.svg?style=flat)](LICENSE)
[![MELPA](https://melpa.org/packages/mini-echo-badge.svg)](https://melpa.org/#/mini-echo)

Show buffer status in echo area, get rid of mode-line !

<!-- markdown-toc start -->

## Contents

- [mini-echo.el](#mini-echoel)
  - [Screenshot](#screenshot)
  - [Install](#install)
    - [dependencies](#dependencies)
    - [package](#package)
  - [Feature](#feature)
  - [Usage](#usage)
  - [Customization](#customization)
    - [Keywords](#keywords)
    - [Utils](#utils)
  - [Similar Package](#similar-package)
  - [Todo](#todo)
  - [FAQ](#faq)
  - [Donate](#donate)

<!-- markdown-toc end -->

## Screenshot

![example](example.gif)

## Install

### dependencies

- Emacs, version >= 29.1
- [hide-mode-line](https://github.com/hlissner/emacs-hide-mode-line)
- [llama](https://github.com/tarsius/llama)

### package

- Manually

Clone and add to `load-path`, require the package.

- Melpa

This package is available on [MELPA].
Install with `M-x package-install` `RET` `mini-echo` within Emacs.

## Feature

- light-weight, very simple structure and no many configs
- don't use mode-line at all, same experience in terminal
- port lots of segments from [doom-modeline](https://github.com/seagle0128/doom-modeline)
- easy to add new segment with macro

## Usage

```elisp
(require 'mini-echo)
(mini-echo-mode)
```

There are two kinds of segments, `persistent` and `temporary`:

- `persistent`: segments like `major-mode`, `buffer-size`, `vcs` displayed persistently, which mainly used by `mini-echo-persistent-rule` and `mini-echo-persistent-function`.
  Any buffer get persistent segments following order: calling `mini-echo-persistent-function` to get plist of segments, otherwise use `mini-echo-persistent-rule` as fallback.

- `temporary`: segments like `process`, `narrow` displayed temporarily, which used by `mini-echo-temporary-rule`. All buffer get same temporary segments according to `mini-echo-temporary-rule` .

1. `mini-echo-persistent-rule`: variable, plist of persistent segments which are default to all buffers, support `:both` or `:long/:short` keywords.

```elisp
(setq mini-echo-persistent-rule
  '(:long ("major-mode" "shrink-path" "vcs" "buffer-position" "buffer-size" "flymake")
    :short ("buffer-name" "buffer-position" "flymake")))
```

2. `mini-echo-temporary-rule`: variable, plist of temporary segments which are default to all buffers, support `:both` or `:long/:short` keywords.

```elisp
(setq mini-echo-temporary-rule
  '(:both ("process" "selection-info" "narrow" "macro"
           "profiler" "repeat" "blame" "text-scale")))
```

3. `mini-echo-persistent-function`: A function which return a plist of persistent segments on conditions.
   `mini-echo-persistent-detect` is the default function to detect whether rule exists. e.g.

```elisp
(defun mini-echo-persistent-detect ()
  "Return a plist of persistent rule if matched.
Otherwise, return nil."
  (with-current-buffer (current-buffer)
    ;; NOTE return the first match, so the former has higher priority
    (pcase major-mode
      ((guard (bound-and-true-p atomic-chrome-edit-mode))
       '(:both ("atomic-chrome" "buffer-name" "buffer-position" "flymake")))
      ((guard (or (memq major-mode '(git-commit-elisp-text-mode git-rebase-mode))
                  (string-match-p "\\`magit-.*-mode\\'" (symbol-name major-mode))))
       '(:both ("major-mode" "project")))
      ('ibuffer-mode '(:both ("major-mode")))
      ('diff-mode '(:both ("major-mode")))
      ('dired-mode '(:both ("major-mode" "dired")))
      ('helpful-mode '(:both ("major-mode" "helpful")))
      ('xwidget-webkit-mode '(:long ("shrink-path") :short ("buffer-name")))
      ((guard (and (fboundp 'popper-display-control-p)
                   (popper-display-control-p (current-buffer))))
       '(:both ("popper")))
      (_ nil))))
```

In `ibuffer` buffer, return `(:both "major-mode")` as persistent segments.

in `dired` buffer, return `(:both ("major-mode" "dired"))` as persistent segments.

In buffers created by `atomic-chrome` package, return `(:both ("atomic-chrome" "buffer-name" "buffer-position" "flymake"))` as persistent segments.

If not matched in the function, use `mini-echo-persistent-rule` as fallback.

4. `mini-echo-toggle`: command, show or hide some segment temporarily

Other options are here, see more info please check the file

```elisp
;; write your own predicate function to switch style
(setq mini-echo-short-style-predicate #'your-own-predicate)

;; set separator to concat information
(setq mini-echo-separator " ")

;; adjust window-divider-mode appearence
(setq mini-echo-window-divider-args '(t 1 1))

;;; adjust update interval as you wish
(setq mini-echo-update-interval 0.3)

;;; adjust the number to avoid truncation or wrap line of minibuffer window
(setq mini-echo-right-padding 1)
```

## Customization

Write a segment with `mini-echo-define-segment`, e.g.

```elisp

(mini-echo-define-segment "vcs"
  "Return vcs info of current buffer.
Segment appearence depends on var `vc-display-status' and faces like
`vc-state-base' and related `vc-**-state'."
  :fetch
  (when (bound-and-true-p vc-mode)
    (mini-echo-segment--print (mini-echo-segment--extract vc-mode)
                              nil mini-echo-vcs-max-length)))

(mini-echo-define-segment "time"
  "Return current time."
  :setup (display-time-mode 1)
  :fetch (mini-echo-segment--extract display-time-string))

(defvar mini-echo--repeat nil)
(mini-echo-define-segment "repeat"
  "Indicator of whether repeating transient map is active."
  :update-advice '((repeat-post-hook . :after))
  :fetch
  (when mini-echo--repeat
    (mini-echo-segment--print "REPEAT" 'mini-echo-repeat))
  :update
  (setq mini-echo--repeat (and repeat-mode repeat-in-progress)))

(mini-echo-define-segment "keycast"
  "Display keycast info."
  :update-hook '(post-command-hook)
  :setup (require 'keycast)
  :fetch (keycast--format keycast-mode-line-format)
  :update (keycast--update))
```

### Keywords

- `:fetch`: sexp, which runs when mini-echo update by interval.
- `:setup`: sexp, which runs when the segment is first activated , e.g. load library `keycast` when activate `keycast` segment.
- `:update`: sexp, which runs when `:update-hook` or `:update-advice` is triggered.
- `:update-hook`: list of hooks which run `:update` after it called, e.g. update "keycast" status after hook `post-command-hook`.
- `:update-advice`: alist of (symbol . how) which runs `:update` after it called, e.g. update "repeat" status after run function `(repeat-post-hook)`.

### Utils

- `mini-echo-segment--extract`: extract segment info from mode-line construct.
- `mini-echo-segment--print`: trim, truncate string with ellipsis if needed.

For more information, please see [mini-echo-segments.el](mini-echo-segments.el).

## Similar Package

- [feebleline](https://github.com/tautologyclub/feebleline)

- [mini-modeline](https://github.com/kiennq/emacs-mini-modeline)

- [awesome-tray](https://github.com/manateelazycat/awesome-tray)

## Todo

- [x] rewrite mini-echo-define-macro
- [x] add minibuffer background to distinguish in terminal
- [x] setup segments per buffer
- [ ] add environment support, such as python, node.js, asdf...
- [ ] add support to highlight current window
- [ ] add support for nerd-icons
- [x] refactor segment to distinguish between persistent and temporary types.

## FAQ

- How to distinguish current window ?

  Highlight current window is still on development, you could set hl-line-mode, or use some dim other window package for now.
  e.g.

  ```elisp
  ;; or (global-hl-line-mode)
  (hl-line-mode)
  ;; Only highliht current buffer in current window
  (setq hl-line-sticky-flag nil)
  (setq global-hl-line-sticky-flag nil)
  ```

- How to show window border in terminal?

  In GUI, customize face `window-divider` to show window border, due to `window-divider-mode` is not available in terminal, you need to use other measures to identify windows.
  In terminal, `internal-border` is displayed, so only need to solve horizontal border problem. Enable packages like tabbar or topsy to help highlight horizontal border instead.

- How to distinguish minibuffer window in terminal?

  Customize face `mini-echo-minibuffer-window` to set different background color from
  default.
