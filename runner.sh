while true; do perl tests/tests.pl; if [ 0 -ne 0 ]; then break; else sleep 5; fi; done;
