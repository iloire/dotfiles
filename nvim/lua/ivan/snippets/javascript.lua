local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("javascript", {
	s("throw", {
    t("throw new Error('"), i(1, "error"), t("')")
	}),
	s("error", {
    t("console.error('"), i(1, "log"), t("')")
	}),
	s("log", {
    t("console.log("), i(1, ""), t(")")
	}),
	s("ternary javascript", {
		i(1, "cond"), t(" ? "), i(2, "then"), t(" : "), i(3, "else")
	})
})

