mod dbus;

use std::fs;
use std::time::Duration;
use std::{collections::HashMap, hash::BuildHasherDefault, path::Path, sync::Arc};

use std::io::Read;
use tokio::sync::Mutex;

use anyhow::Result;
use nohash_hasher::NoHashHasher;
use zbus::export::serde::Serialize;

use crate::dbus::async_run;

type NotificationArc =
    Arc<Mutex<HashMap<u32, Notification, BuildHasherDefault<NoHashHasher<u32>>>>>;

#[derive(Serialize)]
pub struct Notifications<'a> {
    pub notifications: Vec<&'a Notification>,
}

#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct Notification {
    pub id: u32,
    pub app_name: String,
    pub summary: String,
    pub body: String,
    pub time: String,
    pub icon: String,
    pub timeout: i32,
    pub urgency: u8,
    pub actions: Vec<String>,
    pub visible: bool,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Action {
    Close,
    Clear,
    Notify(Notification),
}

#[tokio::main]
async fn main() -> Result<()> {
    let notifications: NotificationArc = Arc::new(Mutex::new(HashMap::with_hasher(
        BuildHasherDefault::default(),
    )));

    fs::remove_file(Path::new("/var/run/user/1000/notify-receive.pipe")).ok();
    unix_named_pipe::create("/var/run/user/1000/notify-receive.pipe", Some(0o644))?;

    let mut reader = unix_named_pipe::open_read("/var/run/user/1000/notify-receive.pipe")?;

    let pipe_notifications = notifications.clone();

    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_millis(100));

        loop {
            let mut contents = String::new();
            if reader.read_to_string(&mut contents).is_ok() && !contents.is_empty() {
                let mut notifs = pipe_notifications.lock().await;
                for line in contents.lines() {
                    if line.is_empty() {
                        continue;
                    }

                    if let Ok(id) = line.parse::<u32>() {
                        if let Some(notif) = notifs.get_mut(&id) {
                            notif.visible = false;
                        }
                    }
                }
                println!(
                    "{}",
                    serde_json::to_string(&notifs.values().collect::<Vec<_>>()).unwrap()
                );
            }

            interval.tick().await;
        }
    });

    async_run(notifications.clone()).await?;

    Ok(())
}
