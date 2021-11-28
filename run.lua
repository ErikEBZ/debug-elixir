local ts_utils = require 'nvim-treesitter.ts_utils'
local ts_query = require"nvim-treesitter.query"

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━--
--	Helper functions --
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━--
local function i(value)
    print(vim.inspect(value))
end

local function check_case(target_identifier, target)
    local bufnm = vim.api.nvim_get_current_buf()

    print("target identifier: ")
    i(target_identifier)

    if (target_identifier == "defmodule")  then
        alias = ts_utils.get_node_text(target[2], bufnm)[1]

        local ret = "#"..alias
        print("Returning 'it's a defmodule' with alias: "..alias)
        return ret
    end

    return "whatever"
end


--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━--
--	Main function--
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━--
local function get_debug_msg()
    local bufnm = vim.api.nvim_get_current_buf()
    local lang = vim.bo.filetype

    print("bufnm: "..bufnm.." lang: "..lang)

    local parser = vim.treesitter.get_parser(bufnm, lang)
    local tree = parser:parse()
    local root = tree[1]:root()

    -- Getting the base node
    local node = ts_utils.get_node_at_cursor()
    local sRow, sCol, eRow, eCol = node:range()

    print("sRow: "..sRow.." sCol: "..sCol.." eRow: "..eRow.."eCol: "..eCol)

    local query = vim.treesitter.parse_query(lang,[[
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

    local coment = ""
    for id, capture, _ in query:iter_captures(root, bufnm) do
        local node_text = ts_utils.get_node_text(capture, bufnm)
        local name = query.captures[id] -- name of the capture in the query

        --[[ print("Capture name: "..name)
        print("node text: "..node_text[1]) ]]
        coment = coment.."#"..node_text[1]
    end

    print(coment)
end

get_debug_msg()
