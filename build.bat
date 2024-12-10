@echo off
win_bison -v -d cpl.y
win_flex cla.lex
gcc lex.yy.c cpl.tab.c