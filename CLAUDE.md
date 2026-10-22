# discourse-kuu-points（给 Claude Code）

## 这是什么
- 京大中文论坛（KUU，京都大学学生论坛，Discourse 自托管）的经验值 / 鲸币插件：等级、每日任务、鲸币商城、头像装饰、管理后台
- 需求以 GitHub Issue #1 为准（2026-10-22 David 确认）：https://github.com/DAVVVVVVVVVVVID/discourse-kuu-points/issues/1
- 技术方案：Notion「项目中心 › 项目文档 › 京大论坛｜经验值和鲸币插件技术方案」
  https://app.notion.com/p/40143ea2113c810e965fc7fc62189c8b 。开发中有变化要同步更新 Notion，在改动处写上日期
- 参考实现：二手市场插件 `~/discourse/plugins/discourse-kuu-market`（结构、Service::Base、测试写法、CLAUDE.md）。**其他 KUU 插件都不要改**
- 线上部署不归本仓库管，由 KUU 运维那边负责（私有仓库 `kuu-forum`）。本仓库只写部署说明，由 David 转交
- 本仓库是**公开**的：不要提交任何密钥、敏感信息、用户数据

## 已确定的规则（不要自行改，要改先问 David）
1. 等级 1–5：每 200 经验升一级（0 / 200 / 400 / 600 / 800），5 级封顶，之后经验继续累计、显示「满级」。和 core 的信任等级**完全无关**，不影响权限
2. 每日任务按**日本时间 0 点**分界（`Asia/Tokyo`），同一任务每人每天只记一次：
   - 签到（点按钮）10 经验 / 5 鲸币；第一个新话题 10 / 5（任何分类，含评分、二手插件直接建的帖子）；
     第一次回复 5 / 3（含评分短评，聊天不算）；第一次给**别人**的帖子点赞 5 / 3；第一次转发 5 / 3
   - 数值是站点设置 `kuu_points_<任务>_xp` / `kuu_points_<任务>_coins`，任务名 `checkin topic reply like share`
   - 删帖、取消点赞**不扣**；所有用户参与（含运营号和鲸仔）；老用户从 0 开始，不补发
   - 被封禁 / 禁言的用户不发奖励；系统账号、staged 用户也不发（2026-10-22 David 确认）
   - 私信里的发帖、回复、点赞不算任务；密语和小动作帖子不算（2026-10-22 David 确认）
3. 「转发」发生在主题组件 discourse-kuu-theme 的分享菜单里，插件只提供接口 `POST /kuu-points/tasks/share`，主题那边的改动由 David 另开 Issue
4. 鲸币商城、兑换、佩戴（同时最多一个头像框 + 一个饰品）、头像装饰显示位置（帖子头像、用户卡片、个人主页）、管理后台：见 Issue #1 第 3–5 条
5. 不在第一期：连续签到奖励、等级特权、鲸币换别的东西、列表 / 聊天小头像装饰、排行榜

## 自己定的技术细节（写进 Notion 方案）
- 数据：`kuu_points_accounts` 每人一行当前值（xp、coins，都有 `>= 0` 约束）；`kuu_points_entries` 明细一笔一行，
  每日任务带 `task_date`，`(user_id, reason, task_date)` 部分唯一索引防并发重复发放
- 加减只走 `Account.credit!`（条件 UPDATE，扣成负数时返回 false），和写明细放在同一个事务里
- 商品 `kuu_points_items`（frame / accessory，图片是 upload）、拥有 `kuu_points_user_items`（唯一索引防重复兑换）、
  佩戴记在账户的 `frame_item_id` / `accessory_item_id`。下架的商品已拥有的人照样能戴
- 装饰图片规格写在 README（300×300 透明 PNG，头像占中间直径 200）。前端叠加层是头像的 1.5 倍、同一个中心
- 帖子页的等级和装饰用 `topic_view.kuu_points_decorations` 一次查出；用户卡片、个人主页用 `user_card` 序列化器
- 鲸币商城页 `/kuu-shop`（`.json` 是页面数据）。侧边栏「话题」下面的入口由主题组件加，插件只加头像菜单「个人资料」栏的入口
- 测试商品：`bin/rake kuu_points:demo_items`（图片由 `script/make_demo_items.sh` 生成）

## 开发环境（共用开发容器，先读 `~/.claude/CLAUDE.md`）
- 本仓库位于 WSL 的 `~/discourse/plugins/discourse-kuu-points`，Discourse 源码在 `~/discourse`（官方仓库，不要改）
- 容器 `discourse_dev` 和开发服务器是好几个会话共用的：**只启动、不停止、不重启**；不 kill 别人的进程
- 测试：在插件目录执行 `kuu-rspec spec/xxx_spec.rb`（测试库 `discourse_test_8`）。加了迁移先跑 `kuu-rspec --migrate`。
  本地只跑相关文件，整套交给 GitHub CI
- 开发库迁移：`docker exec -u discourse -w /src discourse_dev bin/rake db:migrate`
- 系统测试、Playwright 截图、重启开发服务器要排队：`flock ~/discourse/tmp/kuu-heavy.lock <命令>`；先看 `free -m`
- 截图放 `screenshots/`，临时文件放 `~/discourse/tmp/discourse-kuu-points/`
- 截图不用开发库：系统测试里调用 `screenshot("名字")`，带 `KUU_SCREENSHOTS=1` 跑时存到 `screenshots/`（kuu-rspec 不传这个变量，
  照 kuu-rspec 的写法直接 `docker exec ... -e KUU_SCREENSHOTS=1 ... flock /src/tmp/kuu-heavy.lock bin/rspec plugins/discourse-kuu-points/spec/system/xxx_spec.rb`）
- 新加的插件（或改了 `plugin.rb`）要重启开发服务器才会加载。2026-10-22 见过开发服务器的主进程不在、只剩孤儿 pitchfork worker 的情况，
  那时只能整个重启（排队锁里，回复里说明）
- lint 在容器里跑：`docker exec -u discourse -w /src discourse_dev bin/lint --fix plugins/discourse-kuu-points/<文件>`。
  rubocop 有 `corrected` 时再跑一遍；推送前照 CI 检查：
  `docker exec -u discourse -w /src/plugins/discourse-kuu-points discourse_dev bash -lc 'bundle exec stree check Gemfile $(git ls-files "*.rb")'`
- 改了数据库要更新模型注释（CI 的 annotations 检查）：
  `docker exec -u discourse:discourse -w /src -e RAILS_ENV=test -e TEST_ENV_NUMBER=8 -e LOAD_PLUGINS=1 discourse_dev bin/annotaterb models --force --model-dir plugins/discourse-kuu-points/app/models`
- `plugin.rb` 的 `required_version` 保持 `2026.1.0`，不要写当前版本号（原因见二手插件 CLAUDE.md）
- 共用开发库里为了测试改了站点设置、用户数据，测完改回来并在回复里写明。插件开关 `kuu_points_enabled` 默认关

## 约定
- 插件名 `discourse-kuu-points`，Ruby 模块 `DiscourseKuuPoints`，接口挂在 `/kuu-points`，站点设置以 `kuu_points_` 开头，表名以 `kuu_points_` 开头
- 代码标识符用英文；面向用户的文案放在 `config/locales/`（zh_CN 和 en 都要有）
- 跟着 Discourse 官方插件的写法走：业务逻辑用 `Service::Base`，前端用 Glimmer 组件（.gjs）和 plugin outlet，**不要改 core**
- 品牌色：藏青 `#0A2D56`、樱花粉 `#ED8690`、浅雾蓝 `#C0D1E4`、米白 `#FCF9F2`
- 每个功能都要写测试：后端 RSpec，前端交互用 system spec；用**普通用户**测，不要用管理员
- `main` 有保护（PR + 1 人批准 + CI）：开分支、走 PR，提交信息用中文。main 必须随时能上线
- 部署到线上（改 `app.yml`、rebuild）由 KUU 那边负责，必须先得到 David 同意；这是新插件，第一次上线要停机 rebuild
- 规则相关的改动先问 David；纯技术细节自己定，写进 Notion 方案
- 用中文交流
