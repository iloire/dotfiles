local augroup = vim.api.nvim_create_augroup
MyGroup = augroup("mygroup", {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup("HighlightYank", {})

autocmd({"BufWritePre"}, {
    group = MyGroup,
    pattern = "*",
    command = "%s/\\s\\+$//e",
})

autocmd({"BufWritePre"}, {
    group = MyGroup,
    pattern = "*",
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
        time = os.date("# %d-%b-%Y (%a)")
        vim.cmd('echo "journal entry"')
        if vim.fn.getline(1) == "" then
            vim.api.nvim_set_current_line(time)
        end
    end
})

autocmd({"BufEnter", "FocusLost"}, {
    group = MyGroup,
    pattern = "*",
    command = "silent update"
})

