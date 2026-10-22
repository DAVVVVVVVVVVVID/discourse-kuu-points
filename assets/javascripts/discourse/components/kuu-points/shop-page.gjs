import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import routeAction from "discourse/helpers/route-action";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import dBoundAvatar from "discourse/ui-kit/helpers/d-bound-avatar";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import AvatarDecorations from "./avatar-decorations.gjs";
import LevelBadge from "./level-badge.gjs";

const KINDS = ["frame", "accessory"];

// 鲸币商城（Issue #1 第 3 条）：概况、今日任务、商品、我的装饰、明细。
// 签到、兑换、佩戴后用接口返回的最新内容整页更新
export default class ShopPage extends Component {
  @service currentUser;
  @service dialog;

  @tracked summary = this.args.data?.summary;
  @tracked items = this.args.data?.items ?? [];
  @tracked entries = this.args.data?.entries.entries ?? [];
  @tracked hasMoreEntries = this.args.data?.entries.has_more;
  @tracked selectedKind = "frame";
  @tracked busy = false;

  #entriesPage = 0;

  get progress() {
    const {
      level,
      xp,
      level_xp: levelXp,
      next_level_xp: nextLevelXp,
    } = this.summary;
    if (!nextLevelXp) {
      return { full: true, max: 1, value: 1 };
    }

    return {
      full: false,
      max: nextLevelXp - levelXp,
      value: xp - levelXp,
      remaining: nextLevelXp - xp,
      nextLevel: level + 1,
    };
  }

  get tasks() {
    return this.summary.tasks.map((task) => ({
      ...task,
      label: i18n(`kuu_points.tasks.${task.task}`),
      reward: i18n("kuu_points.reward", { xp: task.xp, coins: task.coins }),
      isCheckin: task.task === "checkin",
    }));
  }

  get kindTabs() {
    return KINDS.map((kind) => ({
      kind,
      label: i18n(`kuu_points.kinds.${kind}`),
      isSelected: kind === this.selectedKind,
    }));
  }

  get shelf() {
    return this.items.filter(
      (item) => item.enabled && item.kind === this.selectedKind
    );
  }

  get owned() {
    return this.items.filter((item) => item.owned);
  }

  get myDecorations() {
    const equipped = (kind) =>
      this.items.find((item) => item.kind === kind && item.equipped)?.image_url;
    return {
      frame_url: equipped("frame"),
      accessory_url: equipped("accessory"),
    };
  }

  @action
  entryLabel(entry) {
    return i18n(`kuu_points.reasons.${entry.reason}`, {
      item: entry.item_name,
      note: entry.note,
    });
  }

  @action
  signed(amount) {
    return amount > 0 ? `+${amount}` : `${amount}`;
  }

  @action
  selectKind(kind) {
    this.selectedKind = kind;
  }

  @action
  async checkin() {
    await this.#update(async () => {
      const result = await ajax("/kuu-points/tasks/checkin.json", {
        type: "POST",
      });
      this.summary = result.summary;
      await this.#reloadEntries();
    });
  }

  @action
  redeem(item) {
    this.dialog.yesNoConfirm({
      message: i18n("kuu_points.shop.redeem_confirm", {
        name: item.name,
        price: item.price,
      }),
      didConfirm: () =>
        this.#update(() =>
          this.#apply(
            ajax(`/kuu-points/items/${item.id}/redeem.json`, { type: "POST" })
          )
        ),
    });
  }

  @action
  equip(item) {
    return this.#update(() =>
      this.#apply(
        ajax(`/kuu-points/items/${item.id}/equip.json`, { type: "PUT" })
      )
    );
  }

  @action
  unequip(item) {
    return this.#update(() =>
      this.#apply(
        ajax(`/kuu-points/items/${item.id}/equip.json`, { type: "DELETE" })
      )
    );
  }

  @action
  async loadMoreEntries() {
    await this.#update(async () => {
      const result = await ajax("/kuu-points/entries.json", {
        data: { page: this.#entriesPage + 1 },
      });
      this.#entriesPage += 1;
      this.entries = [...this.entries, ...result.entries];
      this.hasMoreEntries = result.has_more;
    });
  }

  async #apply(request) {
    const shop = await request;
    this.summary = shop.summary;
    this.items = shop.items;
    await this.#reloadEntries();
  }

  async #reloadEntries() {
    const result = await ajax("/kuu-points/entries.json");
    this.#entriesPage = 0;
    this.entries = result.entries;
    this.hasMoreEntries = result.has_more;
  }

  async #update(callback) {
    this.busy = true;
    try {
      await callback();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busy = false;
    }
  }

  <template>
    <div class="kuu-points-shop">
      <h1 class="kuu-points-shop__title">{{i18n "kuu_points.shop.title"}}</h1>

      {{#if @data}}
        <section class="kuu-points-shop__summary">
          <div class="kuu-points-shop__avatar">
            {{dBoundAvatar this.currentUser "huge"}}
            <AvatarDecorations @decorations={{this.myDecorations}} />
          </div>
          <div class="kuu-points-shop__stats">
            <div class="kuu-points-shop__level">
              <LevelBadge @level={{this.summary.level}} />
              <span class="kuu-points-shop__xp">
                {{i18n "kuu_points.shop.xp" amount=this.summary.xp}}
              </span>
            </div>
            <progress
              class="kuu-points-shop__progress"
              max={{this.progress.max}}
              value={{this.progress.value}}
            ></progress>
            <p class="kuu-points-shop__progress-text">
              {{#if this.progress.full}}
                {{i18n "kuu_points.shop.max_level"}}
              {{else}}
                {{i18n
                  "kuu_points.shop.to_next_level"
                  amount=this.progress.remaining
                  level=this.progress.nextLevel
                }}
              {{/if}}
            </p>
            <p class="kuu-points-shop__coins">
              {{dIcon "coins"}}
              {{i18n "kuu_points.shop.coins" amount=this.summary.coins}}
            </p>
          </div>
        </section>

        <section class="kuu-points-shop__section kuu-points-shop__tasks">
          <h2>{{i18n "kuu_points.shop.tasks_title"}}</h2>
          <ul class="kuu-points-shop__task-list">
            {{#each this.tasks as |task|}}
              <li
                class="kuu-points-shop__task
                  {{if task.done 'kuu-points-shop__task--done'}}"
                data-task={{task.task}}
              >
                <span class="kuu-points-shop__task-check">
                  {{dIcon (if task.done "circle-check" "far-circle")}}
                </span>
                <span class="kuu-points-shop__task-label">{{task.label}}</span>
                <span
                  class="kuu-points-shop__task-reward"
                >{{task.reward}}</span>
                {{#if task.isCheckin}}
                  {{#if task.done}}
                    <span class="kuu-points-shop__checked-in">
                      {{i18n "kuu_points.shop.checked_in"}}
                    </span>
                  {{else}}
                    <DButton
                      class="btn-primary btn-small kuu-points-shop__checkin"
                      @action={{this.checkin}}
                      @disabled={{this.busy}}
                      @label="kuu_points.shop.checkin"
                    />
                  {{/if}}
                {{/if}}
              </li>
            {{/each}}
          </ul>
        </section>

        <section class="kuu-points-shop__section kuu-points-shop__items">
          <h2>{{i18n "kuu_points.shop.items_title"}}</h2>
          <div class="kuu-points-shop__tabs" role="tablist">
            {{#each this.kindTabs as |tab|}}
              <DButton
                aria-selected={{if tab.isSelected "true" "false"}}
                class="btn-flat kuu-points-shop__tab
                  {{if tab.isSelected 'kuu-points-shop__tab--selected'}}"
                role="tab"
                @action={{fn this.selectKind tab.kind}}
                @translatedLabel={{tab.label}}
              />
            {{/each}}
          </div>
          {{#if this.shelf.length}}
            <ul class="kuu-points-shop__grid">
              {{#each this.shelf as |item|}}
                <li class="kuu-points-shop__item" data-item-id={{item.id}}>
                  <img
                    alt={{item.name}}
                    class="kuu-points-shop__item-image"
                    src={{item.image_url}}
                  />
                  <span class="kuu-points-shop__item-name">{{item.name}}</span>
                  <span class="kuu-points-shop__item-price">
                    {{dIcon "coins"}}
                    {{item.price}}
                  </span>
                  {{#if item.equipped}}
                    <span class="kuu-points-shop__item-state">
                      {{i18n "kuu_points.shop.equipped"}}
                    </span>
                  {{else if item.owned}}
                    <span class="kuu-points-shop__item-state">
                      {{i18n "kuu_points.shop.owned"}}
                    </span>
                  {{else}}
                    <DButton
                      class="btn-primary btn-small kuu-points-shop__redeem"
                      @action={{fn this.redeem item}}
                      @disabled={{this.busy}}
                      @label="kuu_points.shop.redeem"
                    />
                  {{/if}}
                </li>
              {{/each}}
            </ul>
          {{else}}
            <p class="kuu-points-shop__empty">{{i18n
                "kuu_points.shop.no_items"
              }}</p>
          {{/if}}
        </section>

        <section class="kuu-points-shop__section kuu-points-shop__mine">
          <h2>{{i18n "kuu_points.shop.mine_title"}}</h2>
          <p class="kuu-points-shop__hint">{{i18n
              "kuu_points.shop.mine_hint"
            }}</p>
          {{#if this.owned.length}}
            <ul class="kuu-points-shop__grid">
              {{#each this.owned as |item|}}
                <li
                  class="kuu-points-shop__item
                    {{if item.equipped 'kuu-points-shop__item--equipped'}}"
                  data-item-id={{item.id}}
                >
                  <img
                    alt={{item.name}}
                    class="kuu-points-shop__item-image"
                    src={{item.image_url}}
                  />
                  <span class="kuu-points-shop__item-name">{{item.name}}</span>
                  {{#if item.equipped}}
                    <DButton
                      class="btn-default btn-small kuu-points-shop__unequip"
                      @action={{fn this.unequip item}}
                      @disabled={{this.busy}}
                      @label="kuu_points.shop.unequip"
                    />
                  {{else}}
                    <DButton
                      class="btn-primary btn-small kuu-points-shop__equip"
                      @action={{fn this.equip item}}
                      @disabled={{this.busy}}
                      @label="kuu_points.shop.equip"
                    />
                  {{/if}}
                </li>
              {{/each}}
            </ul>
          {{else}}
            <p class="kuu-points-shop__empty">{{i18n
                "kuu_points.shop.no_owned"
              }}</p>
          {{/if}}
        </section>

        <section class="kuu-points-shop__section kuu-points-shop__entries">
          <h2>{{i18n "kuu_points.shop.entries_title"}}</h2>
          {{#if this.entries.length}}
            <ul class="kuu-points-shop__entry-list">
              {{#each this.entries key="id" as |entry|}}
                <li class="kuu-points-shop__entry">
                  <span class="kuu-points-shop__entry-date">
                    {{dFormatDate entry.created_at format="medium"}}
                  </span>
                  <span class="kuu-points-shop__entry-reason">
                    {{this.entryLabel entry}}
                  </span>
                  <span class="kuu-points-shop__entry-amounts">
                    {{#if entry.xp}}
                      <span class="kuu-points-shop__entry-xp">
                        {{i18n
                          "kuu_points.shop.entry_xp"
                          amount=(this.signed entry.xp)
                        }}
                      </span>
                    {{/if}}
                    {{#if entry.coins}}
                      <span class="kuu-points-shop__entry-coins">
                        {{i18n
                          "kuu_points.shop.entry_coins"
                          amount=(this.signed entry.coins)
                        }}
                      </span>
                    {{/if}}
                  </span>
                </li>
              {{/each}}
            </ul>
            {{#if this.hasMoreEntries}}
              <DButton
                class="btn-default kuu-points-shop__more-entries"
                @action={{this.loadMoreEntries}}
                @disabled={{this.busy}}
                @label="kuu_points.shop.more_entries"
              />
            {{/if}}
          {{else}}
            <p class="kuu-points-shop__empty">{{i18n
                "kuu_points.shop.no_entries"
              }}</p>
          {{/if}}
        </section>
      {{else}}
        <section class="kuu-points-shop__section kuu-points-shop__login">
          <p>{{i18n "kuu_points.shop.login_hint"}}</p>
          <DButton
            class="btn-primary"
            @action={{routeAction "showLogin"}}
            @label="log_in"
          />
        </section>
      {{/if}}
    </div>
  </template>
}
