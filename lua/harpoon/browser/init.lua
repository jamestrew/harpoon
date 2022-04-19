local harpoon = require("harpoon")
local utils = require("harpoon.utils")
local log = require("harpoon.dev").log
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local Path = require("plenary.path")

local M = {}

-- emit_changed
-- add_folder

local function emit_changed()
    log.trace("_emit_changed()")
    if harpoon.get_global_settings().save_on_change then
        harpoon.save()
    end
end

local function insert_path(new_path)
    log.trace("_insert_path()")
    local duplicate = false
    for _, path in ipairs(harpoon.get_browser_config().folders) do
        if path == new_path then
            duplicate = true
            break
        end
    end

    if not duplicate then
        table.insert(harpoon.get_browser_config().folders, new_path)
    end
end

M.add_folder = function(prompt_bufnr)
    log.trace("add_folder()")
    local current_finder = action_state.get_current_picker(prompt_bufnr).finder
    local entry = action_state.get_selected_entry()

    local entry_path
    if entry.ordinal == ".." then
        entry_path = Path:new(current_finder.path)
    else
        entry_path = action_state.get_selected_entry().Path
    end

    local path = entry_path:is_dir() and entry_path:absolute()
        or entry_path:parent():absolute()
    insert_path(path)
    emit_changed()
end

M.get_contents = function()
    local contents = {}
    for _, entry_path in ipairs(harpoon.get_browser_config().folders) do
        local path = Path:new(entry_path):make_relative(vim.loop.cwd())
        table.insert(contents, path)
    end
    return contents
end

M.set_browse_list = function(new_list)
    harpoon.get_browser_config().folders = {}
    for _, entry_path in ipairs(new_list) do
        local path = Path:new(entry_path)
        path = path:is_dir() and path:absolute() or path:parent():absolute()
        insert_path(path)
    end
    emit_changed()
end

M.open_file_browser = function(path_idx)
    local entry_path = harpoon.get_browser_config().folders[path_idx]
    local path = Path:new(entry_path):absolute()
    require("telescope").extensions.file_browser.file_browser({ path = path })
end

return M
