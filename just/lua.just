set export

DEVTOOLS_DIR := justfile_directory()
RECOIL_DIR   := DEVTOOLS_DIR / "RecoilEngine"
BAR_DIR      := DEVTOOLS_DIR / "Beyond-All-Reason"
LDE_DIR      := DEVTOOLS_DIR / "lua-doc-extractor"

# Build lua-doc-extractor from local checkout
build-lde:
    #!/usr/bin/env bash
    set -euo pipefail
    source "$DEVTOOLS_DIR/scripts/common.sh"
    if [ ! -d "$LDE_DIR" ]; then
        err "lua-doc-extractor not found at $LDE_DIR"
        info "Clone it first: just repos::clone extra"
        exit 1
    fi
    cd "$LDE_DIR"
    npm ci && npm run build
    ok "lua-doc-extractor built"

# Generate Lua library from RecoilEngine sources, copy into BAR submodule
library *flags: build-lde
    #!/usr/bin/env bash
    set -euo pipefail
    source "$DEVTOOLS_DIR/scripts/common.sh"
    LDE="node $LDE_DIR/dist/src/cli.js"
    DEST="$RECOIL_DIR/rts/Lua/library/generated"

    info "Extracting Lua docs..."
    $LDE \
        --src "$RECOIL_DIR/rts/{Lua,Rml/SolLua}/**/*.cpp" \
        --dest "$DEST" \
        --repo "https://github.com/beyond-all-reason/RecoilEngine/blob/master" \
        {{flags}}

    if [ -d "$BAR_DIR/recoil-lua-library/library" ]; then
        info "Copying into BAR submodule..."
        clean_dir "$BAR_DIR/recoil-lua-library/library"
        mkdir -p "$BAR_DIR/recoil-lua-library/library"
        cp -r "$RECOIL_DIR/rts/Lua/library/"* \
              "$BAR_DIR/recoil-lua-library/library/"
        ok "Updated $BAR_DIR/recoil-lua-library/library/"
        echo "  Run 'just lua::reset' to reset Recoil library and BAR recoil-lua-library."
    fi

# Generate library then restart LuaLS so the editor picks up changes
library-reload *flags: (library flags)
    -pkill -f lua-language-server
    @echo "LuaLS restarting (editor extension will respawn it)"

# Reset generated Lua library files
#   TODO: This is a workaround for the fact that these CI artifacts are in source control and
#         generally developers don't want generated output dirtying PRs that only change inputs.
#         Prefer recoil-lua-library NOT be a submodule but a local build artifact produced by our
#         scripting layer, with CI building and publishing the package without committing it back.
reset:
    #!/usr/bin/env bash
    set -euo pipefail
    source "$DEVTOOLS_DIR/scripts/common.sh"
    info "Resetting Lua library in RecoilEngine..."
    cd "$RECOIL_DIR"
    git checkout -- rts/Lua/library/
    git clean -fd rts/Lua/library/
    if [ -d "$BAR_DIR/recoil-lua-library" ]; then
        info "Resetting recoil-lua-library submodule in BAR..."
        cd "$BAR_DIR"
        git submodule update --init --force recoil-lua-library
        git -C recoil-lua-library clean -fd
    fi
    ok "Lua library reset."
