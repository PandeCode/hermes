# the native messaging host the firenvim browser extension starts, what
# :call firenvim#install() would write, pointed at this editor. firefox and
# its forks find the manifest in lib/mozilla/native-messaging-hosts, chromium
# in etc/chromium/native-messaging-hosts
{ pkgs, editor }:

let
  # firenvim#install's prolog: opens stdio early so messages printed while the
  # config loads reach the extension
  prolog = pkgs.writeText "firenvim-prolog.vim" ''
    let g:firenvim_config = {'globalSettings': {}, 'localSettings': {'.*': {}}}
    let g:firenvim_i = []
    let g:firenvim_o = []
    let g:Firenvim_oi = {i, d, e -> add(g:firenvim_i, d)}
    let g:Firenvim_oo = {t -> [chansend(2, t)] + add(g:firenvim_o, t)}
    let g:firenvim_c = stdioopen({'on_stdin': {i, d, e -> g:Firenvim_oi(i, d, e)}, 'on_print': {t -> g:Firenvim_oo(t)}})
    let g:started_by_firenvim = v:true
  '';

  host = pkgs.writeShellScript "firenvim" ''
    # firenvim writes the page's text to files here
    dir="''${XDG_DATA_HOME:-$HOME/.local/share}/firenvim"
    mkdir -p "$dir"
    chmod 700 "$dir"
    cd "$dir" || exit 1
    exec ${editor}/bin/nvim --headless --cmd "source ${prolog}" -c "call firenvim#run()"
  '';

  manifest =
    allowed:
    builtins.toJSON (
      {
        name = "firenvim";
        description = "Turn your browser into a Neovim GUI.";
        path = "${host}";
        type = "stdio";
      }
      // allowed
    );

  # the extension's id on addons.mozilla.org and on the chrome web store
  firefox = manifest { allowed_extensions = [ "firenvim@lacamb.re" ]; };
  chromium = manifest {
    allowed_origins = [ "chrome-extension://egpjdkipkomnmjhjmdamaniclmdlobbo/" ];
  };
in

pkgs.runCommand "firenvim-host" { inherit firefox chromium; } ''
  mkdir -p $out/lib/mozilla/native-messaging-hosts $out/etc/chromium/native-messaging-hosts
  printf '%s' "$firefox" > $out/lib/mozilla/native-messaging-hosts/firenvim.json
  printf '%s' "$chromium" > $out/etc/chromium/native-messaging-hosts/firenvim.json
''
