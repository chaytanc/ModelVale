
# README
Discord Admin Tools

## Overview
### Description
This app allows Discord server members to select channels to track and automatically sync the dates and events mentioned in that channel with iCalendar. It also allows server admins to see server statistics and automatically post at peak hours of server use.

## 1. User Stories (Required and Optional)

**Required Must-have Stories**

 * Make Discord Admin Tools account
 * Sign in to Discord
 * Connect to specific servers to manage
 * Post messages at peak hours automatically
     * Base off of number of online users compared to an average, how many have DND on, etc
 * Algorithm to scrape specified channel for date-relevant information 
    * Create meetings based on findings on a calendar within the app
    * Uses regex or other heuristics to determine what is a date
 * Sync with other calendars: create iCal events based on meeting times of the internal calendar
 * Attach links to other sites to each calendar item and store each app user's calendar in an internal database
 * Push or local notifications for when to attend meetings 
     * Possibly using Parse
 * Display server stats in app
     * Top channels for messages and how many
     * Number of members
     * Top posting users
 * One animation of some view
 * Sign out of Discord and app

**Optional Nice-to-have Stories**

* Use NLP models with Python backend to do date-finding
 * Post to multiple channels in a server at once
 * Display most frequent topics in channels and use NLP to categorize and visualize conversation topics over time
 * Sync over iCloud to other devices
 * Side navigation aesthetically similar to actual Discord app

## 2. Screen Archetypes

* Launch view
* Welcome view
 * Login view
   * Users can log in to Discord account
   * Authenticates w Discord API
* Registration view
 * Calendar view
   * Scrapes and displays meetings for specific channels in in-app calendar
   * Syncs with iCal button to create
* Stats view
    * Integrates with discord bots to track statistics in server

## 3. Navigation

**Tab Navigation** (Tab to Screen)

 * Calendar
 * Stats

Optional:
- Settings

**Flow Navigation** (Screen to Screen)

 * Launch
 * Welcome
 * Login
 * Registration


## Wireframes
![](https://i.imgur.com/FH7msj8.jpg)
