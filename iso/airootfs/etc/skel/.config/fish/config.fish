# Tessarchy live shell.
#
# The live user's login shell is fish, so this file replaces the equivalent
# .bash_profile logic: start Tessera once on tty1 with no display or session
# manager, and return to the prompt when the session ends. Nothing here is
# used by a development install; the dev launcher works from any shell.

set -g fish_greeting

if status is-interactive
    if test (tty) = /dev/tty1
        if not set -q DISPLAY; and not set -q WAYLAND_DISPLAY
            printf '\nTessarchy live prototype — no secure locking or persistence.\n'
            printf 'Starting Tessera. After exit, run start-tessarchy to start again.\n'
            start-tessarchy
        end
    end
    abbr -a tessarchy 'start-tessarchy'
    abbr -a ll 'ls -lah'
end
