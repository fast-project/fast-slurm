
#include "src/common/slurm_xlator.h"	/* Must be first */

#include <poll.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

/*
 * These variables are required by the generic plugin interface.  If they
 * are not found in the plugin, the plugin loader will ignore it.
 *
 * plugin_name - A string giving a human-readable description of the
 * plugin.  There is no maximum length, but the symbol must refer to
 * a valid string.
 *
 * plugin_type - A string suggesting the type of the plugin or its
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
const char	plugin_name[]	= "Slurmctld FAST load balancing plugin";
const char	plugin_type[]	= "slurmctld/loadbal";
const uint32_t	plugin_version	= SLURM_VERSION_NUMBER;


static pthread_t loadbal_thread_id;

void *loadbal_t(void *threadid)
{

	char call_str[400];
        strcpy(call_str,"/cluster/slurm-install/scripts/loadbal.sh > /cluster/slurm-install/scripts/logs/loadbal.log 2>&1 ");

	int ret = system(call_str);
        if(ret == -1)
                verbose( "Load balncing plugin script error");
	else
                verbose( "Load balncing plugin script thread created");

	pthread_exit(NULL);
}


extern int init(void)
{


        if (pthread_create(&loadbal_thread_id, NULL, loadbal_t, NULL))
                fatal("pthread_create failed on loadbal plugin");


	verbose("%s loaded", plugin_name);


        return SLURM_SUCCESS;

}


extern int fini(void)
{

	pthread_kill(loadbal_thread_id, SIGALRM);

	return SLURM_SUCCESS;
}
