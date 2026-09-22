require("nvchad.configs.lspconfig").defaults()

local servers = {
  "html",
  "cssls",
  "pyright", -- python
  "rust_analyzer", -- rust
  "gopls", -- go
  "csharp_ls", -- c#
  "ts_ls", -- js/ts
  "clangd", -- c/c++
  "jdtls", -- java
}
vim.lsp.enable(servers)

-- yuck has no LSP server; completion comes from treesitter/buffer sources
-- read :h vim.lsp.config for changing options of lsp servers