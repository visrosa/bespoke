function bkpsv --description 'Create backup savefiles'
    set -l now (date +%y%m%dT%H%M)

    # default savefiles
    if not set -q isaacsavefile[1]
        set -gx isaacsavefile \
            /home/rosvi/.wine/drive_c/users/rosvi/AppData/Roaming/GSE\ Saves/250900/remote/rep+persistentgamedata1.dat \
            /home/rosvi/.wine/drive_c/users/rosvi/AppData/Roaming/GSE\ Saves/250900/remote/rep+gamestate1.dat

        echo (set_color -d grey)"Isaac save file not set, assuming"(set_color normal)
        for f in $isaacsavefile
            echo (set_color -i)"$f"(set_color normal)
        end
    end

    if not set -q deadcellssavedir[1]
        set -gx deadcellssavedir \
            /home/rosvi/.wine/drive_c/users/rosvi/AppData/Roaming/GSE\ Saves/588650/remote

        echo (set_color -d grey)"Dead Cells save dir not set, assuming"(set_color normal)
        echo (set_color -i)"$deadcellssavedir"(set_color normal)
    end

    switch $argv[1]

        case isaac
            set -l savefiles $isaacsavefile

            # verify files exist
            if not test -e "$savefiles[1]"
                echo (set_color red)"Error:"(set_color normal) "save file missing:"
                echo (set_color -d grey)"$savefiles[1]"(set_color normal)
                return 1
            end

            switch $argv[2]

                # --------------------
                # RESTORE SNAPSHOT
                # --------------------
                case restore
                    # resolve snapshot: use argument, or fall back to newest
                    if set -q argv[3]
                        set -l snap $argv[3]
                    else
                        set -l snap (string replace -r '.*\.' '' -- $savefiles[1].??????T????(glob) 2>/dev/null | sort | tail -1)
                        if test -z "$snap"
                            # glob didn't expand — try ls-based fallback
                            set -l snap (ls "$savefiles[1]".??????T???? 2>/dev/null | sort | tail -1 | string replace -r '.*\.' '')
                        end
                        if test -z "$snap"
                            echo (set_color red)"Error:"(set_color normal) "no snapshots found for restore"
                            return 1
                        end
                        echo (set_color -d grey)"No snapshot given, using latest:"(set_color normal) (set_color -i)$snap(set_color normal)
                    end

                    if not string match -rq '^\d{6}T\d{4}$' $snap
                        echo (set_color red)"Error:"(set_color normal) "invalid snapshot id '$snap'"
                        return 1
                    end

                    # ensure snapshot set exists
                    for f in $savefiles
                        if not test -e "$f.$snap"
                            echo (set_color red)"Error:"(set_color normal) "snapshot missing:"
                            echo (set_color -d grey)"$f.$snap"(set_color normal)
                            return 1
                        end
                    end

                    # restore snapshot set
                    for f in $savefiles
                        cp "$f" "$f.deprecated"
                        cp "$f.$snap" "$f"

                        echo (set_color magenta)'~/🍷AppData/' \
                             (set_color normal)(path basename $f) \
                             ' « ' \
                             (set_color -i)$snap
                    end

                # --------------------
                # CREATE BACKUP
                # --------------------
                case ''
                    for f in $savefiles
                        cp "$f" "$f.$now"

                        echo (set_color magenta)'~/🍷AppData/' \
                             (set_color normal)(path basename $f) \
                             ' » ' \
                             (set_color -i)$now
                    end

                case '*'
                    echo (set_color red)"Error:"(set_color normal) "unknown subcommand '$argv[2]'"
                    echo "Usage:"
                    echo "  bkpsv isaac"
                    echo "  bkpsv isaac restore SNAPSHOT"
                    return 1
            end

        # ====================
        # DEAD CELLS
        # ====================
        case deadcells
            set -l savedir $deadcellssavedir

            # verify save directory exists
            if not test -d "$savedir"
                echo (set_color red)"Error:"(set_color normal) "save directory missing:"
                echo (set_color -d grey)"$savedir"(set_color normal)
                return 1
            end

            # collect save files via glob
            set -l savefiles $savedir/user_*.dat $savedir/customGameData_*.json

            if test (count $savefiles) -eq 0
                echo (set_color red)"Error:"(set_color normal) "no Dead Cells save files found in:"
                echo (set_color -d grey)"$savedir"(set_color normal)
                return 1
            end

            switch $argv[2]

                # --------------------
                # RESTORE SNAPSHOT
                # --------------------
                case restore
                    # resolve snapshot: use argument, or fall back to newest
                    if set -q argv[3]
                        set -l snap $argv[3]
                    else
                        set -l snap (string replace -r '.*\.' '' -- $savefiles[1].??????T????(glob) 2>/dev/null | sort | tail -1)
                        if test -z "$snap"
                            set -l snap (ls "$savefiles[1]".??????T???? 2>/dev/null | sort | tail -1 | string replace -r '.*\.' '')
                        end
                        if test -z "$snap"
                            echo (set_color red)"Error:"(set_color normal) "no snapshots found for restore"
                            return 1
                        end
                        echo (set_color -d grey)"No snapshot given, using latest:"(set_color normal) (set_color -i)$snap(set_color normal)
                    end

                    if not string match -rq '^\d{6}T\d{4}$' $snap
                        echo (set_color red)"Error:"(set_color normal) "invalid snapshot id '$snap'"
                        return 1
                    end

                    # ensure every snapshot file exists before touching anything
                    for f in $savefiles
                        if not test -e "$f.$snap"
                            echo (set_color red)"Error:"(set_color normal) "snapshot missing:"
                            echo (set_color -d grey)"$f.$snap"(set_color normal)
                            return 1
                        end
                    end

                    # restore snapshot set
                    for f in $savefiles
                        cp "$f" "$f.deprecated"
                        cp "$f.$snap" "$f"

                        echo (set_color cyan)'~/🗡️ GSESaves/588650/' \
                             (set_color normal)(path basename $f) \
                             ' « ' \
                             (set_color -i)$snap
                    end

                # --------------------
                # CREATE BACKUP
                # --------------------
                case ''
                    for f in $savefiles
                        cp "$f" "$f.$now"

                        echo (set_color cyan)'~/🗡️ GSESaves/588650/' \
                             (set_color normal)(path basename $f) \
                             ' » ' \
                             (set_color -i)$now
                    end

                case '*'
                    echo (set_color red)"Error:"(set_color normal) "unknown subcommand '$argv[2]'"
                    echo "Usage:"
                    echo "  bkpsv deadcells"
                    echo "  bkpsv deadcells restore SNAPSHOT"
                    return 1
            end

        case '*'
            echo "Usage:"
            echo "  bkpsv isaac"
            echo "  bkpsv isaac restore SNAPSHOT"
            echo "  bkpsv deadcells"
            echo "  bkpsv deadcells restore SNAPSHOT"
            return 1
    end
end
