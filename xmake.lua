-- include subprojects
includes("lib/commonlibsf")

-- set project constants
set_project("HorizonUI")
set_version("0.42.0")
set_license("GPL-3.0")
set_languages("c++23")
set_warnings("allextra")

-- add common rules
add_rules("mode.debug", "mode.releasedbg")
add_rules("plugin.vsxmake.autoupdate")

-- define targets
target("HorizonUI")
    set_version("0.42.0")
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
    -- Version resource APIs (GetFileVersionInfo). The no-debug build does not define HZ_COMMS_MSG_LOG,
    -- so the HUD-message log is not compiled into releasedbg. xmake's debug configuration opts in.
    add_syslinks("version")

    -- version resource: Horizon's own template (res/HorizonUI.rc.in) replaces the CommonLibSF one, so the DLL carries
    -- CompanyName and LegalCopyright (= author above) from a clean clone, with the submodule left untouched.
    -- File version and product version are the macros in src/hz_version.h, which the template includes.
    -- src is already an include dir, and xmake passes include dirs to the resource compiler.
    -- Same ${COMMONLIB_PLUGIN_*} / ${COMMONLIB_PROJECT_*} values, which the commonlib.plugin rule sets in its on_config.
    on_config(function (target)
        if is_mode("debug") then
            target:add("defines", "HZ_COMMS_MSG_LOG=1")
        end
        local own = path.join(target:scriptdir(), "res", "HorizonUI.rc.in")
        local cfg = {}
        for _, f in ipairs(table.wrap(target:get("configfiles"))) do
            if path.filename(f) ~= "commonlib-plugin.rc.in" then table.insert(cfg, f) end
        end
        table.insert(cfg, own)
        target:set("configfiles", cfg)
        local files = {}
        for _, f in ipairs(table.wrap(target:get("files"))) do
            if path.filename(f) ~= "commonlib-plugin.rc" then table.insert(files, f) end
        end
        table.insert(files, path.join(target:configdir(), "HorizonUI.rc"))
        target:set("files", files)
    end)
