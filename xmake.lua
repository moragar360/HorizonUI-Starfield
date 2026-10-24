-- include subprojects
includes("lib/commonlibsf")

-- set project constants
set_project("HorizonUI")
-- File version, four parts. The settings schema stays "0.42.0" (HZF::kVersion, preset Version=, HZ_VERSION).
-- CommonLibSF's SFSE::Init line reads this version. The pinned template writes the fourth
-- PluginVersion component as a literal 0, so res/horizonui-plugin.cpp.in uses HZ_FILE_VERSION_BUILD.
set_version("0.42.0.10")
set_license("GPL-3.0")
set_languages("c++23")
set_warnings("allextra")

-- add common rules
add_rules("mode.debug", "mode.releasedbg")
add_rules("plugin.vsxmake.autoupdate")

-- define targets
target("HorizonUI")
    set_version("0.42.0.10")
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
    -- Version resource APIs (GetFileVersionInfo).
    -- HZ_COMMS_MSG_LOG lives in src/hz_version.h (1 for this test build). The README release checklist turns the log off.
    add_syslinks("version")

    -- xmake's semver parser rejects a 4-part numeric version. set_version is still the file version
    -- (0.42.0.10). major.minor.patch stay the first three parts, and the fourth is the build number.
    on_load(function (target)
        local semver = import("core.base.semver")
        if semver._hz4 then return end
        local orig = semver.new
        semver.new = function (version)
            if type(version) == "string" then
                local major, minor, patch, build = version:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
                if major then
                    return orig(string.format("%s.%s.%s+%s", major, minor, patch, build))
                end
            end
            return orig(version)
        end
        semver._hz4 = true
    end)

    -- version resource: Horizon's own template (res/HorizonUI.rc.in) replaces the CommonLibSF one, so the DLL carries
    -- CompanyName and LegalCopyright (= author above) from a clean clone, with the submodule left untouched.
    -- File version and product version are the macros in src/hz_version.h, which the template includes.
    -- src is already an include dir, and xmake passes include dirs to the resource compiler.
    -- Same ${COMMONLIB_PLUGIN_*} / ${COMMONLIB_PROJECT_*} values, which the commonlib.plugin rule sets in its on_config.
    -- The plugin cpp template is also Horizon's (res/horizonui-plugin.cpp.in): the pinned CommonLibSF template
    -- writes PluginVersion's fourth component as a literal 0, which is the "v0.42.0.0" SFSE::Init line.
    on_config(function (target)
        local hdr = io.readfile(path.join(target:scriptdir(), "src", "hz_version.h")) or ""
        local function macro(name)
            return hdr:match("#define%s+" .. name .. "%s+(%d+)")
        end
        local build = macro("HZ_FILE_VERSION_BUILD") or ""
        local ver = target:version() or ""
        local major, minor, patch, fourth = ver:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
        if not fourth then
            raise("set_version must be the 4-part file version from src/hz_version.h, not '" .. ver .. "'")
        end
        if major ~= macro("HZ_FILE_VERSION_MAJOR") or minor ~= macro("HZ_FILE_VERSION_MINOR")
            or patch ~= macro("HZ_FILE_VERSION_PATCH") or fourth ~= build then
            raise("set_version " .. ver .. " does not match src/hz_version.h")
        end
        target:set("configvar", "HZ_FILE_VERSION_BUILD", build)
        local own_rc = path.join(target:scriptdir(), "res", "HorizonUI.rc.in")
        local own_cpp = path.join(target:scriptdir(), "res", "horizonui-plugin.cpp.in")
        local cfg = {}
        for _, f in ipairs(table.wrap(target:get("configfiles"))) do
            local name = path.filename(f)
            if name ~= "commonlib-plugin.rc.in" and name ~= "commonlibsf-plugin.cpp.in" then table.insert(cfg, f) end
        end
        table.insert(cfg, own_rc)
        table.insert(cfg, own_cpp)
        target:set("configfiles", cfg)
        local files = {}
        for _, f in ipairs(table.wrap(target:get("files"))) do
            local name = path.filename(f)
            if name ~= "commonlib-plugin.rc" and name ~= "commonlibsf-plugin.cpp" then table.insert(files, f) end
        end
        table.insert(files, path.join(target:configdir(), "HorizonUI.rc"))
        table.insert(files, path.join(target:configdir(), "horizonui-plugin.cpp"))
        target:set("files", files)
    end)
