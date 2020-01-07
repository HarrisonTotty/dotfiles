# IPython Configuration File
# --------------------------

from IPython.terminal.prompts import Prompts
from pygments.style import Style
from pygments.token import Token

# Obtain the configuration object
config = get_config()

# Import common libraries
config.InteractiveShellApp.exec_lines = [
    'import glob',
    'import itertools',
    'import os',
    'import re',
    'import shutil',
    'import socket',
    'import subprocess',
    'import sys',
    'import time'
]

# Don't confirm on exit
config.InteractiveShell.confirm_exit = False

# Set up the prompts
class MyPrompt(Prompts):
    def in_prompt_tokens(self, cli=None):
        return [
            (Token.PromptNum, str(self.shell.execution_count)),
            (Token.Prompt, '  >  ')
        ]
    def out_prompt_tokens(self, cli=None):
        return [
            (Token.PromptNum, str(self.shell.execution_count)),
            (Token.Prompt, '  <  ')
        ]
config.TerminalInteractiveShell.prompts_class = MyPrompt

# Modify the color scheme
config.TerminalInteractiveShell.highlighting_style_overrides = {
    Token.Comment:      'ansiwhite',
    Token.Error:        'ansiwhite',
    Token.Escape:       'ansiwhite',
    Token.Generic:      'ansiwhite',
    Token.Keyword:      'ansiwhite',
    Token.Keyword.Namespace: 'ansiwhite',
    Token.Keyword.Type:      'ansiwhite',
    Token.Literal:      'ansiwhite',
    Token.Name:         'ansiwhite',
    Token.Number:       'ansiwhite',
    Token.Operator:     'ansiwhite',
    Token.Other:        'ansiwhite',
    Token.OutPrompt:    'ansiwhite',
    Token.OutPromptNum: 'ansiblue',
    Token.Prompt:       'ansiwhite',
    Token.PromptNum:    'ansiblue',
    Token.Punctuation:  'ansiwhite',
    Token.String:       'ansiwhite',
    Token.Text:         'ansiwhite',
    Token.Token:        'ansiwhite'
}
