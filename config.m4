PHP_ARG_ENABLE([fpm2],,
  [AS_HELP_STRING([--enable-fpm2],
    [Enable building of the fpm2 SAPI executable])],
  [no],
  [no])

PHP_ARG_ENABLE([fpm2-entry-debug],,
  [AS_HELP_STRING([--enable-fpm2-entry-debug],
    [Enable fpm2 entry debug info for syslog])],
  [no])

if test "$PHP_fpm2_ENTRY_DEBUG" != "no"; then
  CFLAGS="$CFLAGS -Dfpm2_ENTRY_DEBUG"
fi

dnl Configure checks.
AC_DEFUN([AC_FPM2_STDLIBS],
[
  AC_CHECK_FUNCS(clearenv setproctitle setproctitle_fast)

  AC_SEARCH_LIBS(socket, socket)
  AC_SEARCH_LIBS(inet_addr, nsl)
])

AC_DEFUN([AC_FPM2_SETPFLAGS],
[
  AC_MSG_CHECKING([for setpflags])

  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include <priv.h>]], [[setpflags(0, 0);]])], [
    AC_DEFINE([HAVE_SETPFLAGS], 1, [do we have setpflags?])
    AC_MSG_RESULT([yes])
  ], [
    AC_MSG_RESULT([no])
  ])
])

AC_DEFUN([AC_FPM2_CLOCK],
[
  have_clock_gettime=no

  AC_MSG_CHECKING([for clock_gettime])

  AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <time.h>]], [[struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts);]])], [
    have_clock_gettime=yes
    AC_MSG_RESULT([yes])
  ], [
    AC_MSG_RESULT([no])
  ])

  if test "$have_clock_gettime" = "no"; then
    AC_MSG_CHECKING([for clock_gettime in -lrt])

    SAVED_LIBS="$LIBS"
    LIBS="$LIBS -lrt"

    AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <time.h>]], [[struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts);]])], [
      have_clock_gettime=yes
      AC_MSG_RESULT([yes])
    ], [
      LIBS="$SAVED_LIBS"
      AC_MSG_RESULT([no])
    ])
  fi

  if test "$have_clock_gettime" = "yes"; then
    AC_DEFINE([HAVE_CLOCK_GETTIME], 1, [do we have clock_gettime?])
  fi

  have_clock_get_time=no

  if test "$have_clock_gettime" = "no"; then
    AC_MSG_CHECKING([for clock_get_time])

    AC_RUN_IFELSE([AC_LANG_SOURCE([[#include <mach/mach.h>
      #include <mach/clock.h>
      #include <mach/mach_error.h>

      int main(void)
      {
        kern_return_t ret; clock_serv_t aClock; mach_timespec_t aTime;
        ret = host_get_clock_service(mach_host_self(), REALTIME_CLOCK, &aClock);

        if (ret != KERN_SUCCESS) {
          return 1;
        }

        ret = clock_get_time(aClock, &aTime);
        if (ret != KERN_SUCCESS) {
          return 2;
        }

        return 0;
      }
    ]])], [
      have_clock_get_time=yes
      AC_MSG_RESULT([yes])
    ], [
      AC_MSG_RESULT([no])
    ], [AC_MSG_RESULT([no (cross-compiling)])])
  fi

  if test "$have_clock_get_time" = "yes"; then
    AC_DEFINE([HAVE_CLOCK_GET_TIME], 1, [do we have clock_get_time?])
  fi
])

AC_DEFUN([AC_FPM2_TRACE],
[
  have_ptrace=no
  have_broken_ptrace=no

  AC_MSG_CHECKING([for ptrace])

  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
    #include <sys/types.h>
    #include <sys/ptrace.h> ]], [[ptrace(0, 0, (void *) 0, 0);]])], [
    have_ptrace=yes
    AC_MSG_RESULT([yes])
  ], [
    AC_MSG_RESULT([no])
  ])

  if test "$have_ptrace" = "yes"; then
    AC_MSG_CHECKING([whether ptrace works])

    AC_RUN_IFELSE([AC_LANG_SOURCE([[
      #include <unistd.h>
      #include <signal.h>
      #include <sys/wait.h>
      #include <sys/types.h>
      #include <sys/ptrace.h>
      #include <errno.h>

      #if !defined(PTRACE_ATTACH) && defined(PT_ATTACH)
      #define PTRACE_ATTACH PT_ATTACH
      #endif

      #if !defined(PTRACE_DETACH) && defined(PT_DETACH)
      #define PTRACE_DETACH PT_DETACH
      #endif

      #if !defined(PTRACE_PEEKDATA) && defined(PT_READ_D)
      #define PTRACE_PEEKDATA PT_READ_D
      #endif

      int main(void)
      {
        long v1 = (unsigned int) -1; /* copy will fail if sizeof(long) == 8 and we've got "int ptrace()" */
        long v2;
        pid_t child;
        int status;

        if ( (child = fork()) ) { /* parent */
          int ret = 0;

          if (0 > ptrace(PTRACE_ATTACH, child, 0, 0)) {
            return 2;
          }

          waitpid(child, &status, 0);

      #ifdef PT_IO
          struct ptrace_io_desc ptio = {
            .piod_op = PIOD_READ_D,
            .piod_offs = &v1,
            .piod_addr = &v2,
            .piod_len = sizeof(v1)
          };

          if (0 > ptrace(PT_IO, child, (void *) &ptio, 0)) {
            ret = 3;
          }
      #else
          errno = 0;

          v2 = ptrace(PTRACE_PEEKDATA, child, (void *) &v1, 0);

          if (errno) {
            ret = 4;
          }
      #endif
          ptrace(PTRACE_DETACH, child, (void *) 1, 0);

          kill(child, SIGKILL);

          return ret ? ret : (v1 != v2);
        }
        else { /* child */
          sleep(10);
          return 0;
        }
      }
    ]])], [
      AC_MSG_RESULT([yes])
    ], [
      have_ptrace=no
      have_broken_ptrace=yes
      AC_MSG_RESULT([no])
    ], [
      AC_MSG_RESULT([skipped (cross-compiling)])
    ])
  fi

  if test "$have_ptrace" = "yes"; then
    AC_DEFINE([HAVE_PTRACE], 1, [do we have ptrace?])
  fi

  have_mach_vm_read=no

  if test "$have_broken_ptrace" = "yes"; then
    AC_MSG_CHECKING([for mach_vm_read])

    AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include <mach/mach.h>
      #include <mach/mach_vm.h>
    ]], [[
      mach_vm_read((vm_map_t)0, (mach_vm_address_t)0, (mach_vm_size_t)0, (vm_offset_t *)0, (mach_msg_type_number_t*)0);
    ]])], [
      have_mach_vm_read=yes
      AC_MSG_RESULT([yes])
    ], [
      AC_MSG_RESULT([no])
    ])
  fi

  if test "$have_mach_vm_read" = "yes"; then
    AC_DEFINE([HAVE_MACH_VM_READ], 1, [do we have mach_vm_read?])
  fi

  proc_mem_file=""

  if test -r /proc/$$/mem ; then
    proc_mem_file="mem"
  else
    if test -r /proc/$$/as ; then
      proc_mem_file="as"
    fi
  fi

  if test -n "$proc_mem_file" ; then
    AC_MSG_CHECKING([for proc mem file])

    AC_RUN_IFELSE([AC_LANG_SOURCE([[
      #define _GNU_SOURCE
      #define _FILE_OFFSET_BITS 64
      #include <stdint.h>
      #include <unistd.h>
      #include <sys/types.h>
      #include <sys/stat.h>
      #include <fcntl.h>
      #include <stdio.h>
      int main(void)
      {
        long v1 = (unsigned int) -1, v2 = 0;
        char buf[128];
        int fd;
        sprintf(buf, "/proc/%d/$proc_mem_file", getpid());
        fd = open(buf, O_RDONLY);
        if (0 > fd) {
          return 1;
        }
        if (sizeof(long) != pread(fd, &v2, sizeof(long), (uintptr_t) &v1)) {
          close(fd);
          return 1;
        }
        close(fd);
        return v1 != v2;
      }
    ]])], [
      AC_MSG_RESULT([$proc_mem_file])
    ], [
      proc_mem_file=""
      AC_MSG_RESULT([no])
    ], [
      AC_MSG_RESULT([skipped (cross-compiling)])
    ])
  fi

  if test -n "$proc_mem_file"; then
    AC_DEFINE_UNQUOTED([PROC_MEM_FILE], "$proc_mem_file", [/proc/pid/mem interface])
  fi

  fpm2_trace_type=""

  if test "$have_ptrace" = "yes"; then
    fpm2_trace_type=ptrace

  elif test -n "$proc_mem_file"; then
    fpm2_trace_type=pread

  elif test "$have_mach_vm_read" = "yes" ; then
    fpm2_trace_type=mach

  else
    AC_MSG_WARN([FPM2 Trace - ptrace, pread, or mach: could not be found])
  fi

])

AC_DEFUN([AC_FPM2_BUILTIN_ATOMIC],
[
  AC_MSG_CHECKING([if gcc supports __sync_bool_compare_and_swap])
  AC_LINK_IFELSE([AC_LANG_PROGRAM([], [[
    int variable = 1;
    return (__sync_bool_compare_and_swap(&variable, 1, 2)
           && __sync_add_and_fetch(&variable, 1)) ? 1 : 0;
  ]])], [
    AC_MSG_RESULT([yes])
    AC_DEFINE(HAVE_BUILTIN_ATOMIC, 1, [Define to 1 if gcc supports __sync_bool_compare_and_swap() a.o.])
  ], [
    AC_MSG_RESULT([no])
  ])
])

AC_DEFUN([AC_FPM2_LQ],
[
  have_lq=no

  AC_MSG_CHECKING([for TCP_INFO])

  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include <netinet/tcp.h>]], [[struct tcp_info ti; int x = TCP_INFO;]])], [
    have_lq=tcp_info
    AC_MSG_RESULT([yes])
  ], [
    AC_MSG_RESULT([no])
  ])

  if test "$have_lq" = "tcp_info"; then
    AC_DEFINE([HAVE_LQ_TCP_INFO], 1, [do we have TCP_INFO?])
  fi

  AC_MSG_CHECKING([for TCP_CONNECTION_INFO])

  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include <netinet/tcp.h>]], [[struct tcp_connection_info ti; int x = TCP_CONNECTION_INFO;]])], [
    have_lq=tcp_connection_info
    AC_MSG_RESULT([yes])
  ], [
    AC_MSG_RESULT([no])
  ])

  if test "$have_lq" = "tcp_connection_info"; then
    AC_DEFINE([HAVE_LQ_TCP_CONNECTION_INFO], 1, [do we have TCP_CONNECTION_INFO?])
  fi

  if test "$have_lq" = "no" ; then
    AC_MSG_CHECKING([for SO_LISTENQLEN])

    AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include <sys/socket.h>]], [[int x = SO_LISTENQLIMIT; int y = SO_LISTENQLEN;]])], [
      have_lq=so_listenq
      AC_MSG_RESULT([yes])
    ], [
      AC_MSG_RESULT([no])
    ])

    if test "$have_lq" = "tcp_info"; then
      AC_DEFINE([HAVE_LQ_SO_LISTENQ], 1, [do we have SO_LISTENQxxx?])
    fi
  fi
])

AC_DEFUN([AC_FPM2_SYSCONF],
[
	AC_MSG_CHECKING([for sysconf])

	AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include <unistd.h>]], [[sysconf(_SC_CLK_TCK);]])],[
		AC_DEFINE([HAVE_SYSCONF], 1, [do we have sysconf?])
		AC_MSG_RESULT([yes])
	], [
		AC_MSG_RESULT([no])
	])
])

AC_DEFUN([AC_FPM2_TIMES],
[
	AC_MSG_CHECKING([for times])

	AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include <sys/times.h>]], [[struct tms t; times(&t);]])],[
		AC_DEFINE([HAVE_TIMES], 1, [do we have times?])
		AC_MSG_RESULT([yes])
	], [
		AC_MSG_RESULT([no])
	])
])

AC_DEFUN([AC_FPM2_KQUEUE],
[
	AC_MSG_CHECKING([for kqueue])

	AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
		#include <sys/types.h>
		#include <sys/event.h>
		#include <sys/time.h>
	]], [[
		int kfd;
		struct kevent k;
		kfd = kqueue();
		/* 0 -> STDIN_FILENO */
		EV_SET(&k, 0, EVFILT_READ , EV_ADD | EV_CLEAR, 0, 0, NULL);
	]])], [
		AC_DEFINE([HAVE_KQUEUE], 1, [do we have kqueue?])
		AC_MSG_RESULT([yes])
	], [
		AC_MSG_RESULT([no])
	])
])

AC_DEFUN([AC_FPM2_PORT],
[
	AC_MSG_CHECKING([for port framework])

	AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
		#include <port.h>
	]], [[
		int port;

		port = port_create();
		if (port < 0) {
			return 1;
		}
	]])], [
		AC_DEFINE([HAVE_PORT], 1, [do we have port framework?])
		AC_MSG_RESULT([yes])
	], [
		AC_MSG_RESULT([no])
	])
])

AC_DEFUN([AC_FPM2_DEVPOLL],
[
	AC_MSG_CHECKING([for /dev/poll])

	AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
		#include <stdio.h>
		#include <sys/devpoll.h>
	]], [[
		int n, dp;
		struct dvpoll dvp;
		dp = 0;
		dvp.dp_fds = NULL;
		dvp.dp_nfds = 0;
		dvp.dp_timeout = 0;
		n = ioctl(dp, DP_POLL, &dvp)
	]])], [
		AC_DEFINE([HAVE_DEVPOLL], 1, [do we have /dev/poll?])
		AC_MSG_RESULT([yes])
	], [
		AC_MSG_RESULT([no])
	])
])

AC_DEFUN([AC_FPM2_EPOLL],
[
	AC_MSG_CHECKING([for epoll])

	AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
		#include <sys/epoll.h>
	]], [[
		int epollfd;
		struct epoll_event e;

		epollfd = epoll_create(1);
		if (epollfd < 0) {
			return 1;
		}

		e.events = EPOLLIN | EPOLLET;
		e.data.fd = 0;

		if (epoll_ctl(epollfd, EPOLL_CTL_ADD, 0, &e) == -1) {
			return 1;
		}

		e.events = 0;
		if (epoll_wait(epollfd, &e, 1, 1) < 0) {
			return 1;
		}
	]])], [
		AC_DEFINE([HAVE_EPOLL], 1, [do we have epoll?])
		AC_MSG_RESULT([yes])
	], [
		AC_MSG_RESULT([no])
	])
])

AC_DEFUN([AC_FPM2_SELECT],
[
	AC_MSG_CHECKING([for select])

	AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
		/* According to POSIX.1-2001 */
		#include <sys/select.h>

		/* According to earlier standards */
		#include <sys/time.h>
		#include <sys/types.h>
		#include <unistd.h>
	]], [[
		fd_set fds;
		struct timeval t;
		t.tv_sec = 0;
		t.tv_usec = 42;
		FD_ZERO(&fds);
		/* 0 -> STDIN_FILENO */
		FD_SET(0, &fds);
		select(FD_SETSIZE, &fds, NULL, NULL, &t);
	]])], [
		AC_DEFINE([HAVE_SELECT], 1, [do we have select?])
		AC_MSG_RESULT([yes])
	], [
		AC_MSG_RESULT([no])
	])
])

AC_MSG_CHECKING(for FPM2 build)
if test "$PHP_FPM2" != "no"; then
  AC_MSG_RESULT($PHP_FPM2)

  AC_FPM2_STDLIBS
  AC_FPM2_SETPFLAGS
  AC_FPM2_CLOCK
  AC_FPM2_TRACE
  AC_FPM2_BUILTIN_ATOMIC
  AC_FPM2_LQ
  AC_FPM2_SYSCONF
  AC_FPM2_TIMES
  AC_FPM2_KQUEUE
  AC_FPM2_PORT
  AC_FPM2_DEVPOLL
  AC_FPM2_EPOLL
  AC_FPM2_SELECT

  PHP_ARG_WITH([fpm2-user],,
    [AS_HELP_STRING([[--with-fpm2-user[=USER]]],
      [Set the user for php-fpm2 to run as. (default: nobody)])],
    [nobody],
    [no])

  PHP_ARG_WITH([fpm2-group],,
    [AS_HELP_STRING([[--with-fpm2-group[=GRP]]],
      [Set the group for php-fpm2 to run as. For a system user, this should
      usually be set to match the fpm2 username (default: nobody)])],
    [nobody],
    [no])

  PHP_ARG_WITH([fpm2-systemd],,
    [AS_HELP_STRING([--with-fpm2-systemd],
      [Activate systemd integration])],
    [no],
    [no])

  PHP_ARG_WITH([fpm2-acl],,
    [AS_HELP_STRING([--with-fpm2-acl],
      [Use POSIX Access Control Lists])],
    [no],
    [no])

  PHP_ARG_WITH([fpm2-apparmor],,
    [AS_HELP_STRING([--with-fpm2-apparmor],
      [Support AppArmor confinement through libapparmor])],
    [no],
    [no])

  PHP_ARG_WITH([fpm2-selinux],,
    [AS_HELP_STRING([--with-fpm2-selinux],
      [Support SELinux policy library])],
    [no],
    [no])

  if test "$PHP_FPM2_SYSTEMD" != "no" ; then
    PKG_CHECK_MODULES([SYSTEMD], [libsystemd >= 209])

    AC_CHECK_HEADERS(systemd/sd-daemon.h, [HAVE_SD_DAEMON_H="yes"], [HAVE_SD_DAEMON_H="no"])
    if test $HAVE_SD_DAEMON_H = "no"; then
      AC_MSG_ERROR([Your system does not support systemd.])
    else
      AC_DEFINE(HAVE_SYSTEMD, 1, [FPM2 use systemd integration])
      PHP_FPM2_SD_FILES="fpm/fpm_systemd.c"
      PHP_EVAL_LIBLINE($SYSTEMD_LIBS)
      PHP_EVAL_INCLINE($SYSTEMD_CFLAGS)
      php_fpm2_systemd=notify
    fi
  else
    php_fpm2_systemd=simple
  fi

  if test "$PHP_FPM2_ACL" != "no" ; then
    AC_MSG_CHECKING([for acl user/group permissions support])
    AC_CHECK_HEADERS([sys/acl.h])

    AC_COMPILE_IFELSE([AC_LANG_SOURCE([[#include <sys/acl.h>
      int main(void)
      {
        acl_t acl;
        acl_entry_t user, group;
        acl = acl_init(1);
        acl_create_entry(&acl, &user);
        acl_set_tag_type(user, ACL_USER);
        acl_create_entry(&acl, &group);
        acl_set_tag_type(user, ACL_GROUP);
        acl_free(acl);
        return 0;
      }
    ]])], [
      AC_CHECK_LIB(acl, acl_free, 
        [PHP_ADD_LIBRARY(acl)
          have_fpm2_acl=yes
          AC_MSG_RESULT([yes])
        ],[
          AC_RUN_IFELSE([AC_LANG_SOURCE([[#include <sys/acl.h>
            int main(void)
            {
              acl_t acl;
              acl_entry_t user, group;
              acl = acl_init(1);
              acl_create_entry(&acl, &user);
              acl_set_tag_type(user, ACL_USER);
              acl_create_entry(&acl, &group);
              acl_set_tag_type(user, ACL_GROUP);
              acl_free(acl);
              return 0;
            }
          ]])], [
            have_fpm2_acl=yes
            AC_MSG_RESULT([yes])
          ], [
            have_fpm2_acl=no
            AC_MSG_RESULT([no])
          ], [AC_MSG_RESULT([skipped])])
        ])
    ], [
      have_fpm2_acl=no
      AC_MSG_RESULT([no])
    ], [AC_MSG_RESULT([skipped (cross-compiling)])])

    if test "$have_fpm2_acl" = "yes"; then
      AC_DEFINE([HAVE_FPM2_ACL], 1, [do we have acl support?])
    fi
  fi

  if test "x$PHP_FPM2_APPARMOR" != "xno" ; then
    AC_CHECK_HEADERS([sys/apparmor.h])
    AC_CHECK_LIB(apparmor, aa_change_profile, [
      PHP_ADD_LIBRARY(apparmor)
      AC_DEFINE(HAVE_APPARMOR, 1, [ AppArmor confinement available ])
    ],[
      AC_MSG_ERROR(libapparmor required but not found)
    ])
  fi

  if test "x$PHP_FPM2_SELINUX" != "xno" ; then
    AC_CHECK_HEADERS([selinux/selinux.h])
    AC_CHECK_LIB(selinux, security_setenforce, [
      PHP_ADD_LIBRARY(selinux)
      AC_DEFINE(HAVE_SELINUX, 1, [ SElinux available ])
    ],[])
  fi

  PHP_SUBST_OLD(php_fpm2_systemd)
  AC_DEFINE_UNQUOTED(PHP_FPM2_SYSTEMD, "$php_fpm2_systemd", [fpm2 systemd service type])

  if test -z "$PHP_FPM2_USER" -o "$PHP_FPM2_USER" = "yes" -o "$PHP_FPM2_USER" = "no"; then
    php_fpm2_user="nobody"
  else
    php_fpm2_user="$PHP_FPM2_USER"
  fi

  if test -z "$PHP_FPM2_GROUP" -o "$PHP_FPM2_GROUP" = "yes" -o "$PHP_FPM2_GROUP" = "no"; then
    php_fpm2_group="nobody"
  else
    php_fpm2_group="$PHP_FPM2_GROUP"
  fi

  PHP_SUBST_OLD(php_fpm2_user)
  PHP_SUBST_OLD(php_fpm2_group)
  php_fpm2_sysconfdir=`eval echo $sysconfdir`
  PHP_SUBST_OLD(php_fpm2_sysconfdir)
  php_fpm2_localstatedir=`eval echo $localstatedir`
  PHP_SUBST_OLD(php_fpm2_localstatedir)
  php_fpm2_prefix=`eval echo $prefix`
  PHP_SUBST_OLD(php_fpm2_prefix)

  AC_DEFINE_UNQUOTED(PHP_FPM2_USER, "$php_fpm2_user", [fpm2 user name])
  AC_DEFINE_UNQUOTED(PHP_FPM2_GROUP, "$php_fpm2_group", [fpm2 group name])

  PHP_ADD_BUILD_DIR(sapi/fpm2/fpm)
  PHP_ADD_BUILD_DIR(sapi/fpm2/fpm/events)
  PHP_OUTPUT(sapi/fpm2/php-fpm.conf sapi/fpm2/www.conf sapi/fpm2/init.d.php-fpm sapi/fpm2/php-fpm.service sapi/fpm2/php-fpm.8 sapi/fpm2/status.html)
  PHP_ADD_MAKEFILE_FRAGMENT([$abs_srcdir/sapi/fpm2/Makefile.frag])

  SAPI_FPM2_PATH=sapi/fpm2/php-fpm

  if test "$fpm2_trace_type" && test -f "$abs_srcdir/sapi/fpm2/fpm/fpm_trace_$fpm2_trace_type.c"; then
    PHP_FPM2_TRACE_FILES="fpm/fpm_trace.c fpm/fpm_trace_$fpm2_trace_type.c"
  fi

  PHP_FPM2_CFLAGS="-I$abs_srcdir/sapi/fpm2 -DZEND_ENABLE_STATIC_TSRMLS_CACHE=1"

  PHP_FPM2_FILES="fpm/fpm.c \
    fpm/fpm_children.c \
    fpm/fpm_cleanup.c \
    fpm/fpm_clock.c \
    fpm/fpm_conf.c \
    fpm/fpm_env.c \
    fpm/fpm_events.c \
    fpm/fpm_log.c \
    fpm/fpm_main.c \
    fpm/fpm_php.c \
    fpm/fpm_php_trace.c \
    fpm/fpm_process_ctl.c \
    fpm/fpm_request.c \
    fpm/fpm_shm.c \
    fpm/fpm_scoreboard.c \
    fpm/fpm_signals.c \
    fpm/fpm_sockets.c \
    fpm/fpm_status.c \
    fpm/fpm_stdio.c \
    fpm/fpm_unix.c \
    fpm/fpm_worker_pool.c \
    fpm/zlog.c \
    fpm/events/select.c \
    fpm/events/poll.c \
    fpm/events/epoll.c \
    fpm/events/kqueue.c \
    fpm/events/devpoll.c \
    fpm/events/port.c \
  "

  PHP_SELECT_SAPI(fpm2, program, $PHP_FPM2_FILES $PHP_FPM2_TRACE_FILES $PHP_FPM2_SD_FILES, $PHP_FPM2_CFLAGS, '$(SAPI_FPM2_PATH)')

  case $host_alias in
      *aix*)
        BUILD_FPM2="echo '\#! .' > php.sym && echo >>php.sym && nm -BCpg \`echo \$(PHP_GLOBAL_OBJS) \$(PHP_BINARY_OBJS) \$(PHP_FPM2_OBJS) | sed 's/\([A-Za-z0-9_]*\)\.lo/\1.o/g'\` | \$(AWK) '{ if (((\$\$2 == \"T\") || (\$\$2 == \"D\") || (\$\$2 == \"B\")) && (substr(\$\$3,1,1) != \".\")) { print \$\$3 } }' | sort -u >> php.sym && \$(LIBTOOL) --mode=link \$(CC) -export-dynamic \$(CFLAGS_CLEAN) \$(EXTRA_CFLAGS) \$(EXTRA_LDFLAGS_PROGRAM) \$(LDFLAGS) -Wl,-brtl -Wl,-bE:php.sym \$(PHP_RPATHS) \$(PHP_GLOBAL_OBJS) \$(PHP_BINARY_OBJS) \$(PHP_FASTCGI_OBJS) \$(PHP_FPM2_OBJS) \$(EXTRA_LIBS) \$(FPM2_EXTRA_LIBS) \$(ZEND_EXTRA_LIBS) -o \$(SAPI_FPM2_PATH)"
        ;;
      *darwin*)
        BUILD_FPM2="\$(CC) \$(CFLAGS_CLEAN) \$(EXTRA_CFLAGS) \$(EXTRA_LDFLAGS_PROGRAM) \$(LDFLAGS) \$(NATIVE_RPATHS) \$(PHP_GLOBAL_OBJS:.lo=.o) \$(PHP_BINARY_OBJS:.lo=.o) \$(PHP_FASTCGI_OBJS:.lo=.o) \$(PHP_FPM2_OBJS:.lo=.o) \$(PHP_FRAMEWORKS) \$(EXTRA_LIBS) \$(FPM2_EXTRA_LIBS) \$(ZEND_EXTRA_LIBS) -o \$(SAPI_FPM2_PATH)"
      ;;
      *)
        BUILD_FPM2="\$(LIBTOOL) --mode=link \$(CC) -export-dynamic \$(CFLAGS_CLEAN) \$(EXTRA_CFLAGS) \$(EXTRA_LDFLAGS_PROGRAM) \$(LDFLAGS) \$(PHP_RPATHS) \$(PHP_GLOBAL_OBJS:.lo=.o) \$(PHP_BINARY_OBJS:.lo=.o) \$(PHP_FASTCGI_OBJS:.lo=.o) \$(PHP_FPM2_OBJS:.lo=.o) \$(EXTRA_LIBS) \$(FPM2_EXTRA_LIBS) \$(ZEND_EXTRA_LIBS) -o \$(SAPI_FPM2_PATH)"
      ;;
  esac

  PHP_SUBST(SAPI_FPM2_PATH)
  PHP_SUBST(BUILD_FPM2)

else
  AC_MSG_RESULT(no)
fi
