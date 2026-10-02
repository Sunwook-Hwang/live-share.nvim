if vim.g.loaded_collabo then
	return
end
vim.g.loaded_collabo = true
require("collabo").setup()
