' Hubbalicious Board scene.
' One channel serves both shop TVs. Each TV remembers its own role:
'   TV 1 - portrait menu board + music picker
'   TV 2 - landscape ads slideshow
' Content comes from manifest.json in the GitHub repo (see ManifestTask).
'
' Remote:
'   OK      - open the music picker
'   *       - open setup (board role, menu rotation)
'   Back    - close a panel

sub init()
    m.slide = m.top.findNode("slide")
    m.statusLabel = m.top.findNode("statusLabel")
    m.statusTimer = m.top.findNode("statusTimer")
    m.slideTimer = m.top.findNode("slideTimer")
    m.setupPanel = m.top.findNode("setupPanel")
    m.setupItems = m.top.findNode("setupItems")
    m.musicPanel = m.top.findNode("musicPanel")
    m.musicItems = m.top.findNode("musicItems")
    m.nowPlaying = m.top.findNode("nowPlaying")
    m.audio = m.top.findNode("audio")

    m.images = []
    m.imagesLandscape = []
    m.playlists = []
    m.slideSeconds = 15
    m.index = 0
    m.musicIndex = 0
    m.setupIndex = 0

    m.slideTimer.observeField("fire", "nextSlide")
    m.statusTimer.observeField("fire", "clearStatus")
    m.audio.observeField("state", "onAudioState")

    m.manifestTask = CreateObject("roSGNode", "ManifestTask")
    m.manifestTask.observeField("images", "onImages")
    m.manifestTask.observeField("imagesLandscape", "onImagesLandscape")
    m.manifestTask.observeField("playlists", "onPlaylists")
    m.manifestTask.observeField("slideSeconds", "onSlideSeconds")
    m.manifestTask.observeField("fetchOk", "onFetchOk")
    m.manifestTask.control = "RUN"

    applyMode()
    m.top.setFocus(true)
end sub

' ---- config -------------------------------------------------------------

sub applyMode()
    if m.top.boardMode = "tv2" then
        m.slide.width = 1920
        m.slide.height = 1080
        m.slide.translation = [0, 0]
        m.slide.rotation = 0
        m.slide.loadDisplayMode = "scaleToFit"
    else if m.top.boardMode = "tv1" then
        ' Menu images are portrait 1080x1920 and TV 1 is wall-mounted
        ' sideways, so the image is drawn rotated to fill the panel.
        m.slide.width = 1080
        m.slide.height = 1920
        m.slide.loadWidth = 1080
        m.slide.loadHeight = 1920
        m.slide.scaleRotateCenter = [540, 960]
        m.slide.translation = [420, -420]
        if m.top.rotationDir = "ccw" then
            m.slide.rotation = -1.5707963
        else if m.top.rotationDir = "off" then
            m.slide.rotation = 0
        else
            m.slide.rotation = 1.5707963
        end if
        m.slide.loadDisplayMode = "scaleToFit"
    else
        ' No role saved yet: ask on setup panel, nothing to show yet.
        showSetup()
        return
    end if
    m.index = 0
    showSlide()
    startSlideTimer()
end sub

function currentList() as object
    if m.top.boardMode = "tv2" then return m.imagesLandscape
    return m.images
end function

sub startSlideTimer()
    m.slideTimer.duration = m.slideSeconds
    if currentList().count() > 1 then
        m.slideTimer.control = "start"
    else
        m.slideTimer.control = "stop"
    end if
end sub

sub nextSlide()
    list = currentList()
    if list.count() = 0 then return
    m.index = (m.index + 1) mod list.count()
    showSlide()
end sub

sub showSlide()
    list = currentList()
    if list.count() = 0 then
        showStatus("Loading board content...")
        return
    end if
    if m.index >= list.count() then m.index = 0
    uri = list[m.index]
    if type(uri) = "String" and uri <> "" then
        m.slide.uri = uri
        clearStatus()
    end if
end sub

' ---- manifest updates ----------------------------------------------------

sub onImages(evt as object)
    m.images = evt.getData()
    m.index = 0
    showSlide()
    startSlideTimer()
end sub

sub onImagesLandscape(evt as object)
    m.imagesLandscape = evt.getData()
    m.index = 0
    showSlide()
    startSlideTimer()
end sub

sub onPlaylists(evt as object)
    m.playlists = evt.getData()
    buildMusicItems()
end sub

sub onSlideSeconds(evt as object)
    s = evt.getData()
    if s >= 5 and s <= 600 then
        m.slideSeconds = s
        startSlideTimer()
    end if
end sub

sub onFetchOk(evt as object)
    if evt.getData() = false and currentList().count() = 0 then
        showStatus("Board offline - check the TV's WiFi. Retrying...")
    end if
end sub

' ---- music ---------------------------------------------------------------

sub openMusic()
    if m.playlists.count() = 0 then
        showStatus("Music list not loaded yet")
        return
    end if
    buildMusicItems()
    m.musicPanel.visible = true
end sub

sub buildMusicItems()
    m.musicItems.removeChildrenIndex(m.musicItems.getChildCount(), 0)
    for each p in m.playlists
        addMusicRow(p.name)
    end for
    addMusicRow("Stop music")
    highlightMusic()
end sub

sub addMusicRow(text as string)
    row = m.musicItems.createChild("Label")
    row.text = text
    row.width = 1500
    row.font = "font:MediumSystemFont"
    row.color = "0xCCCCCCFF"
end sub

sub highlightMusic()
    count = m.musicItems.getChildCount()
    for i = 0 to count - 1
        row = m.musicItems.getChild(i)
        if i = m.musicIndex then
            row.color = "0xFFD700FF"
        else
            row.color = "0xCCCCCCFF"
        end if
    end for
end sub

sub selectMusic()
    if m.musicIndex >= m.playlists.count() then
        m.audio.control = "stop"
        m.nowPlaying.text = ""
        m.musicPanel.visible = false
        return
    end if
    p = m.playlists[m.musicIndex]
    content = CreateObject("roSGNode", "ContentNode")
    content.url = p.url
    fmt = "mp3"
    if type(p.format) = "String" and p.format <> "" then fmt = p.format
    content.streamFormat = fmt
    m.audio.content = content
    m.audio.control = "play"
    m.nowPlaying.text = "Playing: " + p.name
    m.musicPanel.visible = false
end sub

sub onAudioState(evt as object)
    state = evt.getData()
    if state = "error" then
        showStatus("That station would not play - try another")
        m.nowPlaying.text = ""
    end if
end sub

' ---- setup panel ---------------------------------------------------------

sub showSetup()
    buildSetupItems()
    m.setupPanel.visible = true
end sub

sub buildSetupItems()
    m.setupItems.removeChildrenIndex(m.setupItems.getChildCount(), 0)
    mode = m.top.boardMode
    rotLabel = "Menu rotation: clockwise"
    if m.top.rotationDir = "ccw" then rotLabel = "Menu rotation: counter-clockwise"
    if m.top.rotationDir = "off" then rotLabel = "Menu rotation: off"
    items = ["Use as TV 1 - menu board", "Use as TV 2 - ads board", rotLabel, "Close"]
    for i = 0 to items.count() - 1
        row = m.setupItems.createChild("Label")
        mark = "    "
        if i = 0 and mode = "tv1" then mark = "[x] "
        if i = 1 and mode = "tv2" then mark = "[x] "
        row.text = mark + items[i]
        row.width = 1500
        row.font = "font:MediumSystemFont"
        row.color = "0xCCCCCCFF"
    end for
    highlightSetup()
end sub

sub highlightSetup()
    count = m.setupItems.getChildCount()
    for i = 0 to count - 1
        row = m.setupItems.getChild(i)
        if i = m.setupIndex then
            row.color = "0xFFD700FF"
        else
            row.color = "0xCCCCCCFF"
        end if
    end for
end sub

sub selectSetup()
    if m.setupIndex = 0 then
        m.top.boardMode = "tv1"
        persistConfig()
        m.setupPanel.visible = false
    else if m.setupIndex = 1 then
        m.top.boardMode = "tv2"
        persistConfig()
        m.setupPanel.visible = false
    else if m.setupIndex = 2 then
        if m.top.rotationDir = "cw" then
            m.top.rotationDir = "ccw"
        else if m.top.rotationDir = "ccw" then
            m.top.rotationDir = "off"
        else
            m.top.rotationDir = "cw"
        end if
        persistConfig()
        buildSetupItems()
        return
    else
        if m.top.boardMode = "" then return
        m.setupPanel.visible = false
    end if
end sub

sub persistConfig()
    ' Render threads cannot touch the registry; main.brs writes these.
    m.top.saveMode = m.top.boardMode
    m.top.saveRotation = m.top.rotationDir
end sub

' ---- status line ---------------------------------------------------------

sub showStatus(text as string)
    m.statusLabel.text = text
    m.statusLabel.visible = true
    m.statusTimer.control = "start"
end sub

sub clearStatus()
    m.statusLabel.visible = false
    m.statusTimer.control = "stop"
end sub

' ---- keys ----------------------------------------------------------------

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if m.setupPanel.visible then
        if key = "down" then
            m.setupIndex = (m.setupIndex + 1) mod 4
            highlightSetup()
            return true
        else if key = "up" then
            m.setupIndex = (m.setupIndex + 3) mod 4
            highlightSetup()
            return true
        else if key = "OK" then
            selectSetup()
            return true
        else if key = "back" or key = "options" then
            if m.top.boardMode <> "" then m.setupPanel.visible = false
            return true
        end if
        return true
    end if

    if m.musicPanel.visible then
        if key = "down" then
            m.musicIndex = (m.musicIndex + 1) mod m.musicItems.getChildCount()
            highlightMusic()
            return true
        else if key = "up" then
            m.musicIndex = (m.musicIndex + m.musicItems.getChildCount() - 1) mod m.musicItems.getChildCount()
            highlightMusic()
            return true
        else if key = "OK" then
            selectMusic()
            return true
        else if key = "back" or key = "options" then
            m.musicPanel.visible = false
            return true
        end if
        return true
    end if

    if key = "OK" then
        openMusic()
        return true
    else if key = "options" then
        showSetup()
        return true
    end if
    return false
end function
