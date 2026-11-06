# ==============================================================================
# NyxNiri 终端增强 — fish 侧的胶水
# ==============================================================================
# 职责边界：提示符归 Starship，配色归 Noctalia，目录跳转归 zoxide，
# 模糊查找归 fzf.fish。这个文件只补「少打几个字、少摸一次鼠标」的部分。
# 私人改动请写 conf.d/__custom__.fish，这个文件会随仓库更新被替换。
# ==============================================================================

# ── fzf 默认行为 ──────────────────────────────────────────────────────────────
if command -q fzf; and command -q fd
    # fd 代替 find：跟随符号链接、默认吃 .gitignore、跳过 .git
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'

    # 颜色用 ANSI 编号而不是十六进制：深浅色切换时由终端调色板决定，
    # 这里永远不用跟着 Noctalia 改。
    # 前半段是 fzf.fish 在变量未设置时才会写进去的默认项，原样带上，
    # 否则它会以为用户自己配好了，--cycle / preview 换行 就丢了。
    set -gx FZF_DEFAULT_OPTS '--cycle --layout=reverse --border=rounded --height=90% --preview-window=wrap --marker=* --info=inline --color=fg:7,bg:-1,hl:5,fg+:15,bg+:8,hl+:13,info:5,prompt:5,pointer:13,marker:5,spinner:6,header:8,border:8'
end

# ── 编辑器与手册 ──────────────────────────────────────────────────────────────
# nyx-nvim 与 sysup 由各自插件部署到 ~/.config 下的独立目录。
# git commit、yazi 这些走 $EDITOR 的程序用不上 fish 函数，只能靠 PATH。
set -gx PATH "$HOME/.config/nyx-nvim" "$HOME/.config/sysup" $PATH
if command -q nyx-nvim
    set -gx EDITOR nyx-nvim
    set -gx VISUAL nyx-nvim
end

# 手册页交给 bat：有语法高亮，退出后不留满屏横线。
if command -q bat; and command -q col
    set -gx MANPAGER 'sh -c "col -bx | bat --language=man --plain"'
    set -gx MANROFFOPT -c
end

# bat / delta 用 ANSI 配色而不是 Monokai：跟着终端调色板走，
# 主题换深浅色时一致。想要花一点的就把这两行删掉，回默认主题。
if command -q bat
    set -gx BAT_THEME ansi
end
if command -q delta
    set -gx DELTA_SYNTAX_THEME ansi
end

# ── 交互式部分 ────────────────────────────────────────────────────────────────
if status is-interactive
    # ── 语法配色 ──────────────────────────────────────────────────────────────
    # 全部用 ANSI 名字，不写十六进制：主题换色时这里一行都不用改。
    # Noctalia 把绿/黄/蓝/青都映射到紫与粉，所以整屏是一片同色的柔和感。
    set -g fish_color_normal             normal
    set -g fish_color_command            magenta --bold
    set -g fish_color_builtin            br_magenta
    set -g fish_color_keyword            br_magenta
    set -g fish_color_function           br_magenta
    set -g fish_color_quote              yellow
    set -g fish_color_redirection        br_blue
    set -g fish_color_end                br_cyan
    set -g fish_color_operator           br_cyan
    set -g fish_color_escape             br_yellow
    set -g fish_color_param              br_white
    set -g fish_color_option             yellow
    set -g fish_color_comment            br_black
    set -g fish_color_error              br_red --bold --underline
    set -g fish_color_status             br_red
    set -g fish_color_cancel             br_red
    set -g fish_color_autosuggestion     br_black
    set -g fish_color_cwd                magenta
    set -g fish_color_cwd_root           red
    set -g fish_color_host               br_black
    set -g fish_color_host_remote        br_blue
    set -g fish_color_user               br_white
    set -g fish_color_valid_path         --underline
    set -g fish_color_history_current    --bold
    set -g fish_color_match              --background=black --bold
    set -g fish_color_selection          --background=black --bold
    set -g fish_color_search_match       --background=black --bold

    # ── 补全列表 ──────────────────────────────────────────────────────────────
    # 选中行整行背景变色，而不是只给文字上色——列表长的时候一眼能认出当前行。
    set -g fish_pager_color_progress              br_black
    set -g fish_pager_color_prefix                magenta --bold
    set -g fish_pager_color_completion            normal
    set -g fish_pager_color_description           br_black
    set -g fish_pager_color_selected_background   --background=black
    set -g fish_pager_color_selected_prefix       magenta --bold
    set -g fish_pager_color_selected_completion   br_white
    set -g fish_pager_color_selected_description  br_black
    set -g fish_pager_color_secondary_background  --background=black

    # 用 --global：缩写跟着配置走，不写进 fish_variables 再跟着机器跑。
    abbr --add --global gs  'git status --short --branch'
    abbr --add --global gd  'git diff'
    abbr --add --global gds 'git diff --staged'
    abbr --add --global gl  'git log --oneline --graph --decorate -20'
    abbr --add --global ga  'git add'
    abbr --add --global gc  'git commit'
    abbr --add --global gcm 'git commit -m'
    abbr --add --global gca 'git commit --amend --no-edit'
    abbr --add --global gp  'git push'
    abbr --add --global gpl 'git pull --rebase'
    abbr --add --global gf  'git fetch --prune'
    abbr --add --global gco 'git switch'
    abbr --add --global gcb 'git switch -c'

    function mkcd --description "创建目录并进入"
        if test (count $argv) -ne 1
            echo "用法: mkcd <目录>" >&2
            return 2
        end
        mkdir -p -- $argv[1]; and cd -- $argv[1]
    end

    function gb --description "fzf 选分支并切换"
        if not git rev-parse --git-dir >/dev/null 2>&1
            echo "不在 git 仓库里" >&2
            return 1
        end
        if not command -q fzf
            git branch --sort=-committerdate
            return
        end

        # for-each-ref 而不是 git branch：branch 会把 origin/HEAD 这类符号引用
        # 也列成一行“origin”，选中后 git switch 会报歧义。%(if) 直接跳过它们。
        set -l branch (git for-each-ref --sort=-committerdate \
            --format='%(if)%(symref)%(then)%(else)%(refname:short)%(end)' refs/heads refs/remotes \
            | string match -rv '^$' \
            | fzf --prompt='branch > ' \
                --preview='git log --oneline --graph --decorate -20 {}' \
                --preview-window='right:60%')

        test -n "$branch"; or return 0

        # origin/xxx：本地有同名分支就切本地的，没有就建跟踪分支
        if string match -q 'origin/*' -- $branch
            set -l local (string replace 'origin/' '' -- $branch)
            if git show-ref --verify --quiet "refs/heads/$local"
                git switch $local
            else
                git switch --track $branch
            end
        else
            git switch $branch
        end
    end
end
