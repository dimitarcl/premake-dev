--
-- tests/actions/vstudio/cs2005/projectsettings.lua
-- Validate generation of root <PropertyGroup/> in Visual Studio 2005+ .csproj
-- Copyright (c) 2009-2012 Jason Perkins and the Premake project
--

	T.vstudio_cs2005_projectsettings = { }
	local suite = T.vstudio_cs2005_projectsettings
	local cs2005 = premake.vstudio.cs2005


--
-- Setup
--

	local sln, prj

	function suite.setup()
		_ACTION = "vs2005"
		sln = test.createsolution()
		language "C#"
		uuid "AE61726D-187C-E440-BD07-2556188A6565"
	end

	local function prepare()
		prj = premake.solution.getproject_ng(sln, 1)
		cs2005.projectProperties(prj)
	end


--
-- Version Tests
--

	function suite.OnVs2005()
		prepare()
		test.capture [[
	<PropertyGroup>
		<Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
		<Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
		<ProductVersion>8.0.50727</ProductVersion>
		<SchemaVersion>2.0</SchemaVersion>
		<ProjectGuid>{AE61726D-187C-E440-BD07-2556188A6565}</ProjectGuid>
		<OutputType>Exe</OutputType>
		<AppDesignerFolder>Properties</AppDesignerFolder>
		<RootNamespace>MyProject</RootNamespace>
		<AssemblyName>MyProject</AssemblyName>
	</PropertyGroup>
		]]
	end


	function suite.OnVs2008()
		_ACTION = "vs2008"
		prepare()
		test.capture [[
	<PropertyGroup>
		<Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
		<Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
		<ProductVersion>9.0.21022</ProductVersion>
		<SchemaVersion>2.0</SchemaVersion>
		<ProjectGuid>{AE61726D-187C-E440-BD07-2556188A6565}</ProjectGuid>
		<OutputType>Exe</OutputType>
		<AppDesignerFolder>Properties</AppDesignerFolder>
		<RootNamespace>MyProject</RootNamespace>
		<AssemblyName>MyProject</AssemblyName>
	</PropertyGroup>
		]]
	end


	function suite.OnVs2010()
		_ACTION = "vs2010"
		prepare()
		test.capture [[
	<PropertyGroup>
		<Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
		<Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
		<ProductVersion>8.0.30703</ProductVersion>
		<SchemaVersion>2.0</SchemaVersion>
		<ProjectGuid>{AE61726D-187C-E440-BD07-2556188A6565}</ProjectGuid>
		<OutputType>Exe</OutputType>
		<AppDesignerFolder>Properties</AppDesignerFolder>
		<RootNamespace>MyProject</RootNamespace>
		<AssemblyName>MyProject</AssemblyName>
		<TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
		<TargetFrameworkProfile></TargetFrameworkProfile>
		<FileAlignment>512</FileAlignment>
	</PropertyGroup>
		]]
	end


--
-- Framework Tests
--

	function suite.OnFrameworkVersion()
		framework "3.0"
		prepare()
		test.capture [[
	<PropertyGroup>
		<Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
		<Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
		<ProductVersion>8.0.50727</ProductVersion>
		<SchemaVersion>2.0</SchemaVersion>
		<ProjectGuid>{AE61726D-187C-E440-BD07-2556188A6565}</ProjectGuid>
		<OutputType>Exe</OutputType>
		<AppDesignerFolder>Properties</AppDesignerFolder>
		<RootNamespace>MyProject</RootNamespace>
		<AssemblyName>MyProject</AssemblyName>
		<TargetFrameworkVersion>v3.0</TargetFrameworkVersion>
	</PropertyGroup>
		]]
	end


--
-- Make sure the root namespace can be overridden.
--

	function suite.canOverrideRootNamespace()
		namespace "MyCompany.%{prj.name}"
		prepare()
		test.capture [[
	<PropertyGroup>
		<Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
		<Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
		<ProductVersion>8.0.50727</ProductVersion>
		<SchemaVersion>2.0</SchemaVersion>
		<ProjectGuid>{AE61726D-187C-E440-BD07-2556188A6565}</ProjectGuid>
		<OutputType>Exe</OutputType>
		<AppDesignerFolder>Properties</AppDesignerFolder>
		<RootNamespace>MyCompany.MyProject</RootNamespace>
		<AssemblyName>MyProject</AssemblyName>
	</PropertyGroup>
		]]
	end

