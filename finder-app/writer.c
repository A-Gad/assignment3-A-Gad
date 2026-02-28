#include <stdio.h>
#include <syslog.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>

int main(int argc, char* argv[])
{
    openlog("writer", LOG_CONS | LOG_PID | LOG_PERROR, LOG_USER);

    if (argc < 3)
    {
        printf("Usage writer <file-name>  <string> !\n");
        syslog(LOG_ERR, "invalid or incomlete arguments passed!");
        closelog();
        return 1;
    }

    const char* file_name = argv[1];
    char* writestr = argv[2];

    int fd;
    fd = open(file_name, O_WRONLY | O_CREAT | O_TRUNC, 0644);

    if(fd == -1)
    {
        syslog(LOG_ERR, "Could not open file %s", file_name);
        perror("fopen");
        closelog();
        return 1;
    }

    size_t count = strlen(writestr);
    ssize_t nr;

    nr = write(fd, writestr, count);
    if (nr == -1)
    {
        perror("write");
        syslog(LOG_ERR, "error while writing to file");
        close(fd);
        closelog();
        return 1;
    }

    else if(nr != count)
    {
        syslog(LOG_DEBUG, "possible partial write!");
    }
    else
    {
       syslog(LOG_DEBUG, "Writing \"%s\" to \"%s\"", writestr, file_name);
    }
    close(fd);
    closelog();

    return 0;

}