{% do require('font.name') %}

(setq user-full-name "Harrison Totty"
      user-mail-address "harrisongtotty@gmail.com")

(setq doom-font (font-spec :family "{{ font.name }}" :size 14))

(load-file "~/.config/doom/themes/doom-wal.el")

(load-theme 'doom-nord)

(setq org-directory "~/docs/org")

(setq display-line-numbers-type t)
