function _pisces_should_insert -a insert -d "Determines if we should insert text"
    # If $pisces_only_insert_at_eol is unset, return true
    # Otherwise, return true if the cursor is at the end of the line OR
    # if the cursor is before a copy of $insert (i.e. a delimiter) at the end
    # of the line.
    set cmd_to_cursor (commandline -c)
    set cmd (commandline)
    test -z "$pisces_only_insert_at_eol" \
        -o "$cmd_to_cursor" = "$cmd" \
        -o "$cmd_to_cursor$insert" = "$cmd"
end
