argosdir = @argosdir@
nodist_argos_SCRIPTS = @GOOGLE_MAIL_SCRIPT@ @GOOGLE_CALENDAR_SCRIPT@ @GOOGLE_TASKS_SCRIPT@
EXTRA_DIST = scripts
CLEANFILES = $(nodist_argos_SCRIPTS) build-scripts.stamp

EXTRA_SCRIPTS =

SCRIPT_MAPPINGS = \
	scripts/google_mail.sh.in:@GOOGLE_MAIL_SCRIPT@ \
	scripts/google_calendar.sh.in:@GOOGLE_CALENDAR_SCRIPT@ \
	scripts/google_tasks.sh.in:@GOOGLE_TASKS_SCRIPT@

if IS_WORKSPACE
nodist_argos_SCRIPTS += $(GOOGLE_CHAT_SCRIPT)
SCRIPT_MAPPINGS += \
	scripts/google_chat.sh.in:@GOOGLE_CHAT_SCRIPT@
endif

$(nodist_argos_SCRIPTS): build-scripts.stamp

build-scripts.stamp: $(EXTRA_DIST)
	@echo "Generating Argos scripts..."
	@for pair in $(SCRIPT_MAPPINGS); do \
		template=$${pair%%:*}; \
		output=$${pair##*:}; \
		echo "  -> Building $$output"; \
		sed -e 's|@MAIL_QUERY[@]|$(MAIL_QUERY)|g' "$(srcdir)/$$template" > "$$output"; \
		chmod +x "$$output"; \
	done
	@touch build-scripts.stamp
