import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowKuuPointsItemsRoute extends DiscourseRoute {
  model() {
    return ajax("/kuu-points/admin/items.json");
  }
}
