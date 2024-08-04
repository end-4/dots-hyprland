function _pisces_append -a text -d "Inserts a pair of strings (left-right) and puts the cursor between them"

    commandline --insert -- $text
    and _pisces_jump -(string length -- $text)
end
