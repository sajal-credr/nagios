#!/bin/sh                                                                                            
#
# Event handler script for restarting the nrpe server on the local machine
# Taken from the Nagios documentation and
# http://www.techadre.com/sites/techadre.com/files/event_handler_script_0.txt
# Adapted by L.C. Karssen
# Time-stamp: <2010-09-14 15:24:33 (root)>
#
# Note: This script will only restart the nrpe server if the service is
#       retried 3 times (in a "soft" state) or if the web service somehow
#       manages to fall into a "hard" error state.
#
 
date=`date`
 
# What state is the NRPE service in?
case "$1" in
OK)
        # The service just came back up, so don't do anything...
        ;;
WARNING)
        # We don't really care about warning states, since the service is probably still running...
        ;;
UNKNOWN)
        # We don't know what might be causing an unknown error, so don't do anything...
        ;;
CRITICAL)
        # Aha!  The BLAH service appears to have a problem - perhaps we should restart the server...
 
        # Is this a "soft" or a "hard" state?
        case "$2" in
 
        # We're in a "soft" state, meaning that Nagios is in the middle of retrying the
        # check before it turns into a "hard" state and contacts get notified...
        SOFT)
                # What check attempt are we on?  We don't want to restart the web server on the firs\
t
                # check, because it may just be a fluke!
                case "$3" in
 
                # Wait until the check has been tried 3 times before restarting the web server.
                # If the check fails on the 4th time (after we restart the web server), the state
                # type will turn to "hard" and contacts will be notified of the problem.
                # Hopefully this will restart the web server successfully, so the 4th check will
                # result in a "soft" recovery.  If that happens no one gets notified because we
                # fixed the problem!
                3)
                        echo -n "Restarting service $6 (3rd soft critical state)...\n"
                        # Call NRPE to restart the service on the remote machine
                        /usr/local/nagios/libexec/check_nrpe -H $4 -c restart-$5
                        echo "$date - restart $6 - SOFT"  >> /tmp/eventhandlers
                        ;;
                        esac
                ;;
 
        # The service somehow managed to turn into a hard error without getting fixed.
        # It should have been restarted by the code above, but for some reason it didn't.
        # Let's give it one last try, shall we?
        # Note: Contacts have already been notified of a problem with the service at this
        # point (unless you disabled notifications for this service)
        HARD)
                case "$3" in
 
                4)
                        echo -n "Restarting $6 service...\n"
                        # Call the init script to restart the NRPE server
                        echo "$date - restart $6 - HARD"  >> /tmp/eventhandlers
                        /usr/local/nagios/libexec/check_nrpe -H $4 -c restart-$5
                        ;;
                        esac
                ;;
        esac
        ;;
esac
exit 0

