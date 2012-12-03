/*
 * Copyright (c) 2010-2012 Michael Kuhn
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#define _XOPEN_SOURCE 500

#include <julea-config.h>

#include <jzfs.h>

#include <glib.h>
#include <glib/gstdio.h>
#include <gmodule.h>

#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include <jtrace-internal.h>

#include "backend.h"
#include "backend-internal.h"

static gchar* jd_backend_path = NULL;
static JZFSPool* pool = NULL;
static JZFSObjectSet* object_set = NULL;

G_MODULE_EXPORT
gboolean
backend_create (JBackendFile* bf, gchar const* store, gchar const* collection, gchar const* item)
{
	gchar* parent;
	gchar* path;
	gint fd;
	JZFSObject* object;

	j_trace_enter(j_trace_get_thread_default(), G_STRFUNC);

	path = g_build_filename(jd_backend_path, store, collection, item, NULL);

	j_trace_file_begin(j_trace_get_thread_default(), path, J_TRACE_FILE_CREATE);
	
	object = j_zfs_object_create(object_set); 
	//parent = g_path_get_dirname(path);
	//g_mkdir_with_parents(parent, 0700);
	//g_free(parent);

	//fd = open(path, O_RDWR | O_CREAT, 0600);

	j_trace_file_end(j_trace_get_thread_default(), path, J_TRACE_FILE_CREATE, 0, 0);

	bf->path = path;
	//bf->user_data = GINT_TO_POINTER(fd);

	j_trace_leave(j_trace_get_thread_default(), G_STRFUNC);

	return (fd != -1);
}

G_MODULE_EXPORT
gboolean
backend_delete (JBackendFile* bf)
{
	gboolean ret;

	j_trace_enter(j_trace_get_thread_default(), G_STRFUNC);

	j_trace_file_begin(j_trace_get_thread_default(), bf->path, J_TRACE_FILE_DELETE);
	ret = (g_unlink(bf->path) == 0);
	//j_zfs_object_destroy(object); 
	j_trace_file_end(j_trace_get_thread_default(), bf->path, J_TRACE_FILE_DELETE, 0, 0);

	j_trace_leave(j_trace_get_thread_default(), G_STRFUNC);

	return ret;
}

G_MODULE_EXPORT
gboolean
backend_open (JBackendFile* bf, gchar const* store, gchar const* collection, gchar const* item)
{
	gchar* path;
	gint fd;

	j_trace_enter(j_trace_get_thread_default(), G_STRFUNC);

	path = g_build_filename(jd_backend_path, store, collection, item, NULL);

	j_trace_file_begin(j_trace_get_thread_default(), path, J_TRACE_FILE_OPEN);
	fd = open(path, O_RDWR);
	j_trace_file_end(j_trace_get_thread_default(), path, J_TRACE_FILE_OPEN, 0, 0);

	bf->path = path;
	bf->user_data = GINT_TO_POINTER(fd);

	j_trace_leave(j_trace_get_thread_default(), G_STRFUNC);

	return (fd != -1);
}

G_MODULE_EXPORT
gboolean
backend_close (JBackendFile* bf)
{
	gint fd = GPOINTER_TO_INT(bf->user_data);

	j_trace_enter(j_trace_get_thread_default(), G_STRFUNC);

	if (fd != -1)
	{
		j_trace_file_begin(j_trace_get_thread_default(), bf->path, J_TRACE_FILE_CLOSE);
		close(fd);
		j_trace_file_end(j_trace_get_thread_default(), bf->path, J_TRACE_FILE_CLOSE, 0, 0);
	}

	g_free(bf->path);

	j_trace_leave(j_trace_get_thread_default(), G_STRFUNC);

	return (fd != -1);
}

G_MODULE_EXPORT
gboolean
backend_status (JBackendFile* bf, JItemStatusFlags flags, gint64* modification_time, guint64* size)
{
	gint fd = GPOINTER_TO_INT(bf->user_data);

	j_trace_enter(j_trace_get_thread_default(), G_STRFUNC);

	if (fd != -1)
	{
		struct stat buf;

		j_trace_file_begin(j_trace_get_thread_default(), bf->path, J_TRACE_FILE_STATUS);
		fstat(fd, &buf);
		j_trace_file_end(j_trace_get_thread_default(), bf->path, J_TRACE_FILE_STATUS, 0, 0);

		*modification_time = buf.st_mtime;
		*size = buf.st_size;
	}

	j_trace_leave(j_trace_get_thread_default(), G_STRFUNC);

	return (fd != -1);
}

G_MODULE_EXPORT
gboolean
backend_sync (JBackendFile* bf)
{
	gint fd = GPOINTER_TO_INT(bf->user_data);

	j_trace_enter(j_trace_get_thread_default(), G_STRFUNC);

	if (fd != -1)
	{
		j_trace_file_begin(j_trace_get_thread_default(), bf->path, J_TRACE_FILE_SYNC);
		fsync(fd);
		j_trace_file_end(j_trace_get_thread_default(), bf->path, J_TRACE_FILE_SYNC, 0, 0);
	}

	j_trace_leave(j_trace_get_thread_default(), G_STRFUNC);

	return (fd != -1);
}

G_MODULE_EXPORT
gboolean
backend_read (JBackendFile* bf, gpointer buffer, guint64 length, guint64 offset, guint64* bytes_read)
{
	gint fd = GPOINTER_TO_INT(bf->user_data);
	gsize nbytes;

	j_trace_enter(j_trace_get_thread_default(), G_STRFUNC);

	if (fd != -1)
	{
		j_trace_file_begin(j_trace_get_thread_default(), bf->path, J_TRACE_FILE_READ);
		nbytes = pread(fd, buffer, length, offset);
		j_trace_file_end(j_trace_get_thread_default(), bf->path, J_TRACE_FILE_READ, nbytes, offset);

		if (bytes_read != NULL)
		{
			*bytes_read = nbytes;
		}
	}

	j_trace_leave(j_trace_get_thread_default(), G_STRFUNC);

	return (fd != -1);
}

G_MODULE_EXPORT
gboolean
backend_write (JBackendFile* bf, gconstpointer buffer, guint64 length, guint64 offset, guint64* bytes_written)
{
	gint fd = GPOINTER_TO_INT(bf->user_data);
	gsize nbytes;

	j_trace_enter(j_trace_get_thread_default(), G_STRFUNC);

	if (fd != -1)
	{
		j_trace_file_begin(j_trace_get_thread_default(), bf->path, J_TRACE_FILE_WRITE);
		nbytes = pwrite(fd, buffer, length, offset);
		j_trace_file_end(j_trace_get_thread_default(), bf->path, J_TRACE_FILE_WRITE, nbytes, offset);

		if (bytes_written != NULL)
		{
			*bytes_written = nbytes;
		}
	}

	j_trace_leave(j_trace_get_thread_default(), G_STRFUNC);

	return (fd != -1);
}

G_MODULE_EXPORT
void
backend_init (gchar const* path)
{
	gchar* poolname = "jzfs";
	gchar* object_set_name = "object_set";

	j_trace_enter(j_trace_get_thread_default(), G_STRFUNC);
	pool = j_zfs_pool_open(poolname);
	object_set = j_zfs_object_set_create(pool, object_set_name);

	jd_backend_path = g_strdup(path);

	g_mkdir_with_parents(path, 0700);

	j_trace_leave(j_trace_get_thread_default(), G_STRFUNC);
}

G_MODULE_EXPORT
void
backend_fini (void)
{
	j_trace_enter(j_trace_get_thread_default(), G_STRFUNC);
	
	j_zfs_object_set_destroy(object_set);
	j_zfs_pool_close(pool);	

	g_free(jd_backend_path);

	j_trace_leave(j_trace_get_thread_default(), G_STRFUNC);
}