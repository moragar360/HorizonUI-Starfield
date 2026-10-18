-- include subprojects
includes("lib/commonlibsf")

-- set project constants
set_project("HorizonUI")
set_version("0.40.2")
set_license("GPL-3.0")
set_languages("c++23")
set_warnings("allextra")

-- add common rules
add_rules("mode.debug", "mode.releasedbg")
add_rules("plugin.vsxmake.autoupdate")

-- define targets
target("HorizonUI")
    set_version("0.40.2")
    add_rules("commonlibsf.plugin", {
        name = "HorizonUI",
        author = "Moragar",
        description = "Horizon UI HUD settings",
        email = "208107460+moragar360@users.noreply.github.com"
    })

    -- add src files
    add_files("src/**.cpp")
    add_headerfiles("src/**.h")
    add_includedirs("src")
    set_pcxxheader("src/pch.h")
