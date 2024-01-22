local M = {}

M.is_git_directory = function()
	local result = vim.fn.system("git rev-parse --is-inside-work-tree")
	if vim.v.shell_error == 0 and result:find("true") then
		return true
	else
		return false
	end
end

return M
