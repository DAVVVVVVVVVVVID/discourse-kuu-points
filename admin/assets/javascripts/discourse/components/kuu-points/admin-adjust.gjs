import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import Form from "discourse/form-kit/components/fk/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DUserLink from "discourse/ui-kit/d-user-link";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import { i18n } from "discourse-i18n";

// 后台「调整」：先找到用户、看现在的经验 / 鲸币和最近明细，再加减。原因必填，用户在明细里能看到
export default class AdminAdjust extends Component {
  @tracked account;

  adjustData = { xp: 0, coins: 0, note: "" };
  #adjustForm;

  @action
  async lookUp(data) {
    try {
      this.account = await ajax(
        `/kuu-points/admin/accounts/${encodeURIComponent(data.username.trim())}.json`
      );
    } catch (error) {
      this.account = null;
      popupAjaxError(error);
    }
  }

  @action
  registerAdjustForm(api) {
    this.#adjustForm = api;
  }

  @action
  async adjust(data) {
    try {
      this.account = await ajax(
        `/kuu-points/admin/accounts/${encodeURIComponent(this.account.user.username)}/adjust.json`,
        {
          type: "POST",
          data: { xp: data.xp, coins: data.coins, note: data.note },
        }
      );
      await this.#adjustForm.reset();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  validateChange(data, { addError }) {
    if (!Number(data.xp) && !Number(data.coins)) {
      addError("xp", {
        title: i18n("kuu_points.admin.fields.xp"),
        message: i18n("kuu_points.admin.nothing_to_change"),
      });
    }
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

  <template>
    <div class="kuu-points-admin kuu-points-admin-adjust">
      <Form @onSubmit={{this.lookUp}} as |form|>
        <form.Field
          @name="username"
          @title={{i18n "kuu_points.admin.fields.username"}}
          @type="input"
          @validation="required"
          as |field|
        >
          <field.Control />
        </form.Field>
        <form.Submit @label="kuu_points.admin.look_up" />
      </Form>

      {{#if this.account}}
        <section class="kuu-points-admin-adjust__account">
          <h2 class="kuu-points-admin-adjust__user">
            <DUserLink @username={{this.account.user.username}}>
              {{dAvatar this.account.user imageSize="medium"}}
              {{this.account.user.username}}
            </DUserLink>
          </h2>
          <p class="kuu-points-admin-adjust__summary">
            {{i18n
              "kuu_points.admin.current"
              level=this.account.summary.level
              xp=this.account.summary.xp
              coins=this.account.summary.coins
            }}
          </p>

          <Form
            @data={{this.adjustData}}
            @onRegisterApi={{this.registerAdjustForm}}
            @onSubmit={{this.adjust}}
            @validate={{this.validateChange}}
            as |form|
          >
            <form.Row as |row|>
              <row.Col @size={{6}}>
                <form.Field
                  @name="xp"
                  @title={{i18n "kuu_points.admin.fields.xp"}}
                  @type="input-number"
                  @validation="integer"
                  as |field|
                >
                  <field.Control />
                </form.Field>
              </row.Col>
              <row.Col @size={{6}}>
                <form.Field
                  @name="coins"
                  @title={{i18n "kuu_points.admin.fields.coins"}}
                  @type="input-number"
                  @validation="integer"
                  as |field|
                >
                  <field.Control />
                </form.Field>
              </row.Col>
            </form.Row>
            <form.Field
              @description={{i18n "kuu_points.admin.note_hint"}}
              @format="full"
              @name="note"
              @title={{i18n "kuu_points.admin.fields.note"}}
              @type="input"
              @validation="required|length:1,500"
              as |field|
            >
              <field.Control />
            </form.Field>
            <form.Submit @label="kuu_points.admin.adjust" />
          </Form>

          <h3>{{i18n "kuu_points.admin.recent_entries"}}</h3>
          <ul class="kuu-points-admin-adjust__entries">
            {{#each this.account.entries key="id" as |entry|}}
              <li class="kuu-points-admin-adjust__entry">
                <span class="kuu-points-admin-adjust__entry-date">
                  {{dFormatDate entry.created_at format="medium"}}
                </span>
                <span>{{this.entryLabel entry}}</span>
                {{#if entry.acting_username}}
                  <span class="kuu-points-admin-adjust__entry-admin">
                    {{i18n
                      "kuu_points.admin.by"
                      username=entry.acting_username
                    }}
                  </span>
                {{/if}}
                <span class="kuu-points-admin-adjust__entry-amounts">
                  {{#if entry.xp}}
                    {{i18n
                      "kuu_points.shop.entry_xp"
                      amount=(this.signed entry.xp)
                    }}
                  {{/if}}
                  {{#if entry.coins}}
                    {{i18n
                      "kuu_points.shop.entry_coins"
                      amount=(this.signed entry.coins)
                    }}
                  {{/if}}
                </span>
              </li>
            {{else}}
              <li>{{i18n "kuu_points.shop.no_entries"}}</li>
            {{/each}}
          </ul>
        </section>
      {{/if}}
    </div>
  </template>
}
