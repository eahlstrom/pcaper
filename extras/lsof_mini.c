#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>
#include <string.h>


int main(int argc, char **argv)
{
  DIR *proc_dir, *fd_dir;
  struct dirent *dent;
  struct stat *fstat;
  char fdpath[1024], buf[1024];
  char *linkname;

  if (argc != 2) {
    printf("Usage: lsof_mini path_to_match\n");
    return(1);
  }

  if ((proc_dir = opendir("/proc")) == NULL) {
    perror("/proc");
    return(1);
  }

  fstat = malloc(sizeof(struct stat));
  linkname = malloc(1024);

  while((dent = readdir(proc_dir)) != NULL) {
    if (atoi(dent->d_name) == 0)
      continue;

    sprintf(fdpath, "/proc/%d/fd", atoi(dent->d_name));
    if ((fd_dir = opendir(fdpath)) == NULL)
      continue;

    while((dent = readdir(fd_dir)) != NULL) {
      if (atoi(dent->d_name) == 0) continue;
      sprintf(buf, "%s/%s", fdpath, dent->d_name);
      if (stat(buf, fstat) == 0 && S_ISREG(fstat->st_mode)) {
        memset(linkname, 0, 1024);
        if (readlink(buf, linkname, 1023)) {
          if (access(linkname, F_OK) == -1) continue;
          if (strncmp(argv[1], linkname, strlen(argv[1])) == 0) {
            printf("%s\n", linkname);
          }
        }
      }
    }
    closedir(fd_dir);
  }

  closedir(proc_dir);
  free(fstat);
  free(linkname);
  return(0);
}
