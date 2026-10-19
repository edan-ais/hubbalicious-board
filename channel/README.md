# Hubbalicious Board - Roku channel

The channel that turns this repo's content into the app on the shop's two
Roku TVs. It reads `manifest.json` from this repo (root) over the internet
and shows:

- **TV 1** - portrait menu board (`images`) + music picker (`playlists`)
- **TV 2** - landscape ads slideshow (`images_landscape`)

The same zip installs on both TVs; each TV picks its own role the first
time it runs. Content updates (new menu image, new ads, station changes)
are just commits to this repo - the TVs pick them up within about 5
minutes. No reinstall needed.

## Remote control

- **OK** - open the music picker, choose a station to play through the TV
- **\*** (Options) - setup: switch this TV between "TV 1 - menu board" and
  "TV 2 - ads board", or flip the menu rotation if the menu shows sideways
- **Back** - close a panel

## Install from an Android phone (no PC)

The TVs are already in developer mode (that is how the current app got
on). Installing this zip replaces the current "dev" app on that TV.

1. Connect the phone to the shop WiFi (same network as the TVs).
2. Download the zip: open
   `https://raw.githubusercontent.com/edan-ais/hubbalicious-board/main/channel/dist/hubbalicious-board.zip`
   in the phone browser. It saves to Downloads.
3. On the TV, find its IP address: **Settings > Network > About** on the
   Roku home screen (or look in the Roku mobile app).
4. In the phone browser go to `http://TV-IP` (for example
   `http://192.168.1.50`). A Roku login page appears.
5. Log in with username **rokudev** and the developer password that was
   set when developer mode was turned on. If nobody remembers it: on the
   TV remote press **Home x3, Up x2, Right, Left, Right, Left, Right**,
   choose "Enable installer and restart", set a new password, and after
   the reboot note the IP it shows.
6. On the developer page choose **Browse**, pick the downloaded zip, then
   **Install**.
7. Open the new app from the Roku home screen ("Hubbalicious Board").
   First run asks which board this TV is: pick **TV 1 - menu board** on
   the menu TV, **TV 2 - ads board** on the ads TV. The choice is saved.
8. Repeat on the second TV with its own IP.

If the menu on TV 1 shows sideways after install, press **\*** and change
"Menu rotation" until it is upright.

## Rollback

Installing replaces the sideloaded "dev" app slot. The previous app built
by David and Lexie is not in this repo, so going back to it would need
their original zip. The content (menus, ads, music) is identical either
way because both apps read this repo's manifest.json.

## Morning auto-launch (ECP + MacroDroid)

Roku's External Control Protocol can launch the sideloaded app over the
shop WiFi - the sideloaded app's ID is always `dev`.

- Check it from any phone browser on shop WiFi:
  `http://TV-IP:8060/query/apps` lists installed apps; `dev` is this one.
- Launch it: `POST http://TV-IP:8060/launch/dev` (empty body).

With the free MacroDroid app on a spare Android phone left at the shop on
a charger:

1. New macro, trigger: **Day/Time** - daily at 9:45am
2. Action: **HTTP Request** - POST to `http://TV1-IP:8060/launch/dev`
3. Add a second HTTP Request action for TV 2's IP
4. In Android settings, exclude MacroDroid from battery optimization

Both TVs should have fixed (reserved) addresses in the shop router so the
IPs do not change.

## Layout

- `manifest` - Roku channel manifest
- `source/main.brs` - entry point, loads saved per-TV settings
- `components/` - the screen, manifest poller, music player
- `images/` - channel icon + splash (copied from `../branding`, icons
  padded to Roku's exact required sizes)
- `dist/hubbalicious-board.zip` - the sideloadable package

## Rebuilding the zip after changes

```
cd channel
zip -r dist/hubbalicious-board.zip manifest source components images
```

Optional manifest.json fields the channel understands:

- `slide_seconds` (5-600) - seconds between slides; default 15
