#!/usr/bin/env bash
# A script to appropriately configure xrandr at boot.
{%
  do require(
    'monitors.primary',
    'monitors.left',
    'monitors.right',
  )
%}

connected=$(xrandr -q | grep ' connected')

if echo "$connected" | grep -q '{{ monitors.primary }}'; then
    if echo "$connected" | grep -q '{{ monitors.left }}' && echo "$connected" | grep -q '{{ monitors.right }}'; then
        xrandr \
            --output "{{ monitors.primary }}" --primary --mode 1920x1080 --pos 1920x0 --rotate normal \
            --output "{{ monitors.right }}" --mode 1920x1080 --pos 3840x0 --rotate normal \
            --output "{{ monitors.left }}" --mode 1920x1080 --pos 0x0 --rotate normal
    else
        xrandr \
            --output "{{ monitors.primary }}" --primary --mode 1920x1080 --pos 0x0 --rotate normal \
            --output "{{ monitors.right }}" --off \
            --output "{{ monitors.left }}" --off
    fi
else
    echo "Primary display is not connected..."
    exit 1
fi
