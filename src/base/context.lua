--
-- context.lua
--
-- DO NOT USE THIS YET! I am just getting started here; please wait until
-- I've had a chance to build it out more before using.
--
-- Provide a context for pulling out values from a configuration set. Each
-- context has an associated list of terms which constrain the values that
-- it will retrieve, i.e. "Windows, "Debug", "x64", and so on.
--
-- The context also provides caching for the values returned from the set.
--
-- Copyright (c) 2012 Jason Perkins and the Premake project
--

	premake.context = {}
	local context = premake.context
	local configset = premake.configset


--
-- Create a new context object.
--
-- @param cfgset
--    The configuration set to provide the data from this context.
-- @param environ
--    An optional key-value environment table for token expansion; keys and
--    values provided in this table will be available for tokens to use.
-- @param filename
--    An optional filename, which will limit the fetched results to blocks
--    which specifically match the provided name.
-- @return
--    A new context object.
--

	function context.new(cfgset, environ, filename)
		local ctx = {}
		ctx._cfgset = cfgset
		ctx.environ = environ or {}
		ctx._filename = { filename } or {}
		ctx._terms = {}
		
		-- when a missing field is requested, fetch it from my config
		-- set, and then cache the value for future lookups
		setmetatable(ctx, context.__mt)
		
		return ctx
	end


--
-- Add additional filtering terms to an existing context.
--
-- @param ctx
--    The context to contain the new terms.
-- @param terms
--    One or more new terms to add to the context. May be nil.
--

	function context.addterms(ctx, terms)
		if terms then
			terms = table.flatten({terms})
			for _, term in ipairs(terms) do
				-- make future tests case-insensitive
				table.insert(ctx._terms, term:lower())
			end
		end
	end


--
-- Copies the list of terms from an existing context.
--
-- @param ctx
--    The context to receive the copied terms.
-- @param src
--    The context containing the terms to copy.
--

	function context.copyterms(ctx, src)
		ctx._terms = table.arraycopy(src._terms)
	end


--
-- Fetch a value from underlying configuration set.
--
-- @param ctx
--    The context to query.
-- @param key
--    The property key to query.
-- @return
--    The value of the key, as determined by the configuration set.  If
--    there is a corresponding Premake field, and it the field is enabled
--    for tokens, any contained tokens will be expanded.
--

	function context.fetchvalue(ctx, key)
		local value = configset.fetchvalue(ctx._cfgset, key, ctx._terms, ctx._filename[1])
		if value then
			-- do I need to expand tokens?
			local field = premake.fields[key]
			if field and field.tokens then
				local ispath = field.kind:startswith("path")
				value = premake.detoken.expand(value, ctx.environ, ispath)
			end
			
			-- store the result for later lookups
			ctx[key] = value
		end

		return value
	end
	
	context.__mt = {
		__index = context.fetchvalue
	}

