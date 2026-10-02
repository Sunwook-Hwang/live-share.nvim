if vim.g.loaded_live_share then
	return
end
vim.g.loaded_live_share = true
require("live-share").setup()
