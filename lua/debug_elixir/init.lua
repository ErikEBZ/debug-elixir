M = {}

local ts_utils = require 'nvim-treesitter.ts_utils'

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━--
--	Helper functions --
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━--
local function i(value)
    print(vim.inspect(value))
end

local function coment_format(lang, coment, line)
    if (lang == "elixir") then
        local file_name = vim.fn.expand('%')
        return "IO.puts( 'File: "..file_name.." - Line: "..line.." - "..coment.."' )"
    end

    return nil
end

local function insert_coment(row, col, coment, lang)
    coment = coment_format(lang, coment, row)
    coment = string.rep(" ", col)..coment -- identation
    row = row + 1

    vim.api.nvim_buf_set_lines(0, row, row, false, {coment})
end

-- local function get_query(lang)
--     if lang == "elixir" then
--         return vim.treesitter.parse_query(lang,[[
--         (call
--         target: (identifier) @function.identifier
--         (arguments (alias) @function.argument))
-- 
--         (call 
--         target: (identifier)
--         (arguments (call target: (identifier) @function.identifier))
--         )
-- 
--         (call
--         target: (identifier) @function.identifier (#eq? @function.identifier "if")
--         ) 
--             ]]
--         )
--     end
-- 
--     return nil
-- end

local function get_partial_coment(type, text, node, bufnm)
    if type == "identifier" then
        if text == "if" or text == "case" then
            return text
        end

        if text == "def" or text == "defp" then
            local sibling = node:next_sibling()
            local sibling_child = sibling:child(0)
            local target = sibling_child:child(0)

            local fun_name = ts_utils.get_node_text(target, bufnm)[1]

            return fun_name
        end

        if text == "defmodule" then
            return text
        end
    end

    return nil
end

local function traverse_node(node, bufnm)
    local cmnt = ""
    for child_node, child_name in node:iter_children() do
        local text = ts_utils.get_node_text(child_node, bufnm)[1]

        local pComent = get_partial_coment(child_node:type(), text, child_node)

        if pComent ~= nil then
            cmnt = pComent..cmnt
        end

    end

    return cmnt
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━--
--	Main function--
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━--
M.get_debug = function ()
    local bufnm = vim.api.nvim_get_current_buf()
    local lang = vim.bo.filetype

    local node = ts_utils.get_node_at_cursor()
    local parent = node:parent()
    local sRow, sCol, eRow, eCol = node:range()

    local cmnt = ""
    while (node:parent() ~= nil) do
        local node_type = node:type()
        local node_text = ts_utils.get_node_text(node, bufnm)[1]

        if (node_type == "call") then
            local info = traverse_node(node, bufnm)
            if info ~= "" then
                cmnt = "#"..info..cmnt
            end
        end

        node = parent
        parent = node:parent()
    end

    insert_coment(sRow, sCol, cmnt, lang)
end

return M
