if vim.g.loaded_collab then
	return
end
vim.g.loaded_collab = true
require("collab").setup()
