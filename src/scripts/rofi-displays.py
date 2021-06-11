#!/usr/bin/env python3
'''
A script to automatically generate display configurations.
'''

from itertools import permutations
import json
import os
import re
import subprocess
import sys

HANDLE_POLYBAR = True

DISPLAY_REGEX = re.compile(
    r'^(?P<display>[\w\-]+)\s+(?P<state>connected|disconnected)\s*(?P<primary>primary)?\s*(?P<current>[\dx\+]+)?\s+\((?P<options>[\w\s]+)\)\s*(?P<size>\d+mm\s+x\s+\d+mm)?$'
)

RESOLUTION_REGEX = re.compile(
    r'^\s+(?P<resolution>\d+x\d+)\s+(?P<remaining>.+)$'
)

RESOLUTION_FILTER = [
    '1920x1080',
    '4096x2160'
]

flatten = lambda t: [item for sublist in t for item in sublist]

def rofi(inputs: list):
    '''
    Displays a rofi prompt with the given list of inputs.
    '''
    with open('/tmp/rofi-displays.input', 'w') as f:
        for l in inputs:
            f.write(f'{l}\n')
    process = subprocess.Popen(
        "cat /tmp/rofi-displays.input | /usr/bin/rofi -dmenu -markup-rows -i -no-custom -p 'displays : '",
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT,
        shell = True
    )
    output = process.communicate()[0].decode('ascii', 'ignore')
    exit_code = process.returncode
    return (output, exit_code)


def get_display_info():
    '''
    Obtains the current configuration and availability of displays.
    '''
    info = {}
    process = subprocess.Popen(
        '/usr/bin/xrandr -q',
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT,
        shell = True
    )
    output = process.communicate()[0].decode('ascii', 'ignore')
    exit_code = process.returncode
    if exit_code: raise Exception('xrandr returned non-zero exit code')
    current = ''
    for l in output.splitlines():
        if match := DISPLAY_REGEX.match(l):
            current = match.group('display')
            info[current] = {
                'connected': match.group('state') == 'connected',
                'options': match.group('options'),
                'primary': 'primary' in match.groups(),
                'resolutions': [],
                'size': match.group('size')
            }
            if not match.group('current') is None and match.group('current'):
                info[current]['current'] = [int(x) for x in match.group('current').split('+', 1)[0].split('x')]
            else:
                info[current]['current'] = []
        elif match := RESOLUTION_REGEX.match(l):
            res = match.group('resolution')
            if res in RESOLUTION_FILTER:
                info[current]['resolutions'].append([int(x) for x in res.split('x')])
    return info


def make_note(input_str):
    return '<span weight="light" size="small"><i>(' + input_str + ')</i></span>'

def rts(res: list):
    return 'x'.join(map(str, res))


# ----- Start -----

info = get_display_info()
connected = [i for i in info.keys() if info[i]['connected']]

with_res = []
for c in connected:
    for res in info[c]['resolutions']:
        with_res.append(
            (c, rts(res))
        )

possible_configurations = []
for r in range(1, len(connected) + 1):
    for p in permutations(with_res, r):
        possible_configurations.append(list(p))

rofi_input = []
for i, p in enumerate(possible_configurations):
    chunks = []
    for disp in p:
        chunks.append(
            disp[0] + ' ' + make_note(disp[1])
        )
    rofi_input.append(str(i) + ': ' + ' | '.join(chunks))

(r_out, r_ec) = rofi(rofi_input)
selected = possible_configurations[int(r_out.split(':', 1)[0].strip())]
vertical = ' ^ ' in r_out

xrandr = '/usr/bin/xrandr'
for display, di in info.items():
    xrandr += ' --output ' + display
    found = False
    for display_tuple in selected:
        if display_tuple[0] == display:
            found = True
            index = selected.index(display_tuple)
            if di['primary']: xrandr += ' --primary'
            xrandr += ' --mode ' + display_tuple[1]
            if index > 0:
                if vertical:
                    xrandr += ' --above ' + selected[index - 1][0]
                else:
                    xrandr += ' --right-of ' + selected[index - 1][0]
            else:
                xrandr += ' --pos 0x0'
    if found:
        xrandr += ' --rotate normal'
    else:
        xrandr += ' --off'

xrandr_process = subprocess.Popen(
    xrandr,
    stdout = subprocess.PIPE,
    stderr = subprocess.STDOUT,
    shell = True
)
xrandr_output = xrandr_process.communicate()[0].decode('ascii', 'ignore')
xrandr_exit_code = xrandr_process.returncode

sys.stderr.write(xrandr_output + '\n')

if xrandr_exit_code:
    sys.exit(1)

if HANDLE_POLYBAR:
    os.system('killall -q polybar; while pgrep -x polybar >/dev/null; do sleep 0.5; done')
    for i, d in enumerate(selected):
        if len(selected) < 3:
            if i == 0:
                os.environ['POLYBAR_DISPLAY_PRIMARY'] = d[0]
                bar = 'primary'
            else:
                os.environ['POLYBAR_DISPLAY_RIGHT'] = d[0]
                bar = 'single-monitor'
        else:
            if i == 0:
                os.environ['POLYBAR_DISPLAY_LEFT'] = d[0]
                bar = 'left'
            elif i == 1:
                os.environ['POLYBAR_DISPLAY_PRIMARY'] = d[0]
                bar = 'primary'
            elif i == 2:
                os.environ['POLYBAR_DISPLAY_RIGHT'] = d[0]
                bar = 'right'
            else:
                bar = ''
        if bar:
            os.system(f'polybar {bar} &')

print(json.dumps(selected))
