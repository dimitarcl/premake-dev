--
-- vs2010_vcxproj.lua
-- Generate a Visual Studio 201x C/C++ project.
-- Copyright (c) 2009-2012 Jason Perkins and the Premake project
--

	premake.vstudio.vc2010 = {}
	local vc2010 = premake.vstudio.vc2010
	local vstudio = premake.vstudio
	local project = premake5.project
	local config = premake5.config
	local tree = premake.tree


--
-- Generate a Visual Studio 201x C++ project, with support for the new platforms API.
--

	function vc2010.generate_ng(prj)
		io.eol = "\r\n"
		io.indent = "  "

		vc2010.header_ng("Build")
		vc2010.projectConfigurations(prj)
		vc2010.globals(prj)

		_p(1,'<Import Project="$(VCTargetsPath)\\Microsoft.Cpp.Default.props" />')

		for cfg in project.eachconfig(prj) do
			vc2010.configurationProperties(cfg)
		end

		_p(1,'<Import Project="$(VCTargetsPath)\\Microsoft.Cpp.props" />')
		_p(1,'<ImportGroup Label="ExtensionSettings">')
		_p(1,'</ImportGroup>')

		for cfg in project.eachconfig(prj) do
			vc2010.propertySheet(cfg)
		end

		_p(1,'<PropertyGroup Label="UserMacros" />')

		for cfg in project.eachconfig(prj) do
			vc2010.outputProperties(cfg)
		end

		for cfg in project.eachconfig(prj) do
			_p(1,'<ItemDefinitionGroup %s>', vc2010.condition(cfg))
			vc2010.clCompile(cfg)
			vc2010.resourceCompile(cfg)
			vc2010.link(cfg)
			vc2010.buildEvents(cfg)
			_p(1,'</ItemDefinitionGroup>')
		end

		vc2010.files_ng(prj)
		vc2010.projectReferences_ng(prj)

		_p(1,'<Import Project="$(VCTargetsPath)\\Microsoft.Cpp.targets" />')
		_p(1,'<ImportGroup Label="ExtensionTargets">')
		_p(1,'</ImportGroup>')
		_p('</Project>')
	end



--
-- Output the XML declaration and opening <Project> tag.
--

	function vc2010.header_ng(target)
		_p('<?xml version="1.0" encoding="utf-8"?>')

		local defaultTargets = ""
		if target then
			defaultTargets = string.format(' DefaultTargets="%s"', target)
		end

		_p('<Project%s ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">', defaultTargets)
	end


--
-- Write out the list of project configurations, which pairs build
-- configurations with architectures.
--

	function vc2010.projectConfigurations(prj)
		-- build a list of all architectures used in this project
		local platforms = {}
		for cfg in project.eachconfig(prj) do
			local arch = vstudio.archFromConfig(cfg, true)
			if not table.contains(platforms, arch) then
				table.insert(platforms, arch)
			end
		end
	
		local configs = {}
		_p(1,'<ItemGroup Label="ProjectConfigurations">')
		for cfg in project.eachconfig(prj) do
			for _, arch in ipairs(platforms) do
				local prjcfg = vstudio.projectConfig(cfg, arch)
				if not configs[prjcfg] then
					configs[prjcfg] = prjcfg
					_x(2,'<ProjectConfiguration Include="%s">', vstudio.projectConfig(cfg, arch))
					_x(3,'<Configuration>%s</Configuration>', vstudio.projectPlatform(cfg))
					_p(3,'<Platform>%s</Platform>', arch)
					_p(2,'</ProjectConfiguration>')
				end
			end
		end
		_p(1,'</ItemGroup>')
	end


--
-- Write out the Globals property group.
--

	function vc2010.globals(prj)
		_p(1,'<PropertyGroup Label="Globals">')
		_p(2,'<ProjectGuid>{%s}</ProjectGuid>', prj.uuid)
				
		-- flags are located on the configurations; grab one
		local cfg = project.getconfig(prj, prj.configurations[1], prj.platforms[1])		
		
		if cfg.flags.Managed then
			_p(2,'<TargetFrameworkVersion>v4.0</TargetFrameworkVersion>')
			_p(2,'<Keyword>ManagedCProj</Keyword>')
		else
			_p(2,'<Keyword>Win32Proj</Keyword>')
		end
		
		if _ACTION == "vs2012" then
			_p(2,[[<VCTargetsPath Condition="'$(VCTargetsPath11)' != '' and '$(VSVersion)' == '' and '$(VisualStudioVersion)' == ''">$(VCTargetsPath11)</VCTargetsPath>]])
		end

		_p(2,'<RootNamespace>%s</RootNamespace>', prj.name)
		_p(1,'</PropertyGroup>')
	end


--
-- Write out the configuration property group: what kind of binary it 
-- produces, and some global settings.
--

	function vc2010.configurationProperties(cfg)
		_p(1,'<PropertyGroup %s Label="Configuration">', vc2010.condition(cfg))
		_p(2,'<ConfigurationType>%s</ConfigurationType>', vc2010.config_type(cfg))
		_p(2,'<UseDebugLibraries>%s</UseDebugLibraries>', tostring(premake.config.isdebugbuild(cfg)))

		if _ACTION == "vs2012" then
			_p(2,'<PlatformToolset>v110</PlatformToolset>')
		end
		
		if cfg.flags.MFC then
			_p(2,'<UseOfMfc>%s</UseOfMfc>', iif(cfg.flags.StaticRuntime, "Static", "Dynamic"))
		end

		if cfg.flags.Managed then
			_p(2,'<CLRSupport>true</CLRSupport>')
		end

		_p(2,'<CharacterSet>%s</CharacterSet>', iif(cfg.flags.Unicode, "Unicode", "MultiByte"))
		_p(1,'</PropertyGroup>')
	end


--
-- Write out the default property sheets for a configuration.
--

	function vc2010.propertySheet(cfg)
		_p(1,'<ImportGroup Label="PropertySheets" %s>', vc2010.condition(cfg))
		_p(2,'<Import Project="$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props" Condition="exists(\'$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props\')" Label="LocalAppDataPlatform" />')
		_p(1,'</ImportGroup>')
	end


--
-- Write the output property group, which  includes the output and intermediate 
-- directories, manifest, etc.
--

	function vc2010.outputProperties(cfg)
		local target = cfg.buildtarget

		_p(1,'<PropertyGroup %s>', vc2010.condition(cfg))

		if cfg.kind ~= premake.STATICLIB then
			_p(2,'<LinkIncremental>%s</LinkIncremental>', tostring(premake.config.canincrementallink(cfg)))
		end

		if cfg.kind == premake.SHAREDLIB and cfg.flags.NoImportLib then
			_p(2,'<IgnoreImportLibrary>true</IgnoreImportLibrary>');
		end

		local outdir = project.getrelative(cfg.project, target.directory)
		_x(2,'<OutDir>%s\\</OutDir>', path.translate(outdir))

		if cfg.system == premake.XBOX360 then
			_x(2,'<OutputFile>$(OutDir)%s</OutputFile>', target.name)
		end

		local objdir = project.getrelative(cfg.project, cfg.objdir)
		_x(2,'<IntDir>%s\\</IntDir>', path.translate(objdir))

		_x(2,'<TargetName>%s%s</TargetName>', target.prefix, target.basename)
		_x(2,'<TargetExt>%s</TargetExt>', target.extension)

		if cfg.flags.NoManifest then
			_p(2,'<GenerateManifest>false</GenerateManifest>')
		end

		_p(1,'</PropertyGroup>')
	end


--
-- Write the the <ClCompile> compiler settings block.
--

	function vc2010.clCompile(cfg)
		_p(2,'<ClCompile>')

		if not cfg.flags.NoPCH and cfg.pchheader then
			_p(3,'<PrecompiledHeader>Use</PrecompiledHeader>')
			_x(3,'<PrecompiledHeaderFile>%s</PrecompiledHeaderFile>', path.getname(cfg.pchheader))
		else
			_p(3,'<PrecompiledHeader>NotUsing</PrecompiledHeader>')
		end

        vc2010.warnings(cfg)
		vc2010.preprocessorDefinitions(cfg.defines)
		vc2010.additionalIncludeDirectories(cfg, cfg.includedirs)

		if #cfg.forceincludes > 0 then
			local includes = project.getrelative(cfg.project, cfg.forceincludes)
			_x(3,'<ForcedIncludeFiles>%s</ForcedIncludeFiles>', table.concat(includes, ';'))
		end

		vc2010.debuginfo(cfg)

		if cfg.flags.Symbols and cfg.debugformat ~= "c7" then
			local filename = cfg.buildtarget.basename
			_p(3,'<ProgramDataBaseFileName>$(OutDir)%s.pdb</ProgramDataBaseFileName>', filename)
		end

		_p(3,'<Optimization>%s</Optimization>', vc2010.optimization(cfg))

		if premake.config.isoptimizedbuild(cfg) then
			_p(3,'<FunctionLevelLinking>true</FunctionLevelLinking>')
			_p(3,'<IntrinsicFunctions>true</IntrinsicFunctions>')
		end

		local minimalRebuild = not premake.config.isoptimizedbuild(cfg) and
		                       not cfg.flags.NoMinimalRebuild and
							   cfg.debugformat ~= premake.C7
		if not minimalRebuild then
			_p(3,'<MinimalRebuild>false</MinimalRebuild>')
		end

		if cfg.flags.NoFramePointer then
			_p(3,'<OmitFramePointers>true</OmitFramePointers>')
		end

		if premake.config.isoptimizedbuild(cfg) then
			_p(3,'<StringPooling>true</StringPooling>')
		end

		if cfg.flags.StaticRuntime then
			_p(3,'<RuntimeLibrary>%s</RuntimeLibrary>', iif(premake.config.isdebugbuild(cfg), "MultiThreadedDebug", "MultiThreaded"))
		end

		if cfg.flags.NoExceptions then
			_p(3,'<ExceptionHandling>false</ExceptionHandling>')
		elseif cfg.flags.SEH then
			_p(3,'<ExceptionHandling>Async</ExceptionHandling>')
		end

		if cfg.flags.NoRTTI and not cfg.flags.Managed then
			_p(3,'<RuntimeTypeInfo>false</RuntimeTypeInfo>')
		end

		if cfg.flags.NativeWChar then
			_p(3,'<TreatWChar_tAsBuiltInType>true</TreatWChar_tAsBuiltInType>')
		elseif cfg.flags.NoNativeWChar then
			_p(3,'<TreatWChar_tAsBuiltInType>false</TreatWChar_tAsBuiltInType>')
		end

		if cfg.flags.FloatFast then
			_p(3,'<FloatingPointModel>Fast</FloatingPointModel>')
		elseif cfg.flags.FloatStrict and not cfg.flags.Managed then
			_p(3,'<FloatingPointModel>Strict</FloatingPointModel>')
		end

		if cfg.flags.EnableSSE2 then
			_p(3,'<EnableEnhancedInstructionSet>StreamingSIMDExtensions2</EnableEnhancedInstructionSet>')
		elseif cfg.flags.EnableSSE then
			_p(3,'<EnableEnhancedInstructionSet>StreamingSIMDExtensions</EnableEnhancedInstructionSet>')
		end

		if #cfg.buildoptions > 0 then
			local options = table.concat(cfg.buildoptions, " ")
			_x(3,'<AdditionalOptions>%s %%(AdditionalOptions)</AdditionalOptions>', options)
		end

		if cfg.project.language == "C" then
			_p(3,'<CompileAs>CompileAsC</CompileAs>')
		end

		_p(2,'</ClCompile>')
	end


--
-- Write out the resource compiler block.
--

	function vc2010.resourceCompile(cfg)
		_p(2,'<ResourceCompile>')
		vc2010.preprocessorDefinitions(table.join(cfg.defines, cfg.resdefines))
		vc2010.additionalIncludeDirectories(cfg, table.join(cfg.includedirs, cfg.resincludedirs))
		_p(2,'</ResourceCompile>')
	end


--
-- Write out the linker tool block.
--

	function vc2010.link(cfg)
		local explicit = vstudio.needsExplicitLink(cfg)

		_p(2,'<Link>')

		local subsystem = iif(cfg.kind == premake.CONSOLEAPP, "Console", "Windows")
		_p(3,'<SubSystem>%s</SubSystem>', subsystem)

		_p(3,'<GenerateDebugInformation>%s</GenerateDebugInformation>', tostring(cfg.flags.Symbols ~= nil))

		if premake.config.isoptimizedbuild(cfg) then
			_p(3,'<EnableCOMDATFolding>true</EnableCOMDATFolding>')
			_p(3,'<OptimizeReferences>true</OptimizeReferences>')
		end

		if cfg.kind ~= premake.STATICLIB then
			vc2010.link_dynamic(cfg, explicit)
		end

		_p(2,'</Link>')

		if cfg.kind == premake.STATICLIB then
			vc2010.link_static(cfg)
		end

		-- Left to its own devices, VS will happily link against a project dependency
		-- that has been excluded from the build. As a workaround, disable dependency
		-- linking and list all siblings explicitly
		if explicit then
			_p(2,'<ProjectReference>')
			_p(3,'<LinkLibraryDependencies>false</LinkLibraryDependencies>')
			_p(2,'</ProjectReference>')
		end
	end

	function vc2010.link_dynamic(cfg, explicit)
		vc2010.additionalDependencies(cfg, explicit)
		vc2010.additionalLibraryDirectories(cfg)

		if cfg.kind == premake.SHAREDLIB then
			_x(3,'<ImportLibrary>%s</ImportLibrary>', path.translate(cfg.linktarget.relpath))
		end

		if vc2010.config_type(cfg) == "Application" and not cfg.flags.WinMain and not cfg.flags.Managed then
			_p(3,'<EntryPointSymbol>mainCRTStartup</EntryPointSymbol>')
		end

		vc2010.additionalLinkOptions(cfg)
	end

	function vc2010.link_static(cfg)
		_p(2,'<Lib>')
		vc2010.additionalLinkOptions(cfg)
		_p(2,'</Lib>')
	end


--
-- Write out the pre- and post-build event settings.
--

	function vc2010.buildEvents(cfg)
		function write(group, list)			
			if #list > 0 then
				_p(2,'<%s>', group)
				_x(3,'<Command>%s</Command>', table.implode(list, "", "", "\r\n"))
				_p(2,'</%s>', group)
			end
		end
		write("PreBuildEvent", cfg.prebuildcommands)
		write("PreLinkEvent", cfg.prelinkcommands)
		write("PostBuildEvent", cfg.postbuildcommands)
	end


--
-- Write out the list of source code files, and any associated configuration.
--

	function vc2010.files_ng(prj)
		vc2010.simplefilesgroup_ng(prj, "ClInclude")
		vc2010.compilerfilesgroup_ng(prj)
		vc2010.simplefilesgroup_ng(prj, "None")
		vc2010.simplefilesgroup_ng(prj, "ResourceCompile")
		vc2010.customBuildFilesGroup(prj)
	end

	function vc2010.simplefilesgroup_ng(prj, group)
		local files = vc2010.getfilegroup_ng(prj, group)
		if #files > 0  then
			_p(1,'<ItemGroup>')
			for _, file in ipairs(files) do
				_x(2,'<%s Include=\"%s\" />', group, path.translate(file.relpath))
			end
			_p(1,'</ItemGroup>')
		end
	end

	function vc2010.compilerfilesgroup_ng(prj)
		local files = vc2010.getfilegroup_ng(prj, "ClCompile")
		if #files > 0  then
			_p(1,'<ItemGroup>')
			for _, file in ipairs(files) do
				_x(2,'<ClCompile Include=\"%s\">', path.translate(file.relpath))
				for cfg in project.eachconfig(prj) do
					local condition = vc2010.condition(cfg)
					
					local filecfg = config.getfileconfig(cfg, file.abspath)
					if not filecfg then
						_p(3,'<ExcludedFromBuild %s>true</ExcludedFromBuild>', condition)
					end
					
					local objectname = project.getfileobject(prj, file.abspath)
					if objectname ~= path.getbasename(file.abspath) then
						_p(3,'<ObjectFileName %s>$(IntDir)\\%s.obj</ObjectFileName>', condition, objectname)
					end
					
					if cfg.pchsource == file.abspath and not cfg.flags.NoPCH then
						_p(3,'<PrecompiledHeader %s>Create</PrecompiledHeader>', condition)
					end
				end
				_p(2,'</ClCompile>')
			end
			_p(1,'</ItemGroup>')
		end
	end

	function vc2010.customBuildFilesGroup(prj)
		local files = vc2010.getfilegroup_ng(prj, "CustomBuild")
		if #files > 0  then
			_p(1,'<ItemGroup>')
			for _, file in ipairs(files) do
				_x(2,'<CustomBuild Include=\"%s\">', path.translate(file.relpath))
				_p(3,'<FileType>Document</FileType>')
				
				for cfg in project.eachconfig(prj) do
					local condition = vc2010.condition(cfg)					
					local filecfg = config.getfileconfig(cfg, file.abspath)
					if filecfg and filecfg.buildrule then
						local commands = table.concat(filecfg.buildrule.commands,'\r\n')
						_p(3,'<Command %s>%s</Command>', condition, premake.esc(commands))
	
						local outputs = table.concat(filecfg.buildrule.outputs, ' ')
						_p(3,'<Outputs %s>%s</Outputs>', condition, premake.esc(outputs))
					end
				end
				
				_p(2,'</CustomBuild>')
			end
			_p(1,'</ItemGroup>')
		end
	end

	function vc2010.getfilegroup_ng(prj, group)
		-- check for a cached copy before creating
		local groups = prj.vc2010_file_groups
		if not groups then
			groups = {
				ClCompile = {},
				ClInclude = {},
				None = {},
				ResourceCompile = {},
				CustomBuild = {},
			}
			prj.vc2010_file_groups = groups
			
			local tr = project.getsourcetree(prj)
			tree.traverse(tr, {
				onleaf = function(node)
					-- if any configuration of this file uses a custom build rule,
					-- then they all must be marked as custom build
					local hasbuildrule = false
					for cfg in project.eachconfig(prj) do				
						local filecfg = config.getfileconfig(cfg, node.abspath)
						if filecfg and filecfg.buildrule then
							hasbuildrule = true
							break
						end
					end
						
					if hasbuildrule then
						table.insert(groups.CustomBuild, node)
					elseif path.iscppfile(node.name) then
						table.insert(groups.ClCompile, node)
					elseif path.iscppheader(node.name) then
						table.insert(groups.ClInclude, node)
					elseif path.isresourcefile(node.name) then
						table.insert(groups.ResourceCompile, node)
					else
						table.insert(groups.None, node)
					end
				end
			})
		end

		return groups[group]
	end


--
-- Generate the list of project dependencies.
--

	function vc2010.projectReferences_ng(prj)
		local deps = project.getdependencies(prj)
		if #deps > 0 then
			local prjpath = project.getlocation(prj)
			
			_p(1,'<ItemGroup>')
			for _, dep in ipairs(deps) do
				local relpath = path.getrelative(prjpath, vstudio.projectfile(dep))
				_x(2,'<ProjectReference Include=\"%s\">', path.translate(relpath))
				_p(3,'<Project>{%s}</Project>', dep.uuid)
				_p(2,'</ProjectReference>')
			end
			_p(1,'</ItemGroup>')
		end
	end


--
-- Write out the linker's additionalDependencies element.
--

	function vc2010.additionalDependencies(cfg, explicit)
		local links

		-- check to see if this project uses an external toolset. If so, let the
		-- toolset define the format of the links
		local toolset = premake.vstudio.vc200x.toolset(cfg)
		if toolset then
			links = toolset.getlinks(cfg, not explicit)
		else
			-- VS always tries to link against project dependencies, even when those
			-- projects are excluded from the build. To work around, linking dependent
			-- projects is disabled, and sibling projects link explicitly
			local scope = iif(explicit, "all", "system")
			links = config.getlinks(cfg, scope, "fullpath")
		end
		
		if #links > 0 then
			links = path.translate(table.concat(links, ";"))
			_x(3,'<AdditionalDependencies>%s;%%(AdditionalDependencies)</AdditionalDependencies>', links)
		end
	end


--
-- Write out the <AdditionalIncludeDirectories> element, which is used by 
-- both the compiler and resource compiler blocks.
--

	function vc2010.additionalIncludeDirectories(cfg, includedirs)
		if #includedirs > 0 then
			local dirs = project.getrelative(cfg.project, includedirs)
			dirs = path.translate(table.concat(dirs, ";"))
			_x(3,'<AdditionalIncludeDirectories>%s;%%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>', dirs)
		end
	end


--
-- Write out the linker's <AdditionalLibraryDirectories> element.
--

	function vc2010.additionalLibraryDirectories(cfg)
		if #cfg.libdirs > 0 then
			local dirs = project.getrelative(cfg.project, cfg.libdirs)
			dirs = path.translate(table.concat(dirs, ";"))
			_x(3,'<AdditionalLibraryDirectories>%s;%%(AdditionalLibraryDirectories)</AdditionalLibraryDirectories>', dirs)
		end
	end


--
-- Write out the <AdditionalOptions> element for the linker blocks.
--

	function vc2010.additionalLinkOptions(cfg)
		if #cfg.linkoptions > 0 then
			local opts = table.concat(cfg.linkoptions, " ")
			_x(3, '<AdditionalOptions>%s %%(AdditionalOptions)</AdditionalOptions>', opts)
		end
	end


--
-- Format and return a Visual Studio Condition attribute.
--

	function vc2010.condition(cfg)
		return string.format('Condition="\'$(Configuration)|$(Platform)\'==\'%s\'"', premake.esc(vstudio.projectConfig(cfg)))
	end


--
-- Map Premake's project kinds to Visual Studio configuration types.
--

	function vc2010.config_type(cfg)
		local map = {
			SharedLib = "DynamicLibrary",
			StaticLib = "StaticLibrary",
			ConsoleApp = "Application",
			WindowedApp = "Application"
		}
		return map[cfg.kind]
	end


--
-- Translate Premake's debugging settings to the Visual Studio equivalent.
--

	function vc2010.debuginfo(cfg)
		local value
		if cfg.flags.Symbols then
			if cfg.debugformat == "c7" then
				value = "OldStyle"
			elseif cfg.architecture == "x64" or 
			       cfg.flags.Managed or 
				   premake.config.isoptimizedbuild(cfg) or 
				   cfg.flags.NoEditAndContinue
			then
				value = "ProgramDatabase"
			else
				value = "EditAndContinue"
			end
		end
		if value then
			_p(3,'<DebugInformationFormat>%s</DebugInformationFormat>', value)
		end
	end


--
-- Translate Premake's optimization flags to the Visual Studio equivalents.
--

	function vc2010.optimization(cfg)
		local result = "Disabled"
		for _, flag in ipairs(cfg.flags) do
			if flag == "Optimize" then
				result = "Full"
			elseif flag == "OptimizeSize" then
				result = "MinSpace"
			elseif flag == "OptimizeSpeed" then
				result = "MaxSpeed"
			end
		end
		return result
	end


--
-- Write out a <PreprocessorDefinitions> element, used by both the compiler
-- and resource compiler blocks.
--

	function vc2010.preprocessorDefinitions(defines)
		if #defines > 0 then
			defines = table.concat(defines, ";")
			_x(3,'<PreprocessorDefinitions>%s;%%(PreprocessorDefinitions)</PreprocessorDefinitions>', defines)
		end
	end


--
-- Convert Premake warning flags to Visual Studio equivalents.
--

	function vc2010.warnings(cfg)
		local warnLevel = 3 -- default to normal warning level if there is not any warnings flags specified
		if cfg.flags.NoWarnings then
			warnLevel = 0
		elseif cfg.flags.ExtraWarnings then
			warnLevel = 4
		end
		_p(3,'<WarningLevel>Level%d</WarningLevel>', warnLevel)

		-- Ohter warning blocks only when NoWarnings are not specified
		if cfg.flags.NoWarnings then
			return
		end

		if premake.config.isdebugbuild(cfg) and cfg.flags.ExtraWarnings then
			_p(3,'<SmallerTypeCheck>true</SmallerTypeCheck>')
		end

		if cfg.flags.FatalWarnings then
			_p(3,'<TreatWarningAsError>true</TreatWarningAsError>')
		end
	end
