# Have You Eaten（吃了吗？）

> 一个帮你解决「今天吃什么」的双场景决策 App。

## 项目介绍

Have You Eaten 是一个 Flutter + Spring Boot 的全栈应用。它把「吃什么」拆成两个日常场景：

- **在家吃**：从菜谱库里转盘抽签，抽到什么做什么。
- **出去吃**：先抽一个菜系，再把附近的店做成卡牌一张张翻，翻到满意为止。

「出去吃」的餐厅数据来自高德 POI 2.0，高德 key 只保存在服务端，App 端不接触。

## 功能特性

- **转盘抽菜**：按菜系筛选后随机抽一道菜，抽中后可直接查看菜谱详情与做法。
- **菜系抽签**：可指定多个菜系，也可留空由系统随机；「换菜系」时自动排除刚抽过的。
- **卡牌翻店**：抽中菜系后返回一组按距离召回、随机排序的店铺卡片；「换一家」本地翻牌不重复请求。
- **附近筛选**：支持菜系多选、人均预算、搜索半径三类条件。
- **记一笔**：确认餐厅后可写入吃过记录，并在记录页分页回看。
- **最近去过降权**：最近 3 天吃过的店自动排到队尾，避免反复推荐同一家。
- **定位与导航**：基于当前位置搜索附近餐厅，可一键唤起高德导航。
- **登录与鉴权**：账号注册登录、令牌刷新，请求侧支持动态 Token + 签名校验。

## 快速开始

### 本地运行

1. 克隆仓库

```bash
git clone <仓库地址>
cd have-you-eaten
```

2. 准备数据库与 Redis

本地自行准备 PostgreSQL 与 Redis，并创建数据库 `have_you_eaten`；账号、密码、端口与服务端配置文件保持一致。

3. 初始化数据库

```bash
psql -h 127.0.0.1 -p 5432 -U postgres -d have_you_eaten -f docs/init.sql
```

`docs/init.sql` 会建表并写入基础数据；`docs/` 下另有菜谱与菜系相关的增量脚本可按需执行。

4. 启动服务端

```bash
cd server
mvn spring-boot:run
```

默认端口 `8080`，接口统一前缀 `/api`。启动后可访问 Knife4j 文档查看全部接口。

5. 启动 App

```bash
cd app
flutter run --dart-define-from-file=config/config.json
```

配置从 `config/config.json` 注入（模板见 `config/config.example.json`）。首次拉取代码后如未安装依赖，先执行一次 `flutter pub get`。真机调试时把 `BASE_URL` 改成电脑的局域网 IP，并允许定位权限（「出去吃」需要当前位置）。

### 配置说明

#### 服务端

- `application.yml`：公共配置，默认激活 `my` profile；含高德 Web 服务配置 `amap.key` / `amap.base-url` / `amap.timeout`。
- `application-my.yml`：本地个人环境（数据库、Redis、Sa-Token、本地鉴权密钥）。
- `application-dev.yml`：开发环境，数据库与 Redis 通过环境变量注入（`POSTGRES_PASSWORD`、`REDIS_HOST`、`REDIS_PORT`、`REDIS_PASSWORD` 等），鉴权密钥通过 `AUTH_APP_KEY` / `AUTH_SECRET` 注入。

动态 Token + 签名鉴权配置（`hye.security`）：

| 配置项 | 说明 |
|---|---|
| `app-key` | App 握手凭证，对应 App 的 `APP_KEY` |
| `sign-secret` | HMAC-SHA256 签名密钥，对应 App 的 `SIGN_SECRET` |
| `token-ttl-seconds` | access token 有效期（秒），默认 7200 |
| `timestamp-window-seconds` | 请求时间戳允许窗口（秒），默认 ±300 |

`app-key` 与 `sign-secret` 都配置时启用动态 Token + 签名校验；任一留空即为开发模式，不做校验。

需要启用校验时，可运行 `server/src/test/java/com/hye/AuthKeyGeneratorTest.java` 生成一对随机凭证：

```bash
cd server
mvn -Dtest=AuthKeyGeneratorTest test
```

输出中的 `AUTH_APP_KEY` / `AUTH_SECRET` 分别填入服务端配置，同时把相同的值填入 App 的 `config/config.json`（`APP_KEY` / `SIGN_SECRET`）。

#### App

App 使用构建参数注入配置（含凭证，不写入代码），入口为 `app/config/config.json`，模板见 `app/config/config.example.json`，启动时通过 `--dart-define-from-file` 读取。

| 字段 | 说明 |
|---|---|
| `APP_NAME` | 应用名称 |
| `BASE_URL` | 后端地址，真机调试填电脑局域网 IP |
| `API_URL` | 接口前缀，默认 `/api` |
| `REQUEST_TIMEOUT` | 请求超时时间（毫秒） |
| `APP_KEY` | 握手凭证，与后端 `hye.security.app-key` 一致 |
| `SIGN_SECRET` | 签名密钥，与后端 `hye.security.sign-secret` 一致 |
| `version` | 应用版本号 |

`APP_KEY` 与 `SIGN_SECRET` 必须与服务端保持一致；两者都留空时服务端为开发模式，不做签名校验。

## 构建部署

### 服务端

```bash
cd server
mvn clean package -DskipTests
java -jar target/have-you-eaten.jar
```

### App

```bash
cd app
flutter build apk --release --dart-define-from-file=config/config.json     # Android
flutter build ios --release --dart-define-from-file=config/config.json     # iOS
```

## 数据来源

- **菜系与菜谱**：来自开源项目 [HowToCook](https://github.com/Anduin2017/HowToCook)。
- **餐厅**：来自高德 POI 2.0 周边搜索（`/v5/place/around`）与详情接口。
