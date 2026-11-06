# NyxNiri Custom Fish Configuration
#
# Any modifications in this file (such as aliases, exports) will be safely preserved during system updates.
# You can also create a `__custom__/` directory in the current folder to drop your private scripts in.
#
# 任何在此文件中的修改（如 alias、export）都会在系统更新时被安全保留。
# 你也可以在当前目录下创建 __custom__/ 文件夹，把自己的私有脚本都扔进去。
#
# Example / 例如：
# alias ll='ls -alF'
# set -gx EDITOR nvim

# Keep the OmO command usable even if a package refresh removes ~/.local/bin/omo.
function omo --description 'Launch the newest installed OmO Native runtime'
    set -l runtimes (command find "$HOME/.omo/binary-runtime" -mindepth 2 -maxdepth 2 -type f -name omo -perm -u+x 2>/dev/null | sort -V)
    if test (count $runtimes) -eq 0
        echo 'omo: no executable runtime found under ~/.omo/binary-runtime' >&2
        return 127
    end
    exec $runtimes[-1] $argv
end

# Automatically source all *.fish scripts inside __custom__/ directories if present
# 自动载入 conf.d/__custom__/ 与 ~/.config/fish/__custom__/ 目录下的所有 *.fish 脚本
set -l custom_dirs (status dirname)/__custom__ ~/.config/fish/__custom__
for cdir in $custom_dirs
    if test -d "$cdir"
        for f in "$cdir"/*.fish
            if test -f "$f"
                source "$f"
            end
        end
    end
end
