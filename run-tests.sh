#!/usr/bin/bash
OPENSCAD="../openscad/build-Debug-vscode/openscad"
tests_failed=0
tests_ran=0
total_tests=`ls test_*.scad | wc -l`
clear_line=`tput el`
for f in test_*.scad; do
  printf "\r$((tests_ran+1))/$total_tests: $f${clear_line}"
  output=`$OPENSCAD -o tmp.stl $f 2>&1 \
    | grep --color=always -E "^(WARNING|ERROR|TRACE):"`
  if [ "$?" == "0" ]; then
    echo "$output" | sed -n 's/^/  /p'
    tests_failed=$((tests_failed+1))
  fi
  tests_ran=$((tests_ran+1))
done

if [ $tests_failed == 0 ]; then
  printf "\rSUCCESS! No failing tests!${clear_line}\n"
fi
