local Input = require("nui.input")
local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

local function get_interface_name()
	local node = ts_utils.get_node_at_cursor()
	while node do
		if node:type() == "type_spec" then
			for child in node:iter_children() do
				if child:type() == "interface_type" then
					for grandchild in node:iter_children() do
						if grandchild:type() == "type_identifier" then
							return vim.treesitter.get_node_text(grandchild, 0)
						end
					end
				end
			end
		end
		node = node:parent()
	end
	return nil
end

local function get_go_module_name()
	local go_mod_path = vim.fs.find("go.mod", { upward = true, path = vim.fn.expand("%:p:h") })[1]
	if not go_mod_path then
		return nil, nil
	end

	local file = io.open(go_mod_path, "r")
	if not file then
		return nil, nil
	end

	local first_line = file:read()
	file:close()

	local mod_name = first_line:match("^module%s+(.+)")
	return mod_name, vim.fn.fnamemodify(go_mod_path, ":h")
end

local function to_snake_case(str)
	return str:gsub("%u", function(c)
		return "_" .. c:lower()
	end):gsub("^_", "")
end

M.generate_mock = function()
	if vim.bo.filetype ~= "go" then
		return
	end
	vim.cmd("write")

	local iface_name = get_interface_name()
	if not iface_name then
		vim.notify("Minimock: Курсор не на интерфейсе", vim.log.levels.WARN)
		return
	end

	local mod_name, mod_root = get_go_module_name()
	if not mod_name then
		vim.notify("Minimock: Не найден go.mod", vim.log.levels.ERROR)
		return
	end

	local current_dir = vim.fn.expand("%:p:h")

	-- current_dir: .../internal/app/ports
	-- mod_root:    .../
	-- relative_pkg_path become: internal/app/ports
	local relative_pkg_path = current_dir:sub(#mod_root + 2)

	local full_import_path = string.format("%s/%s.%s", mod_name, relative_pkg_path, iface_name)

	local output_file = to_snake_case(iface_name) .. "_mock.go"
	local default_output_path

	if relative_pkg_path and relative_pkg_path ~= "" then
		default_output_path = string.format("%s/mocks/%s", relative_pkg_path, output_file)
	else
		default_output_path = string.format("mocks/%s", output_file)
	end

	local struct_name = iface_name .. "Mock"

	-- UI
	local input = Input({
		position = "50%",
		size = { width = 90 },
		border = {
			style = "rounded",
			text = {
				top = " Minimock Output Path ",
				top_align = "center",
			},
		},
	}, {
		prompt = "Path: ",
		default_value = default_output_path,
		on_submit = function(output_path)
			local output_dir_actual = vim.fn.fnamemodify(output_path, ":h")
			local pkg_name = vim.fn.fnamemodify(output_dir_actual, ":t")
			if pkg_name == "." then
				pkg_name = "main"
			end

			local cmd = {
				"minimock",
				"-i",
				full_import_path,
				"-o",
				output_path,
				"-n",
				struct_name,
				"-p",
				pkg_name,
			}

			vim.notify(string.format("Генерация для %s...", full_import_path), vim.log.levels.INFO)

			vim.fn.jobstart(cmd, {
				stdout_buffered = true,
				stderr_buffered = true,
				on_stderr = function(_, data)
					if data and #data > 1 then
						local msg = table.concat(data, "\n")
						if #msg > 0 then
							vim.notify("Minimock Error:\n" .. msg, vim.log.levels.ERROR)
						end
					end
				end,
				on_exit = function(_, code)
					if code == 0 then
						vim.notify("✅ Mock создан: " .. output_path, vim.log.levels.INFO)
					end
				end,
			})
		end,
	})

	input:mount()
	input:map("n", "<Esc>", function()
		input:unmount()
	end, { noremap = true })
	input:map("i", "<C-c>", function()
		input:unmount()
	end, { noremap = true })
end

return M
