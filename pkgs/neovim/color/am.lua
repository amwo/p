local set = vim.api.nvim_set_hl
local cmd = vim.cmd

local normal_bg    = "#111111"
local cursorline_bg= "#222222"
local nerd_bg      = "#000000"
local white        = "#ffffff"
local gray         = "#808080"
local pink         = "#ff69b4"

vim.g.colors_name = "am"

set(0, "Normal",       { fg = white, bg = normal_bg })
set(0, "NormalNC",     { fg = white, bg = normal_bg })
set(0, "Comment",      { fg = gray, italic = false })
set(0, "Constant",     { fg = white })
set(0, "String",       { fg = white })
set(0, "Number",       { fg = white })
set(0, "Statement",    { fg = white })
set(0, "PreProc",      { fg = white })
set(0, "Type",         { fg = white })
set(0, "Special",      { fg = white })
set(0, "Identifier",   { fg = white })
set(0, "Function",     { fg = white })
set(0, "Keyword",      { fg = white })
set(0, "Operator",     { fg = white })
set(0, "LineNr",        { fg = gray, bg = normal_bg })
set(0, "CursorLineNr",  { fg = white, bg = normal_bg })
set(0, "CursorLine",    { bg = cursorline_bg })
set(0, "CursorColumn",  { bg = cursorline_bg })
set(0, "StatusLine",    { fg = cursorline_bg, bg = normal_bg, reverse = true })
set(0, "StatusLineNC",  { fg = cursorline_bg, bg = normal_bg, reverse = true })
set(0, "ModeMsg",       { fg = white })
set(0, "MoreMsg",       { fg = white })
set(0, "Question",      { fg = white })
set(0, "WarningMsg",    { fg = white })
set(0, "ErrorMsg",      { fg = white, bg = normal_bg, reverse = true })
set(0, "Error",         { fg = white, bg = normal_bg, reverse = true })
set(0, "Todo",          { fg = white, bg = normal_bg, reverse = true })
set(0, "Debug",         { fg = white })
set(0, "Visual",        { fg = white, bg = normal_bg, reverse = true })
set(0, "MatchParen",    { fg = white, bg = gray })
set(0, "Cursor",        { fg = normal_bg, bg = white })
set(0, "lCursor",       { fg = normal_bg, bg = white })
set(0, "NonText",       { fg = normal_bg, bg = normal_bg })
set(0, "EndOfBuffer",   { fg = normal_bg, bg = normal_bg })
set(0, "SpecialKey",    { fg = gray })
set(0, "Whitespace",    { fg = gray })
set(0, "Search",        { fg = pink, bg = normal_bg })
set(0, "IncSearch",     { fg = pink, bg = normal_bg })
set(0, "CurSearch",     { fg = pink, bg = normal_bg })
set(0, "VertSplit",     { fg = cursorline_bg, bg = normal_bg })
set(0, "WinSeparator",  { fg = cursorline_bg, bg = normal_bg })
set(0, "SignColumn",    { fg = gray, bg = normal_bg })
set(0, "FoldColumn",    { fg = gray, bg = normal_bg })
set(0, "Folded",        { fg = gray, bg = normal_bg })
set(0, "ColorColumn",   { bg = normal_bg })
set(0, "TabLine",       { fg = gray, bg = normal_bg })
set(0, "TabLineFill",   { fg = gray, bg = normal_bg })
set(0, "TabLineSel",    { fg = white, bg = normal_bg })
set(0, "WildMenu",      { fg = normal_bg, bg = white })
set(0, "Pmenu",         { fg = white, bg = gray })
set(0, "PmenuSel",      { fg = normal_bg, bg = white })
set(0, "PmenuSbar",     { bg = gray })
set(0, "PmenuThumb",    { bg = white })
set(0, "Directory",     { fg = white })
set(0, "Title",         { fg = white })
set(0, "DiffAdd",       { fg = white, bg = normal_bg })
set(0, "DiffChange",    { fg = white, bg = normal_bg })
set(0, "DiffDelete",    { fg = gray,  bg = normal_bg })
set(0, "DiffText",      { fg = white, bg = normal_bg, reverse = true })

cmd [[
  hi! link markdownHeadingDelimiter Comment
  hi! link markdownCode String
  hi! link markdownCodeBlock String
  hi! link markdownH1 Title
  hi! link markdownH2 Title
  hi! link markdownLinkText Underlined
]]

set(0, "Underlined",    { fg = white, underline = true })
set(0, "Ignore",        { fg = gray })

cmd [[
  hi! link GitSignsAdd String
  hi! link GitSignsChange String
  hi! link GitSignsDelete Comment
  hi! link GitSignsAddNr String
  hi! link GitSignsChangeNr String
  hi! link GitSignsDeleteNr Comment
  hi! link GitSignsAddLn DiffAdd
  hi! link GitSignsChangeLn DiffChange
  hi! link GitSignsDeleteLn DiffDelete
]]

cmd [[
  hi! link CocErrorSign        Error
  hi! link CocWarningSign      WarningMsg
  hi! link CocInfoSign         Directory
  hi! link CocHintSign         Comment
  hi! link CocErrorFloat       Error
  hi! link CocWarningFloat     WarningMsg
  hi! link CocInfoFloat        Directory
  hi! link CocHintFloat        Comment
  hi! link CocDiagnosticsError Error
  hi! link CocDiagnosticsWarning WarningMsg
  hi! link CocDiagnosticsInfo  Directory
  hi! link CocDiagnosticsHint  Comment
  hi! link CocSelectedText     Visual
  hi! link CocCodeLens         Comment
]]

cmd [[
  hi! link fzf1 Normal
  hi! link fzf2 Normal
  hi! link fzf3 Normal
]]

cmd [[
  hi! link TSAnnotation        Special
  hi! link TSAttribute         Special
  hi! link TSBoolean           Boolean
  hi! link TSCharacter         Character
  hi! link TSComment           Comment
  hi! link TSConditional       Conditional
  hi! link TSConstant          Constant
  hi! link TSConstBuiltin      Special
  hi! link TSConstMacro        Define
  hi! link TSConstructor       Function
  hi! link TSError             Error
  hi! link TSException         Exception
  hi! link TSField             Identifier
  hi! link TSFloat             Float
  hi! link TSFunction          Function
  hi! link TSFuncBuiltin       Special
  hi! link TSFuncMacro         Macro
  hi! link TSInclude           Include
  hi! link TSKeyword           Keyword
  hi! link TSKeywordFunction   Keyword
  hi! link TSKeywordOperator   Operator
  hi! link TSLabel             Label
  hi! link TSMethod            Function
  hi! link TSNamespace         Identifier
  hi! link TSNone              Normal
  hi! link TSNumber            Number
  hi! link TSOperator          Operator
  hi! link TSParameter         Identifier
  hi! link TSParameterReference Identifier
  hi! link TSProperty          Identifier
  hi! link TSPunctDelimiter    Delimiter
  hi! link TSPunctBracket      Delimiter
  hi! link TSPunctSpecial      Special
  hi! link TSRepeat            Repeat
  hi! link TSString            String
  hi! link TSStringRegex       String
  hi! link TSStringEscape      SpecialChar
  hi! link TSTag               Label
  hi! link TSTagDelimiter      Delimiter
  hi! link TSText              Normal
  hi! link TSTitle             Title
  hi! link TSType              Type
  hi! link TSTypeBuiltin       Type
  hi! link TSVariable          Identifier
  hi! link TSVariableBuiltin   Special
]]

cmd [[
  hi! link Boolean        Constant
  hi! link Character      Constant
  hi! link Conditional    Statement
  hi! link Define         PreProc
  hi! link Delimiter      Special
  hi! link Exception      Statement
  hi! link Float          Number
  hi! link Include        PreProc
  hi! link Label          Statement
  hi! link Macro          PreProc
  hi! link PreCondit      PreProc
  hi! link Repeat         Statement
  hi! link SpecialChar    Special
  hi! link SpecialComment Comment
  hi! link StorageClass   Type
  hi! link Structure      Type
  hi! link Tag            Special
  hi! link Typedef        Type
]]

local nerd_fg = white
local nerd_dim= gray

set(0, "NERDTreeDir",              { fg = nerd_fg, bg = nerd_bg })
set(0, "NERDTreeDirSlash",         { fg = nerd_fg, bg = nerd_bg })
set(0, "NERDTreeFile",             { fg = nerd_fg, bg = nerd_bg })
set(0, "NERDTreeExecFile",         { fg = nerd_fg, bg = nerd_bg })
set(0, "NERDTreeOpenable",         { fg = nerd_fg, bg = nerd_bg })
set(0, "NERDTreeClosable",         { fg = nerd_fg, bg = nerd_bg })
set(0, "NERDTreeUp",               { fg = nerd_dim, bg = nerd_bg })
set(0, "NERDTreeCWD",              { fg = nerd_fg,  bg = nerd_bg })
set(0, "NERDTreeHelp",             { fg = nerd_dim, bg = nerd_bg })
set(0, "NERDTreeToggleOn",         { fg = nerd_fg,  bg = nerd_bg })
set(0, "NERDTreeToggleOff",        { fg = nerd_dim, bg = nerd_bg })
set(0, "NERDTreeBookmark",         { fg = nerd_fg,  bg = nerd_bg })
set(0, "NERDTreeBookmarkName",     { fg = nerd_fg,  bg = nerd_bg })
set(0, "NERDTreeBookmarksHeader",  { fg = nerd_fg,  bg = nerd_bg })
set(0, "NERDTreeBookmarksLeader",  { fg = nerd_dim, bg = nerd_bg })
set(0, "NERDTreeBookmarkTable",    { fg = nerd_fg,  bg = nerd_bg })
set(0, "NERDTreePart",             { fg = nerd_dim, bg = nerd_bg })
set(0, "NERDTreePartFile",         { fg = nerd_fg,  bg = nerd_bg })
set(0, "NERDTreeLinkTarget",       { fg = nerd_fg,  bg = nerd_bg })
set(0, "NERDTreeLinkFile",         { fg = nerd_fg,  bg = nerd_bg })
set(0, "NERDTreeLinkDir",          { fg = nerd_fg,  bg = nerd_bg })
set(0, "NERDTreeCurrentNode",      { fg = pink,     bg = nerd_bg, bold = true })
set(0, "NERDTreeRO",               { fg = nerd_dim, bg = nerd_bg })
set(0, "NERDTreeFlags",            { fg = nerd_fg,  bg = nerd_bg })
