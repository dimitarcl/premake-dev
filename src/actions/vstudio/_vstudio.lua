--
-- _vstudio.lua
-- Define the Visual Studio 200x actions.
-- Copyright (c) 2008-2009 Jason Perkins and the Premake project
--

	_VS = { }


--
-- Map Premake platform identifiers to the Visual Studio versions. Adds the Visual
-- Studio specific "any" and "mixed" to make solution generation easier.
--

	premake.vstudio_platforms = { 
		any     = "Any CPU", 
		mixed   = "Mixed Platforms", 
		Native  = "Win32",
		x32     = "Win32", 
		x64     = "x64",
		PS3     = "PS3",
		Xbox360 = "Xbox 360",
	}

	

--
-- Returns the architecture identifier for a project.
--

	function _VS.arch(prj)
		if (prj.language == "C#") then
			if (_ACTION < "vs2005") then
				return ".NET"
			else
				return "Any CPU"
			end
		else
			return "Win32"
		end
	end
	
	

--
-- Return the version-specific text for a boolean value.
-- (this should probably go in vs200x_vcproj.lua)
--

	function _VS.bool(value)
		if (_ACTION < "vs2005") then
			return iif(value, "TRUE", "FALSE")
		else
			return iif(value, "true", "false")
		end
	end


--
-- Process the solution's list of configurations and platforms, creates a list
-- of build configuration/platform pairs in a Visual Studio compatible format.
--
-- @param sln
--    The solution containing the configuration and platform lists.
-- @param with_pseudo
--    If true, Visual Studio's "Any CPU" and "Mixed Platforms" platforms will
--    be added for .NET and mixed mode solutions.
--

--
-- Process the solution's list of configurations and platforms, creates a list
-- of build configuration/platform pairs in a Visual Studio compatible format.
--
-- @param sln
--    The solution containing the configuration and platform lists.
--

	function premake.vstudio_buildconfigs(sln)
		local cfgs = { }
		
		local platforms = premake.filterplatforms(sln, premake.vstudio_platforms, "Native")

		-- .NET projects add "Any CPU", mixed mode solutions add "Mixed Platforms"
		local hascpp    = premake.hascppproject(sln)
		local hasdotnet = premake.hasdotnetproject(sln)
		if hasdotnet then
			table.insert(platforms, 1, "any")
		end
		if hasdotnet and hascpp then
			table.insert(platforms, 2, "mixed")
		end
		
		for _, buildcfg in ipairs(sln.configurations) do
			for _, platform in ipairs(platforms) do
				local entry = { }
				entry.src_buildcfg = buildcfg
				entry.src_platform = platform
				
				-- PS3 is funky and needs special handling; it's more of a build
				-- configuration than a platform from Visual Studio's point of view				
				if platform ~= "PS3" then
					entry.buildcfg = buildcfg
					entry.platform = premake.vstudio_platforms[platform]
				else
					entry.buildcfg = platform .. " " .. buildcfg
					entry.platform = "Win32"
				end
				
				-- create a name the way VS likes it
				entry.name = entry.buildcfg .. "|" .. entry.platform
				
				-- flag the "fake" platforms added for .NET
				entry.isreal = (platform ~= "any" and platform ~= "mixed")
				
				table.insert(cfgs, entry)
			end
		end
		
		return cfgs
	end
	


--
-- Return a configuration type index.
-- (this should probably go in vs200x_vcproj.lua)
--

	function _VS.cfgtype(cfg)
		if (cfg.kind == "SharedLib") then
			return 2
		elseif (cfg.kind == "StaticLib") then
			return 4
		else
			return 1
		end
	end
	
	

--
-- Clean Visual Studio files
--

	function premake.vstudio_clean(solutions, projects, targets)
		for _,name in ipairs(solutions) do
			os.remove(name .. ".suo")
			os.remove(name .. ".ncb")
			os.remove(name .. ".userprefs")  -- MonoDevelop files
			os.remove(name .. ".usertasks")
		end
		
		for _,name in ipairs(projects) do
			os.remove(name .. ".csproj.user")
			os.remove(name .. ".csproj.webinfo")
		
			local files = os.matchfiles(name .. ".vcproj.*.user", name .. ".csproj.*.user")
			for _, fname in ipairs(files) do
				os.remove(fname)
			end
		end
		
		for _,name in ipairs(targets) do
			os.remove(name .. ".pdb")
			os.remove(name .. ".idb")
			os.remove(name .. ".ilk")
			os.remove(name .. ".vshost.exe")
			os.remove(name .. ".exe.manifest")
		end		
	end
	
	

--
-- Write out entries for the files element; called from premake.walksources().
-- (this should probably go in vs200x_vcproj.lua)
--

	local function output(indent, value)
		-- io.write(indent .. value .. "\r\n")
		_p(indent .. value)
	end
	
	local function attrib(indent, name, value)
		-- io.write(indent .. "\t" .. name .. '="' .. value .. '"\r\n')
		_p(indent .. "\t" .. name .. '="' .. value .. '"')
	end
	
	function _VS.files(prj, fname, state, nestlevel)
		local indent = string.rep("\t", nestlevel + 2)
		
		if (state == "GroupStart") then
			output(indent, "<Filter")
			attrib(indent, "Name", path.getname(fname))
			attrib(indent, "Filter", "")
			output(indent, "\t>")

		elseif (state == "GroupEnd") then
			output(indent, "</Filter>")

		else
			output(indent, "<File")
			attrib(indent, "RelativePath", path.translate(fname, "\\"))
			output(indent, "\t>")
			if (not prj.flags.NoPCH and prj.pchsource == fname) then
				for _, cfginfo in ipairs(prj.solution.vstudio_configs) do
					if cfginfo.isreal then
						local cfg = premake.getconfig(prj, cfginfo.src_buildcfg, cfginfo.src_platform)
						output(indent, "\t<FileConfiguration")
						attrib(indent, "\tName", cfginfo.name)
						output(indent, "\t\t>")
						output(indent, "\t\t<Tool")
						attrib(indent, "\t\tName", iif(cfg.system == "Xbox360", "VCCLX360CompilerTool", "VCCLCompilerTool"))
						attrib(indent, "\t\tUsePrecompiledHeader", "1")
						output(indent, "\t\t/>")
						output(indent, "\t</FileConfiguration>")
					end
				end
			end
			output(indent, "</File>")
		end
	end
	
	
	
--
-- Return the optimization code.
-- (this should probably go in vs200x_vcproj.lua)
--

	function _VS.optimization(cfg)
		local result = 0
		for _, value in ipairs(cfg.flags) do
			if (value == "Optimize") then
				result = 3
			elseif (value == "OptimizeSize") then
				result = 1
			elseif (value == "OptimizeSpeed") then
				result = 2
			end
		end
		return result
	end



--
-- Assemble the project file name.
--

	function _VS.projectfile(prj)
		local extension
		if (prj.language == "C#") then
			extension = ".csproj"
		else
			extension = ".vcproj"
		end

		local fname = path.join(prj.location, prj.name)
		return fname..extension
	end
	
	

-- 
-- Returns the runtime code for a configuration.
-- (this should probably go in vs200x_vcproj.lua)
--

	function _VS.runtime(cfg)
		local debugbuild = (_VS.optimization(cfg) == 0)
		if (cfg.flags.StaticRuntime) then
			return iif(debugbuild, 1, 0)
		else
			return iif(debugbuild, 3, 2)
		end
	end



--
-- Returns the Visual Studio tool ID for a given project type.
--

	function _VS.tool(prj)
		if (prj.language == "C#") then
			return "FAE04EC0-301F-11D3-BF4B-00C04F79EFBC"
		else
			return "8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942"
		end
	end
	
	
	

--
-- Register the Visual Studio command line actions
--

	newaction {
		trigger         = "vs2002",
		shortname       = "Visual Studio 2002",
		description     = "Microsoft Visual Studio 2002",
		os              = "windows",
		
		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++", "C#" },
		
		valid_tools     = {
			cc     = { "msc"   },
			dotnet = { "msnet" },
		},

		solutiontemplates = {
			{ ".sln",         premake.vs2002_solution },
		},

		projecttemplates = {
			{ ".vcproj",      premake.vs200x_vcproj, function(this) return this.language ~= "C#" end },
			{ ".csproj",      premake.vs2002_csproj, function(this) return this.language == "C#" end },
			{ ".csproj.user", premake.vs2002_csproj_user, function(this) return this.language == "C#" end },
		},
		
		onclean = premake.vstudio_clean,
	}

	newaction {
		trigger         = "vs2003",
		shortname       = "Visual Studio 2003",
		description     = "Microsoft Visual Studio 2003",
		os              = "windows",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++", "C#" },
		
		valid_tools     = {
			cc     = { "msc"   },
			dotnet = { "msnet" },
		},

		solutiontemplates = {
			{ ".sln",         premake.vs2003_solution },
		},

		projecttemplates = {
			{ ".vcproj",      premake.vs200x_vcproj, function(this) return this.language ~= "C#" end },
			{ ".csproj",      premake.vs2002_csproj, function(this) return this.language == "C#" end },
			{ ".csproj.user", premake.vs2002_csproj_user, function(this) return this.language == "C#" end },
		},
		
		onclean = premake.vstudio_clean,
	}

	newaction {
		trigger         = "vs2005",
		shortname       = "Visual Studio 2005",
		description     = "Microsoft Visual Studio 2005 (SharpDevelop, MonoDevelop)",
		os              = "windows",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++", "C#" },
		
		valid_tools     = {
			cc     = { "msc"   },
			dotnet = { "msnet" },
		},

		solutiontemplates = {
			{ ".sln",         premake.vs2005_solution },
		},

		projecttemplates = {
			{ ".vcproj",      premake.vs200x_vcproj, function(this) return this.language ~= "C#" end },
			{ ".csproj",      premake.vs2005_csproj, function(this) return this.language == "C#" end },
			{ ".csproj.user", premake.vs2005_csproj_user, function(this) return this.language == "C#" end },
		},
		
		onclean = premake.vstudio_clean,
	}

	newaction {
		trigger         = "vs2008",
		shortname       = "Visual Studio 2008",
		description     = "Microsoft Visual Studio 2008",
		os              = "windows",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		
		valid_languages = { "C", "C++", "C#" },
		
		valid_tools     = {
			cc     = { "msc"   },
			dotnet = { "msnet" },
		},

		solutiontemplates = {
			{ ".sln",         premake.vs2005_solution },
		},

		projecttemplates = {
			{ ".vcproj",      premake.vs200x_vcproj, function(this) return this.language ~= "C#" end },
			{ ".csproj",      premake.vs2005_csproj, function(this) return this.language == "C#" end },
			{ ".csproj.user", premake.vs2005_csproj_user, function(this) return this.language == "C#" end },
		},
		
		onclean = premake.vstudio_clean,
	}
