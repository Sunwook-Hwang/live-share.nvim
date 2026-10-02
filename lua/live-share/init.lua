-- Transport and edit algorithms load only when starting/joining a session.
local M = { config = { discovery = true, max_peers = 8 } }
local actions = { LiveShare = "start", LiveShareJoin = "join", LiveShareStop = "stop", LiveShareStatus = "status" }
for _, action in pairs(actions) do
	M[action] = function(args)
		return require("live-share.core")[action](args or {})
	end
end
function M.setup(opts)
	if vim.fn.has("nvim-0.12") == 0 then
		error("live-share.nvim requires Neovim 0.12 or newer")
	end
	opts = opts or {}
	local config = vim.tbl_extend("force", M.config, opts)
	vim.validate("discovery", config.discovery, "boolean")
	vim.validate("max_peers", config.max_peers, "number")
	assert(
		config.max_peers >= 2 and config.max_peers <= 64 and config.max_peers == math.floor(config.max_peers),
		"max_peers must be an integer between 2 and 64"
	)
	M.config = config
	for command, action in pairs(actions) do
		vim.api.nvim_create_user_command(command, function(args)
			local ok, err = pcall(M[action], args.fargs)
			if not ok then
				vim.notify(tostring(err), vim.log.levels.ERROR)
			end
		end, { nargs = "*", force = true, desc = "Live buffer sharing: " .. action })
	end
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = vim.api.nvim_create_augroup("live-share-discovery", { clear = true }),
		callback = function(args)
			local path = vim.api.nvim_buf_get_name(args.buf)
			if not M.config.discovery or vim.bo[args.buf].buftype ~= "" or path == "" then
				return
			end
			local sidecar = vim.fs.joinpath(vim.fs.dirname(path), "." .. vim.fs.basename(path) .. ".flash-share")
			if not vim.uv.fs_lstat(sidecar) then
				return
			end
			vim.schedule(function()
				if vim.api.nvim_get_current_buf() ~= args.buf or not require("live-share.buffer").is_editor(0) then
					return
				end
				local ok, err = pcall(require("live-share.core").discover, args.buf, true)
				if not ok then
					vim.notify(tostring(err), vim.log.levels.ERROR)
				end
			end)
		end,
	})
end
return M
