import { i18n } from "discourse-i18n";

// 用户名旁的「Lv3」小标签。和 core 的信任等级无关
const LevelBadge = <template>
  {{#if @level}}
    <span
      class="kuu-points-level kuu-points-level--{{@level}}"
      title={{i18n "kuu_points.level.title" level=@level}}
    >{{i18n "kuu_points.level.short" level=@level}}</span>
  {{/if}}
</template>;

export default LevelBadge;
