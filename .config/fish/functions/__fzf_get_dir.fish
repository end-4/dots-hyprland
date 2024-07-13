function __fzf_get_dir -d 'Find the longest existing filepath from input string'
    set dir $argv

    # Strip all trailing slashes. Ignore if $dir is root dir (/)
    if test (string length $dir) -gt 1
        set dir (string replace -r '/*$' '' $dir)
    end

    # Iteratively check if dir exists and strip tail end of path
    while test ! -d "$dir"
        # If path is absolute, this can keep going until ends up at /
        # If path is relative, this can keep going until entire input is consumed, dirname returns "."
        set dir (dirname "$dir")
    end

    echo $dir
end
