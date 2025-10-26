return {
  "brenoprata10/nvim-highlight-colors",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    --- Show TailwindCSS color previews in className="..."
    enable_tailwind = true,

    --- Use colored backgrounds (you can change to "virtual" or "foreground")
    render = "background",

    --- You can tune which color formats are detected
    --- (all are enabled by default)
    enable_hex = true,
    enable_rgb = true,
    enable_hsl = true,
    enable_var_usage = true,
    enable_named_colors = true,
  },
}
