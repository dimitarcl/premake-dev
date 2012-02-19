--
-- tests/solution/test_eachconfig.lua
-- Automated test suite for the solution-level configuration iterator.
-- Copyright (c) 2012 Jason Perkins and the Premake project
--

	T.solution_eachconfig = { }
	local suite = T.solution_eachconfig


--
-- Setup and teardown
--

	local sln
	function suite.setup()
		sln = solution("MySolution") 
	end

	local function prepare()
		for cfg in premake.solution.eachconfig(sln) do
			_p(2, "%s:%s", cfg.buildcfg or "", cfg.platform or "")
		end
	end


--
-- All configurations listed at the solution level should be enumerated.
--

	function suite.listsBuildConfigurations_onSolutionLevel()
		configurations { "Debug", "Release" }
		prepare()
		test.capture [[
		Debug:
		Release:
		]]
	end


--
-- Iteration order should be build configurations, then platforms.
--

	function suite.listsInOrder_onBuildConfigsAndPlatforms()
		configurations { "Debug", "Release" }
		platforms { "x32", "x64" }
		prepare()
		test.capture [[
		Debug:x32
		Debug:x64
		Release:x32
		Release:x64
		]]
	end


--
-- Project-level configurations should be included in the list.
--

	function suite.listsBuildConfigurations_onProjectLevel()
		project("MyProject")
		configurations { "Debug", "Release" }
		platforms { "x32", "x64" }
		prepare()
		test.capture [[
		Debug:x32
		Debug:x64
		Release:x32
		Release:x64
		]]
	end
