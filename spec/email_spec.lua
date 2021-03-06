local lpeg = require "lpeg"
local EOF = lpeg.P(-1)

describe("email Addresses", function()
	local email = lpeg.Ct(require "lpeg_patterns.email".email) * EOF
	it("Pass valid addresses", function()
		assert.same({"localpart", "example.com"}, email:match "localpart@example.com")
	end)
	it("Deny invalid addresses", function()
		assert.falsy(email:match "not an address")
	end)
	it("Handle unusual localpart", function()
		assert.same({"foo.bar", "example.com"}, email:match "foo.bar@example.com")
		assert.same({"foo+", "example.com"}, email:match "foo+@example.com")
		assert.same({"foo+bar", "example.com"}, email:match "foo+bar@example.com")
		assert.same({"!#$%&'*+-/=?^_`{}|~", "example.com"}, email:match "!#$%&'*+-/=?^_`{}|~@example.com")
		assert.same({[[quoted]], "example.com"}, email:match [["quoted"@example.com]])
		assert.same({[[quoted string]], "example.com"}, email:match [["quoted string"@example.com]])
		assert.same({[[quoted@symbol]], "example.com"}, email:match [["quoted@symbol"@example.com]])
		assert.same({[=[very.(),:;<>[]".VERY."very@\ "very".unusual]=], "example.com"},
			email:match [=["very.(),:;<>[]\".VERY.\"very@\\ \"very\".unusual"@example.com]=])
	end)
	it("folds whitespace", function()
		assert.same({"localpart ", "example.com"}, email:match [["localpart "@example.com]])
		assert.same({"localpart ", "example.com"}, email:match [["localpart  "@example.com]])
		assert.same({" localpart ", "example.com"}, email:match [["   localpart  "@example.com]])
		assert.same({" localpart and again ", "example.com"}, email:match [["   localpart and 	 again   "@example.com]])

		assert.same({"localpart", "example.com "}, email:match [=[localpart@[example.com ]]=])
		assert.same({"localpart", "example.com "}, email:match [=[localpart@[example.com  ]]=])
		assert.same({"localpart", " example.com"}, email:match [=[localpart@[  example.com]]=])
		assert.same({"localpart", " example.com "}, email:match [=[localpart@[  example.com 	]]=])
		assert.same({"localpart", " example with whitespace "}, email:match [=[localpart@[  example with    whitespace ]]=])
	end)
	it("Ignore invalid localpart", function()
		assert.falsy(email:match "@example.com")
		assert.falsy(email:match ".@example.com")
		assert.falsy(email:match "foobar.@example.com")
		assert.falsy(email:match "@foo@example.com")
		assert.falsy(email:match "foo@bar@example.com")
		-- quoted strings must be dot separated, or the only element making up the local-pat
		assert.falsy(email:match [[just"not"right@example.com]])
		assert.falsy(email:match "\127@example.com")
	end)
	it("Handle unusual hosts", function()
		assert.same({"localpart", "host_name"}, email:match "localpart@host_name")
		assert.same({"localpart", "127.0.0.1"}, email:match "localpart@[127.0.0.1]")
		assert.same({"localpart", "IPv6:2001::d1"}, email:match "localpart@[IPv6:2001::d1]")
		assert.same({"localpart", "::1"}, email:match "localpart@[::1]")
	end)
	it("Handle comments", function()
		assert.same({"localpart", "example.com"}, email:match "(comment)localpart@example.com")
		assert.same({"localpart", "example.com"}, email:match "localpart(comment)@example.com")
		assert.same({"quoted", "example.com"}, email:match "(comment)\"quoted\"@example.com")
		assert.same({"quoted", "example.com"}, email:match "\"quoted\"(comment)@example.com")
		assert.same({"localpart", "example.com"}, email:match "localpart@(comment)example.com")
		assert.same({"localpart", "example.com"}, email:match "localpart@example.com(comment)")
	end)
	it("Handle escaped items in quotes", function()
		assert.same({"escape d", "example.com"}, email:match [["escape\ d"(comment)@example.com]])
		assert.same({"escape\"d", "example.com"}, email:match [["escape\"d"(comment)@example.com]])
		-- tests obs-qp
		assert.same({"escape\0d", "example.com"}, email:match "\"escape\\\0d\"@example.com")
	end)
	it("processes obs-dtext", function()
		assert.same({"localpart", "escape d"}, email:match "localpart@[escape\\ d]")
	end)
	it("processes obs-local-part", function()
		-- obs-local-part allows whitespace between atoms
		assert.same({"local.part", "example.com"}, email:match [[local  .part@example.com]])
		-- obs-local-part allows individually quoted atoms
		assert.same({"local.part", "example.com"}, email:match [["local".part@example.com]])
	end)
	it("processes obs-domain", function()
		-- obs-domain allows whitespace between atoms
		assert.same({"localpart", "example.com"}, email:match [[localpart@example  .com]])
	end)
	it("Examples from RFC 3696 Section 3", function()
		-- Note: Look at errata 246, the followup 3563 and the followup to the followup 4002
		-- not only did the RFC author get some of these wrong, so did the RFC errata verifiers
		assert.same({"Abc@def", "example.com"}, email:match [["Abc\@def"@example.com]])
		assert.same({"Abc@def", "example.com"}, email:match [["Abc@def"@example.com]])
		assert.same({"Fred Bloggs", "example.com"}, email:match [["Fred\ Bloggs"@example.com]])
		assert.same({"Fred Bloggs", "example.com"}, email:match [["Fred Bloggs"@example.com]])
		assert.same({[[Joe.\Blow]], "example.com"}, email:match [["Joe.\\Blow"@example.com]])
		assert.same({[[Joe.Blow]], "example.com"}, email:match [["Joe.\Blow"@example.com]])
		assert.same({"Abc@def", "example.com"}, email:match [["Abc@def"@example.com]])
		assert.same({"Fred Bloggs", "example.com"}, email:match [["Fred Bloggs"@example.com]])
		assert.same({"user+mailbox", "example.com"}, email:match [[user+mailbox@example.com]])
		assert.same({"customer/department", "example.com"}, email:match [[customer/department@example.com]])
		assert.same({"$A12345", "example.com"}, email:match [[$A12345@example.com]])
		assert.same({"!def!xyz%abc", "example.com"}, email:match [[!def!xyz%abc@example.com]])
		assert.same({"_somename", "example.com"}, email:match [[_somename@example.com]])
	end)
end)
describe("email nocfws variants", function()
	local email_nocfws = lpeg.Ct(require "lpeg_patterns.email".email_nocfws) * EOF
	it("Pass valid addresses", function()
		assert.same({"localpart", "example.com"}, email_nocfws:match "localpart@example.com")
	end)
	it("Deny invalid addresses", function()
		assert.falsy(email_nocfws:match "not an address")
	end)
	it("Handle unusual localpart", function()
		assert.same({"foo.bar", "example.com"}, email_nocfws:match "foo.bar@example.com")
		assert.same({"foo+", "example.com"}, email_nocfws:match "foo+@example.com")
		assert.same({"foo+bar", "example.com"}, email_nocfws:match "foo+bar@example.com")
		assert.same({"!#$%&'*+-/=?^_`{}|~", "example.com"}, email_nocfws:match "!#$%&'*+-/=?^_`{}|~@example.com")
		assert.same({[[quoted]], "example.com"}, email_nocfws:match [["quoted"@example.com]])
		assert.same({[[quoted string]], "example.com"}, email_nocfws:match [["quoted string"@example.com]])
		assert.same({[[quoted@symbol]], "example.com"}, email_nocfws:match [["quoted@symbol"@example.com]])
		assert.same({[=[very.(),:;<>[]".VERY."very@\ "very".unusual]=], "example.com"},
			email_nocfws:match [=["very.(),:;<>[]\".VERY.\"very@\\ \"very\".unusual"@example.com]=])
	end)
	it("Ignore invalid localpart", function()
		assert.falsy(email_nocfws:match "@example.com")
		assert.falsy(email_nocfws:match ".@example.com")
		assert.falsy(email_nocfws:match "foobar.@example.com")
		assert.falsy(email_nocfws:match "@foo@example.com")
		assert.falsy(email_nocfws:match "foo@bar@example.com")
		-- quoted strings must be dot separated, or the only element making up the local-pat
		assert.falsy(email_nocfws:match [[just"not"right@example.com]])
		assert.falsy(email_nocfws:match "\127@example.com")
	end)
	it("Handle unusual hosts", function()
		assert.same({"localpart", "host_name"}, email_nocfws:match "localpart@host_name")
		assert.same({"localpart", "127.0.0.1"}, email_nocfws:match "localpart@[127.0.0.1]")
		assert.same({"localpart", "IPv6:2001::d1"}, email_nocfws:match "localpart@[IPv6:2001::d1]")
		assert.same({"localpart", "::1"}, email_nocfws:match "localpart@[::1]")
	end)
	it("Doesn't allow comments", function()
		assert.falsy(email_nocfws:match "(comment)localpart@example.com")
		assert.falsy(email_nocfws:match "localpart(comment)@example.com")
		assert.falsy(email_nocfws:match "(comment)\"quoted\"@example.com")
		assert.falsy(email_nocfws:match "\"quoted\"(comment)@example.com")
		assert.falsy(email_nocfws:match "localpart@example.com(comment)")
		assert.falsy(email_nocfws:match "localpart@example.com(comment)")
	end)
end)
describe("mailbox", function()
	local mailbox = lpeg.Ct(require "lpeg_patterns.email".mailbox) * EOF
	it("matches an addr-spec", function()
		assert.same({"foo", "example.com"}, mailbox:match "foo@example.com")
	end)
	it("matches a name-addr", function()
		assert.same({"foo", "example.com"}, mailbox:match "<foo@example.com>")
		assert.same({"foo", "example.com", display = "Foo"}, mailbox:match "Foo<foo@example.com>")
		assert.same({"foo", "example.com", display = "Foo "}, mailbox:match "Foo <foo@example.com>")
		assert.same({"foo", "example.com", display = [["Foo"]]}, mailbox:match [["Foo"<foo@example.com>]])
		assert.same({"foo", "example.com", display = "Old.Style.With.Dots"},
			mailbox:match "Old.Style.With.Dots<foo@example.com>")
		assert.same({"foo", "example.com", display = "Multiple Words"},
			mailbox:match "Multiple Words<foo@example.com>")
	end)
	it("matches a old school name-addr", function()
		assert.same({"foo", "example.com", route = {"wow", "such", "domains"}},
			mailbox:match "<@wow,@such,,@domains:foo@example.com>")
	end)
end)
