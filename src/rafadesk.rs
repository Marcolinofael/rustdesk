use hbb_common::config;

const APP_NAME: &str = "RafaDesk";
const SERVER: &str = "acesso.rafaelmarcolino.online";
const KEY: &str = "qvB6u6D58xn7FvcsZ+Dcr1+CEDRy0rhi+CFXrecPbFs=";

/// Applies the RafaDesk branding and server settings, the same way a signed
/// custom.txt would, before anything reads the app name or the options.
pub fn apply() {
    *config::APP_NAME.write().unwrap() = APP_NAME.to_owned();
    let mut overwrite = config::OVERWRITE_SETTINGS.write().unwrap();
    overwrite.insert("custom-rendezvous-server".to_owned(), SERVER.to_owned());
    overwrite.insert("relay-server".to_owned(), SERVER.to_owned());
    overwrite.insert("key".to_owned(), KEY.to_owned());
    drop(overwrite);
    let mut builtin = config::BUILTIN_SETTINGS.write().unwrap();
    for k in [
        "hide-powered-by-me",
        "hide-network-settings",
        "hide-server-settings",
        "hide-proxy-settings",
        "hide-websocket-settings",
        "hide-remote-printer-settings",
        "hide-stop-service",
        "disable-change-id",
    ] {
        builtin.insert(k.to_owned(), "Y".to_owned());
    }
}
