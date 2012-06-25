# Makefile for the Q test bench

.PHONY: all tests clean perlx qx tests test_qtb test_tb test_consq


all: qtb.q

# Check if q is in the path and does run properly
qx: ; echo "exit 0" | q

# Check if perl is in the path
perlx: ; echo "exit 0" | perl

tests: test_consq test_tb test_qtb

qtb.q: perlx test_consq test_qtb qtestbench/qtb-s.q
	cd qtestbench ; perl ../consq/consq.pl qtb-s.q ../qtb.q

test_qtb: qx qtestbench/qtb-s.q
	cd qtestbench ;	\
	q ../tb/runtests.q test_tree.q -q ; \
	q ../tb/runtests.q test_qtb.q -q 

test_tb: qx
	cd tb ; sh runtests.sh

test_consq: test_tb consq/consq.pl
	cd consq ; \
	q ../tb/runtests.q ctxtest.q -q ; \
	perl consq.pl ctxtest.q .cons-ctxtest.q \
	q ../tb/runtests.q .cons-ctxtest.q -q

clean:
	$(foreach d, . consq doc msglib qtestbench tb, rm -fv $(d)/*~ ; )
	rm -vf consq/.cons-ctxtest.q

distclean: clean
	rm -fv qtb.q



