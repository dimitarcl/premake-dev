--
-- tests/actions/make/cpp/test_file_rules.lua
-- Validate the makefile source building rules.
-- Copyright (c) 2009-2013 Jason Perkins and the Premake project
--

	local suite = test.declare("make_cpp_file_rules")
	local make = premake.make
	local project = premake.project


--
-- Setup
--

	local sln, prj

	function suite.setup()
		sln = test.createsolution()
	end

	local function prepare()
		prj = premake.solution.getproject(sln, 1)
		make.cppFileRules(prj)
	end


--
-- Two files with the same base name should have different object files.
--

	function suite.uniqueObjNames_onBaseNameCollision()
		files { "src/hello.cpp", "src/greetings/hello.cpp" }
		prepare()
		test.capture [[
$(OBJDIR)/hello.o: src/greetings/hello.cpp
	@echo $(notdir $<)
	$(SILENT) $(CXX) $(ALL_CXXFLAGS) -o "$@" -MF $(@:%.o=%.d) -c "$<"
$(OBJDIR)/hello1.o: src/hello.cpp
	@echo $(notdir $<)
	$(SILENT) $(CXX) $(ALL_CXXFLAGS) -o "$@" -MF $(@:%.o=%.d) -c "$<"

  		]]
	end


--
-- C files in C++ projects should been compiled as c
--

	function suite.cFilesGetsCompiledWithCCWhileInCppProject()
		files { "src/hello.c", "src/test.cpp" }
		prepare()
		test.capture [[
$(OBJDIR)/hello.o: src/hello.c
	@echo $(notdir $<)
	$(SILENT) $(CC) $(ALL_CFLAGS) -o "$@" -MF $(@:%.o=%.d) -c "$<"
$(OBJDIR)/test.o: src/test.cpp
	@echo $(notdir $<)
	$(SILENT) $(CXX) $(ALL_CXXFLAGS) -o "$@" -MF $(@:%.o=%.d) -c "$<"

  		]]
	end


--
-- If a custom build rule is supplied, it should be used.
--

	function suite.customBuildRule()
		files { "hello.x" }
		configuration "**.x"
			buildmessage "Compiling %{file.name}"
			buildcommands {
				'cxc -c "%{file.path}" -o "%{cfg.objdir}/%{file.basename}.xo"',
				'c2o -c "%{cfg.objdir}/%{file.basename}.xo" -o "%{cfg.objdir}/%{file.basename}.obj"'
			}
			buildoutputs { "%{cfg.objdir}/%{file.basename}.obj" }
		prepare()
		test.capture [[
ifeq ($(config),debug)
obj/Debug/hello.obj: hello.x
	@echo "Compiling hello.x"
	$(SILENT) cxc -c "hello.x" -o "obj/Debug/hello.xo"
	$(SILENT) c2o -c "obj/Debug/hello.xo" -o "obj/Debug/hello.obj"
endif
ifeq ($(config),release)
obj/Release/hello.obj: hello.x
	@echo "Compiling hello.x"
	$(SILENT) cxc -c "hello.x" -o "obj/Release/hello.xo"
	$(SILENT) c2o -c "obj/Release/hello.xo" -o "obj/Release/hello.obj"
endif
		]]
	end
