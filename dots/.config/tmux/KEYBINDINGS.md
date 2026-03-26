# Tmux 快捷键参考

**前缀键：`Ctrl+q`**

## Session 管理

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `Ctrl+q u` | 智能 session 菜单 | 切换/删除选项，删除不会直接退出 |
| `Ctrl+q g` | 切换 session（输入） | 交互式输入 session 名称并切换 |
| `Ctrl+q (` | 上一个 session | 切换到前一个 session |
| `Ctrl+q )` | 下一个 session | 切换到后一个 session |
| `Ctrl+q b` | 上一个活跃 session | 切回前一个活跃的 session（历史记录） |
| `Ctrl+q Ctrl+c` | 新建 session | 创建新的会话 |
| `Ctrl+q Ctrl+r` | 重命名 session | 重命名当前 session |
| `Ctrl+q Q` | 关闭 session | 关闭当前 session（带确认） |

### Ctrl+q u 菜单使用

**有 fzf 时：**
```
Ctrl+q u              # 打开菜单
选择"切换"或"删除"      # 输入或上下箭头
切换：选中 → Enter     # 切换到选中 session
删除：选中 → Enter     # 删除选中 session（如是当前 session 会先切到其他 session）
```

**无 fzf 时：**
```
Ctrl+q u              # 打开菜单
按 1 切换 / 2 删除
按 1：看 session 列表，按空格或 / 选择
按 2：输入要删除的 session 名（如是当前会话会先切到其他 session）
```

**关键：删除 session 时永远不会退出**  
- 如果删除的是当前 attached session，脚本会自动先切换到另一个 session
- 然后再删除之前的 session
- 这样你就一直连接着，不会被踢出

## Window 管理

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `Ctrl+q c` | 新建 window | 创建新 window（继承当前路径） |
| `Ctrl+q 1..9` | 跳转到 window | 快速切换到第 1-9 个 window |
| `Alt+b` | 上一个 window | 切换到前一个 window |
| `Alt+n` | 下一个 window | 切换到后一个 window |
rename-window| `Ctrl+q i` | 重命名 window | 输入新 window 名称 |
| `Ctrl+q ,` | 重命名 window | 备选快捷键 |
| `Ctrl+q X` | 关闭 window | 关闭当前 window（带确认） |

## Pane 管理

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `Ctrl+q v` | 左右分屏 | 竖向分割（左右两个 pane） |
| `Ctrl+q s` | 上下分屏 | 横向分割（上下两个 pane） |
| `Alt+h` | 切换到左 pane | Vim 风格导航 |
| `Alt+j` | 切换到下 pane | Vim 风格导航 |
| `Alt+k` | 切换到上 pane | Vim 风格导航 |
| `Alt+l` | 切换到右 pane | Vim 风格导航 |
| `Alt+Shift+H` | pane 左缩小 5 格 | 无前缀快捷键，可重复按 |
| `Alt+Shift+J` | pane 下缩小 5 格 | 无前缀快捷键，可重复按 |
| `Alt+Shift+K` | pane 上缩小 5 格 | 无前缀快捷键，可重复按 |
| `Alt+Shift+L` | pane 右缩小 5 格 | 无前缀快捷键，可重复按 |
| `Ctrl+q x` | 关闭 pane | 关闭当前 pane（带确认） |
| `Ctrl+q z` | 最大化/还原 pane | 放大当前 pane 或还原 |

## 复制模式

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `Ctrl+q Enter` | 进入复制模式 | 进入 Vi 风格复制模式 |
| `v`（在复制模式中） | 开始选择 | 标记复制范围起点 |
| `y`（在复制模式中） | 复制并退出 | 复制当前选择内容并退出复制模式 |

## 常用组合

### 快速切换和列表
```
Ctrl+q u              # 打开智能菜单（切换/删除两种操作）
                      # 有 fzf: 菜单选择后 Enter 确认
                      # 无 fzf: 按 1 切换 / 2 删除

删除时的关键：
如果删除当前 attached session → 自动先切换到其他 session → 再删除
结果：永远不会被踢出 tmux

其他快捷键：
Ctrl+q g              # 输入 session 名称快速切换
Ctrl+q (/)            # 上/下一个 session 循环切换
Ctrl+q b              # 一键切回最后一个 session
```

### 快速布局
```
Ctrl+q v      # 竖分
Ctrl+q s      # 横分
Alt+h/j/k/l   # 切换 pane
Ctrl+q z      # 最大化当前 pane
```

### 窗口管理
```
Ctrl+q c      # 新建 window
Alt+b/n       # 前/后 window
Ctrl+q w      # 重命名 window
```

## 注意事项

1. **Session 删除时永远不会退出**  
   脚本在删除 attached session 时会自动先切到另一个 session，再删除：
   ```
   Ctrl+q u → 选"删除" → 选你当前 session → 自动切到其他 session → 当前 session 已删除
   整个过程你仍在 tmux 中，不会被踢出
   ```

2. **FZF 增强（可选）**  
   如果装了 fzf，菜单会更友好：
   ```bash
   # macOS
   brew install fzf
   
   # Ubuntu/Debian  
   apt install fzf
   ```
   没 fzf 也能用，只是需要手动输入操作号而已。

3. **鼠标支持已启用**  
   - 可直接点击选择 pane、window、滚动历史
   - Vi 模式复制：鼠标选中自动进入复制模式

4. **会话持久化**  
   - `tmux-resurrect` + `continuum` 已启用
   - 关闭 tmux 后下次启动会自动恢复会话

5. **快捷键冲突检查**  
   - 所有快捷键均无冲突
   - Pane 切换/缩放取消了前缀键，使用 `Alt` 可全局快速响应

6. **配置重载**  
   如修改配置后按键不生效，执行：
   ```bash
   tmux source-file ~/.config/tmux/tmux.conf
   ```

7. **禁用流控**  
   如 `Ctrl+q` 无效（终端拦截），执行：
   ```bash
   stty -ixon
   ```
