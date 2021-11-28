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

local function get_query(lang)
    if lang == "elixir" then
        return vim.treesitter.parse_query(lang,[[
        (call
        target: (identifier) @function.identifier
        (arguments (alias) @function.argument))

        (call 
        target: (identifier)
        (arguments (call target: (identifier) @function.identifier))
        )

        (call
        target: (identifier) @function.identifier (#eq? @function.identifier "if")
        ) 
            ]]
        )
    end

    return nil
end

local function get_parent_nodes(node)
    local parents = {}
    local count  = 1

    -- local parent = node:parent()

    while (node ~= nil) do
        print("Adding node to parents: ")
        i(node)
        parents[count] = node
        node = node:parent()
        count = count + 1
    end

    print("Returning parents nodes: ")
    i(parents)

    return parents
end

local function search_node(parents, cNode)
    -- FIXME: Comparing parent node is wrong implemented
    -- Compare rows and colums from nodes that are parents of the base node to identify the corrent parent nodes
    for _, node in pairs(parents) do
        if (cNode == node) then
            return true
        end
    end

    return false
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━--
--	Main function--
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━--
M.get_debug = function ()
    local bufnm = vim.api.nvim_get_current_buf()
    local lang = vim.bo.filetype

    -- Parsing the fil
    local parser = vim.treesitter.get_parser(bufnm, lang)
    local tree = parser:parse()
    local root = tree[1]:root()

    -- Getting the base node
    local node = ts_utils.get_node_at_cursor()
    local sRow, sCol, eRow, eCol = node:range()

    -- local parent_node = get_parent_nodes(node)
    local query = get_query(lang)

    local parents = get_parent_nodes(node)

    local coment = ""
    for id, capture, _ in query:iter_captures(root, bufnm, 0, sRow+1) do
        if search_node(parents, capture) then
            local node_text = ts_utils.get_node_text(capture, bufnm)

            coment = coment.."#"..node_text[1]
        else
            print("not allowed")
        end
    end

    insert_coment(sRow, sCol, coment, lang)
end

return M
