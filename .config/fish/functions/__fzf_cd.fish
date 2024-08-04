function __fzf_cd -d "Change directory"
    set -l commandline (__fzf_parse_commandline)
    set -l dir $commandline[1]
    set -l fzf_query $commandline[2]

    if not type -q argparse
        # Fallback for fish shell version < 2.7
        function argparse
            functions -e argparse # deletes itself
        end
        if contains -- --hidden $argv; or contains -- -h $argv
            set _flag_hidden "yes"
        end
    end

    # Fish shell version >= v2.7, use argparse
    set -l options  "h/hidden"
    argparse $options -- $argv

    set -l COMMAND

    set -q FZF_CD_COMMAND
    or set -l FZF_CD_COMMAND "
    command find -L \$dir -mindepth 1 \\( -path \$dir'*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' \\) -prune \
    -o -type d -print 2> /dev/null | sed 's@^\./@@'"

    set -q FZF_CD_WITH_HIDDEN_COMMAND
    or set -l FZF_CD_WITH_HIDDEN_COMMAND "
    command find -L \$dir \
    \\( -path '*/\\.git*' -o -fstype 'dev' -o -fstype 'proc' \\) -prune \
    -o -type d -print 2> /dev/null | sed 1d | cut -b3-"

    if set -q _flag_hidden
        set COMMAND $FZF_CD_WITH_HIDDEN_COMMAND
    else
        set COMMAND $FZF_CD_COMMAND
    end

    eval "$COMMAND | "(__fzfcmd)" +m $FZF_DEFAULT_OPTS $FZF_CD_OPTS --query \"$fzf_query\"" | read -l select

    if not test -z "$select"
        builtin cd "$select"

        # Remove last token from commandline.
        commandline -t ""
    end

    commandline -f repaint
end
