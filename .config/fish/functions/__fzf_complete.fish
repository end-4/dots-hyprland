##
# Use fzf as fish completion widget.
#
#
# When FZF_COMPLETE variable is set, fzf is used as completion
# widget for the fish shell by binding the TAB key.
#
# FZF_COMPLETE can have some special numeric values:
#
#   `set FZF_COMPLETE 0` basic widget accepts with TAB key
#   `set FZF_COMPLETE 1` extends 0 with candidate preview window
#   `set FZF_COMPLETE 2` same as 1 but TAB walks on candidates
#   `set FZF_COMPLETE 3` multi TAB selection, RETURN accepts selected ones.
#
# Any other value of FZF_COMPLETE is given directly as options to fzf.
#
# If you prefer to set more advanced options, take a look at the
# `__fzf_complete_opts` function and override that in your environment.


# modified from https://github.com/junegunn/fzf/wiki/Examples-(fish)#completion
function __fzf_complete -d 'fzf completion and print selection back to commandline'
    # As of 2.6, fish's "complete" function does not understand
    # subcommands. Instead, we use the same hack as __fish_complete_subcommand and
    # extract the subcommand manually.
    set -l cmd (commandline -co) (commandline -ct)

    switch $cmd[1]
        case env sudo
            for i in (seq 2 (count $cmd))
                switch $cmd[$i]
                    case '-*'
                    case '*=*'
                    case '*'
                        set cmd $cmd[$i..-1]
                        break
                end
            end
    end

    set -l cmd_lastw $cmd[-1]
    set cmd (string join -- ' ' $cmd)

    set -l initial_query ''
    test -n "$cmd_lastw"; and set initial_query --query="$cmd_lastw"

    set -l complist (complete -C$cmd)
    set -l result

    # do nothing if there is nothing to select from
    test -z "$complist"; and return

    set -l compwc (echo $complist | wc -w)
    if test $compwc -eq 1
        # if there is only one option dont open fzf
        set result "$complist"
    else

        set -l query
        string join -- \n $complist \
        | eval (__fzfcmd) (string escape --no-quoted -- $initial_query) --print-query (__fzf_complete_opts) \
        | cut -f1 \
        | while read -l r
            # first line is the user entered query
            if test -z "$query"
                set query $r
            # rest of lines are selected candidates
            else
                set result $result $r
            end
          end

        # exit if user canceled
        if test -z "$query" ;and test -z "$result"
            commandline -f repaint
            return
        end

        # if user accepted but no candidate matches, use the input as result
        if test -z "$result"
            set result $query
        end
    end

    set prefix (string sub -s 1 -l 1 -- (commandline -t))
    for i in (seq (count $result))
        set -l r $result[$i]
        switch $prefix
            case "'"
                commandline -t -- (string escape -- $r)
            case '"'
                if string match '*"*' -- $r >/dev/null
                    commandline -t --  (string escape -- $r)
                else
                    commandline -t -- '"'$r'"'
                end
            case '~'
                commandline -t -- (string sub -s 2 (string escape -n -- $r))
            case '*'
                commandline -t -- $r
        end
        [ $i -lt (count $result) ]; and commandline -i ' '
    end

    commandline -f repaint
end

function __fzf_complete_opts_common
    if set -q FZF_DEFAULT_OPTS
        echo $FZF_DEFAULT_OPTS
    end
    echo --cycle --reverse --inline-info
end

function __fzf_complete_opts_tab_accepts
    echo --bind tab:accept,btab:cancel
end

function __fzf_complete_opts_tab_walks
    echo --bind tab:down,btab:up
end

function __fzf_complete_opts_preview
    set -l file (status -f)
    echo --with-nth=1 --preview-window=right:wrap --preview="fish\ '$file'\ __fzf_complete_preview\ '{1}'\ '{2..}'"
end

test "$argv[1]" = "__fzf_complete_preview"; and __fzf_complete_preview $argv[2..3]

function __fzf_complete_opts_0 -d 'basic single selection with tab accept'
    __fzf_complete_opts_common
    echo --no-multi
    __fzf_complete_opts_tab_accepts
end

function __fzf_complete_opts_1 -d 'single selection with preview and tab accept'
    __fzf_complete_opts_0
    __fzf_complete_opts_preview
end

function __fzf_complete_opts_2 -d 'single selection with preview and tab walks'
    __fzf_complete_opts_1
    __fzf_complete_opts_tab_walks
end

function __fzf_complete_opts_3 -d 'multi selection with preview'
    __fzf_complete_opts_common
    echo --multi
    __fzf_complete_opts_preview
end

function __fzf_complete_opts -d 'fzf options for fish tab completion'
    switch $FZF_COMPLETE
        case 0
            __fzf_complete_opts_0
        case 1
            __fzf_complete_opts_1
        case 2
            __fzf_complete_opts_2
        case 3
            __fzf_complete_opts_3
        case '*'
            echo $FZF_COMPLETE
    end
    if set -q FZF_COMPLETE_OPTS
        echo $FZF_COMPLETE_OPTS
    end
end
