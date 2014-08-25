# RepoScout Service

The RepoScout Service is a (kind of) small rack app to compute, cache, and serve up ScoutScores. It also tracks recent searches on the site.

## ScoutScore

A ScoutScore is a combination of scores from 5 different event types and a "meta" factor. Each event type has it's own flavor of scoring and the validity of each score type is definitely up for debate. All of the score types are currently shoved into [health.rb](lib/health.rb) which is less than ideal, but works and is fairly understandable for now.

## Setup

_Not verified_

### ENV Variables

#### Google BigQuery

RepoScout needs a BigQuery project to hit and the credentials to do that.

`GOOGLE_API_ISSUER` - Part of the creds you are given on project creation.
`GOOGLE_API_PRIVATE_KEY` - The string version of your private key.

*GOTCHA:* You probably have to change `projectId` in [GoogleBQQuery](lib/google_b_q_query.rb#L42). Bonus points for the PR that makes this an ENV Variable.

#### Database

`DATABASE_URL` - RepoScout runs on Postgres (and uses some specific features) so you'll need a database setup and accessible via this ENV variable.

### Up and Running
```
git clone
bundle install
rake migrate_health_reading
rake migrate_recent_search
rackup config.ru
```

The app _should_ be up and running on http://localhost:9292.

## Tests

Yes. There are actually tests. Run them using `rake test`.

## Confesions

Like all "small rack apps" there is too much hand-rolled-ness here for my liking. Part of it was due to my first stab at the Sequel library. Part of it is just the nature of small rack apps.


