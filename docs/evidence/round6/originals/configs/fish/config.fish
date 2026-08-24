if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# 代理配置 (Proxy Configuration) — 修改此处以适配你的代理端口
set -g PROXY_ADDR "127.0.0.1:7890"

# 开启代理 (支持自定义端口或地址，如: proxy_on 10808 或 proxy_on 192.168.1.5:7890)
function proxy_on
    set -l addr "$PROXY_ADDR"
    if test (count $argv) -gt 0
        if string match -r '^\d+$' -- $argv[1]
            set addr "127.0.0.1:$argv[1]"
        else
            set addr "$argv[1]"
        end
    end

    set -gx http_proxy "http://$addr"
    set -gx https_proxy "http://$addr"
    set -gx all_proxy "socks5://$addr"
    set -gx HTTP_PROXY "http://$addr"
    set -gx HTTPS_PROXY "http://$addr"
    set -gx ALL_PROXY "socks5://$addr"
    echo "[+] 终端代理已开启 (Proxy: $addr)"
end

# 关闭代理
function proxy_off
    set -e http_proxy
    set -e https_proxy
    set -e all_proxy
    set -e HTTP_PROXY
    set -e HTTPS_PROXY
    set -e ALL_PROXY
    echo "[-] 终端代理已关闭"
end

# 查看代理状态
function proxy_status
    echo "--- 代理环境变量 (Proxy Env) ---"
    for var in http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
        if set -q $var
            echo "$var: "$$var
        else
            echo "$var: [未设置]"
        end
    end

    echo ""
    echo "--- 连通性测试 (Connectivity) ---"
    echo -n "测试 Google.com... "
    set -l start (date +%s%3N)
    set -l code (curl -I -s --connect-timeout 3 -o /dev/null -w "%{http_code}" https://www.google.com 2>/dev/null)
    set -l end (date +%s%3N)
    if test "$code" = "200" -o "$code" = "301" -o "$code" = "302"
        set -l duration (math $end - $start)
        echo "成功 (HTTP $code, $duration ms)"
    else
        echo "失败"
    end

    echo -n "测试 GitHub.com... "
    set -l gh_start (date +%s%3N)
    set -l gh_code (curl -I -s --connect-timeout 3 -o /dev/null -w "%{http_code}" https://github.com 2>/dev/null)
    set -l gh_end (date +%s%3N)
    if test "$gh_code" = "200" -o "$gh_code" = "301" -o "$gh_code" = "302"
        set -l gh_duration (math $gh_end - $gh_start)
        echo "成功 (HTTP $gh_code, $gh_duration ms)"
    else
        echo "失败"
    end

    echo ""
    echo "--- IP 地理位置 (IP Location) ---"
    curl -s --connect-timeout 3 -m 3 cip.cc 2>/dev/null | head -n 3
end

function ask_agy
    proxy_on
    agy $argv
end

# ==============================================================================
# NyxNiri TUI Cheatsheet 助手 (唯一指令: nyxhelp)
# ==============================================================================
function nyxhelp --description "NyxNiri Cheatsheet速查手册"
    set -l section ""
    if test (count $argv) -gt 0
        if test "$argv[1]" = "--section" -a (count $argv) -ge 2
            set section $argv[2]
        else
            set section $argv[1]
        end
    end

    switch "$section"
        case header
            echo ""
            set_color -o cyan; echo "  ── NyxNiri Dotfiles 终端与桌面速查手册 ──"; set_color normal
            echo ""
            return
        case cli
            set_color -o magenta; echo "  NyxNiri CLI & 配置快照"; set_color normal
            set_color -o yellow; echo -n "    nyxniri                  "; set_color green; echo "-> 打开控制面板主菜单"; set_color normal
            set_color -o yellow; echo -n "    nyxniri install config   "; set_color green; echo "-> 只部署配置，不安装依赖或壁纸"; set_color normal
            set_color -o yellow; echo -n "    nyxniri update           "; set_color green; echo "-> 更新源码并选择是否部署配置"; set_color normal
            set_color -o yellow; echo -n "    nyxniri doctor           "; set_color green; echo "-> 检查依赖、组件和桌面状态"; set_color normal
            set_color -o yellow; echo -n "    nyxniri apps             "; set_color green; echo "-> 管理 Nautilus、Mission Center、Fcitx5 Rime"; set_color normal
            set_color -o yellow; echo -n "    nyxniri snapshot [备注]  "; set_color green; echo "-> 创建配置快照"; set_color normal
            set_color -o yellow; echo -n "    nyxniri snapshot delete  "; set_color green; echo "-> 选择并删除一个或多个快照"; set_color normal
            set_color -o yellow; echo -n "    nyxniri rollback [序号]  "; set_color green; echo "-> 恢复历史配置快照"; set_color normal
            set_color -o yellow; echo -n "    nyxniri list             "; set_color green; echo "-> 查看所有配置快照"; set_color normal
            set_color -o yellow; echo -n "    nyxniri theme status     "; set_color green; echo "-> 查看当前深浅主题状态"; set_color normal
            return
        case proxy
            set_color -o magenta; echo "  网络代理控制"; set_color normal
            set_color -o yellow; echo -n "    proxy_on [端口/地址]     "; set_color green; echo "-> 开启代理 (默认 127.0.0.1:7890，Starship 实时显示)"; set_color normal
            set_color -o yellow; echo -n "    proxy_off                "; set_color green; echo "-> 关闭代理 (清除环境变量与 Prompt 标识)"; set_color normal
            set_color -o yellow; echo -n "    proxy_status             "; set_color green; echo "-> 检查代理连通性、延迟与公网 IP"; set_color normal
            return
        case pkg
            set_color -o magenta; echo "  包管理与清理"; set_color normal
            set_color -o yellow; echo -n "    up / update              "; set_color green; echo "-> 运行 paru/yay/shelly 一键全量更新"; set_color normal
            set_color -o yellow; echo -n "    in [包名]                "; set_color green; echo "-> 安装软件包 (无参时自动开启 se 模糊搜索)"; set_color normal
            set_color -o yellow; echo -n "    se [关键字]              "; set_color green; echo "-> 模糊搜索软件包 (支持 aur/pac 前缀) 并 fzf 交互安装"; set_color normal
            set_color -o yellow; echo -n "    un [关键字]              "; set_color green; echo "-> 模糊搜索已安装包并 fzf 交互卸载"; set_color normal
            set_color -o yellow; echo -n "    clean [--auto]           "; set_color green; echo "-> 扫描并清理大缓存与日志垃圾"; set_color normal
            return
        case keys bind keybindings
            set_color -o magenta; echo "  Niri 桌面核心快捷键"; set_color normal
            set_color -o blue; echo -n "    Mod + Return             "; set_color green; echo "-> 启动 Kitty 终端"; set_color normal
            set_color -o blue; echo -n "    Mod + T / Mod + Slash    "; set_color green; echo "-> Kitty 终端 / Scratchpad 快速终端"; set_color normal
            set_color -o blue; echo -n "    Mod + Z / Mod + F2       "; set_color green; echo "-> Orbit / Noctalia 设置"; set_color normal
            set_color -o blue; echo -n "    Mod + B / Mod + E        "; set_color green; echo "-> 浏览器 / Yazi 文件管理器"; set_color normal
            set_color -o blue; echo -n "    Mod + Q / Mod+Shift+E    "; set_color green; echo "-> 关闭当前窗口 / 退出桌面会话"; set_color normal
            set_color -o blue; echo -n "    Mod + Tab / Mod + O/G    "; set_color green; echo "-> 切换工作区概览 (Overview)"; set_color normal
            set_color -o blue; echo -n "    Mod + Space              "; set_color green; echo "-> 切换预设列宽比例"; set_color normal
            set_color -o blue; echo -n "    Mod + V / Shift+V        "; set_color green; echo "-> 切换浮动平铺 / 浮动层焦点穿透"; set_color normal
            set_color -o blue; echo -n "    Mod + X / Shift+X        "; set_color green; echo "-> 切换标签页列模式 (Tabbed Group)"; set_color normal
            set_color -o blue; echo -n "    Mod + F / Shift+F        "; set_color green; echo "-> 最大化列宽 / 全屏窗口"; set_color normal
            set_color -o blue; echo -n "    Mod + W / Alt+W          "; set_color green; echo "-> 聚焦上方窗口 / 壁纸选择器"; set_color normal
            set_color -o blue; echo -n "    Mod + N / Shift+N        "; set_color green; echo "-> 浮动层焦点 / 护眼暖色温模式"; set_color normal
            set_color -o blue; echo -n "    Mod + ~                  "; set_color green; echo "-> 切换 Kitty Scratchpad 浮动终端"; set_color normal
            set_color -o blue; echo -n "    Mod + Alt+Z / 鼠标前侧键 "; set_color green; echo "-> 呼出 Orbit 矢量星环启动器"; set_color normal
            set_color -o blue; echo -n "    Mod + Alt+L              "; set_color green; echo "-> 锁定屏幕 (Noctalia Lock)"; set_color normal
            set_color -o blue; echo -n "    Mod + Shift + S / Print  "; set_color green; echo "-> 交互式区域截图"; set_color normal
            set_color -o blue; echo -n "    Mod + Ctrl+Shift+R       "; set_color green; echo "-> 重载 Niri 桌面配置"; set_color normal
            set_color -o blue; echo -n "    Mod + Shift+Slash        "; set_color green; echo "-> 显示 Niri 原生按键覆盖层"; set_color normal
            return
        case shell
            set_color -o magenta; echo "  终端补全与 fzf"; set_color normal
            set_color -o blue; echo -n "    Tab                      "; set_color green; echo "-> 采纳补全 / 触发列表补全"; set_color normal
            set_color -o blue; echo -n "    Ctrl + R                 "; set_color green; echo "-> fzf 模糊搜索历史命令"; set_color normal
            set_color -o blue; echo -n "    Ctrl + Alt + F           "; set_color green; echo "-> fzf 模糊查找文件"; set_color normal
            set_color -o blue; echo -n "    Ctrl + Alt + L / S       "; set_color green; echo "-> fzf 浏览 Git Log / Status"; set_color normal
            return
        case tools
            set_color -o magenta; echo "  NyxNiri 工具入口"; set_color normal
            set_color -o blue; echo -n "    fm / y                   "; set_color green; echo "-> Yazi 文件管理器并回写退出目录"; set_color normal
            set_color -o blue; echo -n "    sys                      "; set_color green; echo "-> btop 系统资源监视器"; set_color normal
            set_color -o blue; echo -n "    proc                     "; set_color green; echo "-> procs 进程列表 (存在时)"; set_color normal
            set_color -o blue; echo -n "    disk                     "; set_color green; echo "-> duf 磁盘挂载表 (缺失时回退 df)"; set_color normal
            set_color -o blue; echo -n "    largest                  "; set_color green; echo "-> dust 大目录分析 (缺失时回退 du)"; set_color normal
            set_color -o blue; echo -n "    gdiff                    "; set_color green; echo "-> delta Git 差异 (缺失时回退 git diff)"; set_color normal
            return
    end

    if test -n "$section"
        nyxhelp header
        for sec in cli proxy pkg keys shell tools
            nyxhelp --section $sec
            echo ""
        end
        return
    end

    # Interactive TUI mode (when fzf is present & in interactive shell)
    if command -v fzf &>/dev/null; and status is-interactive
        set -l choices \
            "1. cli    NyxNiri CLI & 配置快照" \
            "2. proxy  网络代理控制 (Proxy)" \
            "3. pkg    包管理与缓存清理 (Shelly)" \
            "4. keys   Niri 桌面核心快捷键" \
            "5. shell  终端自动补全与 fzf 导航" \
            "6. tools  NyxNiri 工具入口" \
            "7. all    显示全量手册 (Full Cheatsheet)"

        set -l selection (printf '%s\n' $choices | fzf \
            --prompt="nyxhelp > " \
            --header="指令: nyxhelp | [↑/↓] 移动 | [Enter] 选定 | [Esc] 退出" \
            --preview-window="right:65%:wrap" \
            --preview="fish -c 'nyxhelp --section {2}'"
        )
        if test -n "$selection"
            set -l fields (string split -n ' ' -- $selection)
            nyxhelp --section $fields[2]
        end
    else
        nyxhelp --section all
    end
end

# 私有包管理器感知助手 (Paru > Yay > Shelly > Pacman)
function _nyxniri_pkg_helper
    if command -v paru &>/dev/null
        echo "paru"
    else if command -v yay &>/dev/null
        echo "yay"
    else if command -v shelly &>/dev/null
        echo "shelly"
    else
        echo "pacman"
    end
end

# 私有搜索分流助手 (供 se 交互及 fzf change 动态 reload)
function _nyxniri_se_search --argument-names query helper
    set -l input (string trim -- "$query")
    set -l parts (string split -n -m 1 " " -- "$input")
    set -l cmd "$parts[1]"
    set -l kw "$parts[2]"

    switch "$cmd"
        case aur
            if test -n "$kw"
                if test "$helper" = "paru" -o "$helper" = "yay"
                    $helper -Ssq --aur "$kw" 2>/dev/null | awk '{print "[AUR] "$0}' || true
                else if command -v paru &>/dev/null
                    paru -Ssq --aur "$kw" 2>/dev/null | awk '{print "[AUR] "$0}' || true
                else if command -v yay &>/dev/null
                    yay -Ssq --aur "$kw" 2>/dev/null | awk '{print "[AUR] "$0}' || true
                end
            end
        case pac repo
            if test -n "$kw"
                pacman -Slq | grep -i -- "$kw" | awk '{print "[PAC] "$0}' || true
            else
                pacman -Slq | awk '{print "[PAC] "$0}' || true
            end
        case '*'
            if test -n "$input"
                pacman -Slq | grep -i -- "$input" | awk '{print "[PAC] "$0}' || true
            else
                pacman -Slq | awk '{print "[PAC] "$0}' || true
            end
    end
end

if status is-interactive
    # No greeting
    set fish_greeting

    # Tab 智能自动补全：优先采纳灰色历史建议，无建议时触发 Tab 列表补全
    function custom_tab_complete
        if commandline -f accept-autosuggestion
            # 成功采纳自动提示建议
        else
            commandline -f complete
        end
    end

    function fish_user_key_bindings
        # 绑定 Tab 键
        bind \t custom_tab_complete
    end

    # Use starship prompt (Disable in pure TTY to avoid Nerd Font square boxes)
    if test "$TERM" != "linux"; and command -v starship &>/dev/null
        starship init fish | source
    end

    # Aliases
    alias clear "printf '\033[2J\033[3J\033[1;1H'" # fix: kitty doesn't clear scrollback properly
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"

    # 智能一键更新 (优先 paru/yay，自动防中途取消误触发)
    function up --description "一键系统与软件包更新 (Arch / CachyOS)"
        set -l helper (_nyxniri_pkg_helper)
        set -l res 0

        switch "$helper"
            case paru
                paru -Syu $argv
                set res $status
            case yay
                yay -Syu $argv
                set res $status
            case shelly
                shelly upgrade all $argv
                set res $status
            case '*'
                sudo pacman -Syu $argv
                set res $status
        end

        # 用户按 Ctrl+C / SIGINT (130) 或 SIGTERM (143) 取消操作时，安静退出
        if test $res -eq 130 -o $res -eq 143
            set_color yellow; echo "[!] 更新操作已由用户取消"; set_color normal
            return 130
        end

        if test $res -ne 0 -a "$helper" = "shelly"
            set_color yellow; echo "[!] Shelly 更新遇到异常，尝试使用备用包管理器..."; set_color normal
            if command -v paru &>/dev/null
                paru -Syu $argv
            else if command -v yay &>/dev/null
                yay -Syu $argv
            else
                sudo pacman -Syu $argv
            end
        end
    end
    alias update='up'                             # 同上，完整拼写

    # 智能安装 (无参自动触发 se 模糊搜索)
    function in --description "智能安装软件包 (支持包名或交互搜索)"
        if test (count $argv) -eq 0
            se
            return
        end

        set -l helper (_nyxniri_pkg_helper)
        set -l res 0

        switch "$helper"
            case paru
                paru -S $argv
                set res $status
            case yay
                yay -S $argv
                set res $status
            case shelly
                shelly install $argv
                set res $status
            case '*'
                sudo pacman -S $argv
                set res $status
        end

        if test $res -eq 130 -o $res -eq 143
            set_color yellow; echo "[!] 安装操作已由用户取消"; set_color normal
            return 130
        end

        if test $res -ne 0 -a "$helper" = "shelly"
            set_color yellow; echo "[!] Shelly 安装遇到异常，尝试使用备用包管理器..."; set_color normal
            if command -v paru &>/dev/null
                paru -S $argv
            else if command -v yay &>/dev/null
                yay -S $argv
            else
                sudo pacman -S $argv
            end
        end
    end

    alias clean='~/.config/fish/clean-cache'      # 运行一键缓存清理脚本

    # se：模糊搜索软件包 (支持 aur <kw> / pac <kw> 前缀) 并用 fzf 交互安装 (无 fzf 时自动降级)
    function se --description "模糊搜索并安装软件包 (支持 aur <kw> / pac <kw> 前缀)"
        set -l helper (_nyxniri_pkg_helper)

        # 无 fzf 时的降级处理
        if not command -v fzf &>/dev/null
            set_color yellow; echo "[!] 未检测到 fzf，切换至标准 CLI 搜索..."; set_color normal
            switch "$helper"
                case paru
                    paru -Ss $argv
                case yay
                    yay -Ss $argv
                case shelly
                    shelly search $argv
                case '*'
                    pacman -Ss $argv
            end
            return
        end

        # 构建 fzf 选项与搜索预填
        set -l fzf_query ""
        if test (count $argv) -gt 0
            set fzf_query "$argv"
        end

        set -l preview_cmd "pacman -Si {2}"
        if test "$helper" = "paru"
            set preview_cmd "paru -Si {2} 2>/dev/null || pacman -Si {2}"
        else if test "$helper" = "yay"
            set preview_cmd "yay -Si {2} 2>/dev/null || pacman -Si {2}"
        end

        set -l header_str "💡 搜索提示: 输入 'aur 关键字' 搜 AUR | 'pac 关键字' 搜官方源 | [Tab] 多选"

        set -l pkgs (_nyxniri_se_search "$fzf_query" "$helper" | fzf --multi --prompt='📦 包搜索 > ' \
            --header="$header_str" \
            --query="$fzf_query" \
            --bind 'change:reload(fish -c "_nyxniri_se_search {q} '$helper'")' \
            --preview "$preview_cmd" --preview-window 'right:60%:wrap')

        if test -n "$pkgs"
            set -l clean_pkgs
            for p in $pkgs
                set -a clean_pkgs (string replace -r '^\[.*?\]\s+' '' -- $p)
            end
            if test -n "$clean_pkgs"
                in $clean_pkgs
            end
        end
    end

    # un：模糊搜索已安装的包并用 fzf 交互卸载 (无 fzf 时自动降级)
    function un --description "模糊搜索并卸载已安装软件包"
        set -l helper (_nyxniri_pkg_helper)

        if not command -v fzf &>/dev/null
            set_color yellow; echo "[!] 未检测到 fzf，切换至标准已安装查询..."; set_color normal
            pacman -Qs $argv
            return
        end

        set -l fzf_query ""
        if test (count $argv) -gt 0
            set fzf_query "$argv"
        end

        set -l pkgs (pacman -Qq | fzf --multi --prompt='🗑  卸载 > ' \
            --header='[Tab] 多选 | [Enter] 确认卸载 | [Esc] 取消' \
            --query="$fzf_query" \
            --preview 'pacman -Qi {1}' --preview-window 'right:60%:wrap')

        if test -n "$pkgs"
            switch "$helper"
                case paru
                    paru -Rns $pkgs
                case yay
                    yay -Rns $pkgs
                case shelly
                    shelly remove standard $pkgs
                case '*'
                    sudo pacman -Rns $pkgs
            end
        end
    end
    
    if command -v eza &>/dev/null
        if test "$TERM" != "linux"
            alias ls 'eza --icons=auto'
            alias l 'eza --icons=auto --group-directories-first'
            alias ll 'eza -lah --icons=auto --group-directories-first --git'
            alias la 'eza -a --icons=auto --group-directories-first'
            alias lt 'eza --tree --level=2 --icons=auto --group-directories-first'
        else
            alias ls 'eza'
            alias l 'eza --group-directories-first'
            alias ll 'eza -lah --group-directories-first --git'
            alias la 'eza -a --group-directories-first'
            alias lt 'eza --tree --level=2 --group-directories-first'
        end
    end

    # Directory navigation: keep native cd semantics and add frequency-based helpers.
    if command -v zoxide &>/dev/null
        zoxide init fish | source
    end

    # Yazi directory hand-off. The wrapper stays opt-in at runtime and is absent when yazi is missing.
    if command -v yazi &>/dev/null
        function y --description "Open Yazi and return to its last directory"
            set -l cwd_file (mktemp -t nyxniri-yazi-cwd.XXXXXX)
            yazi --cwd-file="$cwd_file" $argv
            if test -r "$cwd_file"
                set -l cwd (string collect < "$cwd_file")
                if test -n "$cwd" -a -d "$cwd" -a "$cwd" != "$PWD"
                    cd -- "$cwd"
                end
            end
            rm -f -- "$cwd_file"
        end
        function fm --description "Open the NyxNiri terminal file manager"
            y $argv
        end
    end

    # Explicit visual replacements for common inspection commands. Native commands remain untouched.
    if command -v btop &>/dev/null
        function sys --description "Open the NyxNiri system monitor"
            btop $argv
        end
    end
    if command -v procs &>/dev/null
        function proc --description "Show a readable process list"
            procs $argv
        end
    end
    if command -v duf &>/dev/null
        function disk --description "Show mounted disks in a readable table"
            duf $argv
        end
    else
        function disk --description "Show mounted disks"
            df -h $argv
        end
    end
    if command -v dust &>/dev/null
        function largest --description "Find the largest entries in a directory"
            dust $argv
        end
    else
        function largest --description "Find the largest entries in a directory"
            du -h --max-depth=1 $argv | sort -h
        end
    end
    if command -v bat &>/dev/null
        function bathelp --description "Read command help with syntax highlighting"
            command $argv[1] --help 2>&1 | bat --language=help --style=plain --paging=never
        end
    end
    if command -v delta &>/dev/null
        function gdiff --description "View a readable Git diff"
            git diff --color=always $argv | delta
        end
    else
        function gdiff --description "View a Git diff"
            git diff $argv
        end
    end

    # Vivid is optional; use the Nyx file palette only when the generator and theme exist.
    if command -v vivid &>/dev/null; and test -f "$HOME/.config/vivid/themes/nyx.yml"
        set -gx LS_COLORS (vivid generate "$HOME/.config/vivid/themes/nyx.yml")
    end
end
