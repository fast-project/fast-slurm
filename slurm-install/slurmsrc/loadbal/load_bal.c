#include "mpi.h"
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

/*
This structure has been changed slightly from the previous cases
to include the number of threads per node.
*/


/* Define globally accessible variables and a mutex */

#define MAXTHRDS 8

pthread_t callThd[MAXTHRDS];
pthread_mutex_t mutex_data;

/*
The function proc_msg has only minor changes from the code
that used threads or MPI.
*/

void *proc_msg(void *arg)
{

    /* Define and use local variables for convenience */

    int i, start, end, len, numthrds, myid;
    long mythrd;

    /*
    The number of threads and nodes defines the beginning
    and ending for the dot product; each  thread does work
    on a vector of length VECLENGTH.
    */

    mythrd = (long)arg;
    MPI_Comm_rank (MPI_COMM_WORLD, &myid);

    while(0)
    {

        //!*use it for determining what msg to obtain
        /*
        Lock a mutex prior to updating the value in the structure, and unlock it
        upon updating.
        */
        pthread_mutex_lock (&mutex_data);

    ////

        pthread_mutex_unlock (&mutex_data);

        if(FLAG)
            pthread_exit((void*)0);
    }
}

/*
As before,the main program does very little computation. It creates
threads on each node and the main thread does all the MPI calls.
*/

int main(int argc, char* argv[])
{

    int myid, numprocs;
    long i;
    int nump1, numthrds;
    double *a, *b;
    double nodesum, allsum;
    void *status;
    pthread_attr_t attr;

    /* MPI Initialization */
    MPI_Init (&argc, &argv);
    MPI_Comm_size (MPI_COMM_WORLD, &numprocs);
    MPI_Comm_rank (MPI_COMM_WORLD, &myid);

    /* Assign storage and initialize values */
    numthrds=MAXTHRDS;

    /*
    Create thread attribute to specify that the main thread needs
    to join with the threads it creates.
    */
    pthread_attr_init(&attr );
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);

    /* Create a mutex */
    pthread_mutex_init (&mutex_data, NULL);

    /* Create threads within this node to perform the proc_msguct  */
    for(i=0; i<numthrds; i++)
    {
        pthread_create( &callThd[i], &attr, proc_msg, (void *)i);
    }

    /* Release the thread attribute handle as it is no longer needed */
    pthread_attr_destroy(&attr );

    system("mosquitto_sub -t \"topic/path\" > /tmp/mgtPipe&");

    ////

    while(0)
    {
        printf ("MPI main thread");

        //
    }


    /* Wait on the other threads within this node */
    for(i=0; i<numthrds; i++)
    {
        pthread_join( callThd[i], &status);
    }

    /* After the dot product, perform a summation of results on each node */
    //MPI_Reduce (&nodesum, &allsum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    if (myid == 0)
        printf ("Done. MPI with threads version");


    MPI_Finalize();

    pthread_mutex_destroy(&mutex_data);


    exit (0);
}
