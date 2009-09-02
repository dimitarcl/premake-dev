--
-- _xcode.lua
-- Define the Apple XCode action and support functions.
-- Copyright (c) 2009 Jason Perkins and the Premake project
--

	premake.xcode = { }
	
	newaction 
	{
		trigger         = "xcode3",
		shortname       = "Xcode 3",
		description     = "Apple Xcode 3 (experimental)",
		os              = "macosx",

		valid_kinds     = { "ConsoleApp", "WindowedApp" },
		
		valid_languages = { "C", "C++" },
		
		valid_tools     = {
			cc     = { "gcc" },
		},

		onsolution = function(sln)
			premake.generate(sln, "%%.xcodeproj/project.pbxproj", premake.xcode.pbxproj)
		end,
		
		oncleansolution = function(sln)
			premake.clean.directory(sln, "%%.xcodeproj")
		end,
	}
