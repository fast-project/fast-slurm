# Makefile for job_submit/prolog plugin

AUTOMAKE_OPTIONS = foreign

PLUGIN_FLAGS = -module -avoid-version --export-dynamic

AM_CPPFLAGS = -I$(top_srcdir) -I$(top_srcdir)/src/common

pkglib_LTLIBRARIES = job_submit_prolog.la

# Job submit prolog plugin.
job_submit_prolog_la_SOURCES = job_submit_prolog.c
job_submit_prolog_la_LDFLAGS = $(SO_LDFLAGS) $(PLUGIN_FLAGS)
