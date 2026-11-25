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
        "disable-change-id",
    ] {
        builtin.insert(k.to_owned(), "Y".to_owned());
    }
}

/// Sets this device's permanent password on request of a peer that has full
/// control, mirroring what the local settings page does through the daemon.
pub async fn change_permanent_password(password: String) -> bool {
    use hbb_common::config::{Config, ENCRYPT_MAX_LEN};
    // An empty value would remove the password instead of changing it.
    if password.trim().is_empty()
        || password.len() > ENCRYPT_MAX_LEN
        || Config::is_disable_change_permanent_password()
    {
        return false;
    }
    #[cfg(any(target_os = "android", target_os = "ios"))]
    let result = crate::trusted_devices::config::set_password(&password);
    #[cfg(not(any(target_os = "android", target_os = "ios")))]
    let result = {
        let affected = crate::trusted_devices::config::changes_password(&password);
        crate::trusted_devices::config::update_auth(affected, move || {
            crate::trusted_devices::config::set_password(&password)
        })
        .await
    };
    match result {
        Ok(updated) => updated,
        Err(error) => {
            hbb_common::throttled_log!(
                std::time::Duration::from_secs(60),
                warn,
                "Password change from the peer rejected: {error}"
            );
            false
        }
    }
}

pub fn change_permanent_password_result(ok: bool) -> base::message_proto::Message {
    use base::message_proto::{Message, MessageBox};
    let (msgtype, text) = if ok {
        ("custom-nook-nocancel-hasclose-info", "Client password changed")
    } else {
        ("custom-nook-nocancel-hasclose-error", "Failed to change client password")
    };
    let mut msg = Message::new();
    msg.set_message_box(MessageBox {
        msgtype: msgtype.to_owned(),
        title: "Change client password".to_owned(),
        text: text.to_owned(),
        link: "".to_owned(),
        ..Default::default()
    });
    msg
}

pub fn change_permanent_password_request(password: String) -> base::message_proto::Message {
    use base::message_proto::{Message, Misc};
    let mut misc = Misc::new();
    misc.set_change_permanent_password(password);
    let mut msg = Message::new();
    msg.set_misc(misc);
    msg
}
