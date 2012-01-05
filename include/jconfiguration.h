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

/**
 * \file
 **/

#ifndef H_CONFIGURATION
#define H_CONFIGURATION

#include <glib.h>

struct JConfiguration;

typedef struct JConfiguration JConfiguration;

JConfiguration* j_configuration_new (void);
JConfiguration* j_configuration_ref (JConfiguration*);
void j_configuration_unref (JConfiguration*);

gchar const* j_configuration_get_data_server (JConfiguration*, guint);
gchar const* j_configuration_get_metadata_server (JConfiguration*, guint);

guint j_configuration_get_data_server_count (JConfiguration*);
guint j_configuration_get_metadata_server_count (JConfiguration*);

gchar const* j_configuration_get_storage_backend (JConfiguration*);
gchar const* j_configuration_get_storage_path (JConfiguration*);
#endif