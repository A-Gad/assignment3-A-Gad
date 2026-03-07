#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{

    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    struct thread_data* thread_func_args =  (struct thread_data *) thread_param;

    struct timespec tso = {
    .tv_sec = thread_func_args->wait_obtain / 1000,
    .tv_nsec = (thread_func_args->wait_obtain % 1000) * 1000000
    };
    nanosleep(&tso,NULL);//wait
    pthread_mutex_lock(thread_func_args->mutex); // lock mutex
    struct timespec tsr = {
    .tv_sec = thread_func_args->wait_release / 1000,
    .tv_nsec = (thread_func_args->wait_release % 1000) * 1000000
    };
    nanosleep(&tsr,NULL);//wait to release 
    pthread_mutex_unlock(thread_func_args->mutex);

    thread_func_args->thread_complete_success = true;

    
    return thread_func_args;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */
    struct thread_data *data;
    data = (struct thread_data*)malloc(sizeof(struct thread_data));
    if (data == NULL)
    {
        perror("malloc");
        return -1;
    }
    data->mutex = mutex;
    data->thread_complete_success = false;
    data->wait_obtain = wait_to_obtain_ms;
    data->wait_release = wait_to_release_ms;

    data->retval = pthread_create(&(data->thread_id),NULL,threadfunc,(void*)data);
    if (data->retval != 0)
    {
       perror("pthread_create"); 
       return false;
    }

    *thread = data->thread_id;
    return true;
}

