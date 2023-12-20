local augroup = vim.api.nvim_create_augroup
MyGroup = augroup("mygroup", {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup("HighlightYank", {})

-- nvim-tree is also there in modified buffers so this function filter it out
-- https://github.com/nvim-tree/nvim-tree.lua/issues/1005
local modifiedBufs = function(bufs)
    local t = 0
    for k,v in pairs(bufs) do
        if v.name:match("NvimTree_") == nil then
            t = t + 1
        end
    end
    return t
end

autocmd({"BufEnter"}, {
    nested = true,
    callback = function()
        if #vim.api.nvim_list_wins() == 1 and
        vim.api.nvim_buf_get_name(0):match("NvimTree_") ~= nil and
        modifiedBufs(vim.fn.getbufinfo({bufmodified = 1})) == 0 then
            vim.cmd "quit"
        end
    end
})

autocmd({"BufWritePre"}, {
    group = MyGroup,
    pattern = "*",
    command = "%s/\\s\\+$//e",
})

autocmd({"BufWritePre"}, {
    group = MyGroup,
    pattern = {"*.js", "*.jsx", "*.tsx", "*.ts", "*.scss", "*.css"},
    command = "Neoformat prettier",
})

autocmd("BufEnter", {
    group = MyGroup,
    pattern = "COMMIT_EDITMSG",
    callback = function()
        vim.wo.spell = true
        vim.api.nvim_win_set_cursor(0, {1, 0})
        if vim.fn.getline(1) == "" then
            vim.cmd "startinsert!"
        end
    end
})

autocmd("BufWritePre", {
    group = format_sync_grp,
    pattern = "*.rs",
    callback = function()
        vim.lsp.buf.format(nil, 200)
    end
})

autocmd({"BufEnter"}, {
    group = MyGroup,
    pattern = "*/journal/**.md",
    callback = function()
        if vim.fn.getline(1) == "" then
            time = os.date("# %d-%b-%Y (%a)")
            vim.api.nvim_set_current_line(time)
        end
    end
})

autocmd({"BufEnter", "FocusLost"}, {
    group = MyGroup,
    pattern = "*",
    command = "silent update"
})

