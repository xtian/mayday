const defaultTheme = require("tailwindcss/defaultTheme");
const plugin = require("tailwindcss/plugin");

const plugins = ["phx-change-loading", "phx-click-loading", "phx-submit-loading", "phx-no-feedback"]
  .map((variant) =>
    plugin(({ addVariant }) => addVariant(variant, [`&.${variant}`, `.${variant} &`]))
  )
  .concat([require("@tailwindcss/forms")]);

module.exports = {
  content: ["../lib/mayday_web/**/*ex"],
  theme: {
    fontFamily: {
      sans: ["Open Sans", ...defaultTheme.fontFamily.sans],
    },
  },
  variants: {},
  plugins,
};
