import Component from "@glimmer/component";
import { action } from "@ember/object";
import Form from "discourse/form-kit/components/fk/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

// 新增 / 编辑商品。类型建好后不能改（有人正戴着时会对不上）
export default class ItemForm extends Component {
  get item() {
    return this.args.model.item;
  }

  get formData() {
    const item = this.item;
    return {
      name: item?.name ?? "",
      kind: item?.kind ?? "frame",
      image: item?.image_url,
      upload_id: item?.upload_id,
      price: item?.price ?? 50,
      position: item?.position ?? 0,
      enabled: item?.enabled ?? true,
    };
  }

  @action
  setImage(upload, { set }) {
    set("image", upload?.url);
    set("upload_id", upload?.id);
  }

  @action
  async save(data) {
    try {
      await ajax(
        this.item
          ? `/kuu-points/admin/items/${this.item.id}.json`
          : "/kuu-points/admin/items.json",
        {
          type: this.item ? "PUT" : "POST",
          data: {
            name: data.name,
            kind: data.kind,
            upload_id: data.upload_id,
            price: data.price,
            position: data.position,
            enabled: data.enabled,
          },
        }
      );
      this.args.model.onSaved();
      this.args.closeModal();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <DModal
      class="kuu-points-item-form"
      @closeModal={{@closeModal}}
      @title={{if
        this.item
        (i18n "kuu_points.admin.edit_item")
        (i18n "kuu_points.admin.new_item")
      }}
    >
      <:body>
        <Form @data={{this.formData}} @onSubmit={{this.save}} as |form|>
          <form.Field
            @format="large"
            @name="name"
            @title={{i18n "kuu_points.admin.fields.name"}}
            @type="input"
            @validation="required|length:1,50"
            as |field|
          >
            <field.Control />
          </form.Field>

          <form.Field
            @disabled={{if this.item true false}}
            @name="kind"
            @title={{i18n "kuu_points.admin.fields.kind"}}
            @type="radio-group"
            @validation="required"
            as |field|
          >
            <field.Control as |radioGroup|>
              <radioGroup.Radio @value="frame">{{i18n
                  "kuu_points.kinds.frame"
                }}</radioGroup.Radio>
              <radioGroup.Radio @value="accessory">{{i18n
                  "kuu_points.kinds.accessory"
                }}</radioGroup.Radio>
            </field.Control>
          </form.Field>

          <form.Field
            @description={{i18n "kuu_points.admin.image_hint"}}
            @name="image"
            @onSet={{this.setImage}}
            @title={{i18n "kuu_points.admin.fields.image"}}
            @type="image"
            @validation="required"
            as |field|
          >
            <field.Control @type="kuu_points_item" />
          </form.Field>

          <form.Row as |row|>
            <row.Col @size={{6}}>
              <form.Field
                @name="price"
                @title={{i18n "kuu_points.admin.fields.price"}}
                @type="input-number"
                @validation="required|integer|number:0,100000"
                as |field|
              >
                <field.Control />
              </form.Field>
            </row.Col>
            <row.Col @size={{6}}>
              <form.Field
                @description={{i18n "kuu_points.admin.position_hint"}}
                @name="position"
                @title={{i18n "kuu_points.admin.fields.position"}}
                @type="input-number"
                @validation="required|integer"
                as |field|
              >
                <field.Control />
              </form.Field>
            </row.Col>
          </form.Row>

          <form.Field
            @name="enabled"
            @title={{i18n "kuu_points.admin.fields.enabled"}}
            @type="toggle"
            as |field|
          >
            <field.Control />
          </form.Field>

          <form.Submit @label="kuu_points.admin.save" />
        </Form>
      </:body>
    </DModal>
  </template>
}
