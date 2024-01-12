#!/usr/bin/env nu

export def stm [
    --file (-f): string = "~/Documents/tasks.json" # the todo file to operate on
    --config (-c): string = "~/.config/stm/config.toml" # path to the config file
    --json (-j) # output as json
    --yes (-y) # skip confirmation prompt

    --title (-t): string # new task title
    --details (-d): string # new task details
    --occurance (-o): string # date of occurance

    --add (-a) # add task interactively
    --modify (-m): number # modify task by id
    --remove (-r): number # remove task by id

    --show-details (-s) # show all details
    --get-details (-g): number # by id
] {
    let skip_confirmation = (try {
        open $config | get skip_confirmation
    } catch { $yes })

    let color = {
        red: 1
        blue: 5
        white: 15
    }

    # config
    try {
        $env.config.color_config = (open $config | get color)
    }
    try {
        $env.config.table = (open $config | get table)
    }
    try {
        $env.config.datetime_format = { table: (open $config | get date_format) }
    }

    def confirm [ask = true] {
        if $ask and (not $skip_confirmation) {
            return ((gum confirm
                --selected.background $color.blue
                | complete
                | get exit_code) == 0)
        }
        return $ask
    }

    def str_check [...strings: string] {
        for string in $strings {
            if $string != null and $string != "" {
                return $string
            }
        }
        return ""
    }

    def open_file [] {
        open $file | each {|i| $i | merge {
            occurance: (try {
                (str_check $i.occurance) | into datetime
            } catch { "" })
        }}
    }

    def add_task [title details occurance] {
        open $file
            | append {
                title: $title
                details: $details
                occurance: $occurance
            }
            | sort-by occurance -r
            | save $file -f
    }

    # create file
    let $dir = $file | path dirname

    if not ($dir | path exists) {
        mkdir $dir
    }

    if not ($file | path exists) {
        [] | save $file
    }

    # check flags
    let flags = [($remove != null) ($modify != null) $add]
    if ($flags | filter {|x| $x } | length) > 1 {
        (gum log -l error -s
            --level.foreground $color.red
            "only one flag can be true"
            remove $"($remove != null)"
            modify $"($modify != null)"
            add $"($add)"
        )
        return
    }

    # remove task
    if (confirm ($remove != null)) {
        open_file
            | reject $remove
            | save $file -f
    }

    # modify
    if $modify != null {
        mut task = (open_file | get $modify)

        let mod_title = (gum input
            --placeholder "Title"
            --prompt "❯ "
            --value $"(str_check $title $task.title)"
            --header "Title:"
            --cursor.foreground $color.white)

        let mod_details = (gum write
            --placeholder "Details"
            --value $"(str_check $details $task.details)"
            --header "Details:"
            --height 12
            --cursor.foreground $color.white)

        let mod_occ = (gum input
            --placeholder "Occurance"
            --prompt "❯ "
            --value $"(str_check $occurance $task.occurance)"
            --header "Occurance:"
            --cursor.foreground $color.white)

        if (confirm) {
            open $file
                | update $modify {
                    title: $mod_title
                    details: $mod_details
                    occurance: $mod_occ
                }
                | sort-by occurance -r
                | save $file -f
        }
    }

    # add task
    if $add {
        let inp_title = (gum input
            --placeholder "Title"
            --prompt "❯ "
            --value $"(str_check $title)"
            --header "Title:"
            --cursor.foreground $color.white)

        let inp_desc = (gum write
            --placeholder "Details"
            --value $"(str_check $details)"
            --header "Details:"
            --height 12
            --cursor.foreground $color.white)

        let inp_occ = (gum input
            --placeholder "Occurance"
            --prompt "❯ "
            --value $"(str_check $occurance)"
            --header "Occurance:"
            --cursor.foreground $color.white)

        add_task $inp_title $inp_desc $inp_occ
    } else if $modify == null and $title != null {
        add_task $title $details $occurance
    }

    # print
    let print_details = try {
        open $config | get print_details
    } catch { false }

    if $get_details != null {
        return (open_file | get $get_details | get details)
    }

    if $json {
        echo (open_file | to json)
    } else if $show_details or $print_details {
        echo (open_file)
    } else {
        echo (open_file | reject details)
    }
}
