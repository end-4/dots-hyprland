# 翻译管理工具套件

这套工具用于管理项目的翻译文件，自动提取可翻译文本，比较不同语言文件之间的差异，并提供维护功能。

## 工具组成

### 1. `translation-manager.py` - 主要翻译管理器
- 提取可翻译文本
- 比较和更新翻译文件
- 交互式添加/删除翻译键

### 2. `translation-cleaner.py` - 翻译文件维护工具
- 清理不再使用的翻译键
- 同步不同语言文件的键结构

### 3. `manage-translations.sh` - 便捷包装脚本
- 提供统一的命令行界面
- 显示翻译状态
- 简化常用操作

## 快速开始

### 使用便捷脚本（推荐）

```bash
# 进入工具目录
cd .config/quickshell/translations/tools

# 查看帮助
./manage-translations.sh --help

# 显示当前翻译状态
./manage-translations.sh status

# 提取可翻译文本
./manage-translations.sh extract

# 更新所有翻译文件
./manage-translations.sh update

# 更新特定语言
./manage-translations.sh update -l zh_CN

# 清理不再使用的键
./manage-translations.sh clean

# 同步所有语言文件的键
./manage-translations.sh sync
```

或者从项目根目录运行：
```bash
# 从项目根目录运行
.config/quickshell/translations/tools/manage-translations.sh status
.config/quickshell/translations/tools/manage-translations.sh update
```

## 详细使用说明

### 翻译管理器 (`translation-manager.py`)

基本用法：
```bash
# 处理所有语言
./translation-manager.py

# 指定特定语言
./translation-manager.py --language zh_CN

# 仅提取可翻译文本
./translation-manager.py --extract-only

# 显示提取的文本
./translation-manager.py --extract-only --show-temp
```

参数说明：
- `--translations-dir`, `-t`: 翻译文件目录（默认：`.config/quickshell/translations`）
- `--source-dir`, `-s`: 源代码目录（默认：`.config/quickshell`）
- `--language`, `-l`: 指定要处理的语言代码
- `--extract-only`, `-e`: 仅提取可翻译文本
- `--show-temp`: 显示临时提取文件的内容

### 翻译清理器 (`translation-cleaner.py`)

```bash
# 清理不再使用的翻译键
./translation-cleaner.py --clean

# 同步翻译键（以 en_US 为基准）
./translation-cleaner.py --sync

# 指定不同的源语言进行同步
./translation-cleaner.py --sync --source-lang zh_CN

# 清理时不创建备份
./translation-cleaner.py --clean --no-backup
```

## 工作流程

### 日常翻译更新流程

1. **检查状态**：
   ```bash
   ./manage-translations.sh status
   ```

2. **更新翻译**：
   ```bash
   ./manage-translations.sh update
   ```

3. **清理无用键**（可选）：
   ```bash
   ./manage-translations.sh clean
   ```

### 新增语言流程

1. **创建新语言文件**：
   ```bash
   ./manage-translations.sh update -l new_lang
   ```

2. **同步键结构**：
   ```bash
   ./manage-translations.sh sync
   ```

### 大规模重构后的清理流程

1. **备份翻译文件**：
   ```bash
   cp -r .config/quickshell/translations .config/quickshell/translations.backup
   ```

2. **清理无用键**：
   ```bash
   ./manage-translations.sh clean
   ```

3. **同步所有语言**：
   ```bash
   ./manage-translations.sh sync
   ```

## 支持的翻译文本格式

工具可以识别以下格式的可翻译文本：

```qml
// 基本格式
Translation.tr("Hello, world!")
Translation.tr('Hello, world!')
Translation.tr(`Hello, world!`)

// 带换行符
Translation.tr("Line 1\nLine 2")

// 带转义字符
Translation.tr("Say \"Hello\"")

// 带参数占位符
Translation.tr("Hello, %1!").arg(name)
```

## 示例输出

### 状态显示
```
$ ./manage-translations.sh status
正在分析翻译状态...
=== 当前项目状态 ===
提取到 166 个可翻译文本

=== 翻译文件状态 ===
  en_US: 470 个键
  zh_CN: 470 个键
```

### 更新翻译
```
$ ./manage-translations.sh update -l zh_CN
更新翻译文件...
==================================================
处理语言: zh_CN
==================================================
分析结果:
  缺少的键: 5
  多余的键: 20

发现 5 个缺少的翻译键：
1. "New feature text"
2. "Another new text"
...

是否添加这 5 个缺少的键？ (y/n): y
已添加 5 个键

发现 20 个多余的翻译键：
1. "Removed old text" -> "已删除的旧文本"
...

是否删除这 20 个多余的键？ (y/n): y
已删除 20 个键

已保存翻译文件
```

### 清理无用键
```
$ ./manage-translations.sh clean
清理不再使用的翻译键...
处理语言: zh_CN
发现 50 个不再使用的键:
  1. "old_unused_text"
  2. "deprecated_message"
  ...

是否删除这 50 个不再使用的键？ (y/n): y
已删除 50 个键
原始键数: 470, 清理后: 420
```

## 高级功能

### 自定义目录结构

```bash
# 使用自定义目录
./translation-manager.py \
  --translations-dir /path/to/translations \
  --source-dir /path/to/source
```


## 注意事项

1. **备份重要**：在执行清理操作前，工具会自动创建备份，但建议手动备份重要文件

2. **文本提取限制**：
   - ~~只支持静态字符串，不支持动态构建的字符串~~
   - 动态资源（如变量拼接、运行时生成的文本）无法自动提取，需要在翻译文件中手动添加，并使用 `/*keep*/` 标记进行忽略管理。
   - 必须使用 `Translation.tr()` 格式
### 忽略标记功能

对于动态资源或特殊文本，如果不希望被自动清理，可在翻译值末尾添加 `/*keep*/`，工具会自动忽略这些键，不会在清理和同步时删除。

示例：
```json
{
  "dynamic_key": "Some dynamic value /*keep*/"
}
```

3. **文件编码**：所有文件必须使用 UTF-8 编码

4. **键名规范**：建议使用英文作为键名，避免使用特殊字符

## 故障排除

### 常见问题


**Q: 添加了 Translation.tr 后文字不显示？**
A: 需要在 QML 文件中使用 `import "root:/"` 导入翻译功能，否则无法正常显示翻译文本。

**Q: 提取的文本数量与预期不符？**
A: 检查是否所有可翻译文本都使用了 `Translation.tr()` 格式，确保没有动态构建的字符串。

**Q: 同步后某些翻译丢失？**
A: 检查源语言文件是否包含所有必要的键，考虑使用不同的源语言进行同步。

**Q: 清理操作删除了需要的键？**
A: 从自动创建的备份文件中恢复，检查源代码中是否正确使用了 `Translation.tr()`。

### 恢复备份

```bash
# 恢复单个文件
cp .config/quickshell/translations/zh_CN.json.backup .config/quickshell/translations/zh_CN.json

# 恢复所有文件
cp .config/quickshell/translations.backup/* .config/quickshell/translations/
```
