## Frank Mega

This web app will be a very simple file sharing service. The main use case:
- user logs in (only works for logged in users)
- there will be a very simple file upload form (single file, no multiple files)
- the service will generate a unique, shareable link
- the service will automatically cleanup the file from the filesystem after some ETA (rules below)

# Deployment

I will install this as a docker container in my home server, and I will expose it through cloudflare tunnel and zero trust, it will have a proper frankmega.example.com domain with TLS. so I need a lean production ready docker configuration.

# Tech stack

- Ruby on Rails 8 (using proper Rails conventions, restful routes/resources, prefer built-in features such as activestorage, activejob, no external database, use sqlite3 if necessary)
- UI should be Tailwind CSS, as clean as possible
- front-end should again use Rails recommendations such as hotwire, stimulus, turbo streams, no react.js or overblown js front-end frameworks. only add npm packages if really necessary (such as for testing)
- prefer the most popular ruby/rails gems, that are well supported, and always check to bundle the most up to date versions
- every important feature must have a unit test associated, I need good coverage.
- make this work properly in development mode, and only consider the real domain in production mode.
- ci script before every git commit, run simplecov, rubocop, brakeman and bundle-audit
- security locks must be less restrict in development so I can test (make that configurable and document in readme)
- it would be good to add security focused tests such as if rate limits in important endpoints, band, ttls are correctly working (could be integration tests)
- always update readme with important configuration aspects
- always check proper http headers such as csp, etc.

# Use Cases

This service must always be protected behind proper authentication. user/password, passkey support, 2fa optional. with a proper user page to change password/passkey/2fa

This service will have a publicly exposed, non-authenticated endpoint, for the downloads, something like frankmega.example.com/download/[hash]

All publicly exposed endpoints (auth or no-auth) must be heavily rate limited (remember it will be behind cloudflare, so maybe keep in mind to not ban their ips)

Very few users will be using the system, all human, so bot behavior (lots of form submits) must be banned for 1 hour 

The download link must have a counter (default to something like 5, overwritable in the file upload form). once counter is reached, the download link should refuse. any attempt to reach a non existent hash must be banned for 1 hour. any attemp to reach any non-existent endpoint must ban for 1 hour. so very strict protections

The will be no sign up page. In the first run, if there is no user, you must let me sign up as the sole admin of the system. As the admin, I will have an invitation management page, where I will be able to create invites. Only one person can sign up with one invite code, which expires as soon as he signs up. No confirmation email is necessary, let the user sign up, change password, passkey, 2fa, etc.

The admin must have a user admin page as well to immediatelly reset password or ban users.

No file uploads will be permanent. There will be the download counter, but even that is hard time limited. If non one downloads until 24 hours after the file is upload, the link is automatically expired, and the file must be deleted. This will be all local file system (docker must allow to mount an external volume to that). use active storage for the uploads, add proper user interface helpers such as progress bar is possible, drag and drop files to the UI, etc.

Just for the admin, maybe it's going to be easier to just have an out of the box admin such as activeadmin or administrate, you can chooose which sounds better.

Only email support will be smtp (maybe gmail pat?) to send reset email and confirmation for 2fa reset. 


# Design

Again, Tailwind, with light and dark themes, user can change through a top menu of sorts. Try to make it using proper HSL color science to choose the pallete but make the colors and visual identity similar to the famous Mega download website. No need to copy, just inspire by it.

# new ideas

Design a plan around all these requirements and suggest important features you think could be important in a service like this.
