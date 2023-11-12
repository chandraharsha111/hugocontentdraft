baseURL = "https://www.chandraharsha111.com"
title = "Chandra Harsha Jupalli"

theme = "hugo-profile"

languageCode = "en"
defaultContentLanguage = "en"

paginate = 20

pygmentsStyle = "b2"
pygmentsCodeFences = true
pygmentsCodeFencesGuessSyntax = true

#disqusShortname = "yourdiscussshortname"

[params]
    author = "Chandra Harsha Jupalli"
    description = "Chandra's personal website"
    keywords = "blog,developer,personal"
    info = "Software Developer and Passive Investor"
    avatarURL = "images/avatar.jpg"
    #gravatar = "john.doe@example.com"
    footerContent = "Every thing should be made as simple as possible, but not simpler - Albert Einstein"

    dateFormat = "January 2, 2006"

    hideFooter = false
    hideCredits = true
    hideCopyright = false
    since = 2020

    # Git Commit in Footer, uncomment the line below to enable it.
    commit = "https://github.com/luizdepra/hugo-coder/tree/"

    rtl = false

    # Specify light/dark colorscheme
    # Supported values:
    # "auto" (use preference set by browser)
    # "dark" (dark background, light foreground)
    # "light" (light background, dark foreground) (default)
    colorScheme = "auto"

    # Hide the toggle button, along with the associated vertical divider
    hideColorSchemeToggle = false

    # Series see also post count
    maxSeeAlsoItems = 5

    # Enable Twemoji
    enableTwemoji = true

    # Custom CSS
    customCSS = []

    # Custom SCSS
    customSCSS = []

    # Custom JS
    customJS = []

# If you want to use fathom(https://usefathom.com) for analytics, add this section
[params.fathomAnalytics]
    siteID = "ABCDE"
    # Default value is cdn.usefathom.com, overwrite this if you are self-hosting
    serverURL = "analytics.example.com"

# If you want to use plausible(https://plausible.io) for analytics, add this section
[params.plausibleAnalytics]
    domain = "example.com"
    # Default value is plausible.io, overwrite this if you are self-hosting or using a custom domain
    serverURL = "analytics.example.com"

# If you want to use goatcounter(https://goatcounter.com) for analytics, add this section
[params.goatCounter]
    code = "code"

[taxonomies]
  category = "categories"
  series = "series"
  tag = "tags"
  author = "authors"

[[params.social]]
    name = "Github"
    icon = "fa fa-github"
    weight = 1
    url = "https://github.com/chandraharsha111/"
[[params.social]]
    name = "Twitter"
    icon = "fa fa-twitter"
    weight = 3
    url = "https://twitter.com/harsha1038/"
[[params.social]]
    name = "LinkedIn"
    icon = "fa fa-linkedin"
    weight = 4
    url = "https://www.linkedin.com/in/cjupa/"
[[params.social]]
    name = "Facebook"
    icon = "fa fa-facebook"
    weight = 5
    url = "https://facebook.com/chandra.harsha.jupalli"

[languages]
    [languages.en]
        languageName = "English"

        [languages.en.menu]

            [[languages.en.menu.main]]
            name = "About"
            weight = 1
            url = "about/"

            [[languages.en.menu.main]]
            name = "Blog"
            weight = 2
            url = "posts/"

            [[languages.en.menu.main]]
            name = "Projects"
            weight = 3
            url = "projects/"
