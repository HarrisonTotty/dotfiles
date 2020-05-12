{% do require('font.alt_name', 'this.modeline') %}
{% if not 'left' in this.modeline %}
{% do raise('left side of modeline is not defined') %}
{% endif %}
{% if not 'right' in this.modeline %}
{% do raise('right side of modeline is not defined') %}
{% endif %}

; -------------- Functions --------------

; A function that "nukes" the "pretty symbols" for a mode.
(defun nuke-pretty-symbols (mode)
  (setq +pretty-code-symbols-alist
        (delq (assq mode +pretty-code-symbols-alist)
              +pretty-code-symbols-alist)))

; A function for merging two plists.
(defun plist-merge (&rest plists)
  (if plists
      (let ((result (copy-sequence (car plists))))
        (while (setq plists (cdr plists))
          (let ((plist (car plists)))
            (while plist
              (setq result (plist-put result (car plist) (car (cdr plist)))
                    plist (cdr (cdr plist))))))
        result)
    nil))

; A function to toggle org mode emphasis markers.
(defun toggle-org-emphasis-markers ()
  "Toggle org-mode's emphasis markers on and off."
  (interactive)
  (setq org-hide-emphasis-markers (if (eq org-hide-emphasis-markers t) nil t))
  (org-mode-restart)
)

; ---------------------------------------


; ---------------- Hooks ----------------

(add-hook! 'org-mode-hook
  (nuke-pretty-symbols 'org-mode)
  (set-pretty-symbols! 'org-mode
    :name "#+NAME:"
    :org_result "#+RESULTS:"
    :src_block "#+BEGIN_SRC"
    :src_block_end "#+END_SRC"
    :title "#+TITLE:"
  )
)

(add-hook! python-mode
  (nuke-pretty-symbols 'python-mode)
  (set-pretty-symbols! 'python-mode
    :alpha "alpha"
    :and "and"
    :beta "beta"
    :def "def"
    :delta "delta"
    :frac_1_2 "1/2"
    :frac_1_3 "1/3"
    :frac_1_4 "1/4"
    :frac_2_3 "2/3"
    :frac_3_4 "3/4"
    :gamma "gamma"
    :integral "integrate"
    :lambda "lambda"
    :mu "mu"
    :not "not"
    :omega "omega"
    :or "or"
    :power_0 "**0"
    :power_1 "**1"
    :power_2 "**2"
    :power_3 "**3"
    :power_4 "**4"
    :power_5 "**5"
    :power_6 "**6"
    :power_7 "**7"
    :power_8 "**8"
    :power_9 "**9"
    :phi "phi"
    :pi "pi"
    :rho "rho"
    :sigma "sigma"
    :sub_0 "_0"
    :sub_1 "_1"
    :sub_2 "_2"
    :sub_3 "_3"
    :sub_4 "_4"
    :sub_5 "_5"
    :sub_6 "_6"
    :sub_7 "_7"
    :sub_8 "_8"
    :sub_9 "_9"
    :theta "theta"
  )
)

; ---------------------------------------


; ------------ External Files -----------

(when (file-readable-p "~/.config/doom/ext/irc.el")
  (load-file "~/.config/doom/ext/irc.el")
)

; ---------------------------------------


; ------------- Key Bindings ------------



; ---------------------------------------


; -------------- Variables --------------

; Set some personal information.
(setq user-full-name "Harrison Totty"
      user-mail-address "{{ email|default('harrisongtotty@gmail.com', true) }}")

; Set the font.
(setq doom-font (font-spec :family "{{ font.alt_name }}" :size 14))

; Set the DOOM theme.
(setq doom-theme 'doom-nord)

; Set the org-mode directory.
(setq org-directory "~/docs/org")

; Make org-tree-slide work how it's supposed to.
(after! org-tree-slide
  (setq org-tree-slide-skip-outline-level 1))

; Extend and/or replace portions of the pretty symbols list.
(setq +pretty-code-symbols
      (plist-merge +pretty-code-symbols
                   '(
                     :alpha "α"
                     :beta "β"
                     :delta "δ"
                     :frac_1_2 "½"
                     :frac_1_3 "⅓"
                     :frac_1_4 "¼"
                     :frac_2_3 "⅔"
                     :frac_3_4 "¾"
                     :gamma "γ"
                     :integral "∫"
                     :mu "μ"
                     :not "¬"
                     :omega "ω"
                     :org_result "┅"
                     :phi "φ"
                     :pi "π"
                     :power_0 "⁰"
                     :power_1 "¹"
                     :power_2 "²"
                     :power_3 "³"
                     :power_4 "⁴"
                     :power_5 "⁵"
                     :power_6 "⁶"
                     :power_7 "⁷"
                     :power_8 "⁸"
                     :power_9 "⁹"
                     :rho "ρ"
                     :sigma "σ"
                     :sub_0 "₀"
                     :sub_1 "₁"
                     :sub_2 "₂"
                     :sub_3 "₃"
                     :sub_4 "₄"
                     :sub_5 "₅"
                     :sub_6 "₆"
                     :sub_7 "₇"
                     :sub_8 "₈"
                     :sub_9 "₉"
                     :sub_x "ₓ"
                     :theta "θ"
                     :title "∷"
                    )
      )
)

; Supress an annoying python warning when running python in org-mode.
(setq python-shell-completion-native-disabled-interpreters '("python"))

; Display line numbers.
(setq display-line-numbers-type t)

; Customize the modeline.
(use-package! doom-modeline
  :init
  (setq doom-modeline-icon nil)
  :config
  (doom-modeline-def-modeline 'main
    '({{ this.modeline.left|join(' ') }}) ; LEFT SIDE
    '({{ this.modeline.right|join(' ') }}) ; RIGHT SIDE
  )
  )

; ---------------------------------------
