AC_INIT([bar], [1.0])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])

AC_PATH_PROG([JQ], [jq])
AC_PATH_PROG([GOGCLI], [gog])

AC_PATH_PROG([SHELLCHECK], [shellcheck])
AM_CONDITIONAL([HAVE_SHELLCHECK], [test -n "$SHELLCHECK"])

AC_PATH_PROG([SHFMT], [shfmt])
AM_CONDITIONAL([HAVE_SHFMT], [test -n "$SHFMT"])

AC_ARG_WITH([argosdir],
    [AS_HELP_STRING([--with-argosdir=DIR], [Path to Argos directory])],
    [argosdir="$withval"],
    [argosdir="$HOME/.config/argos"]
)
AC_SUBST([argosdir])

AC_ARG_WITH([workspace],
    [AS_HELP_STRING([--with-workspace=1], [Enable workspace mode (changes default mail query)])],
    [USE_WORKSPACE="$withval"],
    [USE_WORKSPACE="0"]
)
AM_CONDITIONAL([IS_WORKSPACE], [test "x$USE_WORKSPACE" = "x1"])

AS_IF([test "x$USE_WORKSPACE" = "x1"],
    [default_mail_query="in:inbox is:unread"],
    [default_mail_query="in:inbox is:unread (category:primary OR category:primary)"]
)

AC_ARG_WITH([mail-query],
    [AS_HELP_STRING([--with-mail-query=STRING], [Mail search query])],
    [MAIL_QUERY="$withval"],
    [MAIL_QUERY="$default_mail_query"]
)
AC_SUBST([MAIL_QUERY])

AC_ARG_WITH([google-mail-freq],
    [AS_HELP_STRING([--with-google-mail-freq=TIME], [Google mail refresh frequency (default: 15m)])],
    [GOOGLE_MAIL_FREQ="$withval"], [GOOGLE_MAIL_FREQ="15m"]
)
AC_ARG_WITH([google-mail-pos],
    [AS_HELP_STRING([--with-google-mail-pos=NUM], [Google mail menu position (default: none)])],
    [GOOGLE_MAIL_POS="${withval}-"], [GOOGLE_MAIL_POS=""]
)
GOOGLE_MAIL_SCRIPT="${GOOGLE_MAIL_POS}google_mail.${GOOGLE_MAIL_FREQ}.sh"
AC_SUBST([GOOGLE_MAIL_SCRIPT])

AC_ARG_WITH([google-calendar-freq],
    [AS_HELP_STRING([--with-google-calendar-freq=TIME], [Google calendar refresh frequency (default: 15m)])],
    [GOOGLE_CALENDAR_FREQ="$withval"], [GOOGLE_CALENDAR_FREQ="15m"]
)
AC_ARG_WITH([google-calendar-pos],
    [AS_HELP_STRING([--with-google-calendar-pos=NUM], [Google calendar menu position (default: none)])],
    [GOOGLE_CALENDAR_POS="${withval}-"], [GOOGLE_CALENDAR_POS=""]
)
GOOGLE_CALENDAR_SCRIPT="${GOOGLE_CALENDAR_POS}google_calendar.${GOOGLE_CALENDAR_FREQ}.sh"
AC_SUBST([GOOGLE_CALENDAR_SCRIPT])

AC_ARG_WITH([google-tasks-freq],
    [AS_HELP_STRING([--with-google-tasks-freq=TIME], [Google tasks refresh frequency (default: 15m)])],
    [GOOGLE_TASKS_FREQ="$withval"], [GOOGLE_TASKS_FREQ="15m"]
)
AC_ARG_WITH([google-tasks-pos],
    [AS_HELP_STRING([--with-google-tasks-pos=NUM], [Google tasks menu position (default: none)])],
    [GOOGLE_TASKS_POS="${withval}-"], [GOOGLE_TASKS_POS=""]
)
GOOGLE_TASKS_SCRIPT="${GOOGLE_TASKS_POS}google_tasks.${GOOGLE_TASKS_FREQ}.sh"
AC_SUBST([GOOGLE_TASKS_SCRIPT])

AC_ARG_WITH([google-chat-freq],
    [AS_HELP_STRING([--with-google-chat-freq=TIME], [Google chat refresh frequency (default: 15m)])],
    [GOOGLE_CHAT_FREQ="$withval"], [GOOGLE_CHAT_FREQ="15m"]
)
AC_ARG_WITH([google-chat-pos],
    [AS_HELP_STRING([--with-google-chat-pos=NUM], [Google chat menu position (default: none)])],
    [GOOGLE_CHAT_POS="${withval}-"], [GOOGLE_CHAT_POS=""]
)
GOOGLE_CHAT_SCRIPT="${GOOGLE_CHAT_POS}google_chat.${GOOGLE_CHAT_FREQ}.sh"
AC_SUBST([GOOGLE_CHAT_SCRIPT])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
