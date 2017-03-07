# BUILD ========================

MODULES = system acceptor client commander database leader replica scout server system

ERLC	= erlc -o ebin

ebin/%.beam: %.erl
		$(ERLC) $<

all:	ebin ${MODULES:%=ebin/%.beam}

ebin:
		mkdir ebin

debug:
		erl -s crashdump_viewer start

.PHONY: clean

clean:
		rm -f ebin/* erl_crash.dump

# RUN ========================

SYSTEM    = system

L_ERL     = erl -noshell -pa ebin -setcookie pass
L_ERLNODE = node

run:	all
		$(L_ERL) -s $(SYSTEM) start
