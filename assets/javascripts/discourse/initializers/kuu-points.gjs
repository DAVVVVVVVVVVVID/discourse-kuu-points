import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";
import AvatarDecorations from "../components/kuu-points/avatar-decorations.gjs";
import LevelBadge from "../components/kuu-points/level-badge.gjs";

export default {
  name: "kuu-points",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.kuu_points_enabled) {
      return;
    }

    withPluginApi((api) => {
      // 帖子：头像上的装饰、用户名旁的等级
      api.renderBeforeWrapperOutlet(
        "post-avatar-flair",
        <template>
          <AvatarDecorations @decorations={{@outletArgs.post.kuu_points}} />
        </template>
      );
      api.renderAfterWrapperOutlet(
        "post-meta-data-poster-name",
        <template>
          <LevelBadge @level={{@outletArgs.post.kuu_points.level}} />
        </template>
      );

      // 用户卡片
      api.renderInOutlet(
        "user-card-avatar-flair",
        <template>
          <AvatarDecorations @decorations={{@outletArgs.user.kuu_points}} />
        </template>
      );
      api.renderInOutlet(
        "user-card-after-username",
        <template>
          <LevelBadge @level={{@outletArgs.user.kuu_points.level}} />
        </template>
      );

      // 个人主页
      api.renderInOutlet(
        "user-profile-avatar-flair",
        <template>
          <AvatarDecorations @decorations={{@outletArgs.model.kuu_points}} />
        </template>
      );
      api.renderInOutlet(
        "user-post-names",
        <template>
          <LevelBadge @level={{@outletArgs.model.kuu_points.level}} />
        </template>
      );

      // 点头像后菜单里「个人资料」那一栏。侧边栏「话题」下面的入口由主题组件加
      if (api.getCurrentUser()) {
        api.addQuickAccessProfileItem({
          icon: "coins",
          href: "/kuu-shop",
          content: i18n("kuu_points.shop.title"),
          className: "kuu-points-shop-link",
        });
      }
    });
  },
};
