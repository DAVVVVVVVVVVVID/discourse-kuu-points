import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/ui-kit/d-button";
import DEmptyState from "discourse/ui-kit/d-empty-state";
import { i18n } from "discourse-i18n";
import ItemForm from "./modal/item-form.gjs";

// 后台「商品」：全部商品（包括下架的），新增、编辑、上下架
export default class AdminItems extends Component {
  @service modal;
  @service router;

  @action
  kindLabel(item) {
    return i18n(`kuu_points.kinds.${item.kind}`);
  }

  @action
  edit(item) {
    this.modal.show(ItemForm, {
      model: { item, onSaved: () => this.router.refresh() },
    });
  }

  <template>
    <div class="kuu-points-admin">
      <div class="kuu-points-admin__actions">
        <DButton
          class="btn-primary kuu-points-admin__new-item"
          @action={{fn this.edit null}}
          @icon="plus"
          @label="kuu_points.admin.new_item"
        />
        <p class="kuu-points-admin__hint">{{i18n
            "kuu_points.admin.image_hint"
          }}</p>
        <p class="kuu-points-admin__hint">{{i18n
            "kuu_points.admin.enabled_hint"
          }}</p>
      </div>

      {{#if @items.length}}
        <table class="d-table kuu-points-admin__items">
          <thead class="d-table__header">
            <tr class="d-table__row">
              <th class="d-table__header-cell">{{i18n
                  "kuu_points.admin.columns.item"
                }}</th>
              <th class="d-table__header-cell">{{i18n
                  "kuu_points.admin.columns.kind"
                }}</th>
              <th class="d-table__header-cell">{{i18n
                  "kuu_points.admin.columns.price"
                }}</th>
              <th class="d-table__header-cell">{{i18n
                  "kuu_points.admin.columns.position"
                }}</th>
              <th class="d-table__header-cell">{{i18n
                  "kuu_points.admin.columns.status"
                }}</th>
              <th class="d-table__header-cell">{{i18n
                  "kuu_points.admin.columns.owners"
                }}</th>
              <th class="d-table__header-cell"></th>
            </tr>
          </thead>
          <tbody class="d-table__body">
            {{#each @items key="id" as |item|}}
              <tr
                class="d-table__row kuu-points-admin__item
                  {{unless item.enabled 'kuu-points-admin__item--disabled'}}"
                data-item-id={{item.id}}
              >
                <td class="d-table__cell --overview">
                  <div class="kuu-points-admin__item-overview">
                    <img
                      alt=""
                      class="kuu-points-admin__item-image"
                      src={{item.image_url}}
                    />
                    <span
                      class="kuu-points-admin__item-name"
                    >{{item.name}}</span>
                  </div>
                </td>
                <td class="d-table__cell --detail">{{this.kindLabel item}}</td>
                <td class="d-table__cell --detail">{{item.price}}</td>
                <td class="d-table__cell --detail">{{item.position}}</td>
                <td class="d-table__cell --detail kuu-points-admin__status">
                  {{if
                    item.enabled
                    (i18n "kuu_points.admin.on_sale")
                    (i18n "kuu_points.admin.off_sale")
                  }}
                </td>
                <td class="d-table__cell --detail">{{item.owners_count}}</td>
                <td class="d-table__cell --controls">
                  <DButton
                    class="btn-default btn-small kuu-points-admin__edit"
                    @action={{fn this.edit item}}
                    @label="kuu_points.admin.edit"
                  />
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      {{else}}
        <DEmptyState
          @body={{i18n "kuu_points.admin.no_items_hint"}}
          @title={{i18n "kuu_points.admin.no_items"}}
        />
      {{/if}}
    </div>
  </template>
}
