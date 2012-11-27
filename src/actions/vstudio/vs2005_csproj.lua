--
-- vs2005_csproj.lua
-- Generate a Visual Studio 2005/2008 C# project.
-- Copyright (c) 2009-2012 Jason Perkins and the Premake project
--

	premake.vstudio.cs2005 = {}
	local vstudio = premake.vstudio
	local cs2005  = premake.vstudio.cs2005
	local project = premake5.project
	local config = premake5.config
	local dotnet = premake.tools.dotnet


--
-- Generate a Visual Studio 200x C# project, with support for the new platforms API.
--

	function cs2005.generate_ng(prj)
		io.eol = "\r\n"
		io.indent = "  "
		
		cs2005.projectelement(prj)
		cs2005.projectsettings(prj)

		for cfg in project.eachconfig(prj) do
			cs2005.propertyGroup(cfg)
			cs2005.debugProps(cfg)
			cs2005.outputProps(cfg)
			cs2005.compilerProps(cfg)		
			_p(1,'</PropertyGroup>')			
		end

		cs2005.assemblyReferences(prj)

		_p(1,'<ItemGroup>')
		cs2005.files(prj)
		_p(1,'</ItemGroup>')

		cs2005.projectReferences(prj)

		_p('  <Import Project="$(MSBuildBinPath)\\Microsoft.CSharp.targets" />')
		_p('  <!-- To modify your build process, add your task inside one of the targets below and uncomment it.')
		_p('       Other similar extension points exist, see Microsoft.Common.targets.')
		_p('  <Target Name="BeforeBuild">')
		_p('  </Target>')
		_p('  <Target Name="AfterBuild">')
		_p('  </Target>')
		_p('  -->')

		_p('</Project>')
	end


--
-- Write the opening <Project> element.
--

	function cs2005.projectelement(prj)
		local toolversion = {
			vs2005 = '',
			vs2008 = ' ToolsVersion="3.5"',
			vs2010 = ' ToolsVersion="4.0"',
			vs2012 = ' ToolsVersion="4.0"',
		}

		if _ACTION > "vs2008" then
			_p('<?xml version="1.0" encoding="utf-8"?>')
		end
		_p('<Project%s DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">', toolversion[_ACTION])
	end


--
-- Write the opening PropertyGroup, which contains the project-level settings.
--

	function cs2005.projectsettings(prj)
		local version = {
			vs2005 = '8.0.50727',
			vs2008 = '9.0.21022',
			vs2010 = '8.0.30703',
			vs2012 = '8.0.30703',
		}
		
		local frameworks = {
			vs2010 = "4.0",
			vs2012 = "4.5",
		}

		_p(1,'<PropertyGroup>')
		
		-- find the first configuration in the project, use as the default
		local cfg = project.getfirstconfig(prj)
		
		_p(2,'<Configuration Condition=" \'$(Configuration)\' == \'\' ">%s</Configuration>', premake.esc(cfg.buildcfg))
		_p(2,'<Platform Condition=" \'$(Platform)\' == \'\' ">%s</Platform>', cs2005.arch(prj))
		
		_p(2,'<ProductVersion>%s</ProductVersion>', version[_ACTION])
		_p(2,'<SchemaVersion>2.0</SchemaVersion>')
		_p(2,'<ProjectGuid>{%s}</ProjectGuid>', prj.uuid)
		
		_p(2,'<OutputType>%s</OutputType>', dotnet.getkind(cfg))
		_p(2,'<AppDesignerFolder>Properties</AppDesignerFolder>')

		local target = cfg.buildtarget
		_p(2,'<RootNamespace>%s</RootNamespace>', prj.namespace or target.basename)
		_p(2,'<AssemblyName>%s</AssemblyName>', target.basename)

		local framework = prj.framework or frameworks[_ACTION]
		if framework then
			_p(2,'<TargetFrameworkVersion>v%s</TargetFrameworkVersion>', framework)
		end

		if _ACTION >= "vs2010" then
			_p(2,'<TargetFrameworkProfile></TargetFrameworkProfile>')
			_p(2,'<FileAlignment>512</FileAlignment>')
		end
		
		_p(1,'</PropertyGroup>')
	end


--
-- Write out the source files item group.
--

	function cs2005.files(prj)
		local tr = project.getsourcetree(prj)
		premake.tree.traverse(tr, {
			onleaf = function(node, depth)

				-- Some settings applied at project level; can't be changed in cfg
				local cfg = project.getfirstconfig(prj)
				local filecfg = config.getfileconfig(cfg, node.abspath)

				local action = dotnet.getbuildaction(filecfg)
				local fname = path.translate(node.relpath)
				local elements, dependency = cs2005.getrelated(prj, filecfg, action)
				
				if elements == "None" then
					_p(2,'<%s Include="%s" />', action, fname)
				else
					_p(2,'<%s Include="%s">', action, fname)
					if elements == "AutoGen" then
						_p(3,'<AutoGen>True</AutoGen>')
					elseif elements == "AutoGenerated" then
						_p(3,'<SubType>Designer</SubType>')
						_p(3,'<Generator>ResXFileCodeGenerator</Generator>')
						_x(3,'<LastGenOutput>%s.Designer.cs</LastGenOutput>', path.getbasename(node.name))
					elseif elements == "PreserveNewest" then
						_p(3,'<CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>')
					elseif elements then
						_p(3,'<SubType>%s</SubType>', elements)
					end
					if dependency then
						dependency = project.getrelative(prj, dependency)
						_x(3,'<DependentUpon>%s</DependentUpon>', path.translate(dependency))
					end
					_p(2,'</%s>', action)
				end

			end
		}, false)
	end


--
-- Write the compiler flags for a particular configuration.
--

	function cs2005.compilerProps(cfg)
		_x(2,'<DefineConstants>%s</DefineConstants>', table.concat(cfg.defines, ";"))

		_p(2,'<ErrorReport>prompt</ErrorReport>')
		_p(2,'<WarningLevel>4</WarningLevel>')

		if cfg.flags.Unsafe then
			_p(2,'<AllowUnsafeBlocks>true</AllowUnsafeBlocks>')
		end
		
		if cfg.flags.FatalWarnings then
			_p(2,'<TreatWarningsAsErrors>true</TreatWarningsAsErrors>')
		end
	end


--
-- Write out the debugging and optimization flags for a configuration.
--

	function cs2005.debugProps(cfg)
		if cfg.flags.Symbols then
			_p(2,'<DebugSymbols>true</DebugSymbols>')
			_p(2,'<DebugType>full</DebugType>')
		else
			_p(2,'<DebugType>pdbonly</DebugType>')
		end
		_p(2,'<Optimize>%s</Optimize>', iif(premake.config.isoptimizedbuild(cfg), "true", "false"))
	end


--
-- Write out the target and intermediates settings for a configuration.
--

	function cs2005.outputProps(cfg)
		local outdir = project.getrelative(cfg.project, cfg.buildtarget.directory)
		_x(2,'<OutputPath>%s\\</OutputPath>', path.translate(outdir))
		
		-- Want to set BaseIntermediateOutputPath because otherwise VS will create obj/
		-- anyway. But VS2008 throws up ominous warning if present.
		local objdir = path.translate(project.getrelative(cfg.project, cfg.objdir))
		if _ACTION > "vs2008" then
			_x(2,'<BaseIntermediateOutputPath>%s\\</BaseIntermediateOutputPath>', objdir)
			_p(2,'<IntermediateOutputPath>$(BaseIntermediateOutputPath)</IntermediateOutputPath>')
		else
			_x(2,'<IntermediateOutputPath>%s\\</IntermediateOutputPath>', objdir)
		end
	end


--
-- Given a source file name, look for related elements and files. Pairs up
-- designer and resource files with their corresponding source files, and
-- vice versa.
--
-- @param prj
--    The current project, which contains the source file lists.
-- @param filecfg
--    The configuration of the file being generated.
-- @param action
--    The build action for the file under consideration.
--

	function cs2005.getrelated(prj, filecfg, action)
		local fname = filecfg.abspath
		if action == "Compile" and fname:endswith(".cs") then
			if fname:endswith(".Designer.cs") then
				local basename = fname:sub(1, -13)

				-- is there a matching *.cs file?
				local testname = basename .. ".cs"
				if project.hasfile(prj, testname) then
					return "Dependency", testname
				end
				
				-- is there a matching *.resx file
				testname = basename .. ".resx"
				if project.hasfile(prj, testname) then
					return "AutoGen", testname
				end
			else
				-- is there a matching *.Designer.cs?
				local basename = fname:sub(1, -4)
				testname = basename .. ".Designer.cs"
				if project.hasfile(prj, testname) then
					return "Form"
				end
				
				if filecfg.flags and filecfg.flags.Component then
					return "Component"
				end
			end
		end
		
		if action == "EmbeddedResource" and fname:endswith(".resx") then
			local basename = fname:sub(1, -6)

			-- is there a matching *.cs file?
			local testname = basename .. ".cs"
			if project.hasfile(prj, testname) then
				if project.hasfile(prj, basename .. ".Designer.cs") then
					return "DesignerType", testname
				else
					return "Dependency", testname
				end
			else
				-- is there a matching *.Designer.cs?
				testname = basename .. ".Designer.cs"
				if project.hasfile(prj, testname) then
					return "AutoGenerated"
				end
			end
		end
				
		if action == "Content" then
			return "PreserveNewest"
		end
		
		return "None"
	end


--
-- Write the list of assembly (system, or non-sibling) references.
--

	function cs2005.assemblyReferences(prj)
		_p(1,'<ItemGroup>')

		-- C# doesn't support per-configuration links (does it?) so just use
		-- the settings from the first available config instead
		local links = config.getlinks(project.getfirstconfig(prj), "system", "fullpath")
		for _, link in ipairs(links) do
			if link:find("/", nil, true) then
				_x(2,'<Reference Include="%s">', path.getbasename(link))
				_x(3,'<HintPath>%s</HintPath>', path.translate(link))
				_p(2,'</Reference>')
			else
				_x(2,'<Reference Include="%s" />', path.getbasename(link))
			end
		end
	
		_p(1,'</ItemGroup>')
	end

	
--
-- Write the list of project dependencies.
--
	function cs2005.projectReferences(prj)
		_p(1,'<ItemGroup>')

		local deps = project.getdependencies(prj)
		if #deps > 0 then
			local prjpath = project.getlocation(prj)			
			for _, dep in ipairs(deps) do
				local relpath = path.getrelative(prjpath, vstudio.projectfile(dep))
				_x(2,'<ProjectReference Include="%s">', path.translate(relpath))
				_p(3,'<Project>{%s}</Project>', dep.uuid)
				_x(3,'<Name>%s</Name>', dep.name)
				_p(2,'</ProjectReference>')
			end
		end
	
		_p(1,'</ItemGroup>')
	end


--
-- Return the Visual Studio architecture identification string. The logic
-- to select this is getting more complicated in VS2010, but I haven't 
-- tackled all the permutations yet.
--

	function cs2005.arch(cfg)
		local arch = vstudio.archFromConfig(cfg)
		if arch == "Any CPU" then
			arch = "AnyCPU"
		end
		return arch
	end


--
-- Write the PropertyGroup element for a specific configuration block.
--

	function cs2005.propertyGroup(cfg)
		local arch = cs2005.arch(cfg)
		_x(1,'<PropertyGroup Condition=" \'$(Configuration)|$(Platform)\' == \'%s|%s\' ">', cfg.buildcfg, arch)
		if arch ~= "AnyCPU" or _ACTION > "vs2008" then
			_x(2,'<PlatformTarget>%s</PlatformTarget>', arch)
		end
	end
