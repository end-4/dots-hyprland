function _pisces_insert_right -a right -d "The binding command to insert the right delimiter"
    if _pisces_should_insert $right
        _pisces_skip $right
    else
        commandline -i -- $right
    end
end
