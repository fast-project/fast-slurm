
#if HAVE_CONFIG_H
#  include "config.h"
#  if STDC_HEADERS
#    include <string.h>
#  endif
#  if HAVE_SYS_TYPES_H
#    include <sys/types.h>
#  endif /* HAVE_SYS_TYPES_H */
#  if HAVE_UNISTD_H
#    include <unistd.h>
#  endif
#  if HAVE_INTTYPES_H
#    include <inttypes.h>
#  else /* ! HAVE_INTTYPES_H */
#    if HAVE_STDINT_H
#      include <stdint.h>
#    endif
#  endif /* HAVE_INTTYPES_H */
#else /* ! HAVE_CONFIG_H */
#  include <sys/types.h>
#  include <unistd.h>
#  include <stdint.h>
#  include <string.h>
#endif /* HAVE_CONFIG_H */

#include <stdio.h>

#include "slurm/slurm_errno.h"
#include "src/common/slurm_xlator.h"
#include "src/slurmctld/locks.h"
#include "src/slurmctld/slurmctld.h"
#include "src/slurmctld/job_scheduler.h"



/*
 * These variables are required by the generic plugin interface.  If they
 * are not found in the plugin, the plugin loader will ignore it.
 *
 * plugin_name - a string giving a human-readable description of the
 * plugin.  There is no maximum length, but the symbol must refer to
 * a valid string.
 *
 * plugin_type - a string suggesting the type of the plugin or its
 * applicability to a particular form of data or method of data handling.
 * If the low-level plugin API is used, the contents of this string are
 * unimportant and may be anything.  SLURM uses the higher-level plugin
 * interface which requires this string to be of the form
 *
 *	<application>/<method>
 *
 * where <application> is a description of the intended application of
 * the plugin (e.g., "auth" for SLURM authentication) and <method> is a
 * description of how this plugin satisfies that application.  SLURM will
 * only load authentication plugins if the plugin_type string has a prefix
 * of "auth/".
 *
 * plugin_version - an unsigned 32-bit integer containing the Slurm version
 * (major.minor.micro combined into a single number).
 */
const char plugin_name[]       	= "Job submit prolog plugin";
const char plugin_type[]       	= "job_submit/prolog";
const uint32_t plugin_version   = SLURM_VERSION_NUMBER;

/*****************************************************************************\
 * We've provided a simple example of the type of things you can do with this
 * plugin. If you develop another plugin that may be of interest to others
 * please post it to slurm-dev@schedmd.com  Thanks!
\*****************************************************************************/

//static char **  _build_env(struct job_record *job_ptr);
static int current_vm_id = 0;

void attach_u_param(char* call_str, uint32_t value)
{
	char str_val[100];
        sprintf(str_val," %u",value);
	strcat(call_str,str_val);
}


int init (void)
{
	verbose( "Prolog submit plugin 1.1 loaded" );
	current_vm_id = 0;
        return SLURM_SUCCESS;
}

int fini (void)
{
        return SLURM_SUCCESS;
}

/* This example code will set a job's default prolog to the highest
 * priority prolog that is available to this user. This is only an
 * example and tremendous flexibility is available. */
extern int job_submit(struct job_descriptor *job_desc, uint32_t submit_uid,
		      char **err_msg)
{

	if(job_desc->job_id == (uint32_t)(4294967294))
	{
		verbose("Prolog Submit Plugin skipped");
		return SLURM_SUCCESS;
	}
	if(strcmp(job_desc->partition,"vmq") == 0)
        {
                verbose("Prolog Submit Plugin skipps VM submission jobs");
                return SLURM_SUCCESS;
        }


	verbose( "Prolog submit script started" );

	//keep track of the VMID
	current_vm_id += job_desc->min_nodes;
	if(current_vm_id > 0xFFFFFFFFFF)
	{
		current_vm_id=0;
		current_vm_id += job_desc->min_nodes;
	}

	//create the system call command and the parameters
	char call_str[(400+30*9)];
	strcpy(call_str,"/cluster/slurm-install/scripts/prolog_submit.sh");

	attach_u_param(call_str,current_vm_id);
	attach_u_param(call_str,job_desc->job_id);
	attach_u_param(call_str,job_desc->min_nodes);
	attach_u_param(call_str,job_desc->time_limit);
	attach_u_param(call_str,job_desc->pn_min_memory);
	attach_u_param(call_str,job_desc->min_cpus);
	attach_u_param(call_str,job_desc->cpus_per_task);
	strcat(call_str," ");
	strcat(call_str,job_desc->gres);

	strcat(call_str," &> /cluster/slurm-install/scripts/logs/jobsubmit.log");

	verbose(call_str);
        verbose("Job submit request:job_id:%u account:%s "
             "name:%s partition:%s submit_uid:%u time_limit:%u "
             "user_id:%u min_nodes:%u vm_id:%d pn_min_memory:%u min_cpus:%u cpus_per_task:%u gres:%s",job_desc->job_id,
             job_desc->account,
             job_desc->name, job_desc->partition,
             submit_uid, job_desc->time_limit, job_desc->user_id,
 	     job_desc->min_nodes, current_vm_id, job_desc->pn_min_memory, job_desc->min_cpus, job_desc->cpus_per_task,job_desc->gres);

	//this will fork the system call
	strcat(call_str," &");
	//do the system call
	int ret = system(call_str);
	if(ret == -1)
		verbose( "Prolog submit script error");
	verbose( "Prolog submit script done" );
	return SLURM_SUCCESS;




}

extern int job_modify(struct job_descriptor *job_desc,
		      struct job_record *job_ptr, uint32_t submit_uid)
{
	return SLURM_SUCCESS;
}
