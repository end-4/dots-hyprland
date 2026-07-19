;;; material-theme.el --- Theme using Matugen SCSS variables

;; Copyright (C) 2025 

;; Author: Generated (Improved)
;; Version: 1.2
;; Package-Requires: ((emacs "24.1"))
;; Keywords: faces

;;; Commentary:

;; A theme using Matugen SCSS variables with quality of life improvements:
;; - Better source block distinction
;; - Improved text visibility when selected
;; - Refined org-mode styling with hidden asterisks
;; - Enhanced contrast and readability
;; - Seamless integration of source blocks with consistent styling

;;; Code:

(deftheme material "Theme using Matugen SCSS variables with quality of life improvements.")

;; Define function to read SCSS variables
(defun material-get-color-from-scss (var-name)
  "Extract color value for VAR-NAME from material_colors.scss file."
  (let* ((scss-file (expand-file-name "~/.local/state/quickshell/user/generated/material_colors.scss"))
         (scss-content (with-temp-buffer
                         (insert-file-contents scss-file)
                         (buffer-string)))
         (var-pattern (concat "\\$" var-name ":\\s-+\\(#[0-9a-fA-F]\\{6\\}\\);"))
         (match (string-match var-pattern scss-content)))
    (if match
        (match-string 1 scss-content)
      (message "Could not find color variable: %s" var-name)
      "#000000")))

;; Define function to adjust color brightness
(defun material-adjust-color (hex-color factor)
  "Adjust HEX-COLOR brightness by FACTOR (0-2).
Values < 1 darken, values > 1 lighten."
  (let* ((r (string-to-number (substring hex-color 1 3) 16))
         (g (string-to-number (substring hex-color 3 5) 16))
         (b (string-to-number (substring hex-color 5 7) 16))
         (adjust-channel (lambda (channel)
                           (max 0 (min 255 (round (* channel factor))))))
         (new-r (funcall adjust-channel r))
         (new-g (funcall adjust-channel g))
         (new-b (funcall adjust-channel b)))
    (format "#%02x%02x%02x" new-r new-g new-b)))

;; Define all the color variables
(let* ((bg (material-get-color-from-scss "background"))
      (err (material-get-color-from-scss "error"))
      (err-container (material-get-color-from-scss "errorContainer"))
      (inverse-on-surface (material-get-color-from-scss "inverseOnSurface"))
      (inverse-primary (material-get-color-from-scss "inversePrimary"))
      (inverse-surface (material-get-color-from-scss "inverseSurface"))
      (on-background (material-get-color-from-scss "onBackground"))
      (on-err (material-get-color-from-scss "onError"))
      (on-err-container (material-get-color-from-scss "onErrorContainer"))
      (on-primary (material-get-color-from-scss "onPrimary"))
      (on-primary-container (material-get-color-from-scss "onPrimaryContainer"))
      (on-primary-fixed (material-get-color-from-scss "onPrimaryFixed"))
      (on-primary-fixed-variant (material-get-color-from-scss "onPrimaryFixedVariant"))
      (on-secondary (material-get-color-from-scss "onSecondary"))
      (on-secondary-container (material-get-color-from-scss "onSecondaryContainer"))
      (on-secondary-fixed (material-get-color-from-scss "onSecondaryFixed"))
      (on-secondary-fixed-variant (material-get-color-from-scss "onSecondaryFixedVariant"))
      (on-surface (material-get-color-from-scss "onSurface"))
      (on-surface-variant (material-get-color-from-scss "onSurfaceVariant"))
      (on-tertiary (material-get-color-from-scss "onTertiary"))
      (on-tertiary-container (material-get-color-from-scss "onTertiaryContainer"))
      (on-tertiary-fixed (material-get-color-from-scss "onTertiaryFixed"))
      (on-tertiary-fixed-variant (material-get-color-from-scss "onTertiaryFixedVariant"))
      (outline-color (material-get-color-from-scss "outline"))
      (outline-variant (material-get-color-from-scss "outlineVariant"))
      (primary (material-get-color-from-scss "primary"))
      (primary-container (material-get-color-from-scss "primaryContainer"))
      (primary-fixed (material-get-color-from-scss "primaryFixed"))
      (primary-fixed-dim (material-get-color-from-scss "primaryFixedDim"))
      (scrim (material-get-color-from-scss "scrim"))
      (secondary (material-get-color-from-scss "secondary"))
      (secondary-container (material-get-color-from-scss "secondaryContainer"))
      (secondary-fixed (material-get-color-from-scss "secondaryFixed"))
      (secondary-fixed-dim (material-get-color-from-scss "secondaryFixedDim"))
      (shadow (material-get-color-from-scss "shadow"))
      (surface (material-get-color-from-scss "surface"))
      (surface-bright (material-get-color-from-scss "surfaceBright"))
      (surface-container (material-get-color-from-scss "surfaceContainer"))
      (surface-container-high (material-get-color-from-scss "surfaceContainerHigh"))
      (surface-container-highest (material-get-color-from-scss "surfaceContainerHighest"))
      (surface-container-low (material-get-color-from-scss "surfaceContainerLow"))
      (surface-container-lowest (material-get-color-from-scss "surfaceContainerLowest"))
      (surface-dim (material-get-color-from-scss "surfaceDim"))
      (surface-tint (material-get-color-from-scss "surfaceTint"))
      (surface-variant (material-get-color-from-scss "surfaceVariant"))
      (tertiary (material-get-color-from-scss "tertiary"))
      (tertiary-container (material-get-color-from-scss "tertiaryContainer"))
      (tertiary-fixed (material-get-color-from-scss "tertiaryFixed"))
      (tertiary-fixed-dim (material-get-color-from-scss "tertiaryFixedDim"))
      (success (material-get-color-from-scss "success"))
      (on-success (material-get-color-from-scss "onSuccess"))
      (success-container (material-get-color-from-scss "successContainer"))
      (on-success-container (material-get-color-from-scss "onSuccessContainer"))
      (term0 (material-get-color-from-scss "term0"))
      (term1 (material-get-color-from-scss "term1"))
      (term2 (material-get-color-from-scss "term2"))
      (term3 (material-get-color-from-scss "term3"))
      (term4 (material-get-color-from-scss "term4"))
      (term5 (material-get-color-from-scss "term5"))
      (term6 (material-get-color-from-scss "term6"))
      (term7 (material-get-color-from-scss "term7"))
      (term8 (material-get-color-from-scss "term8"))
      (term9 (material-get-color-from-scss "term9"))
      (term10 (material-get-color-from-scss "term10"))
      (term11 (material-get-color-from-scss "term11"))
      (term12 (material-get-color-from-scss "term12"))
      (term13 (material-get-color-from-scss "term13"))
      (term14 (material-get-color-from-scss "term14"))
      (term15 (material-get-color-from-scss "term15")))

  (custom-theme-set-faces
   'material
   ;; Basic faces
   `(default ((t (:background ,bg :foreground ,on-background))))
   `(cursor ((t (:background ,primary))))
   `(highlight ((t (:background ,primary-container :foreground ,on-primary-container))))
   `(region ((t (:background ,primary-container :foreground ,on-primary-container :extend t))))
   `(secondary-selection ((t (:background ,secondary-container :foreground ,on-secondary-container :extend t))))
   `(isearch ((t (:background ,tertiary-container :foreground ,on-tertiary-container :weight bold))))
   `(lazy-highlight ((t (:background ,secondary-container :foreground ,on-secondary-container))))
   `(vertical-border ((t (:foreground ,surface-variant))))
   `(border ((t (:background ,surface-variant :foreground ,surface-variant))))
   `(fringe ((t (:background ,surface :foreground ,outline-variant))))
   `(shadow ((t (:foreground ,outline-variant))))
   `(link ((t (:foreground ,primary :underline t))))
   `(link-visited ((t (:foreground ,tertiary :underline t))))
   `(success ((t (:foreground ,success))))
   `(warning ((t (:foreground ,secondary))))
   `(error ((t (:foreground ,err))))
   `(match ((t (:background ,secondary-container :foreground ,on-secondary-container))))
   
   ;; Font-lock
   `(font-lock-builtin-face ((t (:foreground ,primary))))
   `(font-lock-comment-face ((t (:foreground ,outline-color :slant italic))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,outline-variant))))
   `(font-lock-constant-face ((t (:foreground ,tertiary :weight bold))))
   `(font-lock-doc-face ((t (:foreground ,on-surface-variant :slant italic))))
   `(font-lock-function-name-face ((t (:foreground ,primary :weight bold))))
   `(font-lock-keyword-face ((t (:foreground ,secondary :weight bold))))
   `(font-lock-string-face ((t (:foreground ,tertiary))))
   `(font-lock-type-face ((t (:foreground ,primary-fixed))))
   `(font-lock-variable-name-face ((t (:foreground ,on-surface))))
   `(font-lock-warning-face ((t (:foreground ,err :weight bold))))
   `(font-lock-preprocessor-face ((t (:foreground ,secondary-fixed-dim))))
   `(font-lock-negation-char-face ((t (:foreground ,tertiary-fixed))))

   ;; Show paren
   `(show-paren-match ((t (:background ,primary-container :foreground ,on-primary-container :weight bold))))
   `(show-paren-mismatch ((t (:background ,err-container :foreground ,on-err-container :weight bold))))
   
   ;; Mode line - improved status bar styling
   `(mode-line ((t (:background ,surface-container :foreground ,on-surface :box nil))))
   `(mode-line-inactive ((t (:background ,surface :foreground ,on-surface-variant :box nil))))
   `(mode-line-buffer-id ((t (:foreground ,primary :weight bold))))
   `(mode-line-emphasis ((t (:foreground ,primary :weight bold))))
   `(mode-line-highlight ((t (:foreground ,primary :box nil))))
   
   ;; Improved Source blocks - make them integrated with the theme
   `(org-block ((t (:background ,surface-container-low :extend t :inherit fixed-pitch))))
   `(org-block-begin-line ((t (:background ,surface-container-low :foreground ,primary-fixed-dim :extend t :slant italic :inherit fixed-pitch))))
   `(org-block-end-line ((t (:background ,surface-container-low :foreground ,primary-fixed-dim :extend t :slant italic :inherit fixed-pitch))))
   `(org-code ((t (:background ,surface-container-low :foreground ,tertiary-fixed :inherit fixed-pitch))))
   `(org-verbatim ((t (:background ,surface-container-low :foreground ,primary-fixed :inherit fixed-pitch))))
   `(org-meta-line ((t (:foreground ,outline-color :slant italic))))
   
   ;; Org mode with hidden asterisks
   `(org-level-1 ((t (:foreground ,primary :weight bold :height 1.2))))
   `(org-level-2 ((t (:foreground ,primary-container :weight bold :height 1.1))))
   `(org-level-3 ((t (:foreground ,secondary :weight bold))))
   `(org-level-4 ((t (:foreground ,secondary-container :weight bold))))
   `(org-level-5 ((t (:foreground ,tertiary :weight bold))))
   `(org-level-6 ((t (:foreground ,tertiary-container :weight bold))))
   `(org-level-7 ((t (:foreground ,primary-fixed :weight bold))))
   `(org-level-8 ((t (:foreground ,primary-fixed-dim :weight bold))))
   `(org-document-title ((t (:foreground ,primary :weight bold :height 1.3))))
   `(org-document-info ((t (:foreground ,primary-container))))
   `(org-todo ((t (:foreground ,err :weight bold))))
   `(org-done ((t (:foreground ,success :weight bold))))
   `(org-headline-done ((t (:foreground ,on-surface-variant))))
   `(org-hide ((t (:foreground ,bg)))) ;; Hide leading asterisks
   `(org-ellipsis ((t (:foreground ,tertiary :underline nil)))) ;; Style for folded content indicator
   `(org-table ((t (:foreground ,secondary-fixed :inherit fixed-pitch))))
   `(org-formula ((t (:foreground ,tertiary :inherit fixed-pitch))))
   `(org-checkbox ((t (:foreground ,primary :weight bold :inherit fixed-pitch))))
   `(org-date ((t (:foreground ,secondary-fixed :underline t))))
   `(org-special-keyword ((t (:foreground ,on-surface-variant :slant italic))))
   `(org-tag ((t (:foreground ,outline-color :weight normal))))
   
   ;; Magit
   `(magit-section-highlight ((t (:background ,surface-container-low))))
   `(magit-diff-hunk-heading ((t (:background ,surface-container :foreground ,on-surface-variant))))
   `(magit-diff-hunk-heading-highlight ((t (:background ,surface-container-high :foreground ,on-surface))))
   `(magit-diff-context ((t (:foreground ,on-surface-variant))))
   `(magit-diff-context-highlight ((t (:background ,surface-container-low :foreground ,on-surface))))
   `(magit-diff-added ((t (:background ,success-container :foreground ,on-success-container))))
   `(magit-diff-added-highlight ((t (:background ,success-container :foreground ,on-success-container :weight bold))))
   `(magit-diff-removed ((t (:background ,err-container :foreground ,on-err-container))))
   `(magit-diff-removed-highlight ((t (:background ,err-container :foreground ,on-err-container :weight bold))))
   `(magit-hash ((t (:foreground ,outline-color))))
   `(magit-branch-local ((t (:foreground ,tertiary :weight bold))))
   `(magit-branch-remote ((t (:foreground ,primary :weight bold))))
   
   ;; Company
   `(company-tooltip ((t (:background ,surface-container :foreground ,on-surface))))
   `(company-tooltip-selection ((t (:background ,primary-container :foreground ,on-primary-container))))
   `(company-tooltip-common ((t (:foreground ,primary))))
   `(company-tooltip-common-selection ((t (:foreground ,on-primary-container :weight bold))))
   `(company-tooltip-annotation ((t (:foreground ,tertiary))))
   `(company-scrollbar-fg ((t (:background ,primary))))
   `(company-scrollbar-bg ((t (:background ,surface-variant))))
   `(company-preview ((t (:foreground ,on-surface-variant :slant italic))))
   `(company-preview-common ((t (:foreground ,primary :slant italic))))
   
   ;; Ido
   `(ido-first-match ((t (:foreground ,primary :weight bold))))
   `(ido-only-match ((t (:foreground ,tertiary :weight bold))))
   `(ido-subdir ((t (:foreground ,secondary))))
   `(ido-indicator ((t (:foreground ,err))))
   `(ido-virtual ((t (:foreground ,outline-color))))
   
   ;; Helm
   `(helm-selection ((t (:background ,primary-container :foreground ,on-primary-container))))
   `(helm-match ((t (:foreground ,primary :weight bold))))
   `(helm-source-header ((t (:background ,surface-container-high :foreground ,primary :weight bold :height 1.1))))
   `(helm-candidate-number ((t (:foreground ,tertiary :weight bold))))
   `(helm-ff-directory ((t (:foreground ,primary :weight bold))))
   `(helm-ff-file ((t (:foreground ,on-surface))))
   `(helm-ff-executable ((t (:foreground ,tertiary))))
   
   ;; Which-key
   `(which-key-key-face ((t (:foreground ,primary :weight bold))))
   `(which-key-separator-face ((t (:foreground ,outline-variant))))
   `(which-key-command-description-face ((t (:foreground ,on-surface))))
   `(which-key-group-description-face ((t (:foreground ,secondary))))
   `(which-key-special-key-face ((t (:foreground ,tertiary :weight bold))))
   
   ;; Line numbers
   `(line-number ((t (:foreground ,outline-variant :inherit fixed-pitch))))
   `(line-number-current-line ((t (:foreground ,primary :weight bold :inherit fixed-pitch))))
   
   ;; Parenthesis matching
   `(sp-show-pair-match-face ((t (:background ,primary-container :foreground ,on-primary-container))))
   `(sp-show-pair-mismatch-face ((t (:background ,err-container :foreground ,on-err-container))))
   
   ;; Rainbow delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,primary))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground ,secondary))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground ,tertiary))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground ,primary-fixed))))
   `(rainbow-delimiters-depth-5-face ((t (:foreground ,secondary-fixed))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground ,tertiary-fixed))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground ,primary-fixed-dim))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground ,secondary-fixed-dim))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground ,tertiary-fixed-dim))))
   `(rainbow-delimiters-mismatched-face ((t (:foreground ,err :weight bold))))
   `(rainbow-delimiters-unmatched-face ((t (:foreground ,err :weight bold))))
   
   ;; Dired
   `(dired-directory ((t (:foreground ,primary :weight bold))))
   `(dired-ignored ((t (:foreground ,outline-variant))))
   `(dired-flagged ((t (:foreground ,err))))
   `(dired-marked ((t (:foreground ,tertiary :weight bold))))
   `(dired-symlink ((t (:foreground ,secondary :slant italic))))
   `(dired-header ((t (:foreground ,primary :weight bold :height 1.1))))
   
   ;; Terminal colors
   `(term-color-black ((t (:foreground ,term0 :background ,term0))))
   `(term-color-red ((t (:foreground ,term1 :background ,term1))))
   `(term-color-green ((t (:foreground ,term2 :background ,term2))))
   `(term-color-yellow ((t (:foreground ,term3 :background ,term3))))
   `(term-color-blue ((t (:foreground ,term4 :background ,term4))))
   `(term-color-magenta ((t (:foreground ,term5 :background ,term5))))
   `(term-color-cyan ((t (:foreground ,term6 :background ,term6))))
   `(term-color-white ((t (:foreground ,term7 :background ,term7))))
   
   ;; EShell
   `(eshell-prompt ((t (:foreground ,primary :weight bold))))
   `(eshell-ls-directory ((t (:foreground ,primary :weight bold))))
   `(eshell-ls-symlink ((t (:foreground ,secondary :slant italic))))
   `(eshell-ls-executable ((t (:foreground ,tertiary))))
   `(eshell-ls-archive ((t (:foreground ,on-tertiary-container))))
   `(eshell-ls-backup ((t (:foreground ,outline-variant))))
   `(eshell-ls-clutter ((t (:foreground ,err))))
   `(eshell-ls-missing ((t (:foreground ,err))))
   `(eshell-ls-product ((t (:foreground ,on-surface-variant))))
   `(eshell-ls-readonly ((t (:foreground ,on-surface-variant))))
   `(eshell-ls-special ((t (:foreground ,secondary-fixed))))
   `(eshell-ls-unreadable ((t (:foreground ,outline-variant))))
   
   ;; Improved markdown mode
   `(markdown-header-face ((t (:foreground ,primary :weight bold))))
   `(markdown-header-face-1 ((t (:foreground ,primary :weight bold :height 1.2))))
   `(markdown-header-face-2 ((t (:foreground ,primary-container :weight bold :height 1.1))))
   `(markdown-header-face-3 ((t (:foreground ,secondary :weight bold))))
   `(markdown-header-face-4 ((t (:foreground ,secondary-container :weight bold))))
   `(markdown-inline-code-face ((t (:foreground ,tertiary-fixed :background ,surface-container-low :inherit fixed-pitch))))
   `(markdown-code-face ((t (:background ,surface-container-low :extend t :inherit fixed-pitch))))
   `(markdown-pre-face ((t (:background ,surface-container-low :inherit fixed-pitch))))
   `(markdown-table-face ((t (:foreground ,secondary-fixed :inherit fixed-pitch))))
   
   ;; Web mode
   `(web-mode-html-tag-face ((t (:foreground ,primary))))
   `(web-mode-html-tag-bracket-face ((t (:foreground ,on-surface-variant))))
   `(web-mode-html-attr-name-face ((t (:foreground ,secondary))))
   `(web-mode-html-attr-value-face ((t (:foreground ,tertiary))))
   `(web-mode-css-selector-face ((t (:foreground ,primary))))
   `(web-mode-css-property-name-face ((t (:foreground ,secondary))))
   `(web-mode-css-string-face ((t (:foreground ,tertiary))))
   
   ;; Flycheck
   `(flycheck-error ((t (:underline (:style wave :color ,err)))))
   `(flycheck-warning ((t (:underline (:style wave :color ,secondary)))))
   `(flycheck-info ((t (:underline (:style wave :color ,tertiary)))))
   `(flycheck-fringe-error ((t (:foreground ,err))))
   `(flycheck-fringe-warning ((t (:foreground ,secondary))))
   `(flycheck-fringe-info ((t (:foreground ,tertiary))))
   
   ;; Mini-buffer customization
   `(minibuffer-prompt ((t (:foreground ,primary :weight bold))))
   
   ;; Improved search highlighting
   `(lsp-face-highlight-textual ((t (:background ,primary-container :foreground ,on-primary-container :weight bold))))
   `(lsp-face-highlight-read ((t (:background ,secondary-container :foreground ,on-secondary-container :weight bold))))
   `(lsp-face-highlight-write ((t (:background ,tertiary-container :foreground ,on-tertiary-container :weight bold))))
   
   ;; Info and help modes
   `(info-title-1 ((t (:foreground ,primary :weight bold :height 1.3))))
   `(info-title-2 ((t (:foreground ,primary-container :weight bold :height 1.2))))
   `(info-title-3 ((t (:foreground ,secondary :weight bold :height 1.1))))
   `(info-title-4 ((t (:foreground ,secondary-container :weight bold))))
   `(Info-quoted ((t (:foreground ,tertiary))))
   `(info-menu-header ((t (:foreground ,primary :weight bold))))
   `(info-menu-star ((t (:foreground ,primary))))
   `(info-node ((t (:foreground ,tertiary :weight bold))))
   
   ;; Fixed-pitch faces
   `(fixed-pitch ((t (:family "monospace"))))
   `(fixed-pitch-serif ((t (:family "monospace serif"))))
   
   ;; Variable-pitch face
   `(variable-pitch ((t (:family "sans serif"))))
   ))

;; Add org-mode hooks for hiding leading stars
(with-eval-after-load 'org
  (setq org-hide-leading-stars t)
  (setq org-startup-indented t))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'material)
;;; material-theme.el ends here
