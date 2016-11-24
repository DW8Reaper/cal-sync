# cal-sync

Cal-sync is an OSX command line utility to synchronize calendar events between calendars. The synced events are tracked through the event 
URL which unfortunately makes the URL field unusable but also means there are no additional files or databases involved.

## Building
Building should be as simple as opening the project file in XCode and then building the cal-sync target. There is also a 
unit-test target for executing the unit tests.
## Viewing available Calendars
To sync calendars, you need to know their unique ID's. This can be retrieved with cal-sync by running with the list command:
```{shell}
./cal-sync --list
```
## Syncing events
To sync events from one calendar to another (currently this is always past 7 days and next 14 days of events)
```{shell}
./cal-sync --src ABC23C36-A75A-4288-A48A-8CEA1135D1E1 --dst ZZZ23C36-Z75Z-4288-Z48Z-8CEA1135D1E1 
```
it is best to add the verbose and test options when you are still testing things out. Verbose prints a message for each event created, updated 
or deleted and test prevents any real changes from being applied
```{shell}
./cal-sync --src ABC23C36-A75A-4288-A48A-8CEA1135D1E1 --dst ZZZ23C36-Z75Z-4288-Z48Z-8CEA1135D1E1 --verbose --test 
```
## Syncing multiple calendars
Cal-sync uses a prefix in the URL field to determine which events to sync. Any events matching the prefix (default is "cal-sync") will be updated. 
This allows you to sync multiple sources into a single destination calendar as long as each source uses its own prefix
```{shell}
./cal-sync --src ABC23C36-A75A-4288-A48A-8CEA1135D1E1 --dst ZZZ23C36-Z75Z-4288-Z48Z-8CEA1135D1E1 --prefix "first-calendar"
./cal-sync --src MMM23C36-MMMM-4288-A48A-8CEA1135D1E1 --dst ZZZ23C36-Z75Z-4288-Z48Z-8CEA1135D1E1 --prefix "second-calendar"
```
Any events that do not match these prefixes will be left alone so you can still create events manually in the destination calendar as well

## Excluding fields
By default, cal-sync will sync titles, notes, locations and availability information. If your company limits calendar access for security 
reasons you should be mindful of those considerations and use the exclusion features to exclude any fields that may have sensitive information

* `--no-title   ` - do not sync titles
* `--no-location` - do not sync locations
* `--no-notes   ` - do not sync notes
* `--no-avail   ` - set all events availability to free
