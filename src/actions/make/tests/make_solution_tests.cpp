/**
 * \file   make_solution_tests.cpp
 * \brief  Automated tests for makefile "solution" processing.
 * \author Copyright (c) 2002-2008 Jason Perkins and the Premake project
 */

#include "premake.h"
#include "actions/tests/action_tests.h"
extern "C" {
#include "actions/make/make_solution.h"
}


SUITE(action)
{
	/**********************************************************************
	 * Signature tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeSolution_SignatureIsCorrect_OnGmake)
	{
		session_set_action(sess, "gmake");
		make_solution_signature(sess, sln, strm);
		CHECK_EQUAL(
			"# GNU Make makefile autogenerated by Premake\n"
			"# Usage: make [ CONFIG=config_name ]\n"
			"# Where {config_name} is one of:\n"
			"#   Debug DLL, Release DLL\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * Default configuration tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeSolution_DefaultConfigIsCorrect)
	{
		make_solution_default_config(sess, sln, strm);
		CHECK_EQUAL(
			"ifndef CONFIG\n"
			"  CONFIG=Debug DLL\n"
			"endif\n"
			"export CONFIG\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * Phony rule tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeSolution_PhonyRuleIsCorrect)
	{
		make_solution_phony_rule(sess, sln, strm);
		CHECK_EQUAL(
			".PHONY: all clean My\\ Project\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * All rule tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, MakeSolution_AllRuleIsCorrect)
	{
		make_solution_all_rule(sess, sln, strm);
		CHECK_EQUAL(
			"all: My\\ Project\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * Project entry tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, Make_ProjectEntry_InSameDirectory)
	{
		project_set_location(prj, "");
		make_solution_projects(sess, sln, strm);
		CHECK_EQUAL(
			"My\\ Project:\n"
			"\t@echo ==== Building My Project ====\n"
			"\t@$(MAKE) -f My\\ Project.make\n"
			"\n",
			buffer);
	}

	TEST_FIXTURE(FxAction, Make_ProjectEntry_InDifferentDirectory)
	{
		project_set_location(prj, "My Project");
		make_solution_projects(sess, sln, strm);
		CHECK_EQUAL(
			"My\\ Project:\n"
			"\t@echo ==== Building My Project ====\n"
			"\t@$(MAKE) --no-print-directory -C My\\ Project\n"
			"\n",
			buffer);
	}


	/**********************************************************************
	 * Clean rule tests
	 **********************************************************************/

	TEST_FIXTURE(FxAction, Gmake_CleanRule_IsCorrect)
	{
		project_set_location(prj, "");
		make_solution_clean_rule(sess, sln, strm);
		CHECK_EQUAL(
			"clean:\n"
			"\t@$(MAKE) -f My\\ Project.make clean\n",
			buffer);
	}

}
