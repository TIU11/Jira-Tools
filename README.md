Jira-Tools
==========

Methods that access Jira's api's to do useful things.

## Usage
1. Pull down code from GitHub
2. Update `jira.yml` with your Jira settings
3. Require Jira class and call the methods.

    <pre>
    require './jira.rb'
    j = Jira.new
    j.search "resolved > startOfDay()"
    puts "#{j.total_time_spent} seconds"
    puts "#{j.total_story_points} points"
    puts "#{j.data['issues'].count} issues"
    </pre>

## Todo

* Clean out dead/broken code so this can be consumed by others.

## License

Copyright 2012 Tuscarora Intermediate Unit

This file is part of Jira-Tools.

Jira-Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Jira-Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Jira-Tools.  If not, see [http://www.gnu.org/licenses/].