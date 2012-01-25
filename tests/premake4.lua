--
-- tests/premake4.lua
-- Automated test suite for Premake 4.x
-- Copyright (c) 2008-2011 Jason Perkins and the Premake project
--

	dofile("testfx.lua")

--
-- Some helper functions
--

	test.createsolution = function()
		local sln = solution "MySolution"
		configurations { "Debug", "Release" }

		local prj = project "MyProject"
		language "C++"
		kind "ConsoleApp"

		return sln, prj
	end


	test.createproject = function(sln)
		local n = #sln.projects + 1
		if n == 1 then n = "" end

		local prj = project ("MyProject" .. n)
		language "C++"
		kind "ConsoleApp"
		return prj
	end


--
-- The test suites
--

	-- Base API tests
	dofile("test_dofile.lua")
	dofile("test_string.lua")
	dofile("test_premake.lua")
	dofile("test_platforms.lua")
	dofile("test_keywords.lua")
	dofile("test_gmake_cpp.lua")
	dofile("test_gmake_cs.lua")
	dofile("base/test_api.lua")
	dofile("base/test_action.lua")
	dofile("base/test_config.lua")
	dofile("base/test_include.lua")
	dofile("base/test_location.lua")
	dofile("base/test_os.lua")
	dofile("base/test_path.lua")
	dofile("base/test_table.lua")
	dofile("base/test_tree.lua")
	dofile("tools/test_gcc.lua")
	dofile("base/test_config_bug.lua")

	-- Project object tests
	dofile("test_project.lua")
	dofile("project/test_baking.lua")
	dofile("project/test_eachconfig.lua")
	dofile("project/test_eachfile.lua")
	dofile("project/test_filtering.lua")
	dofile("project/test_getconfig.lua")
	dofile("project/test_vpaths.lua")

	-- Configuration object tests
	dofile("config/test_linkinfo.lua")
	dofile("config/test_links.lua")
	dofile("config/test_objdir.lua")
	dofile("config/test_targetinfo.lua")

	-- Baking tests
	dofile("base/test_baking.lua")

	-- Clean tests
	dofile("actions/test_clean.lua")

	-- Visual Studio tests
	dofile("test_vs2002_sln.lua")
	dofile("test_vs2003_sln.lua")
	dofile("actions/vstudio/test_vs2010_vcxproj.lua")
	dofile("actions/vstudio/test_vs2010_flags.lua")
	dofile("actions/vstudio/test_vs2010_project_kinds.lua")

	-- Visual Studio 2002-2003 C# projects
	dofile("actions/vstudio/cs2002/files.lua")

	-- Visual Studio 2005-2010 C# projects
	dofile("actions/vstudio/cs2005/files.lua")
	dofile("actions/vstudio/cs2005/projectelement.lua")
	dofile("actions/vstudio/cs2005/projectsettings.lua")
	dofile("actions/vstudio/cs2005/propertygroup.lua")

	-- Visual Studio 2005-2010 solutions
	dofile("actions/vstudio/sln2005/test_dependencies.lua")
	dofile("actions/vstudio/sln2005/test_header.lua")
	dofile("actions/vstudio/sln2005/platforms.lua")
	dofile("actions/vstudio/sln2005/projectplatforms.lua")
	dofile("actions/vstudio/sln2005/test_projects.lua")
	dofile("actions/vstudio/sln2005/test_project_platforms.lua")
	dofile("actions/vstudio/sln2005/test_solution_platforms.lua")

	-- Visual Studio 2002-2008 C/C++ projects
	dofile("actions/vstudio/vc200x/test_compiler_block.lua")
	dofile("actions/vstudio/vc200x/test_debug_settings.lua")
	dofile("actions/vstudio/vc200x/test_configuration.lua")
	dofile("actions/vstudio/vc200x/test_files.lua")
	dofile("actions/vstudio/vc200x/test_filters.lua")
	dofile("actions/vstudio/vc200x/test_linker_block.lua")
	dofile("actions/vstudio/vc200x/test_manifest_block.lua")
	dofile("actions/vstudio/vc200x/test_mfc.lua")
	dofile("actions/vstudio/vc200x/test_platforms.lua")
	dofile("actions/vstudio/vc200x/test_project.lua")

	-- Visual Studio 2010 C/C++ projects
	dofile("actions/vstudio/vc2010/test_compile_settings.lua")
	dofile("actions/vstudio/vc2010/test_debugdir.lua")
	dofile("actions/vstudio/vc2010/test_header.lua")
	dofile("actions/vstudio/vc2010/test_files.lua")
	dofile("actions/vstudio/vc2010/test_filters.lua")
	dofile("actions/vstudio/vc2010/test_link_settings.lua")
	dofile("actions/vstudio/vc2010/test_links.lua")
	dofile("actions/vstudio/vc2010/test_mfc.lua")
	dofile("actions/vstudio/vc2010/test_pch.lua")

	-- Makefile tests
	dofile("actions/make/test_make_escaping.lua")
	dofile("actions/make/test_make_pch.lua")
	dofile("actions/make/test_make_linking.lua")
	-- dofile("actions/make/test_makesettings.lua")
	dofile("actions/make/test_wiidev.lua")

	-- Xcode3 tests
	dofile("actions/xcode/test_file_references.lua")
	dofile("actions/xcode/test_xcode_common.lua")
	dofile("actions/xcode/test_xcode_project.lua")
	dofile("actions/xcode/test_xcode_dependencies.lua")

	-- Xcode4 tests
	dofile("actions/xcode/test_xcode4_project.lua")
	dofile("actions/xcode/test_xcode4_workspace.lua")

	-- CodeLite tests
	dofile("actions/codelite/codelite_files.lua")

	-- CodeBlocks tests
	dofile("actions/codeblocks/codeblocks_files.lua")
	dofile("actions/codeblocks/test_filters.lua")
	dofile("actions/codeblocks/environment_variables.lua")

--
-- Register a test action
--

	newaction {
		trigger     = "test",
		description = "Run the automated test suite",

		execute = function ()
			passed, failed = test.runall()
			msg = string.format("%d tests passed, %d failed", passed, failed)
			if (failed > 0) then
				error(msg, 0)
			else
				print(msg)
			end
		end
	}
