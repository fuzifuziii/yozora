function fish_prompt -d "Write out the prompt"
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive
    set fish_greeting

    fastfetch

    function sudo
        if test "$argv[1]" = nvim
            command sudo -E $argv
        else
            command sudo $argv
        end
    end
end
