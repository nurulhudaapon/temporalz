Add the following tests and mark them as Todo: 

Temporal.Duration
Temporal.Instant
Temporal.Now
Temporal.PlainDate
Temporal.PlainDateTime
Temporal.PlainMonthDay
Temporal.PlainTime
Temporal.PlainYearMonth
Temporal.ZonedDateTime

Temporal.Duration
Constructor
Temporal.Duration()
Static methods
compare()
from()
Instance methods
abs()
add()
negated()
round()
subtract()
toJSON()
toLocaleString()
toString()
total()
valueOf()
with()
Instance properties
blank
days
hours
microseconds
milliseconds
minutes
months
nanoseconds
seconds
sign
weeks
years

Temporal.Instant
Constructor
Temporal.Instant()
Experimental
Static methods
compare()
from()
fromEpochMilliseconds()
fromEpochNanoseconds()
Instance methods
add()
equals()
round()
since()
subtract()
toJSON()
toLocaleString()
toString()
toZonedDateTimeISO()
until()
valueOf()
Instance properties
epochMilliseconds
epochNanoseconds

Temporal.Now
Static methods
instant()
plainDateISO()
plainDateTimeISO()
plainTimeISO()
timeZoneId()
zonedDateTimeISO()

Temporal.PlainDate
Constructor
Temporal.PlainDate()
Experimental
Static methods
compare()
from()
Instance methods
add()
equals()
since()
subtract()
toJSON()
toLocaleString()
toPlainDateTime()
toPlainMonthDay()
toPlainYearMonth()
toString()
toZonedDateTime()
until()
valueOf()
with()
withCalendar()
Instance properties
calendarId
day
dayOfWeek
dayOfYear
daysInMonth
daysInWeek
daysInYear
era
eraYear
inLeapYear
month
monthCode
monthsInYear
weekOfYear
year
yearOfWeek

Temporal.PlainDateTime
Constructor
Temporal.PlainDateTime()
Experimental
Static methods
compare()
from()
Instance methods
add()
equals()
round()
since()
subtract()
toJSON()
toLocaleString()
toPlainDate()
toPlainTime()
toString()
toZonedDateTime()
until()
valueOf()
with()
withCalendar()
withPlainTime()
Instance properties
calendarId
day
dayOfWeek
dayOfYear
daysInMonth
daysInWeek
daysInYear
era
eraYear
hour
inLeapYear
microsecond
millisecond
minute
month
monthCode
monthsInYear
nanosecond
second
weekOfYear
year
yearOfWeek

Temporal.PlainMonthDay
Constructor
Temporal.PlainMonthDay()
Experimental
Static methods
from()
Instance methods
equals()
toJSON()
toLocaleString()
toPlainDate()
toString()
valueOf()
with()
Instance properties
calendarId
day
monthCode

Temporal.PlainTime
Constructor
Temporal.PlainTime()
Static methods
compare()
from()
Instance methods
add()
equals()
round()
since()
subtract()
toJSON()
toLocaleString()
toString()
until()
valueOf()
with()
Instance properties
hour
microsecond
millisecond
minute
nanosecond
second

Temporal.PlainYearMonth
Constructor
Temporal.PlainYearMonth()
Experimental
Static methods
compare()
from()
Instance methods
add()
equals()
since()
subtract()
toJSON()
toLocaleString()
toPlainDate()
toString()
until()
valueOf()
with()
Instance properties
calendarId
daysInMonth
daysInYear
era
eraYear
inLeapYear
month
monthCode
monthsInYear
year

Temporal.ZonedDateTime
Constructor
Temporal.ZonedDateTime()
Experimental
Static methods
compare()
from()
Instance methods
add()
equals()
getTimeZoneTransition()
round()
since()
startOfDay()
subtract()
toInstant()
toJSON()
toLocaleString()
toPlainDate()
toPlainDateTime()
toPlainTime()
toString()
until()
valueOf()
with()
withCalendar()
withPlainTime()
withTimeZone()
Instance properties
calendarId
day
dayOfWeek
dayOfYear
daysInMonth
daysInWeek
daysInYear
epochMilliseconds
epochNanoseconds
era
eraYear
hour
hoursInDay
inLeapYear
microsecond
millisecond
minute
month
monthCode
monthsInYear
nanosecond
offset
offsetNanoseconds
second
timeZoneId
weekOfYear
year
yearOfWeek