# RepoScout

http://reposcout.com

RepoScout helps you quickly understand the activity AND community of any repository hosted on GitHub through a ScoutScore. Use the form below or download the Chrome Extension to view a ScoutScore anytime you are looking at a repo in Chrome.

RepoScout was created as part of the GitHub Data Challenge 2014.

## More About RepoScout

*How do you decide that a repo is worth using?*

For me, it usually involves some spelunking around GitHub to check out recent commits, issues and pull requests, and even things like watches and forks. And that's all before I even settle in to check out the README!

You may have noticed that the process I had been using involved clicking on several links AND then reading. Clicking!?!? Reading!?!? These are two of the things I try to avoid on the internet! I needed something easier.

And so I started writing a complicated piece of logic and assumptions in a form factor we call software. One calendar month, about 60 programming hours, and 37ish commits later I am ready to share RepoScout.

RepoScout is a ruthlessly judgemental piece of software created to assess the activity and community around any given repo. It doesn't care about the fact that you never violated the Law of Demeter or that your Test Coverage is at 97.8%. It cares abouts Events, the currency of activity and community in regards to your repo.

Utilizing the GitHub Events Timeline through Google Big Query, RepoScout looks at Watch, Fork, Issue, PullRequest, and Push Events over the last 90 days for your repo. It then uses a (somewhat overly complex) scoring system to arrive at a ScoutScore for your repo.

And while it's nice to have a website like this as a home base for getting a ScoutScore for any repo, this site sadly does involve the dreaded aforementioned clicking, reading, and as if things could get any worse, TYPING!

That's why I created the RepoScout Chrome Extension. This extension looks at any repo you do and quickly gets the ScoutScore for said repo, no clicking or typing required. (Clicking is required for detailed veiws. Also, it seems we are stuck with the "reading" requirement.)

## Components

Three sections of this repo:

* [Service](service): Tiny website and JSON endpoint for RepoScout. Currently live at http://reposcout.com
* [Chrome Extension](chrome_extension/repo-scout): Code for a Chrome Extension that lets you see a ScoutScore while browsing repos on GitHub
* [Practice](practice): The jumbled mess of scratch work that kicked off each component

## Terminology Note

You may find a lot of "health" references. RepoScout was RepoHealth before it was RepoScout. In an ideal world, all the references would have been changed. The world is not ideal.

## Icons

Icons are all from the great wonderful (Font Awesome)[http://fortawesome.github.io/Font-Awesome/]

## Contributors

@markmcspadden

## License

Release under the [MIT LICENSE](LICENSE) 