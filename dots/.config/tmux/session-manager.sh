#!/bin/bash
# Tmux Session Manager - 智能删除（不会直接退出）
# 用法：从 tmux.conf 中调用或独立运行

CURRENT_SESSION=$(tmux display-message -p '#S' 2>/dev/null)

# 用 fzf 还是内置菜单
if command -v fzf &> /dev/null; then
    ACTION=$(echo -e "切换\n删除" | fzf --no-multi 2>/dev/null)
    
    if [ -z "$ACTION" ]; then
        exit 0
    fi
    
    if [ "$ACTION" = "切换" ]; then
        SESSION=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | \
            fzf --preview 'tmux capture-pane -t {} -p' 2>/dev/null)
        if [ -n "$SESSION" ]; then
            tmux switch-client -t "$SESSION"
        fi
    
    elif [ "$ACTION" = "删除" ]; then
        SESSION=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | \
            fzf --preview "echo 当前: $CURRENT_SESSION; tmux capture-pane -t {} -p" 2>/dev/null)
        
        if [ -n "$SESSION" ]; then
            if [ "$SESSION" = "$CURRENT_SESSION" ]; then
                # 当前 session，先切换到其他 session
                OTHER=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -v "^$SESSION$" | head -1)
                if [ -n "$OTHER" ]; then
                    tmux switch-client -t "$OTHER"
                    sleep 0.1
                fi
            fi
            tmux kill-session -t "$SESSION" 2>/dev/null
        fi
    fi
else
    # 无 fzf 时提示用户选择操作
    echo "选择操作："
    echo "(1) 切换 session"
    echo "(2) 删除 session"
    echo "其他: 取消"
    read -r -s -n 1 choice
    
    case "$choice" in
        1)
            tmux choose-session
            ;;
        2)
            # 删除的逻辑：列出所有 session，用户选择删除
            echo ""
            echo "删除 Session（输入 session 名称）："
            tmux list-sessions -F "#{session_name}" | nl
            read -r -p "删除 session: " SESSION
            
            if [ -n "$SESSION" ] && tmux has-session -t "$SESSION" 2>/dev/null; then
                if [ "$SESSION" = "$CURRENT_SESSION" ]; then
                    # 当前 session，先切换到其他 session
                    OTHER=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -v "^$SESSION$" | head -1)
                    if [ -n "$OTHER" ]; then
                        tmux switch-client -t "$OTHER"
                        sleep 0.1
                    fi
                fi
                tmux kill-session -t "$SESSION" 2>/dev/null
                echo "已删除 $SESSION"
            fi
            ;;
    esac
fi

