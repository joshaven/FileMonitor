# TODO
## Issues
* The process doesn't end when exit is typed in an irb session.  It does, however exit when Ctrl+C 
  is pressed in an irb session. This can be observed by running `ps -A|grep irb` in an alternate window.
  (solution: pass the parent pid to the child and have the child check for the parent before running the process method)

## General
* Add a per directory seconds-between-scans setting so that it isn't possible for a 
  directory to be scanned for changes 1,000,000 times a second or some crazy such thing.
* remove file\_name\_regexp & callback variables from the :files\_recursive method.  The
  :files\_recursive method should not be calling add, it should only return a collection of files.
* Add the ability to register a callbacks for changed, deleted & added files
* Consider if the spawning should be removed from FileMonoitor