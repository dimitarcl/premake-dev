--
-- tests/solution/test_objdirs.lua
-- Test the solution unique objects directory building.
-- Copyright (c) 2012 Jason Perkins and the Premake project
--

	local suite = test.declare("solution_objdir")


--
-- Setup and teardown
--

	local sln

	function suite.setup()
		_ACTION = "test"
		sln = solution("MySolution")
		system "macosx"
	end

	local function result()
		local platforms = sln.platforms or {}
		local prj = project("MyProject")
		local cfg = test.getconfig(prj, "Debug", platforms[1])
		return premake.project.getrelative(cfg.project, cfg.objdir)
	end


--
-- Objects directory should "obj" by default.
--

	function suite.directoryIsObj_onNoValueSet()
		configurations { "Debug" }
		test.isequal("obj", result())
	end


--
-- If a conflict occurs between platforms, the platform names should
-- be used to make unique.
--

	function suite.directoryIncludesPlatform_onPlatformConflict()
		configurations { "Debug" }
		platforms { "x32", "x64" }
		test.isequal("obj/x32",  result())
	end


--
-- If a conflict occurs between build configurations, the build
-- configuration names should be used to make unique.
--

	function suite.directoryIncludesBuildCfg_onBuildCfgConflict()
		configurations { "Debug", "Release" }
		test.isequal("obj/Debug",  result())
	end


--
-- If a conflict occurs between both build configurations and platforms,
-- both should be used to make unique.
--

	function suite.directoryIncludesBuildCfg_onPlatformAndBuildCfgConflict()
		configurations { "Debug", "Release" }
		platforms { "x32", "x64" }
		test.isequal("obj/x32/Debug",  result())
	end


--
-- If a conflict occurs between projects, the project name should be
-- used to make unique.
--

	function suite.directoryIncludesBuildCfg_onProjectConflict()
		configurations { "Debug", "Release" }
		project "MyProject2"
		test.isequal("obj/Debug/MyProject",  result())
	end

