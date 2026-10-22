import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

// 鲸币商城（Issue #1 第 3 条）。未登录时页面只提示登录
export default class KuuShopRoute extends DiscourseRoute {
  @service currentUser;

  async model() {
    if (!this.currentUser) {
      return null;
    }

    const [shop, entries] = await Promise.all([
      ajax("/kuu-shop.json"),
      ajax("/kuu-points/entries.json"),
    ]);
    return { ...shop, entries };
  }

  titleToken() {
    return i18n("kuu_points.shop.title");
  }
}
