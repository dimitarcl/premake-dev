--
-- tests/test_configs.lua
-- Automated test suite for the configuration building functions.
-- Copyright (c) 2009 Jason Perkins and the Premake project
--

	T.configs = { }

	local prj
	function T.configs.setup()
		solution "MySolution"
		configurations { "Debug", "Release" }
		platforms { "x32", "ps3" }
		
		defines "SOLUTION"
		
		configuration "Debug"
		defines "SOLUTION_DEBUG"
		
		prj = project "MyProject"
		language "C"
		kind "SharedLib"
		defines "PROJECT"
		
		configuration "Debug"
		defines "DEBUG"
		  
		configuration "Release"
		defines "RELEASE"

		configuration "native"
		defines "NATIVE"
		
		configuration "x32"
		defines "X86_32"
		
		configuration "x64"
		defines "X86_64"
		
		premake.buildconfigs()
	end
	

	function T.configs.SolutionFields()
		local cfg = premake.getconfig(prj)
		test.isequal("Debug:Release", table.concat(cfg.configurations,":"))
	end
	
	function T.configs.ProjectFields()
		local cfg = premake.getconfig(prj)
		test.isequal("C", cfg.language)
	end
	
	function T.configs.ProjectWideSettings()
		local cfg = premake.getconfig(prj)
		test.isequal("SOLUTION:PROJECT:NATIVE", table.concat(cfg.defines,":"))
	end
	
	function T.configs.BuildCfgSettings()
		local cfg = premake.getconfig(prj, "Debug")
		test.isequal("SOLUTION:SOLUTION_DEBUG:PROJECT:DEBUG:NATIVE", table.concat(cfg.defines,":"))
	end

	function T.configs.PlatformSettings()
		local cfg = premake.getconfig(prj, "Debug", "x32")
		test.isequal("SOLUTION:SOLUTION_DEBUG:PROJECT:DEBUG:X86_32", table.concat(cfg.defines,":"))
	end
			
	function T.configs.SetsConfigName()
		local cfg = premake.getconfig(prj, "Debug", "x32")
		test.isequal("Debug", cfg.name)
	end
	
	function T.configs.SetsPlatformName()
		local cfg = premake.getconfig(prj, "Debug", "x32")
		test.isequal("x32", cfg.platform)
	end
	
	function T.configs.SetsPlatformNativeName()
		local cfg = premake.getconfig(prj, "Debug")
		test.isequal("Native", cfg.platform)
	end
	
	function T.configs.SetsShortName()
		local cfg = premake.getconfig(prj, "Debug", "x32")
		test.isequal("debug32", cfg.shortname)
	end
	
	function T.configs.SetsNativeShortName()
		local cfg = premake.getconfig(prj, "Debug")
		test.isequal("debug", cfg.shortname)
	end
	
	function T.configs.SetsLongName()
		local cfg = premake.getconfig(prj, "Debug", "x32")
		test.isequal("Debug|x32", cfg.longname)
	end
	
	function T.configs.SetsNativeLongName()
		local cfg = premake.getconfig(prj, "Debug")
		test.isequal("Debug", cfg.longname)
	end
	
	function T.configs.SetsProject()
		local cfg = premake.getconfig(prj, "Debug", "x32")
		test.istrue(prj == cfg.project)
	end

--
-- Target system testing
--

	function T.configs.SetsTargetSystem_OnNative()
		local cfg = premake.getconfig(prj, "Debug")
		test.isequal(os.get(), cfg.system)
	end

	function T.configs.SetTargetSystem_OnCrossCompiler()
		local cfg = premake.getconfig(prj, "Debug", "PS3")
		test.isequal("PS3", cfg.system)
	end
	
--
-- Platform kind translation
--

	function T.configs.SetsTargetKind_OnSupportedKind()
		local cfg = premake.getconfig(prj, "Debug")
		test.isequal("SharedLib", cfg.kind)
	end

	function T.configs.SetsTargetKind_OnUnsupportedKind()
		local cfg = premake.getconfig(prj, "Debug", "PS3")
		test.isequal("StaticLib", cfg.kind)
	end
