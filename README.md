# discourse-kuu-points

京大中文论坛（KUU）的经验值和鲸币插件。

- **等级**：1–5 级，每 200 经验升一级，5 级封顶
- **每日任务**（日本时间 0 点分界）：签到、第一个新话题、第一次回复、第一次给别人点赞、第一次转发，每项每天奖励一次
- **鲸币商城**：用鲸币兑换头像框、饰品（开发中）
- **头像装饰**：帖子、用户卡片、个人主页（开发中）

站点设置 `kuu_points_enabled` 默认关闭。

## 接口

- `GET /kuu-points/summary.json`：自己的等级、经验、鲸币和今日任务
- `POST /kuu-points/tasks/checkin.json`：签到
- `POST /kuu-points/tasks/share.json`：转发（主题的分享菜单在复制链接、保存 / 复制分享图成功后调用）。
  需要登录；每天只奖励一次，重复调用也返回 200，`rewarded` 是 `false`

## 许可证

MIT
