export default {
  resource: "admin.adminPlugins.show",

  map() {
    this.route("kuu-points-items", { path: "items" });
    this.route("kuu-points-adjust", { path: "adjust" });
  },
};
