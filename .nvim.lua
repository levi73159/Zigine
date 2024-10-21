local dap = require("dap")
dap.adapters.lldb = {
	type = "executable",
	command = "/bin/lldb-dap", -- adjust as needed, must be absolute path
	name = "lldb",
}

dap.configurations.zig = {
	{
		name = "Launch",
		type = "lldb",
		request = "launch",
		program = "${workspaceFolder}/zig-out/bin/sandbox",
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		preRunCommands = {
			"command script import --allow-reload ~/zig/lldb-pretty/lldb_pretty_printers.py",
			"type category enable zig.lang",
			"type category enable zig.std",
			"type category enable zig.stage2",
			"platform shell zig build",
		},
		args = {},
	},
}
