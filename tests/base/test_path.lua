--
-- tests/base/test_path.lua
-- Automated test suite for the action list.
-- Copyright (c) 2008-2013 Jason Perkins and the Premake project
--

	local suite = test.declare("path")


--
-- path.getabsolute() tests
--

	function suite.getabsolute_worksWithMissingSubdirs()
		local expected = os.getcwd() .. "/a/b/c"
		test.isequal(expected, path.getabsolute("a/b/c"))
	end

	function suite.getabsolute_removesDotDots_onWindows()
		test.isequal("c:/ProjectB/bin", path.getabsolute("c:/ProjectA/../ProjectB/bin"))
	end

	function suite.getabsolute_removesDotDots_OnPosix()
		test.isequal("/ProjectB/bin", path.getabsolute("/ProjectA/../ProjectB/bin"))
	end

	function suite.getabsolute_limitsDotDots_onWindows()
		test.isequal("c:/ProjectB/bin", path.getabsolute("c:/ProjectA/../../ProjectB/bin"))
	end

	function suite.getabsolute_limitsDotDots_OnPosix()
		test.isequal("/ProjectB/bin", path.getabsolute("/ProjectA/../../ProjectB/bin"))
	end

	function suite.getabsolute_removesDot()
		test.isequal("/ProjectA/ProjectB/bin", path.getabsolute("/ProjectA/./ProjectB/bin"))
	end

	function suite.getabsolute_removesTrailingSlash()
		test.isequal("/a/b/c", path.getabsolute("/a/b/c/"))
	end

	function suite.getabsolute_onLeadingEnvVar()
		test.isequal("$(HOME)/user", path.getabsolute("$(HOME)/user"))
	end

	function suite.getabsolute_onMultipleEnvVar()
		test.isequal("$(HOME)/$(USER)", path.getabsolute("$(HOME)/$(USER)"))
	end

	function suite.getabsolute_onTrailingEnvVar()
		test.isequal("/home/$(USER)", path.getabsolute("/home/$(USER)"))
	end

	function suite.getabsolute_onLeadingEnvVarQuoted()
		test.isequal('"$(HOME)/user"', path.getabsolute('"$(HOME)/user"'))
	end

	function suite.getabsolute_normalizesPaths()
		test.isequal("c:/ProjectB/bin", path.getabsolute("c:\\ProjectB\\bin"))
	end

	function suite.getabsolute_acceptsTables()
		test.isequal({ "/a/b", "/c/d" }, path.getabsolute({ "/a/b", "/c/d" }))
	end

	function suite.getabsolute_withRelativeTo()
		local relto = path.getdirectory(os.getcwd())
		local expected = relto .. "/a/b/c"
		test.isequal(expected, path.getabsolute("a/b/c", relto))
	end

	function suite.getabsolute_withRelativeTo_withTrailingSlashes()
		local relto = path.getdirectory(os.getcwd())
		local expected = relto .. "/a/b/c"
		test.isequal(expected, path.getabsolute("a/b/c", relto .. "/"))
	end

	function suite.getabsolute_acceptsTables_withRelativeTo()
		local relto = path.getdirectory(os.getcwd())
		test.isequal({ relto .. "/a/b", relto .. "/c/d" }, path.getabsolute({ "a/b", "c/d" }, relto))
	end

	function suite.getabsolute_leavesDotDot_onShellVar()
		test.isequal("$ORIGIN/../libs", path.getabsolute("$ORIGIN/../libs"))
	end

	function suite.getabsolute_leavesDotDot2_onShellVar()
		test.isequal("$ORIGIN/../../libs", path.getabsolute("$ORIGIN/../../libs"))
	end


--
-- path.getbasename() tests
--

	function suite.getbasename_ReturnsCorrectName_OnDirAndExtension()
		test.isequal("filename", path.getbasename("folder/filename.ext"))
	end


--
-- path.getdirectory() tests
--

	function suite.getdirectory_ReturnsEmptyString_OnNoDirectory()
		test.isequal(".", path.getdirectory("filename.ext"))
	end

	function suite.getdirectory_ReturnsDirectory_OnSingleLevelPath()
		test.isequal("dir0", path.getdirectory("dir0/filename.ext"))
	end

	function suite.getdirectory_ReturnsDirectory_OnMultiLeveLPath()
		test.isequal("dir0/dir1/dir2", path.getdirectory("dir0/dir1/dir2/filename.ext"))
	end

	function suite.getdirectory_ReturnsRootPath_OnRootPathOnly()
		test.isequal("/", path.getdirectory("/filename.ext"))
	end



--
-- path.getdrive() tests
--

	function suite.getdrive_ReturnsNil_OnNotWindows()
		test.isnil(path.getdrive("/hello"))
	end

	function suite.getdrive_ReturnsLetter_OnWindowsAbsolute()
		test.isequal("x", path.getdrive("x:/hello"))
	end



--
-- path.getextension() tests
--

	function suite.getextension_ReturnsEmptyString_OnNoExtension()
		test.isequal("", path.getextension("filename"))
	end

	function suite.getextension_ReturnsExtension()
		test.isequal(".txt", path.getextension("filename.txt"))
	end

	function suite.getextension_OnMultipleDots()
		test.isequal(".txt", path.getextension("filename.mod.txt"))
	end

	function suite.getextension_OnLeadingNumeric()
		test.isequal(".7z", path.getextension("filename.7z"))
	end

	function suite.getextension_OnUnderscore()
		test.isequal(".a_c", path.getextension("filename.a_c"))
	end

	function suite.getextension_OnHyphen()
		test.isequal(".a-c", path.getextension("filename.a-c"))
	end



--
-- path.getrelative() tests
--

	function suite.getrelative_ReturnsDot_OnMatchingPaths()
		test.isequal(".", path.getrelative("/a/b/c", "/a/b/c"))
	end

	function suite.getrelative_ReturnsDoubleDot_OnChildToParent()
		test.isequal("..", path.getrelative("/a/b/c", "/a/b"))
	end

	function suite.getrelative_ReturnsDoubleDot_OnSiblingToSibling()
		test.isequal("../d", path.getrelative("/a/b/c", "/a/b/d"))
	end

	function suite.getrelative_ReturnsChildPath_OnParentToChild()
		test.isequal("d", path.getrelative("/a/b/c", "/a/b/c/d"))
	end

	function suite.getrelative_ReturnsChildPath_OnWindowsAbsolute()
		test.isequal("obj/debug", path.getrelative("C:/Code/Premake4", "C:/Code/Premake4/obj/debug"))
	end

	function suite.getrelative_ReturnsAbsPath_OnDifferentDriveLetters()
		test.isequal("D:/Files", path.getrelative("C:/Code/Premake4", "D:/Files"))
	end

	function suite.getrelative_ReturnsAbsPath_OnDollarMacro()
		test.isequal("$(SDK_HOME)/include", path.getrelative("C:/Code/Premake4", "$(SDK_HOME)/include"))
	end

	function suite.getrelative_ReturnsAbsPath_OnRootedPath()
		test.isequal("/opt/include", path.getrelative("/home/me/src/project", "/opt/include"))
	end

	function suite.ignoresExtraSlashes2()
		test.isequal("..", path.getrelative("/a//b/c","/a/b"))
	end

	function suite.ignoresExtraSlashes3()
		test.isequal("..", path.getrelative("/a///b/c","/a/b"))
	end


--
-- path.isabsolute() tests
--

	function suite.isabsolute_ReturnsTrue_OnAbsolutePosixPath()
		test.istrue(path.isabsolute("/a/b/c"))
	end

	function suite.isabsolute_ReturnsTrue_OnAbsoluteWindowsPathWithDrive()
		test.istrue(path.isabsolute("C:/a/b/c"))
	end

	function suite.isabsolute_ReturnsFalse_OnRelativePath()
		test.isfalse(path.isabsolute("a/b/c"))
	end

	function suite.isabsolute_ReturnsTrue_OnDollarSign()
		test.istrue(path.isabsolute("$(SDK_HOME)/include"))
	end


--
-- path.join() tests
--

	function suite.join_OnValidParts()
		test.isequal("p1/p2", path.join("p1", "p2"))
	end

	function suite.join_OnAbsoluteUnixPath()
		test.isequal("/p2", path.join("p1", "/p2"))
	end

	function suite.join_OnAbsoluteWindowsPath()
		test.isequal("C:/p2", path.join("p1", "C:/p2"))
	end

	function suite.join_OnCurrentDirectory()
		test.isequal("p2", path.join(".", "p2"))
	end

	function suite.join_OnNilSecondPart()
		test.isequal("p1", path.join("p1", nil))
	end

	function suite.join_onMoreThanTwoParts()
		test.isequal("p1/p2/p3", path.join("p1", "p2", "p3"))
	end

	function suite.join_removesExtraInternalSlashes()
		test.isequal("p1/p2", path.join("p1/", "p2"))
	end

	function suite.join_removesTrailingSlash()
		test.isequal("p1/p2", path.join("p1", "p2/"))
	end

	function suite.join_ignoresNilParts()
		test.isequal("p2", path.join(nil, "p2", nil))
	end

	function suite.join_ignoresEmptyParts()
		test.isequal("p2", path.join("", "p2", ""))
	end

	function suite.join_canJoinBareSlash()
		test.isequal("/Users", path.join("/", "Users"))
	end


--
-- path.rebase() tests
--

	function suite.rebase_WithEndingSlashOnPath()
		local cwd = os.getcwd()
		test.isequal("src", path.rebase("../src/", cwd, path.getdirectory(cwd)))
	end


--
-- path.translate() tests
--

	function suite.translate_ReturnsTranslatedPath_OnValidPath()
		test.isequal("dir/dir/file", path.translate("dir\\dir\\file", "/"))
	end

	function suite.translate_returnsCorrectSeparator_onMixedPath()
		local actual = path.translate("dir\\dir/file", "/")
		test.isequal("dir/dir/file", actual)
	end


--
-- path.wildcards tests
--

	function suite.wildcards_MatchesTrailingStar()
		local p = path.wildcards("**/xcode/*")
		test.isequal(".*/xcode/[^/]*", p)
	end

	function suite.wildcards_MatchPlusSign()
		local patt = path.wildcards("file+name.*")
		local name = "file+name.c"
		test.isequal(name, name:match(patt))
	end

	function suite.wildcards_escapeSpecialChars()
		test.isequal("%.%-", path.wildcards(".-"))
	end

	function suite.wildcards_escapeStar()
		test.isequal("vs[^/]*", path.wildcards("vs*"))
	end

	function suite.wildcards_escapeStarStar()
		test.isequal("Images/.*%.bmp", path.wildcards("Images/**.bmp"))
	end
