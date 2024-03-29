{% do require('font.alt_name', 'this.modeline', 'this.org') %}
{% if not 'left' in this.modeline %}
{% do raise('left side of modeline is not defined') %}
{% endif %}
{% if not 'right' in this.modeline %}
{% do raise('right side of modeline is not defined') %}
{% endif %}

; -------------- Functions --------------

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

(after! python-mode
  (set-ligatures! 'python-mode
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


; ------------- Key Bindings ------------

(map! :leader
      (:prefix ("j" . "journal")
        (:desc "View date" "d" #'org-roam-dailies-goto-date
         :desc "New date" "D" #'org-roam-dailies-capture-date
         :desc "View today" "j" #'org-roam-dailies-goto-today
         :desc "New today" "J" #'org-roam-dailies-capture-today
         :desc "View tomorrow" "t" #'org-roam-dailies-goto-tomorrow
         :desc "New tomorrow" "T" #'org-roam-dailies-capture-tomorrow
         :desc "View yesterday" "y" #'org-roam-dailies-goto-yesterday
         :desc "New yesterday" "Y" #'org-roam-dailies-capture-yesterday
         :desc "View next" "." #'org-roam-dailies-find-next-note
         :desc "View previous" "," #'org-roam-dailies-find-previous-note))
      (:prefix "n"
        (:desc "Find topic" "f" #'org-roam-node-find
         :desc "Find reference" "F" #'org-roam-ref-find
         :desc "Insert topic" "i" #'org-roam-node-insert)))

; ---------------------------------------


; -------------- Variables --------------

; Set some personal information.
(setq user-full-name "Harrison Totty"
      user-mail-address "{{ email|default('harrisongtotty@gmail.com', true) }}")

; Set the font.
(setq doom-font (font-spec :family "{{ font.alt_name }}" :size 14))

; Set the DOOM theme.
(setq doom-theme 'ewal-doom-one)

; Where projectile should automatically find projects.
; Invoke M+x projectile-discover-projects-in-search-path to populate.
(setq projectile-project-search-path '("~/projects"))

; Set the org-mode directory.
(setq org-directory "{{ this.org.dir }}")

; Setup where to find org agenda entries.
{% set ctd = this.org.capture_templates_dir %}
{% set ptasks = path_join(this.org.dir, 'roam/personal/tasks') %}
{% set stasks = path_join(this.org.dir, 'roam/shared/tasks') %}
{% set wtasks = path_join(this.org.dir, 'roam/work/tasks') %}
(after! org
  (setq org-agenda-files
        '("{{ ptasks }}"
          "{{ stasks }}"
          "{{ wtasks }}")
        org-capture-templates
       '(("P" "Personal Inbox" entry
          (file "{{ ptasks }}/personal-inbox.org")
          (file "{{ ctd }}/task-entry.org"))
         ("S" "Shared Inbox" entry
          (file "{{ stasks }}/shared-inbox.org")
          (file "{{ ctd }}/task-entry.org"))
         ("W" "Work Inbox" entry
          (file "{{ wtasks }}/work-inbox.org")
          (file "{{ ctd }}/task-entry.org"))
         ("p" "Personal")
         ("pi" "Inbox" entry
          (file "{{ ptasks }}/personal-inbox.org")
          (file "{{ ctd }}/task-entry.org"))
         ("pr" "Recurring" entry
          (file "{{ ptasks }}/personal-recurring.org")
          (file "{{ ctd }}/task-entry.org"))
         ("ps" "Someday" entry
          (file "{{ ptasks }}/personal-someday.org")
          (file "{{ ctd }}/task-entry.org"))
         ("pt" "Todo" entry
          (file "{{ ptasks }}/personal-todo.org")
          (file "{{ ctd }}/task-entry.org"))
         ("s" "Shared")
         ("si" "Inbox" entry
          (file "{{ stasks }}/shared-inbox.org")
          (file "{{ ctd }}/task-entry.org"))
         ("sr" "Recurring" entry
          (file "{{ stasks }}/shared-recurring.org")
          (file "{{ ctd }}/task-entry.org"))
         ("ss" "Someday" entry
          (file "{{ stasks }}/shared-someday.org")
          (file "{{ ctd }}/task-entry.org"))
         ("st" "Todo" entry
          (file "{{ stasks }}/shared-todo.org")
          (file "{{ ctd }}/task-entry.org"))
         ("w" "Work")
         ("wi" "Inbox" entry
          (file "{{ wtasks }}/work-inbox.org")
          (file "{{ ctd }}/task-entry.org"))
         ("wr" "Recurring" entry
          (file "{{ wtasks }}/work-recurring.org")
          (file "{{ ctd }}/task-entry.org"))
         ("ws" "Someday" entry
          (file "{{ wtasks }}/work-someday.org")
          (file "{{ ctd }}/task-entry.org"))
         ("wt" "Todo" entry
          (file "{{ wtasks }}/work-todo.org")
          (file "{{ ctd }}/task-entry.org")))))

; Setup org capture templates.
(after! org-roam
  (setq org-roam-capture-templates
        '(("d" "default" plain
           (file "{{ ctd }}/roam/default.org")
           :target (file+head "${slug}.org" "#+title: ${title}\n#+category: ${title}")
           :empty-lines-after 2
           :unnarrowed t))
        org-roam-dailies-capture-templates
        '(("d" "default" entry
           (file "{{ ctd }}/roam/daily/entry-default.org")
           :target (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n#+category: Journal\n#+date: %U\n#+filetags: journal")
           :empty-lines-after 2))))

(use-package! websocket
    :after org-roam)

(use-package! org-roam-ui
    :after org-roam
    :config
    (setq org-roam-ui-sync-theme t
          org-roam-ui-follow t
          org-roam-ui-update-on-save t
          org-roam-ui-open-on-start t))

; Extend and/or replace portions of the pretty symbols list.
(plist-put! +ligatures-extra-symbols
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
