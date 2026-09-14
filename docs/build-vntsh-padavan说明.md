# Padavan-VNT GitHub Actions 工作流说明

本文档对应工作流文件：`.github/workflows/build-vntsh-padavan.yml`。

它的主要用途是：用户手动选择 Padavan 机型、输入多个 LAN IP 和一个 VNT Token，GitHub Actions 为每个 LAN IP 创建一个独立的矩阵任务，修改 Padavan 默认配置，编译固件，修改固件名称，然后上传到远程服务器和 GitHub Release。

## 一、整体执行流程

```text
手动触发 workflow_dispatch
        |
        v
解析 custom_ips，生成 IP 矩阵
        |
        +--> 每个 IP 启动一个 build 矩阵任务
                    |
                    +--> 检出当前仓库到 build-repo/
                    +--> 安装 Ubuntu 编译依赖
                    +--> 拉取 Padavan 源码
                    +--> 安装 MIPS-L 交叉工具链
                    +--> 执行 vnt-diy.sh
                    +--> 修改默认 LAN IP、SSID 和 STA 参数
                    +--> 修改 VNT 配置
                    +--> 编译固件
                    +--> 修改 .trx 文件名并复制到 output_files/
                    +--> 上传到远程服务器
                    +--> 上传到 GitHub Release
```

每一个矩阵任务都是独立的 GitHub Runner，因此不同 IP 的源码、编译目录和 `output_files` 互不共享。

## 二、工作流顶部配置

### 1. 名称和运行名称

`name` 是 Actions 页面中显示的工作流名称。

`run-name` 会把当前选择的机型和 IP 列表显示在某次运行的名称中，方便区分不同批次。

### 2. 手动输入参数

工作流通过 `workflow_dispatch` 手动触发，提供三个参数。

| 参数 | 类型 | 作用 |
| --- | --- | --- |
| `target_board` | `choice` | 选择 Padavan 目标机型 |
| `custom_ips` | `string` | 输入逗号分隔的 LAN IP，例如 `10.168.1.1,10.168.2.1` |
| `custom_token` | `string` | 同一批固件使用的 VNT Token |

`target_board` 使用固定选项，风险较低。`custom_ips` 和 `custom_token` 是用户自由输入，当前文件没有进行严格格式校验。

### 3. 全局环境变量和权限

```yaml
REPO_URL: https://github.com/waylin88/rt-n56u.git
REPO_BRANCH: master
TZ: Asia/Shanghai
```

当前脚本实际使用的是硬编码的 GitHub 地址，`REPO_URL` 没有被引用，因此修改 `REPO_URL` 不会影响实际拉取地址。`REPO_BRANCH` 被用于 `git clone`。

```yaml
permissions:
  contents: write
```

这允许工作流使用 `GITHUB_TOKEN` 创建或更新 Release。权限范围已经比较集中，没有开放整个仓库的读写权限。

## 三、parse-inputs Job：解析 IP 列表

这一 Job 只负责把字符串形式的 IP 列表转成 JSON 数组，并通过 Job 输出传给后面的 `build` Job。

例如：

```text
10.168.1.1, 10.168.2.1
```

会被转换成：

```json
["10.168.1.1","10.168.2.1"]
```

关键处理过程如下：

1. `tr ',' '\n'` 把逗号转换成换行。
2. `xargs -n1` 去掉每行首尾空白。
3. `grep -v '^$'` 删除空项。
4. `jq -R .` 把每行变成 JSON 字符串。
5. `jq -s -c .` 汇总成紧凑 JSON 数组。
6. 将结果写入 `$GITHUB_OUTPUT`，输出名为 `ip_matrix`。

如果输入为空，脚本会使用 `['default']` 作为兜底值。

### 这里的实际问题

`default` 不是合法 IP。后续代码会执行：

```bash
CURRENT_VNT_IP="10.2.0.$(echo "$CURRENT_LAN_IP" | awk -F. '{print $3}')"
```

当 `CURRENT_LAN_IP=default` 时，最终结果会变成 `10.2.0.`，这不是合法 IPv4 地址。因此当前的空输入兜底逻辑不能真正保证工作流可用。更合理的做法是直接拒绝空输入，或者提供一个合法的默认 IP。

## 四、build Job：矩阵编译

```yaml
matrix:
  ip: ${{ fromJSON(needs.parse-inputs.outputs.ip_matrix) }}
```

如果输入两个 IP，GitHub Actions 会启动两个独立任务：

```text
任务 A：matrix.ip = 10.168.1.1
任务 B：matrix.ip = 10.168.2.1
```

`fail-fast: false` 表示其中一个 IP 的编译失败时，不会自动取消其他 IP 的任务。

## 五、源码和工具链准备

### 1. Checkout

当前仓库被检出到：

```text
build-repo/
```

这样做是为了避免和后面拉取的 Padavan 源码目录 `padavan-src/` 混在一起。

### 2. 安装依赖

工作流安装 GCC、Make、Flex、Bison、Gawk、OpenSSL、ncurses、fakeroot 等编译 Padavan 所需的 Ubuntu 软件包。

### 3. 拉取 Padavan 源码

实际执行的命令是：

```bash
git clone --depth 1 -b $REPO_BRANCH \
  https://x-access-token:${{ secrets.PERSONAL_TOKEN }}@github.com/waylin88/rt-n56u.git \
  padavan-src
```

它依赖仓库 Secret：

```text
PERSONAL_TOKEN
```

由于 URL 中包含 Token，GitHub 通常会对匹配到的 Secret 做日志脱敏，但仍然不建议主动打印完整 clone 命令或 Token。

### 4. 安装交叉编译工具链

进入 `padavan-src/toolchain-mipsel`，执行源码自带的 `dl_toolchain.sh`。

## 六、执行 vnt-diy.sh

脚本优先查找：

```text
vnt-diy.sh
build-repo/vnt-diy.sh
```

找到后赋予执行权限并运行。由于 Runner 的默认工作目录是工作区根目录，通常第二个路径会命中当前仓库中的脚本。

如果没有找到脚本，当前流程只打印警告并继续编译。这种行为适合允许可选补丁的场景；如果该脚本是 VNT 功能的必要组成部分，建议改为直接失败，避免编译出缺少功能的固件。

## 七、修改 Padavan 默认参数

### 1. WiFi SSID

脚本修改 `padavan-src/trunk/user/shared/defaults.h` 中的四个宏：

```text
DEF_WLAN_2G_SSID
DEF_WLAN_5G_SSID
DEF_WLAN_2G_GSSID
DEF_WLAN_5G_GSSID
```

当前固定使用：

```text
YYWiFi
```

生成的形式大致为：

```text
YYWiFi_%s
YYWiFi_5G_%s
YYWiFi_GUEST_%s
YYWiFi_GUEST_5G_%s
```

### 2. LAN 地址和 DHCP 范围

对于 `10.168.2.1`，脚本提取前三段得到网段前缀 `10.168.2`，然后写入：

```text
DEF_LAN_ADDR     10.168.2.1
DEF_LAN_DHCP_BEG 10.168.2.100
DEF_LAN_DHCP_END 10.168.2.244
```

只有当矩阵 IP 不是 `default` 时才执行 LAN 地址替换。

### 3. STA 自动连接参数

如果 `defaults.c` 存在，脚本把下面两个配置的值改成 `1`：

```text
rt_sta_auto
wl_sta_auto
```

## 八、修改 VNT 配置

目标目录是：

```text
padavan-src/trunk/user/vntc/
```

脚本优先使用 `start`，不存在时使用 `vntc.sh`。

### 1. Token

非空时替换配置中的：

```yaml
token: ...
```

### 2. 当前设备 VNT IP

规则是取 LAN IP 的第三段。例如：

```text
10.168.1.1 -> 10.2.0.1
10.168.2.1 -> 10.2.0.2
```

### 3. in_ips 路由

脚本遍历全部 LAN IP，排除当前设备，为其余设备生成：

```text
10.168.2.0/24,10.2.0.2
```

然后使用 `awk` 找到 `in_ips:`，删除旧的缩进列表项，并插入新列表。

### 这里的实际问题

当前只取 LAN IP 的第三段作为 VNT IP 的最后一段。因此以下情况会冲突：

```text
10.168.1.1
192.168.1.1
```

它们都会被映射成 `10.2.0.1`。另外，输入不是标准 IPv4 时，脚本仍会继续生成不完整的网段或 VNT 地址。应在 `parse-inputs` 阶段验证每个 IP，至少限制为合法 IPv4，并检查第三段不能重复。

## 九、Build Firmware

编译步骤进入：

```text
padavan-src/trunk
```

然后执行：

```bash
chmod +x ./build_firmware
chmod +x ./clear_tree
fakeroot ./build_firmware ${{ github.event.inputs.target_board }}
```

编译输出预期位于：

```text
padavan-src/trunk/images/
```

这里当前已经启用真实编译，之前的测试用假固件步骤已经移除。

## 十、编译完成后的固件改名

`Rename Firmware Files` 是独立步骤，负责三件事：

1. 创建工作区根目录下的 `output_files/`。
2. 查找 `images/` 下的所有 `.trx` 文件。
3. 修改文件名，并复制到 `output_files/`。

例如：

```text
JSH-03_3.4.3.9-099.trx
```

会变成：

```text
JSH-03_3.4.3.9-VNT-10.168.2.1.trx
```

文件名处理规则是：

```bash
BASE_NAME="${file%.*}"
PREFIX="${BASE_NAME%-*}"
NEW_NAME="${PREFIX}-VNT-${TARGET_IP}.trx"
```

注意：`mv` 会直接修改 `images/` 中的原文件名；`cp` 再把改名后的文件复制到 `output_files/`。Release 使用的就是 `output_files/*.trx`。

## 十一、远程服务器上传

上传步骤使用以下 Secrets：

| Secret | 用途 |
| --- | --- |
| `SERVER_KEY` | SSH 私钥 |
| `SERVER_USER` | 远程用户名 |
| `SERVER_HOST` | 远程主机 |
| `SERVER_PORT` | SSH 端口 |
| `custom_token` | 远程目录名 |

远程目录为：

```text
/www/wwwroot/vnt_http/firmware/<TOKEN>/
```

步骤先通过 SSH 创建目录，再遍历 `output_files/*.trx`，使用 SCP 上传同名文件。

上传结束后删除：

```text
~/.ssh/id_rsa
```

## 十二、GitHub Release 上传

使用 `softprops/action-gh-release@v2`，Release 标签为：

```text
Padavan_VNT_<TOKEN>
```

上传文件配置为：

```yaml
files: output_files/*.trx
```

这里使用工作区相对路径是正确的。`${GITHUB_WORKSPACE}` 不会在 Action 的 `with.files` 参数中按 Shell 变量方式展开。

## 十三、审查发现的问题

### 高风险：矩阵任务可能并发操作同一个 Release

每个 IP 都会执行一次 `Upload to GitHub Release`，但所有任务使用相同的：

```text
Padavan_VNT_<TOKEN>
```

多个任务可能同时创建或更新同一个 Release。不同版本的 `softprops/action-gh-release` 对并发创建和上传的处理可能不同，可能出现创建竞争、资产上传失败或同名资产冲突。

更稳妥的设计是增加一个独立的汇总 Job：矩阵任务先上传 GitHub Actions Artifact，所有矩阵任务完成后，由一个非矩阵 Job 下载全部 Artifact，再统一创建 Release 和上传资产。远程服务器上传也可以采用同样的汇总设计，或者确认服务器端允许并发上传。

### 高风险：用户输入直接嵌入 Shell

以下表达式直接进入 `run` 脚本：

```text
${{ github.event.inputs.custom_ips }}
${{ github.event.inputs.custom_token }}
${{ matrix.ip }}
```

虽然输入来自手动触发页面，但 `custom_ips` 和 `custom_token` 仍然是自由文本。特殊字符可能破坏 Shell 引号、影响 `sed` 表达式，甚至执行额外命令。Token 也被拼接到远程路径和 Release 标签中。

建议使用 `env:` 传入输入，再在 Shell 内通过变量读取，并对 IP 和 Token 做严格白名单校验。Token 如需保密，不应使用普通 workflow input，而应使用 GitHub Secret。

### 中风险：Token 被打印到日志

当前脚本打印：

```bash
echo ">>> Token: $INPUT_TOKEN"
echo "组网 Token: ${TOKEN}"
```

这会让 Token 出现在 Actions 日志中。应删除这两处完整打印，最多只打印是否已配置，或者只显示脱敏后的前几位和后几位。

### 中风险：IP 校验和唯一性校验不足

当前只做字符串拆分，没有验证 IPv4 格式、网段范围和第三段重复。错误输入会在编译前进入配置文件，导致生成无效 VNT 配置或路由冲突。

### 中风险：SSH 主机密钥检查被关闭

SSH 和 SCP 都使用：

```text
-o StrictHostKeyChecking=no
```

这会关闭远程主机身份校验，降低中间人攻击防护。更安全的做法是把服务器公钥预先放入 GitHub Secret，在连接前写入 `known_hosts`，然后启用严格检查。

### 中风险：异常退出时私钥清理不可靠

如果远程建目录或 SCP 在到达最后一行前失败，`rm -f ~/.ssh/id_rsa` 可能不会执行。Runner 通常是临时环境，但仍建议使用 `trap 'rm -f ~/.ssh/id_rsa' EXIT`，确保成功和失败都会清理。

### 低风险：空输入兜底值不适合当前业务

`["default"]` 会导致无效的 VNT IP 和文件名。建议将空输入直接判定为错误并退出，避免产生看似成功但不可用的固件。

### 低风险：编号和变量命名可读性

最后两个步骤都标记为 `# 10`，不影响执行，但会增加排查日志的困难。`REPO_URL` 已定义但没有使用，`TARGET_IP` 实际表示当前设备 LAN IP，也容易和服务器 IP 混淆。

## 十四、当前检查结果

本次检查确认：

- YAML 文件可以被 Ruby YAML 解析器读取。
- `git diff --check` 通过，没有发现差异中的空白格式错误。
- 编译、改名、远程上传和 Release 上传的步骤顺序是连贯的。
- `output_files/*.trx` 是当前 Release Action 获取产物的正确相对路径。
- 当前工作流存在上面列出的运行和安全风险，不能称为完全没有问题。

## 十五、建议的后续修复顺序

1. 先禁止空 IP，并验证每个 IP 是合法 IPv4，检查第三段不重复。
2. 移除 Token 的完整日志输出，并通过 `env:` 传递用户输入。
3. 使用 `trap` 清理 SSH 私钥，并配置 `known_hosts`。
4. 将 Release 上传移动到单独的汇总 Job，避免矩阵并发更新同一 Release。
5. 删除未使用的 `REPO_URL`，修正步骤编号和变量名。
