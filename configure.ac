AC_INIT([bar], [1.0])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])

AC_PATH_PROG([SHELLCHECK], [shellcheck])
AM_CONDITIONAL([HAVE_SHELLCHECK], [test -n "$SHELLCHECK"])

AC_PATH_PROG([SHFMT], [shfmt])
AM_CONDITIONAL([HAVE_SHFMT], [test -n "$SHFMT"])

AC_ARG_WITH([argosdir],
    [AS_HELP_STRING([--with-argos-dir=DIR], [Path to Argos directory])],
    [argosdir="$withval"],
    [argosdir="$HOME/.config/argos"]
)
AC_SUBST([argosdir])

AC_ARG_VAR([USE_WORKSPACE], [Enable workspace mode (changes default mail query and omits chat script)])
AS_IF([test -z "$USE_WORKSPACE"], [
    USE_WORKSPACE="0"
])
AM_CONDITIONAL([IS_WORKSPACE], [test "x$USE_WORKSPACE" = "x1"])

AS_IF([test "x$USE_WORKSPACE" = "x1"],
    [default_mail_query="in:inbox is:unread"],
    [default_mail_query="in:inbox is:unread (category:primary OR category:primary)"]
)

AC_ARG_VAR([MAIL_QUERY], [Mail search query])
AS_IF([test -z "$MAIL_QUERY"], [
    MAIL_QUERY="$default_mail_query"
])
AC_SUBST([MAIL_QUERY])

AC_ARG_VAR([GOOGLE_MAIL_FREQ], [Google mail refresh frequency (default: 15m)])
AS_IF([test -z "$GOOGLE_MAIL_FREQ"], [
    GOOGLE_MAIL_FREQ="15m"
])
AC_ARG_VAR([GOOGLE_MAIL_POS], [Google mail menu position (default: none)])
AS_IF([test -z "$GOOGLE_MAIL_POS"], [
    GOOGLE_MAIL_POS=""
])
GOOGLE_MAIL_SCRIPT="${GOOGLE_MAIL_POS}google_mail.${GOOGLE_MAIL_FREQ}.sh"
AC_SUBST([GOOGLE_MAIL_SCRIPT])

AC_ARG_VAR([GOOGLE_CALENDAR_FREQ], [Google calendar refresh frequency (default: 15m)])
AS_IF([test -z "$GOOGLE_CALENDAR_FREQ"], [
    GOOGLE_CALENDAR_FREQ="15m"
])
AC_ARG_VAR([GOOGLE_CALENDAR_POS], [Google calendar menu position (default: none)])
AS_IF([test -z "$GOOGLE_CALENDAR_POS"], [
    GOOGLE_CALENDAR_POS=""
])
GOOGLE_CALENDAR_SCRIPT="${GOOGLE_CALENDAR_POS}google_calendar.${GOOGLE_CALENDAR_FREQ}.sh"
AC_SUBST([GOOGLE_CALENDAR_SCRIPT])

AC_ARG_VAR([GOOGLE_TASKS_FREQ], [Google tasks refresh frequency (default: 15m)])
AS_IF([test -z "$GOOGLE_TASKS_FREQ"], [
    GOOGLE_TASKS_FREQ="15m"
])
AC_ARG_VAR([GOOGLE_TASKS_POS], [Google tasks menu position (default: none)])
AS_IF([test -z "$GOOGLE_TASKS_POS"], [
    GOOGLE_TASKS_POS=""
])
GOOGLE_TASKS_SCRIPT="${GOOGLE_TASKS_POS}google_tasks.${GOOGLE_TASKS_FREQ}.sh"
AC_SUBST([GOOGLE_TASKS_SCRIPT])

AC_ARG_VAR([GOOGLE_CHAT_FREQ], [Google chat refresh frequency (default: 15m)])
AS_IF([test -z "$GOOGLE_CHAT_FREQ"], [
    GOOGLE_CHAT_FREQ="15m"
])
AC_ARG_VAR([GOOGLE_CHAT_POS], [Google chat menu position (default: none)])
AS_IF([test -z "$GOOGLE_CHAT_POS"], [
    GOOGLE_CHAT_POS=""
])
GOOGLE_CHAT_SCRIPT="${GOOGLE_CHAT_POS}google_chat.${GOOGLE_CHAT_FREQ}.sh"
AC_SUBST([GOOGLE_CHAT_SCRIPT])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
