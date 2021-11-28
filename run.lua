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
                target: (identifier) @identifier
                (arguments (alias) @module_name))

            (call 
              target: (identifier)
              (arguments (call target: (identifier) @identifier))
            )
        ]]
    )

    for id, match, _ in query:iter_matches(root, bufnm) do
        print("iter")

        local name = query.captures[id] -- name of the capture in the query
        print("name of the capture in the query: "..name)

        print("Size of match is: "..#match)
        for index, data in pairs(match) do
            print(ts_utils.get_node_text(data, bufnm)[1])
            print("Type of node: "..data:type())
        end

        print("-------------------")

--[[ local match_type = ts_utils.get_node_text(match[1], bufnm)[1] -- Gets the type def

print(match_type)
        check_case(match_type, match) ]]
    end
end

get_debug_msg()
