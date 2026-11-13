' Downloads one slide image to a fresh local path, then tells the scene
' where it landed. Every fetch gets its own tmp: path (slide-<seq>) so a
' Poster reload can never show a stale texture cached under a reused
' path. Files two generations old are deleted, so tmp: stays bounded and
' the decoded textures the Poster no longer references are the only ones
' left for the system to reclaim. Before this, every manifest URL kept
' its own cached texture (11 ads x ~8 MB decoded).

sub init()
    m.top.functionName = "fetchSlide"
end sub

sub fetchSlide()
    url = m.top.url
    if url = invalid or url = "" then
        m.top.failed = true
        return
    end if
    ext = "jpg"
    if lcase(right(url, 4)) = ".png" then ext = "png"
    seq = m.top.seq
    path = "tmp:/slide-" + strI(seq) + "." + ext
    ' Remove the generation we no longer need; tmp: then holds at most
    ' the current slide and the one before it.
    fs = CreateObject("roFileSystem")
    if fs <> invalid then
        fs.delete("tmp:/slide-" + strI(seq - 2) + ".jpg")
        fs.delete("tmp:/slide-" + strI(seq - 2) + ".png")
    end if
    http = CreateObject("roUrlTransfer")
    http.setUrl(url)
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    http.initClientCertificates()
    code = http.getToFile(path)
    if code = 200 then
        m.top.localUri = path
    else
        m.top.failed = true
    end if
end sub
