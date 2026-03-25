#!/bin/bash

# ============================================================
# DDD 项目脚手架生成脚本 v2
# 支持: Windows (Git Bash/MSYS2)、Mac (macOS)、Linux
# 使用 ddd-scaffold-lite-jdk17 模板创建 DDD 多模块项目
# ============================================================

set -e

# ============================================================
# 0. 脚本自定位（无论从哪里调用都能找到同目录资源）
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ============================================================
# 1. 全局默认值（仅用于非交互模式兜底）
# ============================================================
DEFAULT_GROUP_ID="com.yourcompany"
DEFAULT_ARTIFACT_ID="your-project-name"
DEFAULT_VERSION="1.0.0-SNAPSHOT"
DEFAULT_PACKAGE="com.yourcompany.project"
DEFAULT_ARCHETYPE_VERSION="1.3"
ARCHETYPE_REPOSITORY="https://maven.xiaofuge.cn/"

# ============================================================
# 2. 操作系统检测
# ============================================================
detect_os() {
    local os_name
    os_name="$(uname -s)"

    case "$os_name" in
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        Darwin*)               echo "mac" ;;
        Linux*)                echo "linux" ;;
        *)
            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                case "$ID" in
                    windows|msys|cygwin) echo "windows" ;;
                    macos|darling)       echo "mac" ;;
                    *)                   echo "linux" ;;
                esac
            else
                echo "linux"
            fi
            ;;
    esac
}

# ============================================================
# 3. 跨平台工具函数
# ============================================================

get_home_dir() {
    echo "$HOME"
}

# 检测目录是否可写
is_writable_dir() {
    [ -d "$1" ] && [ -w "$1" ]
}

# 检测命令是否存在
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# 检测是否为交互式终端
is_interactive() {
    [ -t 0 ]
}

# 交互式读取一行输入
read_line() {
    if is_interactive; then
        read -r "$1"
    fi
}

# ============================================================
# 4. 环境检测
# ============================================================
check_environment() {
    echo ""
    echo "============================================"
    echo "  [$(detect_os | tr '[:lower:]' '[:upper:]')] 环境检测"
    echo "============================================"
    echo "  ⚙️  环境要求: JDK 17+、Maven 3.8.*"
    echo ""

    local env_ok=true

    # Java
    if has_command java; then
        local java_ver
        java_ver=$(java -version 2>&1 | head -1 | sed 's/.*"\(.*\)".*/\1/')
        echo "  ✅ Java   $java_ver ($(command -v java))"
    else
        echo "  ❌ Java   未找到，本项目必须安装 JDK 17+"
        echo "     Windows: https://adoptium.net/"
        echo "     Mac:     brew install openjdk@17"
        echo "     Linux:   sudo apt install openjdk-17-jdk"
        env_ok=false
    fi

    # Maven
    if has_command mvn; then
        local mvn_ver
        mvn_ver=$(mvn -version 2>&1 | head -1 | sed 's/.*Apache Maven \(.*\)/\1/')
        echo "  ✅ Maven  $mvn_ver ($(command -v mvn))"
    else
        echo "  ❌ Maven  未找到，本项目推荐 Maven 3.8.*"
        echo "     Windows: https://maven.apache.org/download.cgi"
        echo "     Mac:     brew install maven"
        echo "     Linux:   sudo apt install maven"
        env_ok=false
    fi

    echo ""

    if [ "$env_ok" = false ]; then
        echo "⚠️  环境检测未通过，继续执行可能会失败，建议先安装缺失工具后再运行脚本。"
    fi
}

# ============================================================
# 5. 收集项目参数
# ============================================================

# 构建可写目录候选列表
build_target_options() {
    local home_dir
    home_dir=$(get_home_dir)
    local pwd_dir
    pwd_dir="$(pwd)"

    local options=()
    local count=0

    # 1. 当前工作目录（如果可写且不是脚本所在目录）
    if is_writable_dir "$pwd_dir" && [ "$pwd_dir" != "$SCRIPT_DIR" ]; then
        count=$((count + 1))
        options+=("$count" "$pwd_dir")
    fi

    # 2. home 目录
    if is_writable_dir "$home_dir" && [ "$home_dir" != "$pwd_dir" ]; then
        count=$((count + 1))
        options+=("$count" "$home_dir")
    fi

    # 3. home/workspace 或 home/projects（如果存在且可写）
    local subdir
    for subdir in "$home_dir/workspace" "$home_dir/projects" "$home_dir/Documents/projects"; do
        if is_writable_dir "$subdir" && [ "$subdir" != "$pwd_dir" ]; then
            count=$((count + 1))
            options+=("$count" "$subdir")
            break
        fi
    done

    # 将选项数组导出，供 ask_target_dir 使用
    TARGET_OPTIONS=("${options[@]}")
    OPTIONS_COUNT=$count
}

# 询问目标目录（选项列表 + 自定义路径）
ask_target_dir() {
    echo ""
    echo "============================================"
    echo "  📂 选择项目生成目录"
    echo "============================================"
    echo ""

    build_target_options

    local count=0

    # 打印选项
    local i
    for ((i = 1; i <= OPTIONS_COUNT; i++)); do
        local path
        path="${TARGET_OPTIONS[$((i * 2 - 1))]}"
        count=$((count + 1))
        printf "   %d) %s\n" "$count" "$path"
    done

    # 自定义路径选项（固定为最后一个）
    local custom_num=$((count + 1))
    echo "   $custom_num) 自定义路径（直接输入路径）"
    echo ""
    echo "  直接回车 = 选择 [1]"
    echo ""

    # 读取用户选择
    local selection=""
    read_line selection

    if [ -z "$selection" ]; then
        # 默认选 1
        TARGET_DIR="${TARGET_OPTIONS[1]}"
    elif [ "$selection" -eq "$custom_num" ] 2>/dev/null; then
        # 用户选择自定义
        echo ""
        echo "  请输入目标目录（绝对路径）:"
        read_line TARGET_DIR
        if [ -z "$TARGET_DIR" ]; then
            echo "  ❌ 未输入路径，退出"
            exit 1
        fi
        if [ ! -d "$TARGET_DIR" ]; then
            echo "  ❌ 目录不存在: $TARGET_DIR"
            exit 1
        fi
        if [ ! -w "$TARGET_DIR" ]; then
            echo "  ❌ 目录不可写: $TARGET_DIR"
            exit 1
        fi
    else
        # 用户选择了某个选项
        local idx=$((selection * 2 - 1))
        TARGET_DIR="${TARGET_OPTIONS[$idx]:-}"
        if [ -z "$TARGET_DIR" ]; then
            echo "  ❌ 无效选择，退出"
            exit 1
        fi
    fi

    echo ""
    echo "  ✅ 已选择: $TARGET_DIR"
}

# 询问其他项目参数
ask_project_params() {
    echo ""
    echo "============================================"
    echo "  📦 项目配置"
    echo "  (直接回车使用默认值)"
    echo "============================================"
    echo ""

    # GroupId
    local group_input=""
    read_line group_input
    GROUP_ID="${group_input:-$DEFAULT_GROUP_ID}"
    echo "   示例: com.yourcompany、cn.bugstack"
    echo ""

    # ArtifactId
    local artifact_input=""
    read_line artifact_input
    ARTIFACT_ID="${artifact_input:-$DEFAULT_ARTIFACT_ID}"
    echo "   示例: order-system、user-center"
    echo ""

    # Version
    local version_input=""
    read_line version_input
    VERSION="${version_input:-$DEFAULT_VERSION}"
    echo "   示例: 1.0.0-SNAPSHOT、2.1.0-RELEASE"
    echo ""

    # Package — 自动从 GroupId + ArtifactId 推导
    local auto_pkg="${DEFAULT_PACKAGE}"
    if [ "$GROUP_ID" != "$DEFAULT_GROUP_ID" ] && [ -n "$GROUP_ID" ]; then
        auto_pkg="${GROUP_ID}.${ARTIFACT_ID//-/.}"
    fi
    local pkg_input=""
    read_line pkg_input
    PACKAGE="${pkg_input:-$auto_pkg}"
    echo "   示例: com.yourcompany.project"
    echo ""

    # Archetype 版本
    local arch_input=""
    read_line arch_input
    ARCHETYPE_VERSION="${arch_input:-$DEFAULT_ARCHETYPE_VERSION}"
    echo ""

    # 验证 ArtifactId
    if [[ ! "$ARTIFACT_ID" =~ ^[a-zA-Z0-9][-a-zA-Z0-9_.]*$ ]]; then
        echo "❌ ArtifactId 不合法，只能包含字母、数字、-、_、.，且以字母或数字开头"
        exit 1
    fi

    # 验证 GroupId
    if [[ ! "$GROUP_ID" =~ ^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)*$ ]]; then
        echo "❌ GroupId 不合法，示例: com.yourcompany、cn.bugstack"
        exit 1
    fi
}

# ============================================================
# 6. 确认配置
# ============================================================
confirm_params() {
    echo ""
    echo "============================================"
    echo "  ✅ 确认配置"
    echo "============================================"
    printf "   %-12s %s\n" "目标目录:" "$TARGET_DIR"
    printf "   %-12s %s\n" "GroupId:" "$GROUP_ID"
    printf "   %-12s %s\n" "ArtifactId:" "$ARTIFACT_ID"
    printf "   %-12s %s\n" "Version:" "$VERSION"
    printf "   %-12s %s\n" "Package:" "$PACKAGE"
    printf "   %-12s %s\n" "Archetype:" "$ARCHETYPE_VERSION"
    echo ""

    local confirm=""
    if is_interactive; then
        read -r -p "确认以上配置开始生成？(y/n): " confirm
    else
        confirm="y"
    fi

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "已取消生成。"
        exit 0
    fi
}

# ============================================================
# 7. 执行 Maven 生成
# ============================================================
run_maven_generate() {
    echo ""
    echo "============================================"
    echo "  🚀 开始生成项目..."
    echo "============================================"
    echo "   目标目录: $TARGET_DIR"
    echo ""

    # Windows MSYS/Git Bash 下补充 PATH
    if [ "$(detect_os)" = "windows" ]; then
        export PATH="$PATH:/c/Program Files/Java:/c/Program Files/Apache/Maven/bin"
    fi

    cd "$TARGET_DIR"

    mvn archetype:generate \
        -DarchetypeGroupId=io.github.fuzhengwei \
        -DarchetypeArtifactId=ddd-scaffold-lite-jdk17 \
        -DarchetypeVersion="$ARCHETYPE_VERSION" \
        -DarchetypeRepository="$ARCHETYPE_REPOSITORY" \
        -DgroupId="$GROUP_ID" \
        -DartifactId="$ARTIFACT_ID" \
        -Dversion="$VERSION" \
        -Dpackage="$PACKAGE" \
        -B

    echo ""
    echo "============================================"
    echo "  🎉 项目生成完成！"
    echo "============================================"
    echo ""
    echo "📁 项目位置: $TARGET_DIR/$ARTIFACT_ID"
    echo ""
    echo "📋 下一步操作:"
    echo "   cd $TARGET_DIR/$ARTIFACT_ID"
    echo "   mvn clean install -DskipTests"
    echo "   导入 IDE 开始开发"
    echo ""
}

# ============================================================
# MAIN
# ============================================================
main() {
    echo ""
    echo "============================================"
    echo "  DDD 六边形架构项目脚手架生成工具"
    echo "  版本: v2.0"
    echo "  平台: $(detect_os)"
    echo "============================================"

    check_environment
    ask_target_dir
    ask_project_params
    confirm_params
    run_maven_generate
}

main "$@"
