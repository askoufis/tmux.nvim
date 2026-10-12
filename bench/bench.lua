-- run through bench.sh, which provides the tmux server
-- usage: nvim --headless -u NONE -l bench/bench.lua <plugin dir> [runs]
local dir, runs = arg[1], tonumber(arg[2] or 50)
vim.opt.rtp:prepend(dir)
require("tmux").setup({ navigation = { persist_zoom = false, cycle_navigation = true } })

local options = require("tmux.configuration.options")
local navigate = require("tmux.navigation.navigate")
local swap = require("tmux.swap")

local function bench(name, fn)
    fn(0) -- warm up
    local times = {}
    for i = 1, runs do
        local start = vim.uv.hrtime()
        fn(i)
        times[i] = (vim.uv.hrtime() - start) / 1e6
    end
    table.sort(times)
    local median, p90 = times[math.ceil(runs / 2)], times[math.ceil(runs * 0.9)]
    print(("%-28s median %6.2f ms   p90 %6.2f ms"):format(name, median, p90))
end

-- a single nvim window, so every move crosses into tmux
bench("navigate to tmux pane", function(i)
    navigate.to(i % 2 == 0 and "h" or "l")
end)
options.navigation.persist_zoom = true
bench("navigate, persist_zoom", function(i)
    navigate.to(i % 2 == 0 and "h" or "l")
end)
options.navigation.persist_zoom = false

bench("swap with tmux pane", function(i)
    swap.to(i % 2 == 0 and "left" or "right")
end)

-- two nvim splits, moving between them never needs to leave nvim
vim.cmd.vsplit()
bench("navigate inside nvim", function(i)
    navigate.to(i % 2 == 0 and "h" or "l")
end)
