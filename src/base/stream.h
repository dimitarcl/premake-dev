/**
 * \file   stream.h
 * \brief  Output stream handling.
 * \author Copyright (c) 2007-2008 Jason Perkins and the Premake project
 *
 * \defgroup stream Streams
 * \ingroup  base
 *
 * An output stream class.
 *
 * @{
 */
#if !defined(PREMAKE_STREAM_H)
#define PREMAKE_STREAM_H

#include <stdarg.h>
#include "strings.h"

DECLARE_CLASS(Stream);

extern Stream Console;

typedef int (*StreamWriterFunc)(Stream strm, const char *value);

Stream stream_create_file(const char* filename);
Stream stream_create_null(void);
void   stream_destroy(Stream stream);
void   stream_set_buffer(Stream strm, char* buffer);
void   stream_set_newline(Stream strm, const char* newline);
int    stream_vprintf(Stream strm, const char* value, va_list args);
int    stream_write(Stream strm, const char* value, ...);
int    stream_write_escaped(Stream strm, const char* value);
int    stream_write_n(Stream strm, const char* value, int n);
int    stream_write_strings(Stream strm, Strings strs, const char* start, const char* prefix, const char* postfix, const char* infix, const char* end, StreamWriterFunc writer);
int    stream_write_unicode_marker(Stream strm);
int    stream_writeline(Stream strm, const char* value, ...);
int    stream_writeline_strings(Stream strm, Strings strs, const char* start, const char* prefix, const char* postfix, const char* infix, const char* end, StreamWriterFunc writer);

#endif
/** @} */
