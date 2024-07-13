function _pisces_insert_left -a left right -d "The binding command to insert the left delimiter"
    commandline -i -- $left
    and _pisces_should_insert $right
    and _pisces_append $right
end
