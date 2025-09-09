-- Basic editor settings
vim.cmd("set expandtab")

vim.cmd("set tabstop=2")

vim.cmd("set softtabstop=2")

vim.cmd("set shiftwidth=2")

vim.api.nvim_set_keymap('i', 'jj', '<Esc>', { noremap = true, silent = true })

vim.opt.number = true

vim.g.mapleader = " "

-- Switch between neovim panes

vim.keymap.set('n', '<c-k>', ':wincmd k<CR>')
vim.keymap.set('n', '<c-j>', ':wincmd j<CR>')
vim.keymap.set('n', '<c-h>', ':wincmd h<CR>')
vim.keymap.set('n', '<c-l>', ':wincmd l<CR>')
