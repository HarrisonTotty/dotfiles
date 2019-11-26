# X Window System Environment Variable Exports
# --------------------------------------------
{% do require('font.name', 'window_manager') %}

export DUNST_FONT='{{ font.name }} 10'
export DUNST_SIZE='300x30-40+40'
export EDITOR='emacs'
export LANG='en_US.UTF-8'
export LC_CTYPE='en_US.UTF-8'
export UI_FONT='{{ font.name }} 10'
export WINDOW_MANAGER='{{ window_manager }}'
