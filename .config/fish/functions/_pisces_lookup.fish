function _pisces_lookup -a pos len -d "Returns the text at the given position relative to the cursor"

    test -z $pos
    and set pos 0
    test -z $len
    and set len 1

    set cur (commandline -C)
    set input (commandline -b)

    # NOTE: it's important to quote $input, because it may have newlines
    string sub --start (math "$cur + $pos + 1") --length $len -- "$input" 2>/dev/null
    or echo '' # if it's out of bounds (probably better to return cut part)
end
