-- Leader früh setzen
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- netrw deaktivieren (empfohlen für nvim-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- schöne Farben für Icons etc.
vim.opt.termguicolors = true

-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
})

-- nvim-tree Setup
require("nvim-tree").setup({
  hijack_netrw = true,
  sync_root_with_cwd = true,
  view = { width = 32, side = "left" },
  renderer = {
    group_empty = true,
    highlight_git = true,
    indent_markers = { enable = true },
  },
  filters = { dotfiles = false },
  actions = { open_file = { quit_on_open = false } },
})

-- Praktische Mappings
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true, desc = "Toggle file tree" })
vim.keymap.set("n", "<leader>f", ":NvimTreeFindFile<CR>", { silent = true, desc = "Reveal current file" })

-- Optional: Wenn nvim-tree das letzte Fenster ist, schließe Neovim
vim.api.nvim_create_autocmd("BufEnter", {
  nested = true,
  callback = function()
    if #vim.api.nvim_list_wins() == 1 and vim.bo.filetype == "NvimTree" then
      vim.cmd("quit")
    end
  end,
})
