return {
    "snacks.nvim",

    keys = {
        { "<leader>ff",      function() Snacks.picker.files() end,   desc = "Find Files" },
        { "<leader>fr",      function() Snacks.picker.grep() end,    desc = "Grep" },
        { "<leader><space>", function() Snacks.picker.smart() end,   desc = "Smart Find Files" },
        { "<leader>,",       function() Snacks.picker.buffers() end, desc = "Buffers" },
        { "<leader>nh",      function() Snacks.notifier.hide() end, desc = "Notifier Hide" },
        { "<leader>nh",      function() Snacks.notifier.show_history() end, desc = "Notifier Show" }
    },

    after = function()
        require("snacks").setup {
            bigfile = { enabled = true },
            dashboard = { enabled = true },
            explorer = { enabled = true },
            indent = { enabled = true },
            input = { enabled = true },
            picker = { enabled = true },
            notifier = { enabled = true },
            quickfile = { enabled = true },
            scope = { enabled = true },
            scroll = { enabled = true },
            statuscolumn = { enabled = true },
            words = { enabled = true }
        }

    end
}
