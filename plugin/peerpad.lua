if vim.g.loaded_peerpad then
	return
end
vim.g.loaded_peerpad = true
require("peerpad").setup()
