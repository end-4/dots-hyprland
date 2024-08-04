function _pisces_remove -a left right -d "Removes an empty pair (left-right) or returns false"

    set left_len (string length $left)
    set right_len (string length $right)
    set length (math "$left_len + $right_len")

    if [ (_pisces_lookup -$left_len $length) = "$left$right" ]

        _pisces_jump $right_len
        for i in (seq 1 $length)
            commandline -f backward-delete-char
        end

        return 0
    end

    return 1
end
