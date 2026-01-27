-- Template function to insert text into new files
---@param pattern string Pattern to match filenames
---@param text string Template text to insert
---@param pos table {row, col} Cursor position after inserting text
local function createTemplate(pattern, text, pos, ignored)
	-- Create an autocommand to handle the event
	vim.api.nvim_create_autocmd("BufNewFile", {
		pattern = pattern, -- Match the given file pattern
		callback = function()
			local filename = vim.fn.expand("%:t")
			local basefilename = vim.fn.expand("%:t:r")
			local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")

			if ignored ~= nil then
				for _, ignore in pairs(ignored) do
					if ignore == filename then
						return
					end
				end
			end

			-- Check if the buffer is empty before inserting text
			if vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then
				-- Insert the template text
				vim.api.nvim_buf_set_lines(
					0,
					0,
					-1,
					false,
					vim.split(
						text
						:gsub("{{cwd}}", cwd) --
						:gsub("{{basefilename}}", basefilename)
						:gsub("{{filename}}", filename),
						"\n"
					)
				)

				-- Set the cursor position
				if pos and #pos == 2 then
					vim.api.nvim_win_set_cursor(0, pos)
				end
			end
		end,
	})
end

local templates = {
	{
		"build.zig",
		--zig
		[[const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .link_libc = true,
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });
    const exe = b.addExecutable(.{ .name = "{{cwd}}", .root_module = exe_mod });
    exe.linkLibC();

    b.installArtifact(exe);

    const run_step = b.step("run", "run");
    const run_exe = b.addRunArtifact(exe);

    run_step.dependOn(&run_exe.step);

    run_exe.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_exe.addArgs(args);
    }

    const exe_check = b.addExecutable(.{
        .name = "__check",
        .root_module = exe_mod,
    });
    const check = b.step("__check", "Check if project compiles");
    check.dependOn(&exe_check.step);
}]],
		{ 4, 44 },
	},
	{
		"main.zig",
		-- zig
		[[const std = @import("std");
const builtins = @import("builtins");

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});

const print = std.debug.print;

pub fn main() !void {
	// var gpa = std.heap.DebugAllocator(.{}){};
	// const allocator = gpa.allocator();
	print("hello {{cwd}}", .{});
}]],
		{ 12, 1 },
	},
	{ "zls.json", [[{
  "enable_build_on_save": true,
  "build_on_save_step": "check"
}]], { 1, 1 } },
	{
		"*.sh",
		[[#!/usr/bin/env bash

set -e

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

exit_trap () {
  local lc="$BASH_COMMAND" rc=$?
  yell "Command [$lc] exited with code [$rc]"
}

trap exit_trap EXIT

]],
		{ 2, 1 },
	},
	{ "default.nix", [[_ :{
	imports = [

	];
}]], { 2, 1 } },
	{
		"modules/**.nix",
		[[{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.{{basefilename}};
in {
  options.{{basefilename}}.enable = lib.mkEnableOption "enable {{basefilename}}";

  config = lib.mkIf cfg.enable {

  };
}]],
		{ 12, 1 },
	},
	{
		"shell.nix",
		[[{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  packages = with pkgs; [

  ];

  shellHook = ''
  '';
}]],
		{ 4, 2 },
	},
	{ "*.nix", [[{...}: {

}]], { 2, 2 }, { "shell.nix", "flake.nix" } },
	{ "main.py", [[def main():
    print()

if __name__ == "__main__":
    main()]], { 2, 7 } },
	{
		"main.cpp",
		[[#include <iostream>

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}]],
		{ 3, 5 },
	},
	{ "lua/plugins/*.lua", [[return {

}]], { 2, 2 } },
	{ ".direnv", [[use nix
#use flake]], { 4, 2 } },
}

for _, template in ipairs(templates) do
	createTemplate(template[1], template[2], template[3])
end
