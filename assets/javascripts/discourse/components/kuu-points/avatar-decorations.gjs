// 叠在头像上的头像框和饰品：方形透明 PNG，比头像大一圈、和头像同一个中心（规格见 README）。
// 外层元素要是 position: relative，大小和头像一样
const AvatarDecorations = <template>
  {{#if @decorations.frame_url}}
    <img
      alt=""
      aria-hidden="true"
      class="kuu-points-decoration kuu-points-decoration--frame"
      src={{@decorations.frame_url}}
    />
  {{/if}}
  {{#if @decorations.accessory_url}}
    <img
      alt=""
      aria-hidden="true"
      class="kuu-points-decoration kuu-points-decoration--accessory"
      src={{@decorations.accessory_url}}
    />
  {{/if}}
</template>;

export default AvatarDecorations;
