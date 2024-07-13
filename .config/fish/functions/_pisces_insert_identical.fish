function _pisces_insert_identical -a text -d "The binding command for a pair where the left and right delimiters are identical"
    if _pisces_should_insert $text
        _pisces_skip $text
        or _pisces_append $text
    else
        commandline -i -- $text
    end
end
