local BEGIN_COMMENT = lpeg.P("/*")
local END_COMMENT = lpeg.P("*/")
local NOT_BEGIN = (1 - BEGIN_COMMENT)^0
local NOT_END = (1 - END_COMMENT)^0
local FULL_COMMENT_CONTENTS = BEGIN_COMMENT * NOT_END * END_COMMENT

-- Parser to find comments from a string
local searchParser = (NOT_BEGIN * lpeg.C(FULL_COMMENT_CONTENTS))^0
-- Parser to find non-comments from a string
local filterParser = (lpeg.C(NOT_BEGIN) * FULL_COMMENT_CONTENTS)^0 * lpeg.C(NOT_BEGIN)

-- Simpler version, although empirically it is slower.... (why?) ... any optimization
-- suggestions are desired as well as optimum integration w/ C++ comments and other
-- syntax elements
local searchParser = (lpeg.C(FULL_COMMENT_CONTENTS) + 1)^0
-- Suggestion by Roberto to make the search faster
-- Works because it loops fast over all non-slashes, then it begins the slower match phase
local searchParser = ((1 - lpeg.P"/")^0 * (lpeg.C(FULL_COMMENT_CONTENTS) + 1))^0
