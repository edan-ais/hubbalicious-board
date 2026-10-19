' Polls manifest.json from the GitHub repo every 5 minutes and publishes
' the content lists to the scene. Content changes pushed to the repo show
' up on the TVs without reinstalling the channel.

sub init()
    m.top.functionName = "pollManifest"
end sub

sub pollManifest()
    url = "https://raw.githubusercontent.com/edan-ais/hubbalicious-board/main/manifest.json"
    while true
        http = CreateObject("roUrlTransfer")
        http.setUrl(url)
        http.setCertificatesFile("common:/certs/ca-bundle.crt")
        http.initClientCertificates()
        http.addHeader("Cache-Control", "no-cache")
        http.setMessagePort(CreateObject("roMessagePort"))
        resp = http.getToString()
        if resp <> invalid and resp <> "" then
            json = ParseJson(resp)
            if type(json) = "roAssociativeArray" then
                if type(json.images) = "roArray" then m.top.images = json.images
                if type(json.images_landscape) = "roArray" then m.top.imagesLandscape = json.images_landscape
                if type(json.playlists) = "roArray" then m.top.playlists = json.playlists
                ss = json.slide_seconds
                if (type(ss) = "Integer" or type(ss) = "Float" or type(ss) = "Double") and ss > 0 then
                    m.top.slideSeconds = int(ss)
                end if
                m.top.fetchOk = true
            else
                m.top.fetchOk = false
            end if
        else
            m.top.fetchOk = false
        end if
        sleep(300000)
    end while
end sub
