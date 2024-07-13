function _pisces_jump -a n -d "Moves cursor by n/-n characters"

    test -z $n
    and set n 0

    set current (commandline -C)
    commandline -C (math "$current + $n")
end
