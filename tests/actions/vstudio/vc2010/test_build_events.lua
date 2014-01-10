--
-- tests/actions/vstudio/vc2010/test_build_events.lua
-- Check generation of pre- and post-build commands for C++ projects.
-- Copyright (c) 2012-2013 Jason Perkins and the Premake project
--

	local suite = test.declare("vstudio_vc2010_build_events")
	local vc2010 = premake.vstudio.vc2010


--
-- Setup
--

	local sln, prj, cfg

	function suite.setup()
		io.esc = premake.vstudio.vs2010.esc
		sln = test.createsolution()
	end

	local function prepare(platform)
		prj = premake.solution.getproject(sln, 1)
		vc2010.buildEvents(prj)
	end


--
-- If no build steps are specified, nothing should be written.
--

	function suite.noOutput_onNoEvents()
		prepare()
		test.isemptycapture()
	end


--
-- If one command set is used and not the other, only the one should be written.
--

	function suite.onlyOne_onPreBuildOnly()
		prebuildcommands { "command1" }
		prepare()
		test.capture [[
		<PreBuildEvent>
			<Command>command1</Command>
		</PreBuildEvent>
		]]
	end

	function suite.onlyOne_onPostBuildOnly()
		postbuildcommands { "command1" }
		prepare()
		test.capture [[
		<PostBuildEvent>
			<Command>command1</Command>
		</PostBuildEvent>
		]]
	end

	function suite.both_onBoth()
		prebuildcommands { "command1" }
		postbuildcommands { "command2" }
		prepare()
		test.capture [[
		<PreBuildEvent>
			<Command>command1</Command>
		</PreBuildEvent>
		<PostBuildEvent>
			<Command>command2</Command>
		</PostBuildEvent>
		]]
	end


--
-- Multiple commands should be separated with un-escaped EOLs.
--

	function suite.splits_onMultipleCommands()
		postbuildcommands { "command1", "command2" }
		prepare()
		test.capture ("\t\t<PostBuildEvent>\n\t\t\t<Command>command1\r\ncommand2</Command>\n\t\t</PostBuildEvent>\n")
	end



--
-- Quotes should not be escaped, other special characters should.
--

	function suite.onSpecialChars()
		postbuildcommands { '\' " < > &' }
		prepare()
		test.capture [[
		<PostBuildEvent>
			<Command>' " &lt; &gt; &amp;</Command>
		</PostBuildEvent>
		]]
	end
