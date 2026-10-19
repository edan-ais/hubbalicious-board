' Hubbalicious Board - entry point.
' Reads the saved per-TV config (which board this TV is, menu rotation)
' from the device registry and hands it to the scene. Registry access is
' only allowed here and in Task threads, never in the render thread.

sub Main()
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    sec = CreateObject("roRegistrySection", "hubbalicious-board")
    mode = sec.read("mode")
    rot = sec.read("rotation")
    if rot = "" then rot = "cw"

    scene = screen.CreateScene("BoardScene")
    scene.observeField("saveMode", m.port)
    scene.observeField("saveRotation", m.port)
    scene.boardMode = mode
    scene.rotationDir = rot
    screen.show()

    while true
        msg = wait(0, m.port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent" then
            if msg.isScreenClosed() then exit while
        else if msgType = "roSGNodeEvent" then
            ' The scene asked us to persist config; write it here where
            ' registry access is legal.
            field = msg.getField()
            if field = "saveMode" or field = "saveRotation" then
                sec.write("mode", scene.saveMode)
                sec.write("rotation", scene.saveRotation)
                sec.flush()
            end if
        end if
    end while
end sub
