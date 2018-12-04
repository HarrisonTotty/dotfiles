;; Emacs color template for use with pywal
(require 'base16-theme)

;; colours generated dynamically by wal
(defun set-wal-colors () (setq base16-wal-colors
			       '(:base00 "{color0}"
					 :base01 "{color1}"
					 :base02 "{color2}"
					 :base03 "{color15}"
					 :base04 "{color4}"
					 :base05 "{color5}"
					 :base06 "{color6}"
					 :base07 "{color7}"
					 :base08 "{color8}"
					 :base09 "{color9}"
					 :base0A "{color10}"
					 :base0B "{color11}"
					 :base0C "{color12}"
					 :base0D "{color13}"
					 :base0E "{color14}"
					 :base0F "{color3}")))

(setq wal-foreground "{foreground}"
      wal-background "{background}"
      wal-cursor "{cursor}"
      wal-color0 "{color0}"
      wal-color1 "{color1}"
      wal-color2 "{color2}"
      wal-color3 "{color3}"
      wal-color4 "{color4}"
      wal-color5 "{color5}"
      wal-color6 "{color6}"
      wal-color7 "{color7}"
      wal-color8 "{color8}"
      wal-color9 "{color9}"
      wal-color10 "{color10}"
      wal-color11 "{color11}"
      wal-color12 "{color12}"
      wal-color13 "{color13}"
      wal-color14 "{color14}"
      wal-color15 "{color15}")

(defvar base16-wal-colors nil "All colors for base16-wal are defined here.")
(set-wal-colors)

;; Define the theme
(deftheme base16-wal)

;; Add all the faces to the theme
(base16-theme-define 'base16-wal base16-wal-colors)

;; Mark the theme as provided
(provide-theme 'base16-wal)

(provide 'base16-wal)
